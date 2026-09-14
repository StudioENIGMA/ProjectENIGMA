extends Label

## Updates the clock display in the top bar with the current hour and minute.
##
## current_hour: The current hour to display
## current_minute: The current minute to display
func update_clock_display(current_hour:int, current_minute:int) -> void:
	# Same HH:MM shape as the home screen clock, with leading zeros
	self.text = "%02d:%02d" % [current_hour % 24, current_minute]
