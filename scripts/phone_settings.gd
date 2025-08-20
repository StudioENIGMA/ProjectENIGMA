extends Node2D

@onready var passwords_gui = $passwordspass
@onready var os_scanner_guis = [$update_OS, $scanner]
@onready var button_password = $Button_password
@onready var button_os = $Button_OS
@onready var button_scanner = $Button_scanner
@onready var passwords_manager = $passwords_manager
@onready var os_updater = $os_updater
@onready var close_button = $close

@onready var day : int = 3

func _ready() -> void:
	button_os.hide()
	button_scanner.hide()
		
	for gui in os_scanner_guis:
		change_gui_color(gui, Color(0.72, 0.72, 0.72), Color(0.36, 0.36, 0.36))
		#var style_box_flat = StyleBoxFlat.new()
		#style_box_flat.bg_color = Color(0.72, 0.72, 0.72)
		#gui.get_child(0).add_theme_stylebox_override("panel", style_box_flat)
		
		#var style_box_flat2 = StyleBoxFlat.new()
		#style_box_flat2.bg_color = Color(0.36, 0.36, 0.36)
		#gui.get_child(0).get_child(1).add_theme_stylebox_override("panel", style_box_flat2)
	
	close_button.pressed.connect(_on_close_button_pressed)

func _process(delta: float) -> void:
	if day == 2:
		enable_feature(os_scanner_guis[0], button_os)
	if day >= 3:
		enable_feature(os_scanner_guis[0], button_os)
		enable_feature(os_scanner_guis[1], button_scanner)
		
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
