extends Control

signal subscreen_open_requested(app: GameData.App, data: Dictionary)

const MASK_CHARACTER: String = "•"

#region CHILDREN NODES REFERENCES
@export var app_icon: TextureRect
@export var app_name_label: Label
@export var password_label: Label
@export var change_password_button: Button
@export var toggle_visibility_button: Button
#endregion

#region ICONS
@export var visible_password_icon: Texture2D
@export var hidden_password_icon: Texture2D
#endregion

var gated_app: GameData.App
var password_visible: bool = false

func _ready() -> void:
	change_password_button.pressed.connect(_on_change_password_pressed)
	toggle_visibility_button.pressed.connect(_on_toggle_visibility_pressed)

## Sets up the PasswordInstance UI with the provided data, initializing the gated app
## and filling in its icon, name and (masked) password
func setup(data: Dictionary) -> void:
	# Get gated app from data and set up the UI accordingly
	gated_app = int(data["GatedApp"]) as GameData.App

	var app_data: Dictionary = GameData.apps_data.get(gated_app, {})

	# Set app icon
	var app_icon_path = app_data.get("icon_path", "")
	if app_icon_path != "":
		app_icon.texture = load(app_icon_path)

	# Name the row after the app the password gates
	app_name_label.text = app_data.get(
		"name", GameData.apps_name_reverse.get(gated_app, "Aplicativo")
	)

	password_visible = false
	_refresh_password_label()

## Requests base app to open the password change subscreen for the gated app
func _on_change_password_pressed() -> void:
	emit_signal("subscreen_open_requested", GameData.App.PASSWORDCHANGE, {"GatedApp": gated_app})

## Toggles the visibility of the current password between masked and plain text
func _on_toggle_visibility_pressed() -> void:
	password_visible = not password_visible
	_refresh_password_label()

## Redraws the password line and the eye button for the current visibility state
func _refresh_password_label() -> void:
	var current_password: String = GameData.passwords.get(gated_app, "")

	if password_visible:
		password_label.text = current_password
		toggle_visibility_button.icon = visible_password_icon
		toggle_visibility_button.tooltip_text = "Ocultar senha"
	else:
		password_label.text = MASK_CHARACTER.repeat(current_password.length())
		toggle_visibility_button.icon = hidden_password_icon
		toggle_visibility_button.tooltip_text = "Mostrar senha"
