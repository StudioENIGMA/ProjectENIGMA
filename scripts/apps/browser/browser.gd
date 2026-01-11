extends Control

var day_news_data : Dictionary

signal request_news

signal subscreen_open_requested(subscreen_name:GameData.App)

func _on_open_browser(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name)

func _ready():
	request_news.emit()	
	call_deferred("emit_signal", "request_news")
	

func _on_news_received(day_news: Dictionary) -> void:
	day_news_data = day_news
	print("Browser: news received -> ", day_news_data)
	
