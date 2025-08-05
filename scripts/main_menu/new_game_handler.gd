extends Button

var new_game_scene : Resource

func _ready() -> void:
	new_game_scene = preload("res://scenes/main.tscn")

func _on_pressed() -> void:
	change_scene()

func change_scene() -> void:
	new_game_scene.instantiate()
