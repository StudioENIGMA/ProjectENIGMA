extends Control

@export var settings : Button
@export var new_game : Button

func _on_new_game_button_pressed() -> void:
	GameData.start_date_dict = Time.get_date_dict_from_system()
	print(get_tree().root.get_children())
	var menu : Control = get_tree().root.get_child(1)
	menu.visible = false
	new_game.new_game_scene.visible = true
	new_game.new_game_scene.process_mode = Node.PROCESS_MODE_ALWAYS

func _on_settings_button_pressed() -> void:
	GameData.start_date_dict = Time.get_date_dict_from_system()
	print(get_tree().root.get_children())
	self.visible = false
	settings.settings_scene.visible = true
