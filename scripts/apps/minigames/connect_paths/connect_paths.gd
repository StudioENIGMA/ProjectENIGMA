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

func _ready() -> void:
	path_generator.hexagons_generated.connect(get_hexagon_path)
	path_generator.generate()
	create_hexagons_node_array()
	set_lines()

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
