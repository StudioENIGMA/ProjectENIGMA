extends HBoxContainer

@export var news_content: Label 
@export var news_metadata: Label

signal open_news(news_data: Dictionary)
var _news_data: Dictionary

func set_news_data(news_title : String, news_text_content : String, news_data : String) -> void:
	
	_news_data = {
		"title": news_title,
		"content": news_text_content,
		"metadata": news_data,
	}
	news_content.text = news_title
	news_metadata.text = news_data

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			open_news.emit(_news_data)
