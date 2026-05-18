extends Button

const MODS_SCENE_PATH := "res://mods/loader/ui/mods_screen.tscn"

func _pressed() -> void:
	get_tree().change_scene_to_file(MODS_SCENE_PATH)
