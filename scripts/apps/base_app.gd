extends Control

signal message_answered(answer_id:int)

signal apk_installation_requested(app: GameData.App)

@export var close_app_button:TextureButton
@export var back_button:TextureButton

## Reference to the apps buttons (to manage app opening/closing)
@export var apps_ui:Control

## Reference to the controller that holds specific app controls
@export var app_specific_screen:Control
@export var hack_screen: Control

@export var notification_ui: Control

var messages_app_home = preload("res://scenes/apps/messages/messages_app_home.tscn").instantiate()
var messages_app_chat = preload("res://scenes/apps/messages/messages_app_chat.tscn").instantiate()
var settings_app = preload("res://scenes/settings/settings_app.tscn").instantiate()
var passwords_manager_app = preload("res://scenes/settings/passwords_manager.tscn").instantiate()
var store_app = preload("res://scenes/apps/store-shop/store_app.tscn").instantiate()
var fake_store_app = preload("res://scenes/apps/store-shop/fake_store_app.tscn").instantiate()
var browser_app = preload("res://scenes/apps/browser/browser.tscn").instantiate()
var browser_app_news = preload("res://scenes/apps/browser/news_page.tscn").instantiate()
var browser_app_amazonia_shop = preload(
	"res://scenes/apps/browser/shops/amazonia/amazonia_shop.tscn"
).instantiate()
var browser_app_amazonia_cart = preload(
	"res://scenes/apps/browser/shops/amazonia/amazonia_cart.tscn"
).instantiate()
var browser_app_emilia_shop = preload(
	"res://scenes/apps/browser/shops/emilia_bolos/emilia_shop.tscn"
).instantiate()
var browser_app_emilia_cart = preload(
	"res://scenes/apps/browser/shops/emilia_bolos/emilia_cart.tscn"
).instantiate()
var browser_app_aec_shop = preload(
	"res://scenes/apps/browser/shops/aec/aec_shop.tscn"
).instantiate()
var browser_app_aec_cart = preload(
	"res://scenes/apps/browser/shops/aec/aec_cart.tscn"
).instantiate()
var browser_app_shop_payment_screen = preload(
"res://scenes/apps/browser/shops/payment_screen.tscn"
).instantiate()
var browser_app_fake_shop = preload("res://scenes/apps/browser/fake_shop_site.tscn").instantiate()
var browser_reviews_site = preload(
	"res://scenes/apps/browser/reviews_site/reviews_site.tscn"
).instantiate()
var email_app_home = preload("res://scenes/apps/email/email_app_home.tscn").instantiate()
var email_app_viewer = preload("res://scenes/apps/email/email_app_viewer.tscn").instantiate()
var authenticator_app = preload(
	"res://scenes/apps/authenticator/authenticator_app.tscn"
).instantiate()
var bank_app = preload("res://scenes/apps/bank/bank_app.tscn").instantiate()
var bank_payment_code = preload("res://scenes/apps/bank/payment_code.tscn").instantiate()
var bank_payment_info = preload("res://scenes/apps/bank/payment_information.tscn").instantiate()
var password_check_dialog = preload(
	"res://scenes/settings/passwords_inserter.tscn"
).instantiate()
var password_change_dialog = preload(
	"res://scenes/settings/passwords_changer.tscn"
).instantiate()
var virus_scanner = preload(
	"res://scenes/settings/virus_scanner.tscn"
).instantiate()
var fast_typing = preload(
	"res://scenes/apps/minigames/fast-typing/fast_typing.tscn"
).instantiate()
var line_connect = preload(
	"res://scenes/apps/minigames/connect_paths/connect_paths.tscn"
).instantiate()
var update_os_screen = preload(
	"res://scenes/settings/update_os.tscn"
).instantiate()

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

	# Connect to apps UI app opened signal
	apps_ui.app_opened.connect(_on_app_opened)

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
	passwords_manager_app.password_change_requested.connect(_on_app_opened)
	app_specific_screen.add_child(passwords_manager_app)

	# Update OS screen (Settings app)
	update_os_screen.visible = false
	app_specific_screen.add_child(update_os_screen)

	# Password Check Dialog (Password Manager)
	password_check_dialog.visible = false
	password_check_dialog.password_correct.connect(_on_back_button_pressed)
	app_specific_screen.add_child(password_check_dialog)

	# Virus Scanner app (Virus Scanner app)
	virus_scanner.visible = false
	virus_scanner.app_uninstalled.connect(apps_ui.on_app_uninstalled) # Remove from home screen
	virus_scanner.app_uninstalled.connect(_on_app_uninstalled) # Remove from open apps
	app_specific_screen.add_child(virus_scanner)

	# Store app (Store app)
	store_app.visible = false
	store_app.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(store_app)

	# Fake Store app (Fake Store app)
	fake_store_app.visible = false
	fake_store_app.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(fake_store_app)

	# Browser App (Browser App)
	browser_app.visible = false
	browser_app_news.visible = false
	browser_app.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app)
	app_specific_screen.add_child(browser_app_news)

	#Browser Shops (Browser App)
	#Amazonia
	browser_app_amazonia_shop.visible = false
	browser_app_amazonia_shop.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app_amazonia_shop)

	browser_app_amazonia_cart.visible = false
	browser_app_amazonia_cart.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app_amazonia_cart)

	#Emilia_Bolos
	browser_app_emilia_shop.visible = false
	browser_app_emilia_shop.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app_emilia_shop)

	browser_app_emilia_cart.visible = false
	browser_app_emilia_cart.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app_emilia_cart)

	#A&C
	browser_app_aec_shop.visible = false
	browser_app_aec_shop.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app_aec_shop)

	browser_app_aec_cart.visible = false
	browser_app_aec_cart.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(browser_app_aec_cart)

	#Payment_Screen
	browser_app_shop_payment_screen.visible = false
	app_specific_screen.add_child(browser_app_shop_payment_screen)
	browser_app_shop_payment_screen.cancel_order.connect(_on_back_button_pressed)

	#Reviews Site (Browser App)
	browser_reviews_site.visible = false
	app_specific_screen.add_child(browser_reviews_site)

	# Email app home (Email app)
	email_app_home.visible = false
	email_app_home.subscreen_open_requested.connect(_on_app_opened)
	app_specific_screen.add_child(email_app_home)

	# Email app viewer (Email app)
	email_app_viewer.visible = false
	app_specific_screen.add_child(email_app_viewer)

	# Authenticator app
	authenticator_app.visible = false
	app_specific_screen.add_child(authenticator_app)

	# Bank app (Bank app)
	bank_app.visible = false
	app_specific_screen.add_child(bank_app)
	bank_app.subscreen_open_requested.connect(_on_app_opened)

	# Payment Code (Bank app)
	bank_payment_code.visible = false
	app_specific_screen.add_child(bank_payment_code)
	bank_payment_code.subscreen_open_requested.connect(_on_app_opened)

	# Payment Information (Bank app)
	bank_payment_info.visible = false
	app_specific_screen.add_child(bank_payment_info)
	bank_payment_info.transaction_completed.connect(
		func(_payment_code: GameData.PaymentCode): _on_back_button_pressed(); _on_back_button_pressed()
	)
	bank_payment_info.transaction_completed.connect(
		browser_app_shop_payment_screen._on_transaction_completed
	)

	# Password Change Dialog (Password)
	password_change_dialog.visible = false
	password_change_dialog.password_changed.connect(passwords_manager_app.refresh_passwords_list)
	app_specific_screen.add_child(password_change_dialog)

	# Hack minigame fast type (Hack minigames)
	fast_typing.visible = false
	fast_typing.hack_concluded.connect(_on_back_button_pressed)
	hack_screen.add_child(fast_typing)

	# Hack minigame line connect (Hack minigames)
	line_connect.visible = false
	line_connect.hack_concluded.connect(_on_back_button_pressed)
	hack_screen.add_child(line_connect)

