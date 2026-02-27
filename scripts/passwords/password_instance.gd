extends MarginContainer

signal subscreen_open_requested(app: GameData.App, data: Dictionary)

#region CHILDREN NODES REFERENCES
@export var app_icon: TextureRect
@export var current_password_label: Label
@export var change_password_button: TextureButton
@export var toggle_visibility_button: TextureButton
#endregion

var gated_app: GameData.App
var password_visible: bool = false

## Sets up the PasswordInstance UI with the provided data, initializing the gated app
## and updating the instruction label accordingly
func setup(data: Dictionary) -> void:
	# Get gated app from data and set up the UI accordingly
	gated_app = data["GatedApp"]

	# Set app icon
	var app_icon_path = GameData.apps_data.get(gated_app, {}).get("icon_path", "")
	if app_icon_path != "":
		app_icon.texture = load(app_icon_path)

	# Connect button signals
	change_password_button.pressed.connect(_on_change_password_pressed)
	toggle_visibility_button.pressed.connect(_on_toggle_visibility_pressed)

## Requests base app to open the password change subscreen for the gated app
func _on_change_password_pressed() -> void:
	emit_signal("subscreen_open_requested", GameData.App.PASSWORDCHANGE, {"GatedApp": gated_app})

## Toggles the visibility of the current password label between masked and actual password
func _on_toggle_visibility_pressed() -> void:
	# Toggle the visibility of the current password label
	if password_visible:
		current_password_label.text = "Senha atual: ****"
		password_visible = false
	else:
		var current_password = GameData.passwords.get(gated_app)
		current_password_label.text = "Senha atual: %s" % current_password
		password_visible = true
