class_name StoredPassword

extends Control

signal change_requested(app_name: String)

var app_name: String = ""

@onready var app_icon: Sprite2D = $MarginContainer/AppIcon
@onready var password_label: Label = $PasswordLabel
@onready var password_title: Label = $PasswordTitle
@onready var change_password_button: BaseButton = $ChangePasswordButton

## Initializes the StoredPassword UI and connects the change password button
func _ready() -> void:
	change_password_button.pressed.connect(_on_change_password_pressed)

## Sets up the StoredPassword item with the given password and app name
##
## saved_password: The stored password to display
## new_app_name: The name of the app associated with the password
func setup(saved_password: String, new_app_name: String) -> void:
	app_name = new_app_name
	password_label.text = saved_password
	password_title.text = "Senha de %s:" % new_app_name
	_set_icon_texture(new_app_name)

## Updates the displayed password
##
## new_password: The new password to display
func set_password(new_password: String) -> void:
	password_label.text = new_password

## Handles the change password button press
##
## Emits the change_requested signal with the app name
func _on_change_password_pressed() -> void:
	change_requested.emit(app_name)

## Sets the icon texture based on the app name
##
## app_name_param: The name of the app for which to set the icon
func _set_icon_texture(app_name_param: String) -> void:
	if not app_icon:
		return

	var icon_path := "res://assets/icons/%s.png"

	match app_name_param:
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
		_:
			return

	app_icon.texture = load(icon_path)
