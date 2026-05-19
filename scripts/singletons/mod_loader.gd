extends Node

const ModDescriptorScript := preload("res://mods/loader/mod_descriptor.gd")
const ModLoaderAPIScript := preload("res://mods/loader/mod_loader_api.gd")

const BUILTIN_MODS_DIR := "res://mods/available"
const USER_MODS_DIR := "user://mods"
const ENABLED_MODS_FILE := "user://mods_enabled.json"

# Maps a semantic data-target name -> the real res:// path the base game reads.
# Mods declare data overlays using these keys in mod.json.
const DATA_TARGETS := {
	"messages_dir": "res://data/messages",
	"emails_dir": "res://data/emails",
	"tasks_dir": "res://data/random/tasks",
	"scams_dir": "res://data/random/scams",
	"events": "res://data/events/events.json",
	"news": "res://data/news.json",
	"shops_items": "res://data/browser/shops_items.json",
	"pix_codes": "res://data/bank/pix_codes_data.json",
	"ticket_codes": "res://data/bank/ticket_codes_data.json",
	"reviews": "res://data/browser/reviewed_companies.json",
}

#region STATE
var available_mods: Array = []
var enabled_mod_ids: PackedStringArray = PackedStringArray()
var loaded_mods: Array = []

var _directory_extras: Dictionary = {}
var _file_patches: Dictionary = {}
var _asset_roots: Dictionary = {}
var _hooks: Dictionary = {}
var _mod_apis: Dictionary = {}
var _mod_script_instances: Dictionary = {}
var _path_to_target_key: Dictionary = {}
#endregion

func _ready() -> void:
	print("[ModLoader] booting")
	_ensure_user_mods_dir()
	_build_path_reverse_map()

	available_mods = _discover_all_mods()
	enabled_mod_ids = _read_enabled_list()

	if available_mods.is_empty():
		print("[ModLoader] no mods discovered")
		return

	_activate_enabled_mods()
	print("[ModLoader] active: %d / %d available" % [loaded_mods.size(), available_mods.size()])


#region DISCOVERY

func _ensure_user_mods_dir() -> void:
	if not DirAccess.dir_exists_absolute(USER_MODS_DIR):
		DirAccess.make_dir_recursive_absolute(USER_MODS_DIR)

func _build_path_reverse_map() -> void:
	for key in DATA_TARGETS:
		_path_to_target_key[DATA_TARGETS[key]] = key

func _discover_all_mods() -> Array:
	var all: Array = []
	all.append_array(_discover_in_directory(BUILTIN_MODS_DIR, true))
	all.append_array(_discover_in_directory(USER_MODS_DIR, false))

	var seen := {}
	var unique: Array = []
	for desc in all:
		if seen.has(desc.id):
			push_warning("[ModLoader] duplicate mod id '%s' at %s — ignoring" % [desc.id, desc.mod_path])
			continue
		seen[desc.id] = true
		unique.append(desc)
	return unique

func _discover_in_directory(base_path: String, builtin: bool) -> Array:
	var found: Array = []
	if not DirAccess.dir_exists_absolute(base_path):
		return found

	var dir := DirAccess.open(base_path)
	if dir == null:
		return found

	dir.list_dir_begin()
	while true:
		var entry := dir.get_next()
		if entry == "":
			break
		if not dir.current_is_dir():
			continue
		if entry.begins_with("."):
			continue

		var manifest_path: String = base_path.path_join(entry).path_join("mod.json")
		if not FileAccess.file_exists(manifest_path):
			continue

		var desc: Variant = ModDescriptorScript.from_manifest(manifest_path, builtin)
		if desc == null:
			push_warning("[ModLoader] invalid manifest at %s" % manifest_path)
			continue
		found.append(desc)
	dir.list_dir_end()
	return found

#endregion


#region ENABLED LIST PERSISTENCE

func _read_enabled_list() -> PackedStringArray:
	var out := PackedStringArray()
	if not FileAccess.file_exists(ENABLED_MODS_FILE):
		return out
	var file := FileAccess.open(ENABLED_MODS_FILE, FileAccess.READ)
	if file == null:
		return out
	var text := file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_ARRAY:
		return out
	for id in parsed:
		out.append(str(id))
	return out

