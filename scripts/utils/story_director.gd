extends Node2D

#region CHILDREN NODES REFERENCES
@export var messages_director:Node2D
#endregion CHILDREN NODES REFERENCES

func on_clock_tick(current_minutes: int) -> void:
	messages_director.on_clock_tick(current_minutes)

func reload_day_story() -> void:
	messages_director.reload_and_queue_today()