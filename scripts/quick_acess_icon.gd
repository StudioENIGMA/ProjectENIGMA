extends Control

func _on_gui_input(event: InputEvent) -> void:
	if ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch) and event.pressed:
		var scene = load("res://scenes/real_shop_site.tscn").instantiate()
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
		
