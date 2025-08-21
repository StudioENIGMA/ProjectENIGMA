extends Panel

func _on_gui_input(event: InputEvent) -> void:
	if ((event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or event is InputEventScreenTouch) and event.pressed:
		var scene = load("res://scenes/news_page.tscn").instantiate()
		scene.title = "Título da notícia"
		scene.text = "Texto da Notícia"
		get_tree().root.add_child(scene)
		get_tree().current_scene = scene
			
