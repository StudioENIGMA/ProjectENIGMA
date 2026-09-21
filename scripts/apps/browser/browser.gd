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

const QuickSite = preload("res://scripts/apps/browser/quick_acess_icon.gd")
const PLACEHOLDER_TEXT = "Escolha um site abaixo"
const ADDRESS_COLOR = Color(0.09019608, 0.10980392, 0.18039216, 1)
const PLACEHOLDER_COLOR = Color(0.43137255, 0.44313726, 0.5019608, 1)

@export var news_container : VBoxContainer
@export var news_empty_state: Control
@export var quick_sites_containier: Container
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
	var sites = quick_sites_containier.get_children()
	if not sites.is_empty():
		sites[-1].divider.visible = false
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
	address_label.text = QuickSite.SITE_ADDRESSES.get(app, "")
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
		# Emits toggled (not pressed), so the row puts its badge back without picking itself again
		picked.button_pressed = false
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

	var rows = news_container.get_children().filter(func(row): return not row.is_queued_for_deletion())
	if not rows.is_empty():
		rows[-1].divider.visible = false
	news_empty_state.visible = day_news_data.get("news", []).is_empty()
