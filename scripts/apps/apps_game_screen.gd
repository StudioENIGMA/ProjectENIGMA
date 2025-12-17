extends Node

var app_buttons = {}
var downloaded_apps: Array[AppsControl.App] = []

@onready var email_button =  $VBoxContainer/Email
@onready var browser_button   = $VBoxContainer/BrowserButton
@onready var message_button   = $VBoxContainer/MessagesButton
@onready var settings_button  = $VBoxContainer/SettingsButton
@onready var app_store_button = $VBoxContainer/AppStoreButton
@onready var fake_store_button =  $VBoxContainer/FakeAppStoreButton

func _ready():
	app_buttons[AppsControl.App.EMAIL] = email_button
	app_buttons[AppsControl.App.STORE] = app_store_button
	app_buttons[AppsControl.App.BROWSER] = browser_button
	app_buttons[AppsControl.App.MESSAGES] = message_button
	app_buttons[AppsControl.App.SETTINGS] = settings_button
	app_buttons[AppsControl.App.FAKESTORE] = fake_store_button

	update_button_visibility()


func _process(_delta: float) -> void:
	update_button_visibility()

func update_button_visibility():
	downloaded_apps = AppsControl.get_downloaded_apps()

	for app in app_buttons.keys():
		app_buttons[app].visible = downloaded_apps.has(app)
