extends Node

enum Sender {
	PLAYER,
	NPC,
}

enum App {
	# Messages app
	MESSAGESHOME,
	MESSAGESCHAT,
	# Settings app
	SETTINGS,
	PASSWORDMANAGER,
	PASSWORDCHECK,
	PASSWORDCHANGE,
	VIRUSSCANNER,
	UPDATEOS,
	# Store app
	STORE,
	FAKESTORE,
	# Browser app
	BROWSER,
	BROWSERNEWS,
	BROWSERAMAZONIASHOP,
	BROWSERAMAZONIACART,
	BROWSEREMILIASHOP,
	BROWSEREMILIACART,
	BROWSERAECSHOP,
	BROWSERAECCART,
	BROWSERPAYMENTSCREEN,
	BROWSERFAKESHOP,
	REVIEWSSITE,
	# Email app
	EMAIL,
	EMAILREAD,
	# Authenticator app
	AUTHENTICATOR,
	# Bank app
	BANK,
	PAYMENTCODE,
	PAYMENTINFORMATION,
	# Hack minigames
	HACK, # Used only for notifications
	FASTTYPING,
	LINECONNECT,
	MAZE,
}

enum HackMinigame {
	FASTTYPING,
	MAZE,
	LINECONNECT,
}

enum PaymentType {
	PIX,
	TICKET,
}

class PaymentCode:
	var code: String
	var type: PaymentType

class ShoppingInfo:
	var shop_enum: App
	var shopping_cart: Array = []
	var total_price: float = 0
	var is_order_opened: bool = false

	func reset():
		shopping_cart.clear()
		total_price = 0
		is_order_opened = false

var shops_names = {
	App.BROWSERAMAZONIASHOP: "Amazônia",
	App.BROWSEREMILIASHOP: "Emília Bolos",
	App.BROWSERAECSHOP: "A&C"
}

var cart_enum_to_shop_enum = {
	App.BROWSERAMAZONIACART: App.BROWSERAMAZONIASHOP,
	App.BROWSEREMILIACART: App.BROWSEREMILIASHOP,
	App.BROWSERAECCART: App.BROWSERAECSHOP
}

var verified_contacts = []

var bank_balance: float = 200

var random_events_history = []

var start_date_dict: Dictionary # {year, month, day, weekday}
var starting_hours_minutes:int = 600	# Start at 10:00
var hours_minutes:int = 600 # This one will increase with time
var max_hours_minutes:int = 960 # End at 16:00
var current_day:int = 0
var reputation_points:int = 0
var authentication_codes: Dictionary = {} # GameData.App as key, code as value
var passwords: Dictionary = {
	App.BANK: str(randi_range(0, 9999)).pad_zeros(4), # Random default password each time
}

var updated_password_today: bool = false
var updated_os_today: bool = false
var breaches_immunity_ticks: int = 45

var current_hack_probability: float = 0 # Probability of being hacked every tick
var expected_ticks_between_hacks: int = 90 # Desired average number of ticks between hacks
var decrement_due_breach: int = 30
var hack_immunity_ticks: int = 10 # Number of ticks of immunity after being hacked
var is_hacked: bool = false
var is_in_minigame: bool = false
var last_hacked_tick: int = starting_hours_minutes # Safe game start
var number_of_viruses: int = 1
var unsafe_apps: Array[App] = [App.FAKESTORE]

var saved_messages_conversations: Array[Dictionary] = []
var saved_email_threads: Array = []

