class_name PasswordsManager

extends Node2D

const STORED_PASSWORD_SCENE := preload("res://scenes/phone_settings/password.tscn")
const CHANGE_PASSWORD_SCENE := preload("res://scenes/phone_settings/change_password.tscn")

var none_password_label: Label
var change_password_ui: ChangePassword
var stored_by_app: Dictionary = {} # app_name -> StoredPassword

@onready var background: Control = $Control/Panel
@onready var vbox: VBoxContainer = $Control/Panel/VBoxContainer
@onready var close_button: BaseButton = $Control/Panel/CloseButton
@onready var password_controller:Controller = $PasswordController

func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)

	none_password_label = Label.new()
	none_password_label.text = "Você não possui nenhuma senha cadastrada"
	none_password_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	none_password_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	none_password_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	none_password_label.add_theme_font_size_override("font_size", 50)
	background.add_child(none_password_label)

	var custom_font := FontFile.new()
	custom_font.font_data = load("res://assets/fonts/IBMPlexSans-Regular.ttf")
	none_password_label.add_theme_font_override("font", custom_font)

	password_controller.new_password_created.connect(_on_new_password_created)

	_rebuild_list()

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

	none_password_label.visible = stored_by_app.is_empty()

func _add_stored_password_item(app_name: String, password_value: String) -> void:
	var item := STORED_PASSWORD_SCENE.instantiate() as StoredPassword
	vbox.add_child(item)

	item.setup(password_value, app_name)
	item.change_requested.connect(_on_change_requested)

	stored_by_app[app_name] = item

func _on_change_requested(app_name: String) -> void:
	_open_change_password(app_name)

func _open_change_password(app_name: String) -> void:
	# Reuse a single ChangePassword instance (avoids stacking hidden CanvasLayers)
	if not is_instance_valid(change_password_ui):
		change_password_ui = CHANGE_PASSWORD_SCENE.instantiate() as ChangePassword
		_get_overlay_parent().add_child(change_password_ui)
		change_password_ui.password_confirmed.connect(_on_password_confirmed)

	change_password_ui.setup(app_name, ChangePassword.Mode.CHANGE)
	change_password_ui.show()

func _on_password_confirmed(new_password: String, app_name: String) -> void:
	GameData.data.passwords[app_name] = new_password
	_rebuild_list()

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

## Handles the event when a new password is created
##
## When a new password is created, rebuilds the password list
func _on_new_password_created() -> void:
	_rebuild_list()
