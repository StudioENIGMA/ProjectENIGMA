extends Control

var day_news_data : Dictionary
var day : int

signal subscreen_open_requested(subscreen_name:GameData.App)

func _on_open_browser(subscreen_name:GameData.App) -> void:
	subscreen_open_requested.emit(subscreen_name)

func _ready() -> void:
	day = get_day()
	day_news_data = load_news_data(day)
	print(day_news_data)
	

func load_news_data(current_day) -> Dictionary:
	var file = FileAccess.open("res://data/news.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	var day_key = "day_%d" % current_day
	return data[day_key]

func get_day() -> int:
	var file = FileAccess.open("res://data/save.json", FileAccess.READ)
	var json_text = file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_text)
	var current_day = data["current_day"]
	return current_day
