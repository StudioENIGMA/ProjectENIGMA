extends Controller

signal new_password_created()

const NEW_PASSWORD = preload("res://scenes/settings/change_password.tscn")

@onready var settings_button = get_tree().root.find_child("SettingsButton", true, false)
@onready var messages_button = get_tree().root.find_child("MessagesButton", true, false)
@onready var store_button = get_tree().root.find_child("AppStoreButton", true, false)
@onready var browser_button = get_tree().root.find_child("BrowserButton", true, false)
@onready var email_button = get_tree().root.find_child("Email", true, false)

@onready var node = get_tree().root.find_child("notifications_control", true, false)

## Handles app button presses
##
## app_name: The name of the app whose button was pressed
func _app_pressed(app_name:String) -> void:
	if GameData.data.passwords[app_name] == "":
		_create_password(app_name)

## Creates a new password for the given app
##
## app_name: The name of the app for which to create a password
func _create_password(app_name:String) -> void:
	var new_password_instance = NEW_PASSWORD.instantiate()
	node.add_child(new_password_instance)
	new_password_instance.setup(
		app_name,
		ChangePassword.Mode.CREATE
	)

	new_password_instance.password_confirmed.connect(_on_password_confirmed)

## Handles the event when a new password is created
##
## new_password: The newly created password
## app_name: The name of the app for which the password was created
func _on_password_confirmed(new_password: String, app_name: String) -> void:
	GameData.data.passwords[app_name] = new_password
	new_password_created.emit()
