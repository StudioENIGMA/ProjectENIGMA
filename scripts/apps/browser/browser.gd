extends Control

signal request_news
signal news_received(day_news: Dictionary)

signal subscreen_open_requested(
	subscreen_name: GameData.App,
	optional_data
)

@export var news_container : VBoxContainer
@export var quick_sites_containier: GridContainer

var day_news_data : Dictionary

func _on_open_browser(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name, null)

func _ready():
	request_news.emit()
	call_deferred("emit_signal", "request_news")
	await news_received
	for news in day_news_data["news"]:

		var browser_home_news = load("res://scenes/apps/browser/browser_home_news.tscn").instantiate()

		browser_home_news.set_news_data(news["title"], news["content"], news["metadata"])
		browser_home_news.open_news.connect(_on_open_news)
		news_container.add_child(browser_home_news)

	for quick_site in quick_sites_containier.get_children():
		quick_site.open_site_requested.connect(_on_open_site_requested)


func _on_news_received(day_news: Dictionary) -> void:
	day_news_data = day_news
	news_received.emit(day_news)

func _on_open_news(news_data : Dictionary):
	subscreen_open_requested.emit(GameData.App.BROWSERNEWS, news_data)

func _on_open_site_requested(app: GameData.App):
	subscreen_open_requested.emit(app, null)
