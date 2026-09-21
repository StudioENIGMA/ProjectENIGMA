extends Control

signal request_news
signal news_received(day_news: Dictionary)

signal subscreen_open_requested(
	subscreen_name: GameData.App,
	optional_data
)

signal open_site_requested(
	app: GameData.App
)

## Address written on the search bar when a quick access site is picked
const SITE_ADDRESSES = {
	GameData.App.REVIEWSSITE: "elogiela.com.br",
	GameData.App.BROWSERAMAZONIASHOP: "amazonia.com.br",
	GameData.App.BROWSERLIBREMERCADOSHOP: "libremercado.com.br",
	GameData.App.BROWSEREMILIASHOP: "emiliabolos.com.br",
	GameData.App.BROWSEREMPORIOBOLOSSHOP: "emporiodosbolos.com.br",
	GameData.App.BROWSERAECSHOP: "aec.com.br",
	GameData.App.BROWSERZORASHOP: "zora.com.br",
}
const PLACEHOLDER_TEXT = "Escolha um site abaixo"
const ADDRESS_COLOR = Color(0.039215688, 0.23137255, 0.19215687, 1)
const PLACEHOLDER_COLOR = Color(0.039215688, 0.23137255, 0.19215687, 0.55)

@export var news_container : VBoxContainer
@export var news_empty_state: Control
@export var quick_sites_containier: GridContainer
@export var address_label: Label
@export var go_button: Button

var day_news_data : Dictionary

## Keeps a single quick access site picked at a time
var _site_group := ButtonGroup.new()
## The site waiting to be opened, null while the player has not picked one
var _picked_site = null

func _on_open_browser(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name, null)

func _ready():
	update_news()
	_site_group.allow_unpress = true
	for quick_site in quick_sites_containier.get_children():
		quick_site.toggle_mode = true
		quick_site.button_group = _site_group
		quick_site.open_site_requested.connect(_on_site_picked)
	go_button.pressed.connect(_on_go_button_pressed)
	visibility_changed.connect(func(): if not visible: _clear_address())
	_clear_address()

#region ADDRESS BAR

## Writes the site the player picked on the search bar, ready to be opened
func _on_site_picked(app: GameData.App) -> void:
	if _picked_site == app:
		# Tapping the picked site again unpicks it
		_clear_address()
		return
	_picked_site = app
	address_label.text = SITE_ADDRESSES.get(app, "")
	address_label.add_theme_color_override("font_color", ADDRESS_COLOR)
	go_button.disabled = false

func _on_go_button_pressed() -> void:
	if _picked_site == null:
		return
	var site: GameData.App = _picked_site
	_clear_address()
	_on_open_site_requested(site)

## Empties the search bar, leaving the placeholder and nothing to open
func _clear_address() -> void:
	_picked_site = null
	var picked = _site_group.get_pressed_button()
	if picked:
		picked.set_pressed_no_signal(false)
	address_label.text = PLACEHOLDER_TEXT
	address_label.add_theme_color_override("font_color", PLACEHOLDER_COLOR)
	go_button.disabled = true

#endregion ADDRESS BAR


func _on_news_received(day_news: Dictionary) -> void:
	day_news_data = day_news
	news_received.emit(day_news)

func _on_open_news(news_data : Dictionary):
	subscreen_open_requested.emit(GameData.App.BROWSERNEWS, news_data)

func _on_open_site_requested(app: GameData.App):
	open_site_requested.emit(app)

func update_news():
	if news_container:
		for child in news_container.get_children():
			child.queue_free()
	request_news.emit()
	call_deferred("emit_signal", "request_news")
	await news_received

	if day_news_data.has("news"):
		for news in day_news_data["news"]:

			var browser_home_news = load("res://scenes/apps/browser/browser_home_news.tscn").instantiate()

			browser_home_news.set_news_data(news["title"], news["content"], news["metadata"])
			browser_home_news.open_news.connect(_on_open_news)
			news_container.add_child(browser_home_news)

	news_empty_state.visible = day_news_data.get("news", []).is_empty()
