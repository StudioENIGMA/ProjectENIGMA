extends CanvasLayer

@onready var new_password_line = $Panel/new_password_line
@onready var confirm_password_line = $Panel/confirm_password_line

@onready var confirm_button = $Panel/confirm_button
@onready var close_button = $Panel/close

@onready var app_node = $".."
@onready var app_label1 = $Panel/Label
@onready var app_label2 = $Panel/Label2
@onready var app_text = "Criar senha para App %s:" 
@onready var app_confirm_text = "Confirmar Senha para App %s:"

var new_password : String
var confirm_password : String

var first_password : bool = false
var app_name : String

signal first_correct_password(new_password: String, app_name: String)	

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	
	await get_tree().create_timer(0.01).timeout	
	app_text = app_text % app_name
	app_label1.text = app_text
	
	app_confirm_text = app_confirm_text % app_name
	app_label2.text = app_confirm_text

func setup(_app_name : String) -> void:
	self.app_name = _app_name

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not new_password_line.text == null:
		new_password = new_password_line.text

	if not confirm_password_line.text == null:
		confirm_password = confirm_password_line.text

func _on_confirm_button_pressed() -> void:
	if new_password != confirm_password or new_password == "":
		return
		
	EventBus.first_correct_password.emit(new_password, app_name)
	first_password = false
	
	self.hide()
