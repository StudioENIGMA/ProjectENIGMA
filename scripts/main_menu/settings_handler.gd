extends Button

@export var settings_menu : Control
@export var settings_back_button : Control
@export var main_menu : Control

func _on_pressed() -> void:
	settings_menu.visible = true
	settings_back_button.visible = true
	main_menu.visible = false

func _on_settings_back_button_pressed() -> void:
	settings_menu.visible = false
	settings_back_button.visible = false
	main_menu.visible = true
