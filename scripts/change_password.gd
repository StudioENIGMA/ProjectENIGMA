extends CanvasLayer

@onready var new_password_line = $Panel/new_password_line
@onready var confirm_password_line = $Panel/confirm_password_line

@onready var confirm_button = $Panel/confirm_button
@onready var close_button = $Panel/close

@onready var app_node = $".."
@onready var app_label1 = $Panel/Label
@onready var app_label2 = $Panel/Label2
@onready var app_text = "Nova senha para App %s:" 
@onready var app_confirm_text = "Confirmar Senha para App %s:"

var new_password : String
var confirm_password : String

var app_name : String

signal correct_password(new_password: String)

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	
	await get_tree().create_timer(0.01).timeout
	var app_name = app_node.app_name
	
	app_text = app_text % app_name
	app_label1.text = app_text
	
	app_confirm_text = app_confirm_text % app_name
	app_label2.text = app_confirm_text
	


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not new_password_line.text == null:
		new_password = new_password_line.text

	if not confirm_password_line.text == null:
		confirm_password = confirm_password_line.text

func _on_confirm_button_pressed() -> void:
	if new_password != confirm_password or new_password == "":
		return
		
	correct_password.emit(new_password)
	self.hide()
	
func _on_close_button_pressed() -> void:
	self.hide()
