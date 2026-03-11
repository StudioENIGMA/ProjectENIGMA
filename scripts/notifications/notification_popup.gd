extends Control

@export var notification_content_label: Label
@export var notification_title_label: Label
@export var app_icon: TextureRect
@export var background: Panel

var initial_content:String
var initial_title:String
var initial_icon:String

func setup(app_enum:GameData.App, content:String, title:String):
	self.initial_content = content
	self.initial_title = title

	var app_data = GameData.apps_data[app_enum]
	initial_icon = app_data.icon_path

	# Check if is a bad app
	var is_bad = app_data.has("is_bad") and app_data.is_bad
	if is_bad:
		# If it's a bad app, set color schema to red
		notification_content_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1))
		notification_title_label.add_theme_color_override("font_color", Color(0.4, 0.1, 0.1))
		app_icon.modulate = Color(1, 0.5, 0.5)

		# Update background color to a red tone
		var styleBox = background.get_theme_stylebox("panel").duplicate()
		styleBox.set("bg_color", Color(1, 0.2, 0.2, 0.8))
		background.add_theme_stylebox_override("panel", styleBox)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	notification_content_label.text = initial_content
	notification_title_label.text = initial_title
	app_icon.texture = load(initial_icon)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
