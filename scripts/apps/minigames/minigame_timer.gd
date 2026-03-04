extends ProgressBar

signal timer_finished

var idle = true

func setup(max_time) -> void:
  # Set the progress bar to full at the start of the minigame
  max_value = max_time
  value = max_value
  idle = false

func update_timer() -> void:
  if idle:
    return

  # Decrease the progress bar value over time
  value = max(value - 1, 0)

  # If the timer has run out, emit the signal
  if value <= 0:
    timer_finished.emit()