var apps_name: Dictionary = {
	# Messages app
	"MessagesHome": App.MESSAGESHOME,
	"MessagesChat": App.MESSAGESCHAT,
	# Settings app
	"Settings": App.SETTINGS,
	"PasswordManager": App.PASSWORDMANAGER,
	# Store apps
	"Store": App.STORE,
	"fake_store": App.FAKESTORE,
	# Browser
	"browser": App.BROWSER,
	"BrowserNews": App.BROWSERNEWS,
	"BrowserAmazoniaShop": App.BROWSERAMAZONIASHOP,
	"BrowserAmazoniaCart": App.BROWSERAMAZONIACART,
	"BrowserEmiliaShop": App.BROWSEREMILIASHOP,
	"BrowserEmiliaCart": App.BROWSEREMILIACART,
	"BrowserAeCShop": App.BROWSERAECSHOP,
	"BrowserAeCCart": App.BROWSERAECCART,
	"BrowserFakeShop": App.BROWSERFAKESHOP,
	"ReviewsSite": App.REVIEWSSITE,
	# Bank app
	"Bank" : App.BANK,
	"PaymentCode" : App.PAYMENTCODE,
	"PaymentInformation" : App.PAYMENTINFORMATION,
	# Email app
	"Email": App.EMAIL,
	"EmailRead": App.EMAILREAD,
	# Authenticator app
	"Authenticator": App.AUTHENTICATOR,
	# Password app
	"PasswordCheck": App.PASSWORDCHECK,
}

var apps_name_reverse: Dictionary = {}

# WARNING: Only Main Apps should be here, not subscreens
var apps_data = {
	App.MESSAGESHOME: {
		"name": "Mensagens",
		"chinese_name": "訊息和對話",
		"description": "Receba e Envie Mensagens!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/messages.png",
	},

	App.BROWSER: {
		"name": "Navegador",
		"chinese_name": "導航和搜尋",
		"description": "Acesse seus sites favoritos!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/browser.png",
	},

	App.EMAIL: {
		"name": "Email",
		"chinese_name": "電子郵件",
		"description": "Receba e envie emails aqui!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/email.png",
	},

	App.SETTINGS: {
		"name": "Configurações",
		"chinese_name": "設定和個人化",
		"description": "Ajuste as configurações do seu dispositivo!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/settings.png",
	},

	App.STORE: {
		"name": "Loja",
		"chinese_name": "應用程式商店",
		"description": "Baixe novos aplicativos para o seu dispositivo!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/app-store.png",
	},

	App.FAKESTORE: {
		"name": "Loja Falsa",
		"chinese_name": "假商店",
		"description": "Uma loja falsa para testar se o jogador sabe identificar golpes!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/fake-app-store.png",
	},

	App.AUTHENTICATOR: {
		"name": "Autenticador",
		"chinese_name": "身份驗證器",
		"description": "Gerencie seus códigos de autenticação de dois fatores aqui!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/default-app.png",
	},

	App.BANK: {
		"name": "Banco",
		"chinese_name": "銀行和財務",
		"description": "Gerencie suas finanças e faça pagamentos aqui!",
		"description_in_chinese": "Chinese",
		"icon_path": "res://assets/icons/utai.png",
	},

	App.HACK: {
		"name": "Hack",
		"icon_path": "res://assets/icons/utai.png",
		"is_bad": true,
	}
}

var apps_chinese_operations = {
	"install": "開始安裝",
	"installing": "正在安裝...",
	"update": "應用程式更新",
	"open": "阿布里爾"
}

var apps_in_store: Array[App] = [App.MESSAGESHOME, App.EMAIL]
var downloaded_apps: Array[App] = [App.MESSAGESHOME]

func _ready() -> void:
	# Create reverse mapping for apps_name
	for app_name in apps_name.keys():
		var app_enum = apps_name[app_name]
		apps_name_reverse[app_enum] = app_name

	# Export game data for tools (like the app icons)
	export_game_data_for_tools()

func get_human_typing_time(message: String) -> int:
	var word_count = message.split(" ").size()

	# 1. Base time: simulated reaction/start time
	var base_thinking_time = 0.5

	var total_time = base_thinking_time

	# 2. Variable time: approx 0.15 to 0.3 seconds per word
	for _i in range(word_count):
		var time_per_word = randf_range(0.15, 0.3)
		total_time += time_per_word

	return total_time

func format_brl(value: float) -> String:
	var result = "-" if sign(value) == -1 else ""
	value = abs(value)

	# Round to 2 decimal places
	var rounded: String = "%.2f" % value
	var parts: PackedStringArray = rounded.split(".")
	var integer_part: String = parts[0]
	var decimal_part: String = parts[1]

	# Add thousand separators
	var formatted_int: String = ""
	var count: int = 0

	for i in range(integer_part.length() - 1, -1, -1):
		formatted_int = integer_part[i] + formatted_int
		count += 1
		if count == 3 and i != 0:
			formatted_int = "." + formatted_int
			count = 0

	result += "R$ %s,%s" % [formatted_int, decimal_part]

	return result

