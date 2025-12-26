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
var messages_app:Control

var open_apps:Array[String] = []

## Setup signal connections for app management
func _ready() -> void:
	# Connect close app button signal
	close_app_button.pressed.connect(_on_close_app_button_pressed)

	# Connect to desktop UI app opened signal
	desktop_ui.app_opened.connect(_on_app_opened)

	# Create messages app as a child of the specific app control
	messages_app = preload("res://scenes/apps/messages/messages_app.tscn").instantiate()
	messages_app.visible = false
	app_specific_screen.add_child(messages_app)

## Handles the app opened event from the desktop UI
##
## app_name: The name of the application being opened
func _on_app_opened(app_name:String) -> void:
	# Show top bar when an app is opened
	self.visible = true
	open_apps.append(app_name)

	# Get specific app that should be opened
	var specific_app = get_app_by_name(app_name)

	# Pull specific app to front and make it visible
	specific_app.visible = true
	app_specific_screen.move_child(specific_app, app_specific_screen.get_child_count() - 1)

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

	# If no apps are open, hide the top bar
	if open_apps.size() == 0:
		self.visible = false

## Returns the app node by its name
##
## app_name: The name of the application
func get_app_by_name(app_name:String) -> Control:
	match app_name:
		"Messages":
			return messages_app
		_:
			return null # Will break if app not found, should not happen
