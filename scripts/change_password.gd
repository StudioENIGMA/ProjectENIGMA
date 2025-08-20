extends CanvasLayer

@onready var new_password_line = $Panel/new_password_line
@onready var confirm_password_line = $Panel/confirm_password_line

@onready var confirm_button = $Panel/confirm_button
@onready var close_button = $Panel/close

var new_password : String
var confirm_password : String

var first_password : bool = false
var app_name : String

signal correct_password(new_password: String)
signal first_correct_password(new_password: String, app_name: String)

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if not new_password_line.text == null:
		new_password = new_password_line.text

	if not confirm_password_line.text == null:
		confirm_password = confirm_password_line.text

func _on_confirm_button_pressed() -> void:
	if first_password:
		first_correct_password.emit(new_password, app_name)
		first_password = false
		return
	
	correct_password.emit(new_password)
	self.hide()
	
func _on_close_button_pressed() -> void:
	self.hide()