## Handles the app opened event from the desktop UI
func _on_app_opened(app:GameData.App, optional_data = null) -> void:
	# Show top bar when an app is opened
	self.visible = true

	var main_app:GameData.App

	if (app != GameData.App.PASSWORDCHECK):
		main_app = _get_main_app_enum(app)
	else:
		main_app = optional_data["GatedApp"]

	# Add app to open apps list
	open_apps.append({"MainApp": main_app, "SubScreen": app})

	# Get specific app that should be opened
	var specific_app = _get_app_by_enum(app)

	if optional_data != null:
		specific_app.setup(optional_data)
	
	specific_app.visible = true
	notification_ui.visible = true

	# If is a hack minigame, do not show back or close buttons
	var hack_minigames = [
		GameData.App.FASTTYPING,
		GameData.App.LINECONNECT,
	]
	if main_app in hack_minigames:
		hack_screen.visible = true
		specific_app.setup()
		hack_screen.move_child(specific_app, hack_screen.get_child_count() - 1)
		notification_ui.visible = false
		return

	# Pull specific app to front
	app_specific_screen.move_child(specific_app, app_specific_screen.get_child_count() - 1)

	# Show back button if more than one app is open and hide previous app
	# Also, do not show back button if the current app is the password check dialog
	if open_apps.size() > 1 && app != GameData.App.PASSWORDCHECK:
		back_button.visible = true
		close_app_button.visible = true
		var previous_app_dict:Dictionary = open_apps[open_apps.size() - 2]
		var previous_app_enum:GameData.App = previous_app_dict["SubScreen"]
		var previous_app = _get_app_by_enum(previous_app_enum)
		previous_app.visible = false
	else:
		back_button.visible = false
		close_app_button.visible = true
	# Open password check dialog if the app is password protected
	if app in GameData.passwords.keys(): # Single source of truth
		_on_app_opened(GameData.App.PASSWORDCHECK, {"GatedApp": main_app})

