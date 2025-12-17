extends Node2D

var initial_content:String
var initial_title:String
var initial_icon:String = "res://assets/icons/%s.png"

@onready var content_node = $notification/content
@onready var title_node = $notification/title
@onready var icon = $notification/icon

func setup(app_enum:EventBus.App, content:String, title:String):
	self.initial_content = content
	self.initial_title = title

	var app_icon_path = ""
	match app_enum:
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
	content_node.text = initial_content
	title_node.text = initial_title
	icon.texture = load(initial_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
