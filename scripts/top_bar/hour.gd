extends Node

@onready var clock = $"."

func _process(delta: float) -> void:
	var hours_minutes: String = GameData.hours_minutes
	var parsed_time = "\n".join(hours_minutes.split(':'))
	
	clock.text = parsed_time
	
