extends Node2D

@export var player: CharacterBody2D

var dragging: bool = false
var drag_offset: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	input_moviment_player()

func input_moviment_player() -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		player.global_position = get_global_mouse_position()
