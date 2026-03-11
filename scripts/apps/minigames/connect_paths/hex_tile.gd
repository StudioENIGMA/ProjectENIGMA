extends TextureButton

signal rotation_click

@export var line1: Panel
@export var line2: Panel
@export var line3: Panel
@export var line4: Panel
@export var line5: Panel
@export var line6: Panel
@export var lines_container: Control

var rotation_step = 0

func _ready() -> void:
	if texture_normal:
		# Get the image from the texture normal
		var image = texture_normal.get_image()
		# Create the BitMap
		var bitmap = BitMap.new()
		# Fill it from the image alpha
		bitmap.create_from_image_alpha(image)
		# Assign it to the mask
		texture_click_mask = bitmap

func _pressed() -> void:
	rotate_once()
	rotation_click.emit()

func rotate_once() -> void:
	lines_container.rotation += deg_to_rad(60)

func set_rotation_steps(steps: int) -> void:
	lines_container.rotation = steps * deg_to_rad(60)

func reset_rotation() -> void:
	lines_container.rotation = 0.0

func set_active_lines(active_lines: Array) -> void:
	var all_lines = [line1, line2, line3, line4, line5, line6]

	for line in all_lines:
		line.visible = false

	for line_number in active_lines:
		if line_number >= 1 and line_number <= 6:
			all_lines[line_number - 1].visible = true