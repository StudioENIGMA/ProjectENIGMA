## THIS CODE IS JUST FOR A STUB
## THUS, THIS IS NOT THE FINAL VERSION, BUT JUST A PLACEHOLDER TO TEST THE HACK MINIGAME
## ALSO, IT SHOWS THE EXPECTED STRUCTURE OF THE SIGNAL SENT BY THE HACK MINIGAME
## IT IS EMMITED UP TO GAME SCREEN, THEN SENT TO THE HACK HANDLER
## SIGNAL IS ALSO ABSORBED IN BASE APP TO CLOSE THE HACK MINIGAME UI

extends CenterContainer

signal hack_concluded

#region CHILDREN NODES REFERENCES
@export var confirm_button: Button
#endregion CHILDREN NODES REFERENCES

## Setup signal connections to redirect events to each app
func _ready():
  confirm_button.pressed.connect(_on_confirm_button_pressed)

## Set the hack minigame according to the type of minigame received
func setup(hack_minigame: Dictionary) -> void:
  # For now, we will just print the hack minigame
  print("Hack minigame data received: ", hack_minigame.get("HackMinigame", "Unknown"))

## Hack minigame concluded, emit signal to notify the event handler
func _on_confirm_button_pressed():
  hack_concluded.emit()
