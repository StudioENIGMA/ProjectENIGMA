extends Button

var new_game_scene : Control

func _ready() -> void:
	new_game_scene = preload("res://scenes/game_screen.tscn").instantiate()
	get_tree().root.add_child.call_deferred(new_game_scene)
	new_game_scene.visible = false
	new_game_scene.process_mode = Node.PROCESS_MODE_DISABLED

func _on_pressed() -> void:
	GameData.start_date_dict = Time.get_date_dict_from_system()
	print(get_tree().root.get_children())
	var menu : Control = get_tree().root.get_child(1)
	menu.visible = false
	new_game_scene.visible = true
	new_game_scene.process_mode = Node.PROCESS_MODE_ALWAYS
# 	change_scene()

# func change_scene() -> void:
# 	new_game_scene.instantiate()
# 	get_tree().change_scene_to_packed(new_game_scene)
