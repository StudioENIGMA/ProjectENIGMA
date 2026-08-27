extends OptionButton

signal difficulty_changed()

func _ready() -> void:
	item_selected.connect(_on_option_button_item_selected)
	get_popup().visibility_changed.connect(_on_popup_visibility_changed)
	match GameData.clock_tick_interval:
		2.0:
			self.selected = 0 # Easy
		1.5:
			self.selected = 1 # Normal
		1.0:
			self.selected = 2 # Difícil

func _on_popup_visibility_changed() -> void:
	if get_popup().visible:
		get_popup().position += Vector2i(0, 10)

func _on_option_button_item_selected(index: int) -> void:
	match index:
		0:
			GameData.clock_tick_interval = 2.0 # Easy
		1:
			GameData.clock_tick_interval = 1.5 # Normal
		2:
			GameData.clock_tick_interval = 1.0 # Difícil
	difficulty_changed.emit()
