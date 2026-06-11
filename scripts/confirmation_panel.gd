extends PanelContainer

signal start_new_game()

@export var confirm_button: Button
@export var cancel_button: Button

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_button_pressed)
	cancel_button.pressed.connect(_on_cancel_button_pressed)

func _on_confirm_button_pressed() -> void:
	start_new_game.emit()
	hide()

func _on_cancel_button_pressed() -> void:
	hide()
