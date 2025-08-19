extends Node2D

@onready var content = $notification/content
@onready var title = $notification/title
@onready var icon = $notification/icon

var initial_content : String
var initial_title : String
var initial_icon : String = "res://assets/icons/%s.png"

func setup(app_ : EventBus.App, content_ : String, title_ : String):
	self.initial_content = content_
	self.initial_title = title_
	
	var app_icon_path = ""
	match app_:
		0:
			app_icon_path = "app-store"
		1:
			app_icon_path = "browser"
		2:
			app_icon_path = "fake-app-store"
		3:
			app_icon_path = "messages"
		4:
			app_icon_path = "settings"
		5:
			app_icon_path = "email"
	
	self.initial_icon = initial_icon % app_icon_path	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	content.text = initial_content
	title.text = initial_title
	icon.texture = load(initial_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
