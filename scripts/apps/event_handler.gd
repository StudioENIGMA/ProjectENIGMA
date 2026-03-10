extends Node2D

#region SIGNALS
signal clock_tick(current_minutes:int)
signal start_new_day()
signal day_ended()
#endregion SIGNALS

#region CHILDREN NODES REFERENCES
@export var clock_timer:Timer
@export var hack_handler:Node2D
#endregion CHILDREN NODES REFERENCES

#region INITIALIZATION
## Initializes the event handler by connecting timers to their respective functions
func _ready() -> void:
	clock_timer.timeout.connect(_on_clock_timer_timeout)
	clock_timer.timeout.connect(hack_handler.on_clock_tick)

	# Update the in-game time display at start
	_update_in_game_time()
#endregion INITIALIZATION

#region CLOCK TICK
## Runs every in-game 'minute' (1 second real time)
##
## Updates the clock display and checks for scheduled message deliveries
func _on_clock_timer_timeout() -> void:
	_update_in_game_time()
	clock_tick.emit(GameData.hours_minutes)

## Updates the in-game clock display
func _update_in_game_time() -> void:
	# Calculate current hour and minute from total minutes
	var current_day_minutes:float = GameData.hours_minutes
	var current_hour:int = int(current_day_minutes / 60)
	var current_minute:int = int(current_day_minutes) % 60

	# Update all nodes that display the clock
	# Warning: this is one of the few exceptions to "signal up, command down" principle for simplicity
	var clock_nodes = get_tree().get_nodes_in_group("clock_display")
	for clock_node in clock_nodes:
		clock_node.update_clock_display(current_hour, current_minute)
	if GameData.hours_minutes >= GameData.max_hours_minutes:
		_on_day_over_timeout()

	# Increment in-game time by X minutes, X = 1 + number of viruses / 50 as integer
	var minutes_to_add = 1 + int(GameData.number_of_viruses / 50)
	GameData.hours_minutes = GameData.hours_minutes + minutes_to_add
#endregion CLOCK TICK

#region DAY CYCLE MANAGEMENT
## Handles the end of the day event
func _on_day_over_timeout() -> void:
	# Emit the day ended signal to notify other systems
	day_ended.emit()

	# Stop the timers
	clock_timer.stop()

## Resets game data for the new day
func reset_data_for_new_day() -> void:
	start_new_day.emit()
	GameData.current_day += 1

	if GameData.current_day == 1:
		GameData.apps_in_store.append(GameData.App.BROWSER)

	print("current day: ", GameData.current_day)

	# Reset in-game time
	GameData.hours_minutes = GameData.starting_hours_minutes

	# Restart timers
	clock_timer.start()
#endregion DAY CYCLE MANAGEMENT
