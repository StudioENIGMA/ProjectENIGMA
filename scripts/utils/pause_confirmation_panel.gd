extends PanelContainer

const MENU_SCENE_PATH = "res://scenes/main_menu.tscn"

var continue_operation: String

func setup(operation: String) -> void:
	continue_operation = operation

func _on_cancel_button_pressed() -> void:
	self.hide()

func _on_continue_button_pressed() -> void:
	match continue_operation:
		"menu":
			get_tree().paused = false
			GameData.reset_to_defaults()
			get_tree().change_scene_to_file(MENU_SCENE_PATH)
		"quit":
			get_tree().quit()
