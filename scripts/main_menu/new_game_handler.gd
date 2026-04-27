extends Button

var new_game_scene : Control

func _ready() -> void:
	new_game_scene = preload("res://scenes/game_screen.tscn").instantiate()
	get_tree().root.add_child.call_deferred(new_game_scene)
	new_game_scene.visible = false
	new_game_scene.process_mode = Node.PROCESS_MODE_DISABLED
