extends MarginContainer

signal on_time_exceeded(minigame_failed:bool)

const MINIGAME_MAX_TIME_TO_COMPLETE:int = 30

#region CHILDREN NODES REFERENCES
@export var remaining_time_bar: ProgressBar
@export var fisnish_minigame_button: Button
#endregion CHILDREN NODES REFERENCES

var is_sucessed_completed:bool = false
var current_remaining_time:int = 0

## Updates the validity timer
func setup() -> void:
	update_timer()

func update_timer() -> void:
	current_remaining_time = current_remaining_time - 1
	if current_remaining_time == -1:
		current_remaining_time = MINIGAME_MAX_TIME_TO_COMPLETE
	
	if current_remaining_time == 0:
		process_minigame_failed()

	remaining_time_bar.value = MINIGAME_MAX_TIME_TO_COMPLETE - current_remaining_time
	
func process_minigame_failed() -> void:
	if is_sucessed_completed:
		refill_timer()
		fisnish_minigame_button.visible = true
		return
	on_time_exceeded.emit(is_sucessed_completed)

func refill_timer() -> void:
	while remaining_time_bar.value < 30:
		if (remaining_time_bar.value+5) > 30:
			remaining_time_bar.value = 30
		remaining_time_bar.value += 5
	
	remaining_time_bar.size.y = 160
