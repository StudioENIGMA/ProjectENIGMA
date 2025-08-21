extends Node

@onready var email_button =  $VBoxContainer/Email
@onready var browser_button   = $VBoxContainer/BrowserButton
@onready var message_button   = $VBoxContainer/MessagesButton
@onready var settings_button  = $VBoxContainer/SettingsButton
@onready var app_store_button = $VBoxContainer/AppStoreButton
@onready var fake_store_button =  $VBoxContainer/FakeAppStoreButton

var app_buttons = {}
var downloaded_apps: Array[AppsControll.App] = []

func _ready():
	app_buttons[AppsControll.App.Email] = email_button
	app_buttons[AppsControll.App.Store] = app_store_button
	app_buttons[AppsControll.App.Browser] = browser_button
	app_buttons[AppsControll.App.Messages] = message_button
	app_buttons[AppsControll.App.Settings] = settings_button
	app_buttons[AppsControll.App.FakeStore] = fake_store_button

	update_button_visibility()


func _process(delta: float) -> void:
	update_button_visibility()
		
func update_button_visibility():
	downloaded_apps = AppsControll.get_downloaded_apps()

	for app in app_buttons.keys():
		app_buttons[app].visible = downloaded_apps.has(app)
