extends Control

signal hack_concluded

@export var mid_hex : TextureButton
@export var ul_hex : TextureButton
@export var ur_hex : TextureButton
@export var l_hex : TextureButton
@export var r_hex : TextureButton
@export var ll_hex : TextureButton
@export var lr_hex : TextureButton
@export var path_generator : Node
@export var minigame_timer : ProgressBar


var hexagons = []
var hexagons_node = []
var hexagons_positions = [1, 1, 1, 1, 1, 1, 1]

func _ready() -> void:
	path_generator.hexagons_generated.connect(get_hexagon_path)
	mid_hex.rotation_click.connect(update_rotation.bind(0))
	ul_hex.rotation_click.connect(update_rotation.bind(1))
	ur_hex.rotation_click.connect(update_rotation.bind(2))
	r_hex.rotation_click.connect(update_rotation.bind(3))
	lr_hex.rotation_click.connect(update_rotation.bind(4))
	ll_hex.rotation_click.connect(update_rotation.bind(5))
	l_hex.rotation_click.connect(update_rotation.bind(6))
	setup()

func setup() -> void:
	hexagons_positions = [1, 1, 1, 1, 1, 1, 1]
	path_generator.generate()
	create_hexagons_node_array()
	set_lines()
	randomize_rotation()
	minigame_timer.setup(10)

func get_hexagon_path(hexagon_array):
	hexagons = hexagon_array

func set_lines() -> void:
	for i in range(hexagons.size()):
		var hexagon_data = hexagons[i]
		var hexagon_node = hexagons_node[i]
		hexagon_node.set_active_lines(hexagon_data["vertex_positions"])

func create_hexagons_node_array() -> void:
	hexagons_node = [
		mid_hex,
		ul_hex,
		ur_hex,
		r_hex,
		lr_hex,
		ll_hex,
		l_hex,
	]

func randomize_rotation() -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	for i in range(hexagons.size()):
		hexagons_node[i].reset_rotation()

		var rotations = rng.randi_range(0, 5)
		if hexagons[i]["vertex_number"] != 0:
			hexagons_positions[i] = rotations + 1
			hexagons_node[i].set_rotation_steps(rotations)

func update_rotation(index):
	if hexagons[index]["vertex_number"] != 0:
		if hexagons_positions[index] != 6:
			hexagons_positions[index] += 1
		else:
			hexagons_positions[index] = 1

	check_rotations()

func get_rotation_period(vertex_positions: Array) -> int:
	var base = vertex_positions.duplicate()
	base.sort()

	for step in range(1, 6):
		var rotated = []
		for v in vertex_positions:
			var new_v = v + step
			if new_v > 6:
				new_v -= 6
			rotated.append(new_v)

		rotated.sort()

		if rotated == base:
			return step

	return 6

func check_rotations():
	var check = true

	for i in range(7):

		if hexagons[i]["vertex_number"] == 0:
			continue

		var period = get_rotation_period(hexagons[i]["vertex_positions"])

		if ((hexagons_positions[i] - 1) % period) != 0:
			check = false
			break

	if check:
		minigame_timer.stop_timer()
		hack_concluded.emit()

func _on_time_finished() -> void:
	setup()
