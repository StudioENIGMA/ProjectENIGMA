extends Button

signal enable_settings

var settings_scene : Control

func _ready() -> void:
	settings_scene = preload("res://scenes/game_settings.tscn").instantiate()
	get_tree().root.add_child.call_deferred(settings_scene)
	settings_scene.visible = false
