extends Node2D

var title : String
var text : String

func _ready():
	var news_title = $Panel/ScrollContainer/VBoxContainer/news_title
	var news_text = $Panel/ScrollContainer/VBoxContainer/news_text
	
	if title != "" and text != "":
		news_title.text = title
		news_text.text = text


func _on_go_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/browser.tscn")
