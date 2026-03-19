extends PanelContainer

@export var conscent_button: Button

func _ready() -> void:
  conscent_button.pressed.connect(_on_conscent_button_pressed)

func _on_conscent_button_pressed() -> void:
  hide()