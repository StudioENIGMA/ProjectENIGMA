extends Node2D

signal npc_message_created(npc_name:String, message:String, sender:EventBus.Sender, time:String)

@export var day_over_timer:Timer
@export var clock_timer:Timer

var messages_to_deliver:Array[Dictionary] = []

## Initializes the event handler by connecting timers to their respective functions
func _ready() -> void:
	day_over_timer.timeout.connect(_on_day_over_timeout)
	clock_timer.timeout.connect(_on_clock_timer_timeout)

	# Update the in-game time display at start
	_update_in_game_time()

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
	_deliver_scheduled_messages()

## Updates the in-game clock display
func _update_in_game_time() -> void:
	# Calculate current hour and minute from total minutes
	var current_day_minutes:float = GameData.hours_minutes
	var current_hour:int = int(current_day_minutes / 60)
	var current_minute:int = int(current_day_minutes) % 60

	# Update all nodes that display the clock
	var clock_nodes = get_tree().get_nodes_in_group("clock_display")
	for clock_node in clock_nodes:
		clock_node.update_clock_display(current_hour, current_minute)

	# Increment in-game time by 1 minute
	GameData.hours_minutes = GameData.hours_minutes + 1

## Delivers any scheduled messages whose time has come
##
func _deliver_scheduled_messages() -> void:
	for message in messages_to_deliver:
		print(message.time)
		print(GameData.hours_minutes)
		if message.time <= GameData.hours_minutes:
			npc_message_created.emit(
				message.name,
				message.message,
				EventBus.Sender.OTHER,
				GameData.hours_minutes
			)
			messages_to_deliver.erase(message)
