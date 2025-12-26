extends Control

@export var notification_content_label: Label
@export var notification_title_label: Label
@export var app_icon: TextureRect

var initial_content:String
var initial_title:String
var initial_icon:String = "res://assets/icons/%s.png"

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
	notification_content_label.text = initial_content
	notification_title_label.text = initial_title
	app_icon.texture = load(initial_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