func save_enabled_list(ids: PackedStringArray) -> void:
	enabled_mod_ids = ids
	var file := FileAccess.open(ENABLED_MODS_FILE, FileAccess.WRITE)
	if file == null:
		push_error("[ModLoader] could not write %s" % ENABLED_MODS_FILE)
		return
	var as_array: Array = []
	for id in ids:
		as_array.append(id)
	file.store_string(JSON.stringify(as_array))
	file.close()

func is_enabled(mod_id: String) -> bool:
	return mod_id in enabled_mod_ids

#endregion


#region ACTIVATION

func _activate_enabled_mods() -> void:
	var queue: Array = []
	for desc in available_mods:
		if is_enabled(desc.id):
			queue.append(desc)

	queue.sort_custom(func(a, b): return a.priority > b.priority)

	for desc in queue:
		if not _check_dependencies(desc, queue):
			push_warning("[ModLoader] skipping '%s' — missing dependencies" % desc.id)
			continue
		_activate_mod(desc)

func _check_dependencies(desc, queue: Array) -> bool:
	if desc.depends.is_empty():
		return true
	var queued_ids := {}
	for d in queue:
		queued_ids[d.id] = true
	for dep_id in desc.depends:
		if not queued_ids.has(dep_id):
			return false
	return true

func _activate_mod(desc) -> void:
	if desc.pack_path != "":
		_load_resource_pack_for_mod(desc)

	_index_data_overlays(desc)

	if desc.assets_path != "":
		_asset_roots[desc.id] = desc.mod_path.path_join(desc.assets_path)

	if desc.script_path != "":
		_instantiate_mod_script(desc)

	loaded_mods.append(desc)
	print("[ModLoader] loaded: %s v%s (%s)" % [desc.display_name, desc.version, desc.id])

func _load_resource_pack_for_mod(desc) -> void:
	var pack_full_path: String = desc.mod_path.path_join(desc.pack_path)
	if not FileAccess.file_exists(pack_full_path):
		push_warning("[ModLoader] pack not found for '%s': %s" % [desc.id, pack_full_path])
		return
	var ok := ProjectSettings.load_resource_pack(pack_full_path, true)
	if not ok:
		push_warning("[ModLoader] failed to load pack for '%s'" % desc.id)

func _index_data_overlays(desc) -> void:
	for target_key in desc.data_entries.keys():
		if not DATA_TARGETS.has(target_key):
			push_warning("[ModLoader] mod '%s' references unknown data target '%s'" % [desc.id, target_key])
			continue
		var entry: Variant = desc.data_entries[target_key]
		var rel_path: String = ""
		var mode: String = "merge"

		if entry is String:
			rel_path = entry
		elif entry is Dictionary:
			rel_path = str(entry.get("path", ""))
			mode = str(entry.get("mode", "merge"))
		else:
			continue

		if rel_path == "":
			continue

		var fs_path: String = desc.mod_path.path_join(rel_path)

		if target_key.ends_with("_dir"):
			if not DirAccess.dir_exists_absolute(fs_path):
				push_warning("[ModLoader] mod '%s': directory not found %s" % [desc.id, fs_path])
				continue
			if not _directory_extras.has(target_key):
				_directory_extras[target_key] = []
			_directory_extras[target_key].append(fs_path)
		else:
			if not FileAccess.file_exists(fs_path):
				push_warning("[ModLoader] mod '%s': file not found %s" % [desc.id, fs_path])
				continue
			if not _file_patches.has(target_key):
				_file_patches[target_key] = []
			_file_patches[target_key].append({
				"mod_id": desc.id,
				"mode": mode,
				"fs_path": fs_path,
			})

func _instantiate_mod_script(desc) -> void:
	var script_full_path: String = desc.mod_path.path_join(desc.script_path)
	if not FileAccess.file_exists(script_full_path):
		push_warning("[ModLoader] mod '%s' script not found: %s" % [desc.id, script_full_path])
		return

	var script_resource: Script = null

	if desc.is_builtin:
		script_resource = load(script_full_path) as Script
	else:
		var file := FileAccess.open(script_full_path, FileAccess.READ)
		if file == null:
			push_warning("[ModLoader] cannot read '%s'" % script_full_path)
			return
		var source := file.get_as_text()
		file.close()

		var gd := GDScript.new()
		gd.source_code = source
		var err := gd.reload()
		if err != OK:
			push_warning("[ModLoader] failed to compile script of mod '%s' (err %d)" % [desc.id, err])
			return
		script_resource = gd
		push_warning("[ModLoader] '%s' uses user-supplied GDScript — has full access to OS APIs, install only from sources you trust" % desc.id)

	if script_resource == null:
		return

	var instance: Variant = script_resource.new()
	if instance == null:
		push_warning("[ModLoader] could not instance mod script for '%s'" % desc.id)
		return

	var api := ModLoaderAPIScript.new(desc.id)
	_mod_apis[desc.id] = api
	_mod_script_instances[desc.id] = instance

	if instance is Node:
		add_child(instance)

	if instance.has_method("_on_mod_load"):
		instance.call("_on_mod_load", api)

