extends Button

var new_game_scene:Resource

func _ready() -> void:
	new_game_scene = preload("res://scenes/game_screen.tscn")

func _on_pressed() -> void:
	GameData.start_date_dict = Time.get_date_dict_from_system()
	change_scene()

func change_scene() -> void:
	new_game_scene.instantiate()
	get_tree().change_scene_to_packed(new_game_scene)
