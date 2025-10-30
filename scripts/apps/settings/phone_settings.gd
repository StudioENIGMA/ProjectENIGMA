extends Node2D

@export var passwords_gui: Control
@export var os_gui: Control
@export var scanner_gui: Control

@export var button_password: Button
@export var button_os: Button
@export var button_scanner: Button
@export var close_button: Button

@export var passwords_manager: Node2D
@export var os_updater: Node2D

@onready var day : int = 2

func _ready() -> void:
	day = GameData.data.current_day
	passwords_gui.get_child(0).get_child(2).get_child(0).text = "Gerenciador de Senhas"
	os_gui.get_child(0).get_child(2).get_child(0).text = "Autualização de Software"
	scanner_gui.get_child(0).get_child(2).get_child(0).text = "Verificar Presença de Vírus"
	
	button_os.hide()
	button_scanner.hide()
		
	change_gui_color(os_gui, Color(0.72, 0.72, 0.72), Color(0.36, 0.36, 0.36))
	change_gui_color(scanner_gui, Color(0.72, 0.72, 0.72), Color(0.36, 0.36, 0.36))
	
	close_button.pressed.connect(_on_close_button_pressed)

func _process(delta: float) -> void:
	if day == 2:
		enable_feature(os_gui, button_os)
	if day >= 3:
		enable_feature(os_gui, button_os)
		enable_feature(scanner_gui, button_scanner)

func enable_feature(feature : Control, button : Button) -> void:
	button.show()
	change_gui_color(feature, Color(0, 0.7, 0.52), Color(0, 0.34, 0.26))

func change_gui_color(gui : Control, color1 : Color, color2 : Color) -> void:
	var style_box_flat = StyleBoxFlat.new()
	style_box_flat.bg_color = color1
	gui.get_child(0).add_theme_stylebox_override("panel", style_box_flat)
	
	var style_box_flat2 = StyleBoxFlat.new()
	style_box_flat2.bg_color = color2
	gui.get_child(0).get_child(1).add_theme_stylebox_override("panel", style_box_flat2)

func _on_button_password_pressed() -> void:
	passwords_manager.show()

func _on_button_os_pressed() -> void:
	os_updater.show()
	
func _on_close_button_pressed() -> void:
	self.hide()
