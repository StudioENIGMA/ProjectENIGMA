extends Node2D

@onready var passwords_gui = $passwordspass
@onready var os_scanner_guis = [$update_OS, $scanner]
@onready var button_password = $Button_password
@onready var button_os = $Button_OS
@onready var button_scanner = $Button_scanner
@onready var passwords_manager = $passwords_manager

func _ready() -> void:	
	button_os.hide()
	button_scanner.hide()
		
	for gui in os_scanner_guis:
		var style_box_flat = StyleBoxFlat.new()
		style_box_flat.bg_color = Color(0.72, 0.72, 0.72)
		gui.get_child(0).add_theme_stylebox_override("panel", style_box_flat)
		
		var style_box_flat2 = StyleBoxFlat.new()
		style_box_flat2.bg_color = Color(0.36, 0.36, 0.36)
		gui.get_child(0).get_child(1).add_theme_stylebox_override("panel", style_box_flat2)


func _on_button_password_pressed() -> void:
	passwords_manager.show()
