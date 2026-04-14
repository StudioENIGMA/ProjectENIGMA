extends Button

signal show_confirmation_panel()

var new_game_scene:Resource

func _ready() -> void:
	new_game_scene = preload("res://scenes/game_screen.tscn")

func _on_pressed() -> void:
	var file_path := "user://saved_game.json"
	if FileAccess.file_exists(file_path):
		show_confirmation_panel.emit()
		return

	change_scene()

func change_scene() -> void:
	var file_path := "user://saved_game.json"
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)

	GameData.start_date_dict = Time.get_date_dict_from_system()
	new_game_scene.instantiate()
	get_tree().change_scene_to_packed(new_game_scene)
