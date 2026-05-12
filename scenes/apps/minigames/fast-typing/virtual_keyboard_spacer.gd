extends MarginContainer


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if OS.has_feature("mobile"):
		var margin = DisplayServer.virtual_keyboard_get_height()
		margin /= DisplayServer.screen_get_scale();
		margin -= get_viewport_rect().size.y - get_global_rect().size.y;
		add_theme_constant_override("margin_bottom", max(margin));




# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
