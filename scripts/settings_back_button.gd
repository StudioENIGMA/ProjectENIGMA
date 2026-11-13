extends Button

const MAIN_MENU_SCENE_PATH = "res://scenes/main_menu.tscn"

## Back to the main menu, or, for the settings opened over the paused game, back to it
func _pressed() -> void:
	if owner != get_tree().current_scene:
		owner.queue_free()
		return
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
