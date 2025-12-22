class_name PasswordsManager

extends Node2D

const STORED_PASSWORD_SCENE := preload("res://scenes/phone_settings/password.tscn")
const CHANGE_PASSWORD_SCENE := preload("res://scenes/phone_settings/change_password.tscn")

var change_password_ui: ChangePassword
var stored_by_app: Dictionary = {} # app_name -> StoredPassword

@onready var none_passwords_label: Label = $Control/Panel/NonePasswordsLabel
@onready var vbox: VBoxContainer = $Control/Panel/VBoxContainer
@onready var close_button: BaseButton = $Control/Panel/CloseButton
@onready var password_controller:Controller = $PasswordController

## Initializes the PasswordsManager UI and connects the close button
func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	password_controller.new_password_created.connect(_on_new_password_created)

	_rebuild_list()

## Rebuilds the list of stored passwords in the UI
##
## Clears existing items and repopulates the list based on GameData.data.passwords
func _rebuild_list() -> void:
	for child in vbox.get_children():
		child.queue_free()

	stored_by_app.clear()

	var keys: Array = GameData.data.passwords.keys()
	keys.sort()

	for app_name in keys:
		var password_value: String = GameData.data.passwords[app_name]
		if password_value != "":
			_add_stored_password_item(app_name, password_value)

	none_passwords_label.visible = vbox.get_child_count() == 0

## Adds a StoredPassword item to the UI for the specified app and password
##
## app_name: The name of the app
## password_value: The password associated with the app
func _add_stored_password_item(app_name: String, password_value: String) -> void:
	var item := STORED_PASSWORD_SCENE.instantiate() as StoredPassword
	vbox.add_child(item)

	item.setup(password_value, app_name)
	item.change_requested.connect(_on_change_requested)

	stored_by_app[app_name] = item

## Opens the ChangePassword UI for the specified app
##
## app_name: The name of the app for which to change the password
func _open_change_password(app_name: String) -> void:
	# Reuse a single ChangePassword instance (avoids stacking hidden CanvasLayers)
	if not is_instance_valid(change_password_ui):
		change_password_ui = CHANGE_PASSWORD_SCENE.instantiate() as ChangePassword
		_get_overlay_parent().add_child(change_password_ui)
		change_password_ui.password_confirmed.connect(_on_password_confirmed)

	change_password_ui.setup(app_name, ChangePassword.Mode.CHANGE)
	change_password_ui.show()

## Gets the appropriate parent node for overlay UIs
##
## Returns: The Node to which overlay UIs should be added
func _get_overlay_parent() -> Node:
	var overlay := get_tree().root.find_child("notifications_control", true, false)
	return overlay if overlay != null else get_tree().root

## Handles the close button press
##
## Hides the PasswordsManager UI
func _on_close_button_pressed() -> void:
	hide()

## Handles the event when a new password is created (from within other parts of the code)
##
## When a new password is created, rebuilds the password list
func _on_new_password_created() -> void:
	_rebuild_list()

## Handles the change password request from a StoredPassword item
##
## Opens the ChangePassword UI for the specified app
##
## app_name: The name of the app for which the password change was requested
func _on_change_requested(app_name: String) -> void:
	_open_change_password(app_name)

## Handles the event when a password is changed
##
## Sets the new password for the specified app and rebuilds the password list
##
## new_password: The newly changed password
## app_name: The name of the app for which the password was changed
func _on_password_confirmed(new_password: String, app_name: String) -> void:
	GameData.data.passwords[app_name] = new_password
	_rebuild_list()
