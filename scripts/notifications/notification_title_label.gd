extends Label

@export var max_font_size: int
@export var min_font_size: int
@export var max_x_size: int

func update_font_size() -> void:
	var current_font_size = max_font_size

	add_theme_font_size_override("font_size", current_font_size)

	# Loop to shrink font if the text width is larger than the label width
	while size.x > max_x_size and current_font_size > min_font_size:
		current_font_size -= 1
		add_theme_font_size_override("font_size", current_font_size)
