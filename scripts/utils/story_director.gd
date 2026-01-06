extends Node2D

@onready var messages_director:Node2D

func on_clock_tick(current_minutes: int) -> void:
	# Parent scene should connect EventHandler.clock_tick -> StoryDirector.on_clock_tick
	messages_director.on_clock_tick(current_minutes)

func start_day() -> void:
	# Optional: call when a new day starts (if you have a day-advance flow)
	messages_director.reload_and_queue_today()