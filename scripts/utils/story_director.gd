extends Node2D

#region CHILDREN NODES REFERENCES
@export var messages_director:Node2D
#endregion CHILDREN NODES REFERENCES

## Every time the clock ticks, notify the messages director
##
## @param current_minutes The current time in minutes
func on_clock_tick(current_minutes: int) -> void:
	messages_director.on_clock_tick(current_minutes)

## Reloads and queues today's story
func reload_day_story() -> void:
	messages_director.reload_and_queue_today()