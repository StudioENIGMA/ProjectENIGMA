extends Controller

const NEW_PASSWORD = preload("res://scenes/phone_settings/new_password.tscn")

@onready var settings_button = get_tree().root.find_child("SettingsButton", true, false)
@onready var messages_button = get_tree().root.find_child("MessagesButton", true, false)
@onready var store_button = get_tree().root.find_child("AppStoreButton", true, false)
@onready var browser_button = get_tree().root.find_child("BrowserButton", true, false)
@onready var email_button = get_tree().root.find_child("Email", true, false)

@onready var node = get_tree().root.find_child("notifications_control", true, false)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#settings_button.pressed.connect(_on_settings_pressed)
	messages_button.pressed.connect(_on_messages_pressed)
	store_button.pressed.connect(_on_store_pressed)
	browser_button.pressed.connect(_on_browser_pressed)
	email_button.pressed.connect(_on_email_pressed)

#func _on_settings_pressed() -> void: 
	#var app_name = AppsControll.apps_name[AppsControll.App.Settings]
	#if not GameData.data.passwords[app_name] == "":
		#return
		#
	#create_password(app_name)

func _on_messages_pressed() -> void: 
	var app_name = AppsControll.apps_name[AppsControll.App.Messages]
	if not GameData.data.passwords[app_name] == "":
		return
		
	create_password(app_name)
	
func _on_store_pressed() -> void: 
	var app_name = AppsControll.apps_name[AppsControll.App.Store]
	if not GameData.data.passwords[app_name] == "":
		return
		
	create_password(app_name)
	
func _on_browser_pressed() -> void: 
	var app_name = AppsControll.apps_name[AppsControll.App.Browser]
	if not GameData.data.passwords[app_name] == "":
		return
		
	create_password(app_name)
	
func _on_email_pressed() -> void: 
	var app_name = AppsControll.apps_name[AppsControll.App.Email]
	if not GameData.data.passwords[app_name] == "":
		return
		
	create_password(app_name)
		
func create_password(app_name : String) -> void:
	var new_password_instance = NEW_PASSWORD.instantiate()
	node.add_child(new_password_instance)
	new_password_instance.setup(app_name)
