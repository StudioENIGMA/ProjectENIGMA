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
	FASTTYPING,
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

var bank_balance: float = 200

var starting_hours_minutes:int = 600	# Start at 6:00
var hours_minutes:int = 600 # This one will increase with time
var max_hours_minutes:int = 1200 # End at 12:00
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
var hack_immunity_ticks: int = 30 # Number of ticks of immunity after being hacked
var is_hacked: bool = false
var last_hacked_tick: int = starting_hours_minutes # Safe game start
var number_of_viruses: int = 1
var unsafe_apps: Array[App] = [App.FAKESTORE]

var apps_name: Dictionary = {
	# Messages app
	"MessagesHome": App.MESSAGESHOME,
	"MessagesChat": App.MESSAGESCHAT,
	# Settings app
	"Settings": App.SETTINGS,
	"PasswordManager": App.PASSWORDMANAGER,
	# Store apps
	"Store": App.STORE,
	"FakeStore": App.FAKESTORE,
	# Browser
	"Browser": App.BROWSER,
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
}

var apps_chinese_operations = {
	"install": "開始安裝",
	"installing": "正在安裝...",
	"update": "應用程式更新",
	"open": "阿布里爾"
}

var apps_in_store: Array[App] = [App.MESSAGESHOME, App.EMAIL, App.BROWSER]
var downloaded_apps: Array[App] = [App.MESSAGESHOME, App.BROWSER]
var available_updates: Array[App] = []

func _ready() -> void:
	# Create reverse mapping for apps_name
	for app_name in apps_name.keys():
		var app_enum = apps_name[app_name]
		apps_name_reverse[app_enum] = app_name

	# Export game data for tools (like the app icons)
	export_game_data_for_tools()

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

func export_game_data_for_tools() -> void:
	var file_path = "res://data/exported_game_data.json"

	var json_string = JSON.stringify({
		"apps_data": apps_data,
	})

	var save_file = FileAccess.open(file_path, FileAccess.WRITE)
	if save_file:
		save_file.store_string(json_string)
		save_file.close()
