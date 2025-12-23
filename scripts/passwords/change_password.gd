class_name ChangePassword

extends CanvasLayer

signal password_confirmed(new_password: String, app_name: String)

enum Mode { CREATE, CHANGE }

@export var new_password_line: LineEdit
@export var confirm_password_line: LineEdit

@export var title_label: Label
@export var confirm_label: Label

@export var confirm_button: BaseButton
@export var close_button: BaseButton

var is_change_mode: bool
var app_name: String = ""

## Sets up the ChangePassword UI
##
## app_name_parameter: The name of the app for which the password is being created or changed
## mode: The mode of the password change (CREATE or CHANGE)
func setup(
	app_name_parameter: String,
	mode: Mode,
) -> void:
	app_name = app_name_parameter
	is_change_mode = mode == Mode.CHANGE
	_refresh_ui()

## Connects button signals and refreshes the UI
func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	close_button.pressed.connect(_on_close_pressed)

	_refresh_ui()

## Refreshes the UI elements based on the current mode and app name
func _refresh_ui() -> void:
	var title_template := ""
	match is_change_mode:
		false:
			title_template = "Criar senha para App %s:"
		true:
			title_template = "Nova senha para App %s:"

	var confirm_template := "Confirmar Senha para App %s:"

	title_label.text = title_template % app_name
	confirm_label.text = confirm_template % app_name

	close_button.visible = is_change_mode
	close_button.disabled = not is_change_mode

## Handles the confirm button press
##
## Emits the password_confirmed signal if the passwords match and are not empty
func _on_confirm_pressed() -> void:
	var typed_password := new_password_line.text.strip_edges()
	var typed_confirmation := confirm_password_line.text.strip_edges()

	if typed_password.is_empty():
		return
	if typed_password != typed_confirmation:
		return

	password_confirmed.emit(typed_password, app_name)

	# Delete any typed passwords
	new_password_line.text = ""
	confirm_password_line.text = ""

	hide()

## Handles the close button press
func _on_close_pressed() -> void:
	# Delete any typed passwords
	new_password_line.text = ""
	confirm_password_line.text = ""

	hide()
