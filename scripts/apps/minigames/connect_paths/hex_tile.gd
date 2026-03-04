extends Area2D

@export var line1: Sprite2D
@export var line2: Sprite2D
@export var line3: Sprite2D
@export var line4: Sprite2D
@export var line5: Sprite2D
@export var line6: Sprite2D

signal rotation_click

func _input_event(viewport, event, shape_idx):
    if event is InputEventMouseButton:
        if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
            rotation += deg_to_rad(60)
            rotation_click.emit()