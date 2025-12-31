extends Control

@export var next_day_button:Button

func show_day_over() -> void:
	self.visible = true
	next_day_button.text = "Iniciar Dia " + str(GameData.data.current_day + 1)

func hide_day_over() -> void:
	self.visible = false

func _on_next_day_button_pressed() -> void:
	GameData.data.current_day += 1
	# TODO start new day logic
