extends Control

@export var notification_content_label: Label
@export var notification_title_label: Label
@export var app_icon: TextureRect

var initial_content:String
var initial_title:String
var initial_icon:String

func setup(app_enum:GameData.App, content:String, title:String):
	self.initial_content = content
	self.initial_title = title

	var app_data = GameData.apps_data[app_enum]
	initial_icon = app_data.icon_path

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	notification_content_label.text = initial_content
	notification_title_label.text = initial_title
	app_icon.texture = load(initial_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
