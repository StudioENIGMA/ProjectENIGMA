## Base application script that handles common functionality for all apps
## Buttons from the top bar should be handled here

extends Control

## Reference to the close app button in the top bar
@export var close_app_button:TextureButton
## Reference to the return app button in the top bar
@export var back_button:TextureButton

## Reference to the desktop UI node (to manage app opening/closing)
@export var desktop_ui:Control

## Reference to the controller that holds specific app controls
@export var app_specific_screen:Control

## Reference to the messaging app node
var messages_app_home:Control
var messages_app_chat:Control

var settings_app:Control
var passwords_manager_app:Control

var open_apps:Array[String] = []

## Setup signal connections for app management
func _ready() -> void:
	# Connect close app button signal
	close_app_button.pressed.connect(_on_close_app_button_pressed)

	# Connect to desktop UI app opened signal
	desktop_ui.app_opened.connect(_on_app_opened)

	# Messages app home (Messages app)
	messages_app_home = preload("res://scenes/apps/messages/messages_app_home.tscn").instantiate()
	messages_app_home.visible = false
	messages_app_home.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(messages_app_home)

	# Messages app chat (Messages app)
	messages_app_chat = preload("res://scenes/apps/messages/messages_app_chat.tscn").instantiate()
	messages_app_chat.visible = false
	app_specific_screen.add_child(messages_app_chat)

	# Settings app home (Settings app)
	settings_app = preload("res://scenes/settings/settings_app.tscn").instantiate()
	settings_app.visible = false
	app_specific_screen.add_child(settings_app)
	settings_app.subscreen_open_requested.connect(_on_app_opened)

	# Passwords Manager app (Settings app)
	passwords_manager_app = preload("res://scenes/settings/passwords_manager.tscn").instantiate()
	passwords_manager_app.visible = false
	app_specific_screen.add_child(passwords_manager_app)

## Handles the app opened event from the desktop UI
##
## app_name: The name of the application being opened
## optional_data: Additional data that might be passed when opening the app
func _on_app_opened(app_name:String, optional_data = null) -> void:
	# Show top bar when an app is opened
	self.visible = true
	open_apps.append(app_name)

	# Get specific app that should be opened
	var specific_app = get_app_by_name(app_name)

	if optional_data != null:
		specific_app.setup(optional_data)

	# Pull specific app to front and make it visible
	specific_app.visible = true
	app_specific_screen.move_child(specific_app, app_specific_screen.get_child_count() - 1)

	# Show back button if more than one app is open and hide previous app
	if open_apps.size() > 1:
		back_button.visible = true
		var previous_app_name:String = open_apps[open_apps.size() - 2]
		var previous_app = get_app_by_name(previous_app_name)
		previous_app.visible = false
	else:
		back_button.visible = false

## Handles the close app button press event
##
## Hides the currently open app and updates the top bar visibility accordingly
func _on_close_app_button_pressed() -> void:
	# Get the currently open app (topmost)
	var current_app_name:String = open_apps[open_apps.size() - 1]
	var current_app = get_app_by_name(current_app_name)

	# Hide the current app
	current_app.visible = false
	open_apps.erase(current_app_name)

	var number_of_open_apps:int = open_apps.size()

	# If no apps are open, hide the top bar
	if number_of_open_apps == 0:
		self.visible = false

	# Show back button if more than one app is still open and show previous app
	if number_of_open_apps > 1:
		back_button.visible = true
	else:
		back_button.visible = false

	# Show previous app if any
	if number_of_open_apps > 0:
		var previous_app_name:String = open_apps[number_of_open_apps - 1]
		var previous_app = get_app_by_name(previous_app_name)
		previous_app.visible = true

## Returns the app node by its name
##
## app_name: The name of the application
func get_app_by_name(app_name:String) -> Control:
	match app_name:
		"Messages_home":
			return messages_app_home
		"Messages_chat":
			return messages_app_chat
		"Settings":
			return settings_app
		"PasswordManager":
			return passwords_manager_app
		_:
			return null # Will break if app not found, should not happen