## Handles the close app button press event
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
		close_app_button.visible = true
	else:
		back_button.visible = false
		close_app_button.visible = number_of_open_apps == 1

	# Show previous app if any
	if number_of_open_apps > 0:
		var previous_app_dict:Dictionary = open_apps[number_of_open_apps - 1]
		var previous_app_enum:GameData.App = previous_app_dict["SubScreen"]
		var previous_app = _get_app_by_enum(previous_app_enum)
		previous_app.visible = true

## Handles the close app button press event
func _on_close_app_button_pressed() -> void:
	if open_apps.is_empty():
		return

	var current_app_dict: Dictionary = open_apps[open_apps.size() - 1]
	var main_app_enum: GameData.App = current_app_dict["MainApp"]

	_close_main_app(main_app_enum)

## Handles the app uninstalled event from the store app
func _on_app_uninstalled(app:GameData.App) -> void:
	# If the uninstalled app is currently open, close it
	var main_app := _get_main_app_enum(app)

	if _has_open_main_app(main_app):
		_close_main_app(main_app)

## Checks if there is any open app with the specified main app enum
func _has_open_main_app(main_app: GameData.App) -> bool:
	for app_dict in open_apps:
		if app_dict.get("MainApp") == main_app:
			return true
	return false

## Closes all open apps with the specified main app enum
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

## Starts the hack minigame
func start_hack_minigame(hack_minigame: GameData.HackMinigame) -> void:
	match hack_minigame:
		GameData.HackMinigame.FASTTYPING:
			_on_app_opened(GameData.App.LINECONNECT)
		GameData.HackMinigame.MAZE:
			_on_app_opened(GameData.App.LINECONNECT)
		GameData.HackMinigame.LINECONNECT:
			_on_app_opened(GameData.App.LINECONNECT)
		_:
			_on_app_opened(GameData.App.LINECONNECT)

