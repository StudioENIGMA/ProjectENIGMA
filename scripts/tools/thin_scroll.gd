@tool
extends ScrollContainer

@export var size_x: int:
	set(value):
		size_x = value
		_ready()

func _ready() -> void:
	var scroll_bar := get_v_scroll_bar()
	
	var current_style = scroll_bar.get_theme_stylebox("scroll").duplicate()

	current_style.content_margin_left = 0
	current_style.content_margin_right = 0
	current_style.content_margin_top = 0
	current_style.content_margin_bottom = 0

	if current_style is StyleBoxFlat:
		current_style.expand_margin_left = 0
		current_style.expand_margin_right = 0

	scroll_bar.add_theme_stylebox_override("scroll", current_style)

	var grabber_style = scroll_bar.get_theme_stylebox("grabber").duplicate()
	grabber_style.content_margin_left = 0
	grabber_style.content_margin_right = 0
	scroll_bar.add_theme_stylebox_override("grabber", grabber_style)

	scroll_bar.custom_minimum_size.x = size_x;
