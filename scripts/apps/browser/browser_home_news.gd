extends HBoxContainer

@export var news_content: Label 
@export var news_metadata: Label 

func set_news_data(news_title : String, news_data : String) -> void:
	
	news_content.text = news_title
	news_metadata.text = news_data
