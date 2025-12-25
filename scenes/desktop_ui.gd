extends Control

signal app_opened(app_name:String)

func _on_messages_button_pressed() -> void:
	emit_signal("app_opened", "Messages")