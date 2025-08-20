extends Control

@onready var password_changer = $password_changer
@onready var password_label = $password
@onready var change_button = $change_button
@onready var app_name : String
@onready var title = $title
@onready var icon = $MarginContainer/icon

@onready var App: String = "Mensagens"
signal change_button_has_been_pressed()

func _ready() -> void: 
	password_changer.hide()
	
	password_changer.correct_password.connect(_on_correct_password_emitted)
	change_button.pressed.connect(_on_change_button_pressed)

func setup(new_password : String, new_title : String) -> void:
	password_label.text = new_password
	title.text = "Senha de " + new_title + ":"
	
	app_name = new_title
	
	set_icon_texture(app_name)
	
func set_icon_texture(app_name : String) -> void:
	var icon_path : String = "res://assets/icons/%s.png"
	
	match app_name:
		"Mensagens":
			icon_path = icon_path % "messages"
		"Loja":
			icon_path = icon_path % "app-store"
		"Ajustes":
			icon_path = icon_path % "settings"
		"Navegador":
			icon_path = icon_path % "browser"
		"Email":
			icon_path = icon_path % "email"
	
	icon.texture = load(icon_path)

func _process(delta: float) -> void:
	await get_tree().create_timer(2).timeout
	print(GameData.data.passwords)
	
func _on_correct_password_emitted(new_password: String) -> void:
	password_label.text = new_password
	GameData.data.passwords[app_name] = new_password
	
func _on_change_button_pressed() -> void:
	change_button_has_been_pressed.emit()
	password_changer.show()
