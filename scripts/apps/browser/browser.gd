extends Control

@export var news_container : VBoxContainer

var day_news_data : Dictionary

signal request_news
signal news_received(day_news: Dictionary)

signal subscreen_open_requested(subscreen_name:GameData.App)

func _on_open_browser(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name)

func _ready():
	request_news.emit()	
	call_deferred("emit_signal", "request_news")
	await news_received
	for news in day_news_data["news"]:
		print(news)
		var browser_home_news = load("res://scenes/apps/browser/browser_home_news.tscn").instantiate()
		browser_home_news.set_news_data(news["title"], news["metadata"])
		news_container.add_child(browser_home_news)
	

func _on_news_received(day_news: Dictionary) -> void:
	day_news_data = day_news
	news_received.emit(day_news)
	
