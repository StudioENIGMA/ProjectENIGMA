extends OptionButton

signal difficulty_changed()

func _ready() -> void:
  item_selected.connect(_on_option_button_item_selected)

func _on_option_button_item_selected(index: int) -> void:
  match index:
    0:
      GameData.clock_tick_interval = 2.0 # Easy
    1:
      GameData.clock_tick_interval = 1.5 # Normal
    2:
      GameData.clock_tick_interval = 1.0 # Difícil
  difficulty_changed.emit()