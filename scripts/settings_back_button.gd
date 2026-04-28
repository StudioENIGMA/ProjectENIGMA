extends Button

const MAIN_MENU_SCENE_PATH = "res://scenes/main_menu.tscn"

func _pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
