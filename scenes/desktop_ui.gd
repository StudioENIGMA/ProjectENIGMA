extends Control

signal app_opened(app_name:String)

func _on_messages_button_pressed() -> void:
	emit_signal("app_opened", "Messages_home")

func _on_settings_button_pressed() -> void:
	emit_signal("app_opened", "Settings")

func _on_email_button_pressed() -> void:
	emit_signal("app_opened", "Email")

func _on_shop_button_pressed() -> void:
	emit_signal("app_opened", "Store")