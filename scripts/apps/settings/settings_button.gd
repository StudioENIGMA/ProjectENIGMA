extends Control

signal settings_gui_pressed()

@export var app_name_label: Label
@export var header_panel: Panel
@export var content_panel: Panel

func setup(app_name: String) -> void:
	app_name_label.text = app_name

func change_gui_color(color1 : Color, color2 : Color) -> void:
	var style_box_flat = StyleBoxFlat.new()
	style_box_flat.bg_color = color1
	header_panel.add_theme_stylebox_override("panel", style_box_flat)

	var style_box_flat2 = StyleBoxFlat.new()
	style_box_flat2.bg_color = color2
	content_panel.add_theme_stylebox_override("panel", style_box_flat2)

func _on_button_pressed() -> void:
	settings_gui_pressed.emit()
