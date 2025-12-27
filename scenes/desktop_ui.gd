extends Control

signal app_opened(app_name:String, optional_data:Dictionary)

func _on_messages_button_pressed() -> void:
	emit_signal("app_opened", "Messages_home", null)

func _on_settings_button_pressed() -> void:
	emit_signal("app_opened", "Settings", null)

func _on_email_button_pressed() -> void:
	emit_signal("app_opened", "Email", null)

func _on_shop_button_pressed() -> void:
	emit_signal("app_opened", "Store", null)

func _on_fake_shop_button_pressed() -> void:
	emit_signal("app_opened", "FakeStore")