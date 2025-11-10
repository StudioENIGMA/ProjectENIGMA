extends Node2D

@onready var news_container = $Panel/News
var news_panel := preload("res://scenes/browser/browser_news.tscn")
var current_day

func _ready():
	var path = "res://data/save.json"	
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var json = JSON.parse_string(content)
	current_day = json["current_day"]
	if(current_day == 1.0):
		var news1 = load("res://data/news/day1/news_1.tres")
		var news2 = load("res://data/news/day1/news_2.tres")
		var news3 = load("res://data/news/day1/news_3.tres")
		create_news(news1)
		create_news(news2)
		create_news(news3)
	elif(current_day == 2.0):
		pass
	elif(current_day == 3.0):
		pass
	elif(current_day == 4.0):
		pass
	elif(current_day == 5.0):
		pass
	else:
		pass
	#fazer os outros casos...

func create_news(news):
	var panel = news_panel.instantiate()
	panel.get_node("news_title").text = news.title
	panel.get_node("news_author_time").text = news.author + " • " + news.published_hour
	panel.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			open_news_page(news)
	)
	news_container.add_child(panel)
	
func open_news_page(news):
	var scene = load("res://scenes/browser/news_page.tscn").instantiate()
	get_tree().current_scene.add_child(scene)
	scene.receive_news(news)
	

func _on_exit_browser_pressed() -> void:
	invisible()
func invisible() -> void:
	visible = not visible
