extends Control

@export var mid_hex : Node2D
@export var ul_hex : Node2D
@export var ur_hex : Node2D
@export var l_hex : Node2D
@export var r_hex : Node2D
@export var ll_hex : Node2D
@export var lr_hex : Node2D
@export var path_generator : Node


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

	path_generator.generate()
	create_hexagons_node_array()
	set_lines()
	randomize_rotation()


func get_hexagon_path(hexagon_array):
	hexagons = hexagon_array
	print(hexagons)

func set_lines():
	for i in range(hexagons.size()):
		var hexagon_data = hexagons[i]
		var hexagon_node = hexagons_node[i]

		var active_lines = hexagon_data["vertex_positions"]

		# Primeiro desativa todas
		for j in range(1, 7):
			hexagon_node.get("line" + str(j)).visible = false

		# Depois ativa só as que estão no array
		for line_number in active_lines:
			hexagon_node.get("line" + str(line_number)).visible = true



func create_hexagons_node_array():
	hexagons_node.append(mid_hex)
	hexagons_node.append(ul_hex)
	hexagons_node.append(ur_hex)
	hexagons_node.append(r_hex)
	hexagons_node.append(lr_hex)
	hexagons_node.append(ll_hex)
	hexagons_node.append(l_hex)

func randomize_rotation():
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	for i in range(hexagons.size()):
		var rotations = rng.randi_range(0, 5)
		if not hexagons[i]["vertex_number"] == 0:
			hexagons_positions[i] = rotations + 1
			hexagons_node[i].rotation = rotations * deg_to_rad(60)

func update_rotation(index):
	if not hexagons[index]["vertex_number"] == 0:
		if not hexagons_positions[index] == 6:
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
	for i in range(0, 7):
		var period = get_rotation_period(hexagons[i]["vertex_positions"])
		if not (hexagons_positions[i] - 1) % period == 0:
			check = false
	if check:
		print("concluiu minigame")
		