func hours_minutes_as_string(relative_time: int) -> String:
	var current_day_minutes:float = relative_time + starting_hours_minutes
	var current_hour:int = int(current_day_minutes / 60)
	var current_minute:int = int(current_day_minutes) % 60
	return "%02d:%02d" % [current_hour, current_minute]

func get_current_date_dict() -> Dictionary:
	var current_date_dict: Dictionary = start_date_dict.duplicate(true)

	# convert all values to int to avoid issues with JSON parsing
	for key in current_date_dict.keys():
		current_date_dict[key] = int(current_date_dict[key])

	# Gets the current system timezone offset (in minutes)
	var tz = Time.get_time_zone_from_system()
	var offset_seconds = tz.bias * 60

	# Converts to Unix timestamp, but add the offset to correct it
	# We add the offset because Godot treats the input as UTC.
	# By adding the offset, we "shift" the local time into true UTC.
	var utc_unix = Time.get_unix_time_from_datetime_dict(current_date_dict) + offset_seconds

	# 3. Adds the current day (86,400 seconds)
	var next_day_utc = utc_unix + current_day * 86400

	# Convert back to dictionary and subtract the offset to return to local time
	return Time.get_datetime_dict_from_unix_time(next_day_utc - offset_seconds)

func export_game_data_for_tools() -> void:
	var file_path = "res://data/exported_game_data.json"

	var json_string = JSON.stringify({
		"apps_data": apps_data,
	})

	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(json_string)
		save_file.close()

func save_game() -> void:
	var file_path = "user://saved_game.json"
	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file == null:
		push_error("Could not open save file for writing")
		return

	var game_state = {
		"start_date_dict": start_date_dict,
		"current_day": current_day,
		"reputation_points": reputation_points,
		"passwords": passwords,
		"apps_in_store": apps_in_store,
		"downloaded_apps": downloaded_apps,
		"saved_messages_conversations": saved_messages_conversations,
		"saved_email_threads": saved_email_threads,
	}

	save_file.store_string(JSON.stringify(game_state))
	save_file.close()

func load_game() -> void:
	var file_path := "user://saved_game.json"
	if not FileAccess.file_exists(file_path):
		return

	var load_file := FileAccess.open(file_path, FileAccess.READ)
	if load_file == null:
		return

	var json_string := load_file.get_as_text()
	load_file.close()

	var json := JSON.new()
	var err := json.parse(json_string)
	if err != OK:
		push_error("Failed to parse save file")
		return

	var game_state: Dictionary = json.data

	start_date_dict = game_state.get("start_date_dict")
	current_day = int(game_state.get("current_day"))
	reputation_points = int(game_state.get("reputation_points"))

	var game_state_passwords = game_state.get("passwords", {})
	var saved_passwords: Dictionary = {}
	for app_number in game_state_passwords.keys():
		var app_enum = int(app_number)
		saved_passwords[app_enum] = str(game_state_passwords[app_number])
	passwords = saved_passwords

	var raw_apps_in_store: Array = game_state.get("apps_in_store", [])
	var restored_apps_in_store: Array[App] = []
	for value in raw_apps_in_store:
		restored_apps_in_store.append(int(value))
	apps_in_store = restored_apps_in_store

	var raw_downloaded_apps: Array = game_state.get("downloaded_apps", [])
	var restored_downloaded_apps: Array[App] = []
	for value in raw_downloaded_apps:
		restored_downloaded_apps.append(int(value))
	downloaded_apps = restored_downloaded_apps

	var raw_saved_conversations: Array = game_state.get("saved_messages_conversations", [])
	saved_messages_conversations.clear()
	for saved_conversation in raw_saved_conversations:
		saved_conversation.notification_count = int(saved_conversation.get("notification_count", 0))
		saved_messages_conversations.append(saved_conversation.duplicate(true))

	var raw_saved_email_threads: Array = game_state.get("saved_email_threads", [])
	saved_email_threads.clear()

	for saved_thread in raw_saved_email_threads:
		saved_email_threads.append(saved_thread.duplicate(true))
