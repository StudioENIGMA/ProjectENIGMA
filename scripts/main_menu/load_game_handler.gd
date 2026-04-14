extends Button

var new_game_scene:Resource

func _ready() -> void:
	new_game_scene = preload("res://scenes/game_screen.tscn")

	var file_path := "user://saved_game.json"
	if not FileAccess.file_exists(file_path):
		self.visible = false

func _on_pressed() -> void:
	GameData.load_game()
	change_scene()

func change_scene() -> void:
	new_game_scene.instantiate()
	get_tree().change_scene_to_packed(new_game_scene)
