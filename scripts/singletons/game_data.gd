extends Node

enum App {
	# Messages app
	MESSAGESHOME,
	MESSAGESCHAT,
	# Settings app
	SETTINGS,
	PASSWORDMANAGER,
	# Store app
	STORE,
	FAKESTORE,
	# Browser app
	BROWSER,
	# Email app
	EMAIL,
}

enum Sender {
	PLAYER,
	NPC,
}

var hours_minutes:int = 1080 # Start at 18:00

var apps_name: Dictionary = {
	# Messages app
	App.MESSAGESHOME: "MessagesHome",
	App.MESSAGESCHAT: "MessagesChat",
	# Settings app
	App.SETTINGS: "Settings",
	App.PASSWORDMANAGER: "PasswordManager",
	# Store apps
	App.STORE: "Store",
	App.FAKESTORE: "FakeStore",
}

var apps_data = {
	App.MESSAGESHOME: {
		"name": "Mensagens",
		"chinese_name": "訊息和對話",
		"description": "Receba e Envie Mensagens!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/messages.png",
	},

	App.EMAIL: {
		"name": "Email",
		"chinese_name": "電子郵件",
		"description": "Receba e envie emails aqui!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/email.png",
	},

	App.BROWSER: {
		"name": "Navegador",
		"chinese_name": "導航和搜尋",
		"description": "Acesse seus sites favoritos!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/browser.png",
	},
}

var apps_chinese_operations = {
	"install": "開始安裝",
	"installing": "正在安裝...",
	"update": "應用程式更新",
	"open": "阿布里爾"
}

var apps_in_store: Array[App] = [App.MESSAGESHOME, App.BROWSER, App.EMAIL]
var downloaded_apps: Array[App] = [App.MESSAGESHOME, App.EMAIL]
var available_updates: Array[App] = []

var data = {
	"current_day": 0,
	"reputation_points": 0,
	"random_send_amplitude_max":480,
	"max_game_time":600,
	"virus_info": {
		"has_virus": false,
		"viruses_quantity":0,
		"virus_time": 0
	},
	"OS_version": "0",
	"passwords": {
		"Ajustes":"",
		"Mensagens":"",
		"Loja":"",
		"Navegador":"",
		"Email":"",
		"Loja Alternativa":"",
	},
	"downloaded_apps": ["mensagens", "settings"],
	"has_store": true,
	"has_fake_store": true,
	"has_browser": true,
	"has_mail": true,
	"has_settings": true
}

func load_game() -> void:
	var file_path = "res://data/save.json"

	var save_file = FileAccess.open(file_path, FileAccess.READ)
	if save_file:
		var json_string = save_file.get_as_text()
		save_file.close()

		var save_json = JSON.new()
		var parse_result = save_json.parse(json_string)
		if not parse_result == OK:
			print("JSON Parse Error: ", save_json.get_error_message())
			return

		var save_data = save_json.data
		data = save_data

func save_game() -> void:
	var file_path = "res://data/save.json"

	var json_string = JSON.stringify(data)
	print(json_string)

	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(json_string)
		save_file.close()
