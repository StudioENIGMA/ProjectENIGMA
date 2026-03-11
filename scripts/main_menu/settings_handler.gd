extends TextureButton

const SETTINGS_SCENE_PATH = "res://scenes/game_settings.tscn"

func _pressed() -> void:
	get_tree().change_scene_to_file(SETTINGS_SCENE_PATH)
