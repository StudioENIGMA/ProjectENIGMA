extends Node2D

signal position_changed

@export var player_body: CharacterBody2D

var dragging: bool = false
var drag_offset: Vector2

func _ready() -> void:
	player_body.drag_started.connect(_on_player_drag_started) 
	player_body.drag_ended.connect(_on_player_drag_ended)
	player_body.moved.connect(_on_player_moved)

func _on_player_drag_started(global_mouse_pos: Vector2) -> void:
	dragging = true
	drag_offset = global_mouse_pos - player_body.global_position

func _on_player_drag_ended() -> void:
	dragging = false

func _on_player_moved() -> void:
	position_changed.emit()

func _input(event):
	if dragging and event is InputEventMouseMotion:
		var target_pos = get_global_mouse_position() - drag_offset
		var displacement = target_pos - player_body.global_position
		player_body.try_move(displacement)
