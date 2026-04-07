extends Button

var settings_scene : Control

func _ready() -> void:
	settings_scene = preload("res://scenes/game_settings.tscn").instantiate()
	get_tree().root.add_child.call_deferred(settings_scene)
	settings_scene.visible = false

func _on_pressed() -> void:
	GameData.start_date_dict = Time.get_date_dict_from_system()
	print(get_tree().root.get_children())
	var menu : Control = get_tree().root.get_child(1)
	menu.visible = false
	settings_scene.visible = true
