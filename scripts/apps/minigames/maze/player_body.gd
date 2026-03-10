extends CharacterBody2D

signal drag_started(global_mouse_pos)
signal drag_ended()
signal moved

@export var collision_shape: CollisionShape2D

func try_move(displacement: Vector2, max_step: float = 10.0) -> void:
	#print("Tentando mover com deslocamento: ", displacement)
	var remaining = displacement
	var start_position = global_position
	# var collision
	

	while remaining.length() > max_step:
		var step = remaining.normalized() * max_step
		move_and_collide(step)
		remaining -= step

		## Remove friction
		#if collision:
			#velocity = velocity.slide(collision.get_normal())
			#move_and_collide(collision.get_remainder().slide(collision.get_normal()))

	if remaining.length() > 0:
		move_and_collide(remaining)

		## Remove friction
		#if collision:
			#velocity = velocity.slide(collision.get_normal())
			#move_and_collide(collision.get_remainder().slide(collision.get_normal()))

	
	if global_position != start_position:
		moved.emit()

func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed and _is_mouse_over_player():
			drag_started.emit(get_global_mouse_position())

		elif not event.pressed:
			drag_ended.emit()

func _is_mouse_over_player() -> bool:
	var mouse_pos = get_global_mouse_position()
	var local_mouse = to_local(mouse_pos)

	var shape = collision_shape.shape as CircleShape2D

	if not shape:
		return false
	
	return local_mouse.length() <= shape.radius
		
