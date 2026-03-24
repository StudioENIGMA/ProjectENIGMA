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

""" 
NOTAS: 
Mid = 0, UL = 1, UR = 2, R = 3, LR = 4, LL = 5, L = 6 
Criar uma Matriz de adjacencia 
Todas posições como 0 
Após gerar o caminho, colocar 1 na matriz se i tem um caminho para j 
Sempre que girar percorrer a matriz completa, se ij = 1, entao ji tem que ser 1, se nao for, nao está conectado 
"""
#Usado para transformar o vetor "vertex_positions" para a matriz de adjacencia (ex 0 é o mid, posição 1 equivale ao hexagono numero 2, ou seja, matriz[0][2] = 1)
var position_to_index = {
	0: {1: 2, 2: 3, 3: 4, 4: 5, 5: 6, 6: 1},
	1: {2: 2, 3: 0, 4: 6},
	2: {3: 3, 4: 0, 5: 1},
	3: {4: 4, 5: 0, 6: 2},
	4: {1: 3, 5: 5, 6: 0},
	5: {1: 0, 2: 4, 6: 6},
	6: {1: 1, 2: 0, 3: 5},
}

var adjacency = []
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
	adjacency.clear()

	for i in range(7):
		adjacency.append([])
		for j in range(7):
			adjacency[i].append(0)

	hexagons_positions = [1, 1, 1, 1, 1, 1, 1]

	path_generator.generate()
	create_hexagons_node_array()
	set_lines()
	randomize_rotation()

	minigame_timer.setup(20)

func get_hexagon_path(hexagon_array):
	hexagons = hexagon_array
	rebuild_adjacency()

func rotate_vertex(vertex: int, steps: int) -> int:
	var v = vertex + steps
	while v > 6:
		v -= 6
	return v

func rebuild_adjacency():
	for i in range(7):
		for j in range(7):
			adjacency[i][j] = 0

	for i in range(hexagons.size()):
		if hexagons[i]["vertex_number"] == 0:
			continue

		var rotation = hexagons_positions[i] - 1

		for vertex in hexagons[i]["vertex_positions"]:
			var rotated_vertex = rotate_vertex(vertex, rotation)

			if position_to_index[i].has(rotated_vertex):
				var j = position_to_index[i][rotated_vertex]
				adjacency[i][j] = 1

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

	rebuild_adjacency()

func update_rotation(index):
	if hexagons[index]["vertex_number"] == 0:
		return

	if hexagons_positions[index] != 6:
		hexagons_positions[index] += 1
	else:
		hexagons_positions[index] = 1

	rebuild_adjacency()
	check_rotations()

func check_rotations():
	var check = true

	for i in range(7):
		for j in range(7):
			if adjacency[i][j] == 1 and adjacency[j][i] != 1:
				check = false
				break

	if check:
		print("cabo")
		minigame_timer.stop_timer()
		hack_concluded.emit()

func _on_time_finished() -> void:
	setup()