extends Control

signal message_answered(answer_id:int)

signal apk_installation_requested(app: GameData.App)

## Reference to the close app button in the top bar
@export var close_app_button:TextureButton
## Reference to the return app button in the top bar
@export var back_button:TextureButton

## Reference to the desktop UI node (to manage app opening/closing)
@export var desktop_ui:Control

## Reference to the controller that holds specific app controls
@export var app_specific_screen:Control

var messages_app_home = preload("res://scenes/apps/messages/messages_app_home.tscn").instantiate()
var messages_app_chat = preload("res://scenes/apps/messages/messages_app_chat.tscn").instantiate()
var settings_app = preload("res://scenes/settings/settings_app.tscn").instantiate()
var passwords_manager_app = preload("res://scenes/settings/passwords_manager.tscn").instantiate()
var store_app = preload("res://scenes/apps/store-shop/store_app.tscn").instantiate()
var fake_store_app = preload("res://scenes/apps/store-shop/fake_store_app.tscn").instantiate()
var email_app_home = preload("res://scenes/apps/email/email_app_home.tscn").instantiate()
var email_app_viewer = preload("res://scenes/apps/email/email_app_viewer.tscn").instantiate()

## List of currently open apps (as dictionaries with MainApp and SubScreen keys)
var open_apps:Array = []

## Called when the node enters the scene tree for the first time.
##
## Initializes the app top bar and connects necessary signals
## Sets up instances of various apps and adds them to the app specific screen
## Hides all apps initially
## Connects to the desktop UI to handle app opening events
## Sets up signals for app uninstallation from the fake store app
## Preloads and instantiates app scenes
## Connects signals for subscreen opening requests from apps
## Sets up messaging app to propagate signals for message answering and creation
## Sets up settings app and passwords manager app
## Sets up store app and fake store app
func _ready() -> void:
	# Connect close app button signal
	back_button.pressed.connect(_on_back_button_pressed)
	close_app_button.pressed.connect(_on_close_app_button_pressed)

	# Connect to desktop UI app opened signal
	desktop_ui.app_opened.connect(_on_app_opened)

	# Messages app home (Messages app)
	messages_app_home.visible = false
	messages_app_home.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(messages_app_home)

	# Messages app chat (Messages app)
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
	messages_app_chat.apk_installation_requested.connect(
		apk_installation_requested.emit # Propagate signal to desktop UI
	)
	app_specific_screen.add_child(messages_app_chat)

	# Settings app home (Settings app)
	settings_app.visible = false
	app_specific_screen.add_child(settings_app)
	settings_app.subscreen_open_requested.connect(_on_app_opened)

	# Passwords Manager app (Settings app)
	passwords_manager_app.visible = false
	app_specific_screen.add_child(passwords_manager_app)

	# Store app (Store app)
	store_app.visible = false
	store_app.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(store_app)

	# Fake Store app (Fake Store app)
	fake_store_app.visible = false
	fake_store_app.subscreen_open_requested.connect(_on_app_opened)
	fake_store_app.app_uninstalled.connect(desktop_ui._on_app_uninstalled) # Remove from home screen
	fake_store_app.app_uninstalled.connect(_on_app_uninstalled) # Remove from open apps
	app_specific_screen.add_child(fake_store_app)

	# Email app home (Email app)
	email_app_home.visible = false
	email_app_home.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(email_app_home)

	# Email app viewer (Email app)
	email_app_viewer.visible = false
	app_specific_screen.add_child(email_app_viewer)

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

## Handles the close app button press event
##
## Closes the current main app and all its subscreens
func _on_close_app_button_pressed() -> void:
	if open_apps.is_empty():
		return

	var current_app_dict: Dictionary = open_apps[open_apps.size() - 1]
	var main_app_enum: GameData.App = current_app_dict["MainApp"]

	_close_main_app(main_app_enum)

## Handles the app uninstalled event from the store app
##
## app_name: The name of the application being uninstalled
func _on_app_uninstalled(app:GameData.App) -> void:
	# If the uninstalled app is currently open, close it
	var main_app := _get_main_app_enum(app)

	if _has_open_main_app(main_app):
		_close_main_app(main_app)

## Checks if there is any open app with the specified main app enum
##
## main_app: The main app enum to check
func _has_open_main_app(main_app: GameData.App) -> bool:
	for app_dict in open_apps:
		if app_dict.get("MainApp") == main_app:
			return true
	return false

## Closes all open apps with the specified main app enum
##
## main_app_enum: The main app enum to close
func _close_main_app(main_app_enum: GameData.App) -> void:
	# Close all open apps with same main_app
	for i in range(open_apps.size() - 1, -1, -1):
		var app_dict: Dictionary = open_apps[i]
		if app_dict.get("MainApp") != main_app_enum:
			continue

		var subscreen_enum: GameData.App = app_dict["SubScreen"]
		var subscreen_node := _get_app_by_enum(subscreen_enum)
		if subscreen_node:
			subscreen_node.visible = false

		open_apps.remove_at(i)

	# Update top bar + show previous if any
	if open_apps.is_empty():
		self.visible = false
		back_button.visible = false
		return

	self.visible = true
	back_button.visible = open_apps.size() > 1

	var previous_app_dict: Dictionary = open_apps[open_apps.size() - 1]
	var previous_enum: GameData.App = previous_app_dict["SubScreen"]
	var previous_node := _get_app_by_enum(previous_enum)
	if previous_node:
		previous_node.visible = true

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
		GameData.App.FAKESTORE: fake_store_app,
		# Email app
		GameData.App.EMAIL: email_app_home,
		GameData.App.EMAILREAD: email_app_viewer,
	}
	return app_map.get(app_enum, null)

## Returns the main app enum for a given subscreen enum
##
## subscreen_enum: The subscreen enum
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
		GameData.App.FAKESTORE: GameData.App.STORE,
		# Email app
		GameData.App.EMAIL: GameData.App.EMAIL,
		GameData.App.EMAILREAD: GameData.App.EMAIL
	}
	return main_app_map.get(subscreen_enum, null)
