extends Control

#region SIGNALS
signal app_opened(app_name:String, optional_data:Dictionary)
#endregion SIGNALS

#region BUTTONS NODES REFERENCES
@export var messages_button: Button
@export var settings_button: Button
@export var email_button: Button
@export var shop_button: Button
@export var fake_shop_button: Button
@export var authenticator_button: Button
@export var bank_button: Button
@export var touch_sound_player:AudioStreamPlayer2D
#endregion BUTTONS NODES REFERENCES

#region INITIALIZATION
## Setup signal connections for buttons and installation events
func _ready() -> void:
	# Main screen buttons connections
	messages_button.pressed.connect(_on_messages_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	email_button.pressed.connect(_on_email_button_pressed)
	shop_button.pressed.connect(_on_shop_button_pressed)
	fake_shop_button.pressed.connect(_on_fake_shop_button_pressed)
	bank_button.pressed.connect(_on_bank_button_pressed)
	authenticator_button.pressed.connect(_on_authenticator_button_pressed)
#endregion INITIALIZATION

#region BUTTONS SIGNALS HANDLERS
## Handles the messages button press
func _on_messages_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.MESSAGESHOME, null)
	touch_sound_player.play_touch_sound()

## Handles the settings button press
func _on_settings_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.SETTINGS, null)
	touch_sound_player.play_touch_sound()

## Handles the email button press
func _on_email_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.EMAIL, null)
	touch_sound_player.play_touch_sound()

## Handles the shop button press
func _on_shop_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.STORE, {
		"available_apps": GameData.apps_in_store,
		"downloaded_apps": GameData.downloaded_apps
	})
	touch_sound_player.play_touch_sound()

## Handles the fake shop button press
func _on_fake_shop_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.FAKESTORE, {
		"available_apps": GameData.apps_in_store,
		"downloaded_apps": GameData.downloaded_apps
	})
	touch_sound_player.play_touch_sound()

## Handles the bank button press
func _on_bank_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.BANK, null)
	touch_sound_player.play_touch_sound()

## Handles the authenticator button press
func _on_authenticator_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.AUTHENTICATOR, null)
	touch_sound_player.play_touch_sound()
#endregion BUTTONS SIGNALS HANDLERS

#region INSTALLATION HELPERS
## Handles the app installation request
##
## app: The application to install
func _on_app_installed(app:GameData.App) -> void:
	# Add the app to downloaded apps
	if not GameData.downloaded_apps.has(app):
		GameData.downloaded_apps.append(app)

	# Show the icon on the home screen
	var app_button:Button = _get_app_button(app)
	if app_button:
		app_button.visible = true

## Handles the app uninstalled event from the store app
##
## app_name: The name of the application being uninstalled
func _on_app_uninstalled(app:GameData.App) -> void:
	# Remove the app from downloaded apps
	if GameData.downloaded_apps.has(app):
		GameData.downloaded_apps.erase(app)

	# Remove the icon from the home screen
	var app_button:Button = _get_app_button(app)
	if app_button:
		app_button.visible = false

## Gets the button node corresponding to the given app
##
## app: The application enum value
func _get_app_button(app:GameData.App) -> Button:
	var app_buttons = {
		GameData.App.MESSAGESHOME: messages_button,
		GameData.App.SETTINGS: settings_button,
		GameData.App.EMAIL: email_button,
		GameData.App.STORE: shop_button,
		GameData.App.FAKESTORE: fake_shop_button
	}
	return app_buttons.get(app)
#endregion INSTALLATION HELPERS
