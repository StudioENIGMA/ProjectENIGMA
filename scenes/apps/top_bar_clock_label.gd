extends Label

## Updates the clock display in the top bar with the current hour and minute.
##
## current_hour: The current hour to display
## current_minute: The current minute to display
func update_clock_display(current_hour:int, current_minute:int) -> void:
  # Add leading zeros to hours and minutes if needed
  var hours:String = str(current_hour) if current_hour >= 10 else "0" + str(current_hour)
  var minutes:String = str(current_minute) if current_minute >= 10 else "0" + str(current_minute)

  self.text = hours + "\n" + minutes