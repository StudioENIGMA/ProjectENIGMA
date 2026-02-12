extends Button


var answers_waiting_response : Dictionary[int, Message] = load("res://scripts/apps/messages/control.gd")

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if answers_waiting_response.is_empty():
		pass
