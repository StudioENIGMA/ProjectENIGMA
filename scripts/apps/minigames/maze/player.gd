extends Node2D

const MOVE_SPEED = 300.0

@export var player: CharacterBody2D

var dragging: bool = false
var drag_offset: Vector2


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#player.input_event.connect(_on_input_event)
	player.drag_started.connect(_on_player_drag_started) # Replace with function body.
	player.drag_ended.connect(_on_player_drag_ended)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(_delta: float) -> void:
	#input_moviment_player()

#func input_moviment_player() -> void:
	#if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		#player.global_position = get_global_mouse_position()

#func _on_input_event(_viewport, event, _shape_idx):
	#if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		#if event.pressed:
			#dragging = true
			#drag_offset = get_global_mouse_position() - global_position
		
		#else:
			#dragging = false

func _on_player_drag_started(global_mouse_pos: Vector2):
	dragging = true
	drag_offset = global_mouse_pos - player.global_position

func _on_player_drag_ended():
	dragging = false

func _input(event):
	if dragging and event is InputEventMouseMotion:
		var target_pos = get_global_mouse_position() - drag_offset
		var displacement = target_pos - player.global_position
		player.try_move(displacement)

#func _input(event):
	#if dragging and event is InputEventMouseMotion:
		#global_position = get_global_mouse_position() - drag_offset
