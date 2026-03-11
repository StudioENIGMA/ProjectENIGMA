extends Control

signal day_over_clicked()

@export var next_day_button:Button

func _ready() -> void:
	next_day_button.pressed.connect(_on_next_day_button_pressed)

func show_day_over() -> void:
	self.visible = true
	next_day_button.text = "Iniciar Dia " + str(GameData.current_day + 1)

func hide_day_over() -> void:
	self.visible = false

func _on_next_day_button_pressed() -> void:
	day_over_clicked.emit()
