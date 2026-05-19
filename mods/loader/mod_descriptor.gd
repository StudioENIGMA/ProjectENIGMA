class_name ModDescriptor
extends RefCounted

var id: String = ""
var display_name: String = ""
var version: String = "0.0.0"
var authors: Array = []
var description: String = ""
var priority: int = 0
var depends: Array = []

var mod_path: String = ""
var is_builtin: bool = false

var data_entries: Dictionary = {}
var script_path: String = ""
var assets_path: String = ""
var pack_path: String = ""

static func from_manifest(manifest_path: String, builtin: bool) -> ModDescriptor:
	var file := FileAccess.open(manifest_path, FileAccess.READ)
	if file == null:
		return null
	var text := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return null

	var data: Dictionary = parsed
	var id: String = str(data.get("id", "")).strip_edges()
	if id == "":
		return null

	var desc := ModDescriptor.new()
	desc.id = id
	desc.display_name = str(data.get("name", id))
	desc.version = str(data.get("version", "0.0.0"))
	desc.authors = data.get("authors", [])
	desc.description = str(data.get("description", ""))
	desc.priority = int(data.get("priority", 0))
	desc.depends = data.get("depends", [])
	desc.is_builtin = builtin
	desc.mod_path = manifest_path.get_base_dir()
	desc.data_entries = data.get("data", {})
	desc.script_path = str(data.get("main_script", ""))
	desc.assets_path = str(data.get("assets", ""))
	desc.pack_path = str(data.get("pack", ""))
	return desc
