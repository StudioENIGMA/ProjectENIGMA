extends Button

func _pressed() -> void:
	self.get_parent().get_parent().visible = false
	var menu : Control = get_tree().root.get_child(1)
	menu.visible = true
