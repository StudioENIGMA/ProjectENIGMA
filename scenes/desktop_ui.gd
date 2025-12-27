extends Control

signal app_opened(app_name:String, optional_data:Dictionary)

func _on_messages_button_pressed() -> void:
	emit_signal("app_opened", "MessagesHome", null)

func _on_settings_button_pressed() -> void:
	emit_signal("app_opened", "Settings", null)

func _on_email_button_pressed() -> void:
	emit_signal("app_opened", "Email", null)

func _on_shop_button_pressed() -> void:
	emit_signal("app_opened", "Store", {
		"available_apps": GameData.apps_in_store,
		"downloaded_apps": GameData.downloaded_apps
	})

func _on_fake_shop_button_pressed() -> void:
	emit_signal("app_opened", "FakeStore", {
		"available_apps": GameData.apps_in_store,
		"downloaded_apps": GameData.downloaded_apps
	})