## Returns the app node by its name
func _get_app_by_enum(app_enum:GameData.App) -> Control:
	var app_map = {
		# Messages app
		GameData.App.MESSAGESHOME: messages_app_home,
		GameData.App.MESSAGESCHAT: messages_app_chat,
		# Settings app
		GameData.App.SETTINGS: settings_app,
		GameData.App.PASSWORDMANAGER: passwords_manager_app,
		GameData.App.PASSWORDCHECK: password_check_dialog,
		GameData.App.VIRUSSCANNER: virus_scanner,
		GameData.App.UPDATEOS: update_os_screen,
		# Store app
		GameData.App.STORE: store_app,
		GameData.App.FAKESTORE: fake_store_app,
		# Browser app
		GameData.App.BROWSER: browser_app,
		GameData.App.BROWSERNEWS: browser_app_news,
		GameData.App.BROWSERAMAZONIASHOP: browser_app_amazonia_shop,
		GameData.App.BROWSERAMAZONIACART: browser_app_amazonia_cart,
		GameData.App.BROWSEREMILIASHOP: browser_app_emilia_shop,
		GameData.App.BROWSEREMILIACART: browser_app_emilia_cart,
		GameData.App.BROWSERAECSHOP: browser_app_aec_shop,
		GameData.App.BROWSERAECCART: browser_app_aec_cart,
		GameData.App.BROWSERFAKESHOP: browser_app_fake_shop,
		GameData.App.BROWSERPAYMENTSCREEN: browser_app_shop_payment_screen,
		GameData.App.REVIEWSSITE: browser_reviews_site,
		# Email app
		GameData.App.EMAIL: email_app_home,
		GameData.App.EMAILREAD: email_app_viewer,
		# Authenticator app
		GameData.App.AUTHENTICATOR: authenticator_app,
		# Bank app
		GameData.App.BANK: bank_app,
		GameData.App.PAYMENTCODE: bank_payment_code,
		GameData.App.PAYMENTINFORMATION: bank_payment_info,
		# Password Manager app (not settings, as it must close alone)
		GameData.App.PASSWORDCHANGE: password_change_dialog,
		# Hack minigames
		GameData.App.FASTTYPING: fast_typing,
		GameData.App.LINECONNECT: line_connect,
	}
	return app_map.get(app_enum, null)

## Returns the main app enum for a given subscreen enum
func _get_main_app_enum(subscreen_enum:GameData.App) -> GameData.App:
	var main_app_map = {
		# Messages app
		GameData.App.MESSAGESHOME: GameData.App.MESSAGESHOME,
		GameData.App.MESSAGESCHAT: GameData.App.MESSAGESHOME,
		# Settings app
		GameData.App.SETTINGS: GameData.App.SETTINGS,
		GameData.App.PASSWORDMANAGER: GameData.App.SETTINGS,
		GameData.App.VIRUSSCANNER: GameData.App.SETTINGS,
		GameData.App.UPDATEOS: GameData.App.SETTINGS,
		# Store app
		GameData.App.STORE: GameData.App.STORE,
		GameData.App.FAKESTORE: GameData.App.STORE,
		# Browser app
		GameData.App.BROWSER: GameData.App.BROWSER,
		GameData.App.BROWSERNEWS: GameData.App.BROWSER,
		GameData.App.BROWSERAMAZONIASHOP: GameData.App.BROWSER,
		GameData.App.BROWSERAMAZONIACART: GameData.App.BROWSER,
		GameData.App.BROWSEREMILIASHOP: GameData.App.BROWSER,
		GameData.App.BROWSEREMILIACART: GameData.App.BROWSER,
		GameData.App.BROWSERAECSHOP: GameData.App.BROWSER,
		GameData.App.BROWSERAECCART: GameData.App.BROWSER,
		GameData.App.BROWSERFAKESHOP: GameData.App.BROWSER,
		GameData.App.BROWSERPAYMENTSCREEN: GameData.App.BROWSER,
		GameData.App.REVIEWSSITE: GameData.App.BROWSER,
		# Email app
		GameData.App.EMAIL: GameData.App.EMAIL,
		GameData.App.EMAILREAD: GameData.App.EMAIL,
		# Authenticator app
		GameData.App.AUTHENTICATOR: GameData.App.AUTHENTICATOR,
		# Bank app
		GameData.App.BANK: GameData.App.BANK,
		GameData.App.PAYMENTCODE: GameData.App.BANK,
		GameData.App.PAYMENTINFORMATION: GameData.App.BANK,
		# Password Manager app (not settings, as it must close alone)
		GameData.App.PASSWORDCHANGE: GameData.App.PASSWORDMANAGER,
		# Hack minigames
		GameData.App.FASTTYPING: GameData.App.FASTTYPING,
		GameData.App.LINECONNECT: GameData.App.LINECONNECT,
	}
	return main_app_map.get(subscreen_enum, null)
