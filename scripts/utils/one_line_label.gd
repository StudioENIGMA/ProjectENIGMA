extends Label

func _ready() -> void:
	call_deferred("adjust_font_size")

func adjust_font_size() -> void:
	if not label_settings:
		label_settings = LabelSettings.new()

	if not label_settings.resource_local_to_scene:
		label_settings = label_settings.duplicate()

	while get_line_count() > 1 and label_settings.font_size > 1:
		label_settings.font_size -= 1
