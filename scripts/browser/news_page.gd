extends Node2D

var title : String
var text : String
@onready var news_title = $Panel/ScrollContainer/MarginContainer/VBoxContainer/news_title
@onready var news_text = $Panel/ScrollContainer/MarginContainer/VBoxContainer/news_text

func _ready():
	if title != "" and text != "":
		news_title.text = title
		news_text.text = text


func _on_go_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/browser/browser.tscn")
	
func receive_news(news):
	news_title.text = news.title
	news_text.text = news.text
