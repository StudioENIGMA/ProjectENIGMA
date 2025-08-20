extends Control

@onready var password_changer = $password_changer
@onready var password_label = $password
@onready var change_button = $change_button
@onready var title = $title

@onready var App: String = "Mensagens"
signal change_button_has_been_pressed()

func _ready() -> void: 
	password_changer.hide()
	
	password_changer.correct_password.connect(_on_correct_password_emitted)
	change_button.pressed.connect(_on_change_button_pressed)

func _process(delta: float) -> void:
	pass
	
func _on_correct_password_emitted(new_password: String) -> void:
	text_password(new_password)
	
func _on_change_button_pressed() -> void:
	change_button_has_been_pressed.emit()
	password_changer.show()
	
func text_password(new_password: String) -> void:
	password_label.text = new_password
	
func text_title(new_title: String) -> void:
	title.text = "Senha App de " + new_title
	
