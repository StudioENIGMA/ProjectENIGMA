## Base application script that handles common functionality for all apps
## Buttons from the top bar should be handled here

extends Control

signal message_answered(answer_id:int)

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

## Reference to the settings app node
var settings_app:Control
var passwords_manager_app:Control

## Reference to the store app node
var store_app:Control
var fake_store_app:Control

var open_apps:Array = []

## Setup signal connections for app management
func _ready() -> void:
	# Connect close app button signal
	back_button.pressed.connect(_on_back_button_pressed)
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
	messages_app_chat.message_answered.connect(message_answered.emit) # Propagate signal to UI
	messages_app_chat.request_message_creation_on_answer.connect(
		messages_app_home.on_create_message # Propagate signal to app home
	)
	messages_app_chat.storage_answer.connect(
		messages_app_home.on_player_answer # Propagate signal to app home
	)
	messages_app_chat.delete_answers.connect(
		messages_app_home.on_delete_answers # Propagate signal to app home
	)
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

	# Store app (Store app)
	store_app = preload("res://scenes/apps/store-shop/store_app.tscn").instantiate()
	store_app.visible = false
	store_app.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(store_app)

	# Fake Store app (Fake Store app)
	fake_store_app = preload("res://scenes/apps/store-shop/fake_store_app.tscn").instantiate()
	fake_store_app.visible = false
	fake_store_app.subscreen_open_requested.connect(_on_app_opened)
	fake_store_app.app_uninstalled.connect(desktop_ui._on_app_uninstalled) # Remove from home screen
	fake_store_app.app_uninstalled.connect(_on_app_uninstalled) # Remove from open apps
	app_specific_screen.add_child(fake_store_app)

## Handles the app opened event from the desktop UI
##
## app_name: The name of the application being opened
## optional_data: Additional data that might be passed when opening the app
func _on_app_opened(app:GameData.App, optional_data = null) -> void:
	# Show top bar when an app is opened
	self.visible = true

	var main_app:GameData.App = _get_main_app_enum(app)

	# Add app to open apps list
	open_apps.append({"MainApp": main_app, "SubScreen": app})

	# Get specific app that should be opened
	var specific_app = _get_app_by_enum(app)

	if optional_data != null:
		specific_app.setup(optional_data)

	# Pull specific app to front and make it visible
	specific_app.visible = true
	app_specific_screen.move_child(specific_app, app_specific_screen.get_child_count() - 1)

	# Show back button if more than one app is open and hide previous app
	if open_apps.size() > 1:
		back_button.visible = true
		var previous_app_dict:Dictionary = open_apps[open_apps.size() - 2]
		var previous_app_enum:GameData.App = previous_app_dict["SubScreen"]
		var previous_app = _get_app_by_enum(previous_app_enum)
		previous_app.visible = false
	else:
		back_button.visible = false

## Handles the close app button press event
##
## Hides the currently open app and updates the top bar visibility accordingly
func _on_back_button_pressed() -> void:
	# Get the currently open app (topmost)
	var current_app_dict:Dictionary = open_apps[open_apps.size() - 1]
	var current_app_enum:GameData.App = current_app_dict["SubScreen"]
	var current_app = _get_app_by_enum(current_app_enum)

	# Hide the current app
	current_app.visible = false
	open_apps.erase(current_app_dict)

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
		var previous_app_dict:Dictionary = open_apps[number_of_open_apps - 1]
		var previous_app_enum:GameData.App = previous_app_dict["SubScreen"]
		var previous_app = _get_app_by_enum(previous_app_enum)
		previous_app.visible = true

func _on_close_app_button_pressed() -> void:
	# Close all open apps with same main_app as the topmost app
	var current_app_dict:Dictionary = open_apps[open_apps.size() - 1]
	var main_app_enum:GameData.App = current_app_dict["MainApp"]

	# Create a copy of open_apps to avoid modifying the array while iterating
	var open_apps_copy = open_apps.duplicate()

	for app_dict in open_apps_copy:
		if app_dict["MainApp"] == main_app_enum:
			var app_enum:GameData.App = app_dict["SubScreen"]
			var app = _get_app_by_enum(app_enum)
			app.visible = false
			open_apps.erase(app_dict)

	# Update top bar visibility
	if open_apps.size() == 0:
		self.visible = false
	else:
		# Show previous app if any
		var previous_app_dict:Dictionary = open_apps[open_apps.size() - 1]
		var previous_app_enum:GameData.App = previous_app_dict["SubScreen"]
		var previous_app = _get_app_by_enum(previous_app_enum)
		previous_app.visible = true

## Handles the app uninstalled event from the store app
##
## app_name: The name of the application being uninstalled
func _on_app_uninstalled(app:GameData.App) -> void:
	# If the uninstalled app is currently open, close it
	if open_apps.has(app):
		# Close the app
		_on_close_app_button_pressed()

## Returns the app node by its name
##
## app_name: The name of the application
func _get_app_by_enum(app_enum:GameData.App) -> Control:
	var app_map = {
		# Messages app
		GameData.App.MESSAGESHOME: messages_app_home,
		GameData.App.MESSAGESCHAT: messages_app_chat,
		# Settings app
		GameData.App.SETTINGS: settings_app,
		GameData.App.PASSWORDMANAGER: passwords_manager_app,
		# Store app
		GameData.App.STORE: store_app,
		GameData.App.FAKESTORE: fake_store_app
	}
	return app_map.get(app_enum, null)

func _get_main_app_enum(subscreen_enum:GameData.App) -> GameData.App:
	var main_app_map = {
		# Messages app
		GameData.App.MESSAGESHOME: GameData.App.MESSAGESHOME,
		GameData.App.MESSAGESCHAT: GameData.App.MESSAGESHOME,
		# Settings app
		GameData.App.SETTINGS: GameData.App.SETTINGS,
		GameData.App.PASSWORDMANAGER: GameData.App.SETTINGS,
		# Store app
		GameData.App.STORE: GameData.App.STORE,
		GameData.App.FAKESTORE: GameData.App.STORE
	}
	return main_app_map.get(subscreen_enum, null)