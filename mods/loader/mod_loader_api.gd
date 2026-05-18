class_name ModLoaderAPI
extends RefCounted

var mod_id: String

func _init(owner_mod_id: String) -> void:
	mod_id = owner_mod_id

func hook(hook_name: String, callback: Callable) -> void:
	ModLoader._register_hook(mod_id, hook_name, callback)

func info(message: String) -> void:
	print("[mod:%s] %s" % [mod_id, message])

func warn(message: String) -> void:
	push_warning("[mod:%s] %s" % [mod_id, message])

func mod_path() -> String:
	return ModLoader.get_mod_path(mod_id)

func resolve_asset(relative_path: String) -> String:
	return ModLoader.resolve_asset("mod://%s/%s" % [mod_id, relative_path])
