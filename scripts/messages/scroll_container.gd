extends ScrollContainer

func _ready() -> void:
	self.scroll_vertical = self.get_v_scroll_bar().max_value		
