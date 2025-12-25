extends Node2D

signal npc_message_created(npc_name:String, message:String, sender:EventBus.Sender, time:String)

@export var day_over_timer:Timer
@export var clock_timer:Timer

var messages_to_deliver:Array[Dictionary] = []

@onready var clock_time = $"../ClockRichTextLabel"

## Initializes the event handler by connecting timers to their respective functions
func _ready() -> void:
	day_over_timer.timeout.connect(_on_day_over_timeout)
	clock_timer.timeout.connect(_on_clock_timer_timeout)

## Handles receiving a scheduled message to be delivered later
##
## npc_name: The name of the NPC which the conversation is with
## message: The content of the message
## time: The in-game time (in minutes) when the message should be delivered
func on_receive_message(npc_name:String, message:String, time:int) -> void:
	messages_to_deliver.push_front({"name":npc_name, "message":message, "time":time})

## Handles the end of the day event
func _on_day_over_timeout() -> void:
	# Show results screen or any end-of-day logic here
	pass

## Runs every in-game 'minute' (1 second real time)
##
## Updates the clock display and checks for scheduled message deliveries
func _on_clock_timer_timeout() -> void:
	_update_in_game_time()
	_deliver_scheduled_messages(clock_timer)

## Updates the in-game clock display
func _update_in_game_time() -> void:
	var hours_minutes = GameData.hours_minutes
	var parsed_time = "\n".join(hours_minutes.split(':'))
	clock_time.text = parsed_time

## Delivers any scheduled messages whose time has come
##
## timer: The Timer node used to track in-game time
func _deliver_scheduled_messages(timer:Timer) -> void:
	for message in messages_to_deliver:
		# TODO: wait time should not be used here, should be GameData.hours_minutes
		if message.time <= timer.wait_time - timer.time_left:
			npc_message_created.emit(
				message.name,
				message.message,
				EventBus.Sender.OTHER,
				GameData.hours_minutes
			)
			messages_to_deliver.erase(message)
