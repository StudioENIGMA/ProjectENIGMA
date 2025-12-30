extends Control

signal app_opened(app_name:String, optional_data:Dictionary)

@export var messages_button: Button
@export var settings_button: Button
@export var email_button: Button
@export var shop_button: Button
@export var fake_shop_button: Button

@export var base_app: Control

@export var touch_sound_player:AudioStreamPlayer2D

func _ready() -> void:
	base_app.apk_installation_requested.connect(
		_on_app_installed
	)

func _on_messages_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.MESSAGESHOME, null)
	touch_sound_player.play_touch_sound()

func _on_settings_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.SETTINGS, null)
	touch_sound_player.play_touch_sound()

func _on_email_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.EMAIL, null)
	touch_sound_player.play_touch_sound()

func _on_shop_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.STORE, {
		"available_apps": GameData.apps_in_store,
		"downloaded_apps": GameData.downloaded_apps
	})
	touch_sound_player.play_touch_sound()

func _on_fake_shop_button_pressed() -> void:
	emit_signal("app_opened", GameData.App.FAKESTORE, {
		"available_apps": GameData.apps_in_store,
		"downloaded_apps": GameData.downloaded_apps
	})
	touch_sound_player.play_touch_sound()

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

func _on_app_installed(app:GameData.App) -> void:
	# Add the app to downloaded apps
	if not GameData.downloaded_apps.has(app):
		GameData.downloaded_apps.append(app)

	# Show the icon on the home screen
	var app_button:Button = _get_app_button(app)
	if app_button:
		app_button.visible = true

func _get_app_button(app:GameData.App) -> Button:
	var app_buttons = {
		GameData.App.MESSAGESHOME: messages_button,
		GameData.App.SETTINGS: settings_button,
		GameData.App.EMAIL: email_button,
		GameData.App.STORE: shop_button,
		GameData.App.FAKESTORE: fake_shop_button
	}
	return app_buttons.get(app)
