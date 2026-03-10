extends Label

const DEFAULT_SIZE: int = 30
@export var MAX_WIDTH: float = 50

func _ready() -> void:
	visibility_changed.connect(_on_update_font_size)

func _on_update_font_size() -> void:
	var current_font_size = DEFAULT_SIZE
	add_theme_font_size_override("font_size", current_font_size)
	while get_minimum_size().x > MAX_WIDTH and current_font_size > 5:
		current_font_size -= 1
		add_theme_font_size_override("font_size", current_font_size)
	print(current_font_size)
