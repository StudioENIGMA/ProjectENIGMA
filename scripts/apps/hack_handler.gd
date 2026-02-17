extends Node2D

signal open_hack_minigame(hack_minigame: GameData.HackMinigame)

func on_clock_tick() -> void:
  var current_minutes = GameData.hours_minutes
  #if GameData.is_hacked:
    #return # Already hacked, no need to check again

  if GameData.last_hacked_tick + GameData.hack_immunity_ticks > current_minutes:
    return # Minimal delay not passed yet, cannot be hacked again

  var breaches = 0
  # If breaches immunity timer has passed, check for breaches and increase the hack probability
  if current_minutes > GameData.starting_hours_minutes + GameData.breaches_immunity_ticks:
    if not GameData.updated_password_today:
      breaches += 1
    if not GameData.updated_os_today:
      breaches += 1

  print("Current breaches: ", breaches)

  var hack_probability_increment = calculate_hack_probability_increment(
    GameData.expected_ticks_between_hacks - GameData.decrement_due_breach * breaches
  )
  print("hack increment", hack_probability_increment)

  GameData.current_hack_probability += hack_probability_increment

  var random_value = randi_range(0, 100)
  if random_value < GameData.current_hack_probability * 100:
    GameData.is_hacked = true
    GameData.last_hacked_tick = current_minutes

    # Select random hack minigame
    var hack_index = randi_range(0, GameData.HackMinigame.size() - 1)
    var hack_minigame = GameData.HackMinigame.values()[hack_index]
    open_hack_minigame.emit(hack_minigame)

## Receives the expected number of ticks of immunity between hacks and the number
## of ticks expected between hacks, and calculates the parameters for the hacking system
func calculate_hack_probability_increment(
    expected_ticks_between_hacks: int
  ) -> float:

  # Approximation:
  # E[T] ≈ sqrt(π / (2 * hack_probability_increment))
  # Solving for increment:
  # hack_probability_increment ≈ π / (2 * E[T]^2)

  var hack_probability_increment = PI / (2.0 * pow(expected_ticks_between_hacks, 2))

  return hack_probability_increment

## Once hack minigame is concluded, reset hack probability and set the last hacked tick to the
## current tick to give the player some time of immunity before the next hack can happen
func on_hack_concluded() -> void:
  GameData.is_hacked = false
  GameData.current_hack_probability = 0.0
  GameData.last_hacked_tick = GameData.hours_minutes