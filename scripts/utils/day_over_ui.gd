extends Control

signal day_over_clicked()

@export var next_day_button:Button

func show_day_over() -> void:
	self.visible = true
	next_day_button.text = "Iniciar Dia " + str(GameData.current_day + 1)
	next_day_button.pressed.connect(_on_next_day_button_pressed)

func hide_day_over() -> void:
	self.visible = false

func _on_next_day_button_pressed() -> void:
	GameData.current_day += 1
	day_over_clicked.emit()