#endregion


#region DATA OVERLAY API

func read_json_root(file_path: String) -> Variant:
	var base: Variant = _read_raw_json(file_path)
	var target_key: String = _path_to_target_key.get(file_path, "")
	if target_key == "" or not _file_patches.has(target_key):
		return base

	var result: Variant = base
	for patch in _file_patches[target_key]:
		var overlay: Variant = _read_raw_json(patch.fs_path)
		if overlay == null:
			continue
		if patch.mode == "replace":
			result = overlay
		else:
			result = _deep_merge(result, overlay)
	return result

func load_directory_roots(base_dir_path: String) -> Array:
	var roots: Array = []
	roots.append_array(_load_roots_in_dir(base_dir_path))

	var target_key: String = _path_to_target_key.get(base_dir_path, "")
	if target_key != "" and _directory_extras.has(target_key):
		for extra_dir in _directory_extras[target_key]:
			roots.append_array(_load_roots_in_dir(extra_dir))
	return roots

func _read_raw_json(file_path: String) -> Variant:
	if not FileAccess.file_exists(file_path):
		return null
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()
	return JSON.parse_string(text)

func _load_roots_in_dir(dir_path: String) -> Array:
	var roots: Array = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return roots

	var names: Array[String] = []
	dir.list_dir_begin()
	while true:
		var fname := dir.get_next()
		if fname == "":
			break
		if dir.current_is_dir():
			continue
		if fname.begins_with("."):
			continue
		if fname.get_extension().to_lower() != "json":
			continue
		names.append(fname)
	dir.list_dir_end()

	names.sort()
	for fname in names:
		var data: Variant = _read_raw_json(dir_path.path_join(fname))
		if data != null:
			roots.append(data)
	return roots

func _deep_merge(base: Variant, overlay: Variant) -> Variant:
	if base == null:
		return overlay
	if overlay == null:
		return base
	if typeof(base) == TYPE_DICTIONARY and typeof(overlay) == TYPE_DICTIONARY:
		var merged: Dictionary = base.duplicate(true)
		for key in overlay.keys():
			if merged.has(key):
				merged[key] = _deep_merge(merged[key], overlay[key])
			else:
				merged[key] = overlay[key]
		return merged
	if typeof(base) == TYPE_ARRAY and typeof(overlay) == TYPE_ARRAY:
		var merged_arr: Array = base.duplicate(true)
		for item in overlay:
			merged_arr.append(item)
		return merged_arr
	return overlay

#endregion


#region HOOKS

func _register_hook(mod_id: String, hook_name: String, callback: Callable) -> void:
	if not _hooks.has(hook_name):
		_hooks[hook_name] = []
	_hooks[hook_name].append({"mod_id": mod_id, "callback": callback})

func emit_hook(hook_name: String, args: Array = []) -> void:
	if not _hooks.has(hook_name):
		return
	for entry in _hooks[hook_name]:
		var cb: Callable = entry.callback
		if not cb.is_valid():
			continue
		cb.callv(args)

func patch_apps_data(apps_data: Dictionary) -> void:
	emit_hook("apps_data_loaded", [apps_data])

#endregion


#region ASSET RESOLUTION

func resolve_asset(uri: String) -> String:
	if not uri.begins_with("mod://"):
		return uri
	var rest: String = uri.substr("mod://".length())
	var slash: int = rest.find("/")
	if slash == -1:
		return ""
	var mod_id: String = rest.substr(0, slash)
	var relative: String = rest.substr(slash + 1)
	if not _asset_roots.has(mod_id):
		return ""
	return _asset_roots[mod_id].path_join(relative)

#endregion


#region INTROSPECTION

func get_mod_path(mod_id: String) -> String:
	for desc in available_mods:
		if desc.id == mod_id:
			return desc.mod_path
	return ""

func find_descriptor(mod_id: String):
	for desc in available_mods:
		if desc.id == mod_id:
			return desc
	return null

#endregion
