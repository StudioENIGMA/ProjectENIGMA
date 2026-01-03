extends Control

func _on_exit_browser_pressed() -> void:
	invisible()
func invisible() -> void:
	visible = not visible
