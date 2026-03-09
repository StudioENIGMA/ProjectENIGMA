extends Node

signal hexagons_generated(hexagon_array)

func _ready():
	pass


func generate():
	var hexagon_array: Array = []
	generate_hexagons(hexagon_array)
	hexagons_generated.emit(hexagon_array)


func generate_hexagons(hexagon_array: Array) -> void:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var mid_hexagon_vertex_number = rng.randi_range(1, 4)

	var mid_hexagon = {
		"vertex_number": mid_hexagon_vertex_number,
		"vertex_positions": [],
		"hexagon_position": 1,
	}

	while mid_hexagon["vertex_positions"].size() < mid_hexagon_vertex_number:
		var position = rng.randi_range(1, 6)
		if not mid_hexagon["vertex_positions"].has(position):
			mid_hexagon["vertex_positions"].append(position)

	var ul_hexagon = {"vertex_number": 0, "vertex_positions": [], "hexagon_position": 1}
	var ur_hexagon = {"vertex_number": 0, "vertex_positions": [], "hexagon_position": 1}
	var l_hexagon  = {"vertex_number": 0, "vertex_positions": [], "hexagon_position": 1}
	var r_hexagon  = {"vertex_number": 0, "vertex_positions": [], "hexagon_position": 1}
	var ll_hexagon = {"vertex_number": 0, "vertex_positions": [], "hexagon_position": 1}
	var lr_hexagon = {"vertex_number": 0, "vertex_positions": [], "hexagon_position": 1}

	# UPPER LEFT
	if mid_hexagon["vertex_positions"].has(6):
		var valid_positions = [2, 4]
		ul_hexagon["vertex_positions"].append(3)
		var n_more_hexagons = rng.randi_range(0, 2)
		ul_hexagon["vertex_number"] = 1 + n_more_hexagons

		while ul_hexagon["vertex_positions"].size() < ul_hexagon["vertex_number"]:
			var position = valid_positions[rng.randi_range(0, valid_positions.size() - 1)]
			if not ul_hexagon["vertex_positions"].has(position):
				ul_hexagon["vertex_positions"].append(position)

	# UPPER RIGHT
	if mid_hexagon["vertex_positions"].has(1):
		var valid_positions = [3]
		ur_hexagon["vertex_positions"].append(4)
		var n_more_hexagons = rng.randi_range(0, 1)
		ur_hexagon["vertex_number"] = ur_hexagon["vertex_positions"].size() + n_more_hexagons

		while ur_hexagon["vertex_positions"].size() < ur_hexagon["vertex_number"]:
			var position = valid_positions[rng.randi_range(0, valid_positions.size() - 1)]
			if not ur_hexagon["vertex_positions"].has(position):
				ur_hexagon["vertex_positions"].append(position)

	if ul_hexagon["vertex_positions"].has(2):
		ur_hexagon["vertex_positions"].append(5)

	# RIGHT
	if mid_hexagon["vertex_positions"].has(2):
		var valid_positions = [4]
		r_hexagon["vertex_positions"].append(5)
		var n_more_hexagons = rng.randi_range(0, 1)
		r_hexagon["vertex_number"] = r_hexagon["vertex_positions"].size() + n_more_hexagons

		while r_hexagon["vertex_positions"].size() < r_hexagon["vertex_number"]:
			var position = valid_positions[rng.randi_range(0, valid_positions.size() - 1)]
			if not r_hexagon["vertex_positions"].has(position):
				r_hexagon["vertex_positions"].append(position)

	if ur_hexagon["vertex_positions"].has(3):
		r_hexagon["vertex_positions"].append(6)

	# LOWER RIGHT
	if mid_hexagon["vertex_positions"].has(3):
		var valid_positions = [5]
		lr_hexagon["vertex_positions"].append(6)
		var n_more_hexagons = rng.randi_range(0, 1)
		lr_hexagon["vertex_number"] = lr_hexagon["vertex_positions"].size() + n_more_hexagons

		while lr_hexagon["vertex_positions"].size() < lr_hexagon["vertex_number"]:
			var position = valid_positions[rng.randi_range(0, valid_positions.size() - 1)]
			if not lr_hexagon["vertex_positions"].has(position):
				lr_hexagon["vertex_positions"].append(position)

	if r_hexagon["vertex_positions"].has(4):
		lr_hexagon["vertex_positions"].append(1)
		lr_hexagon["vertex_number"] += 1

	# LOWER LEFT
	if mid_hexagon["vertex_positions"].has(4):
		var valid_positions = [6]
		ll_hexagon["vertex_positions"].append(1)
		var n_more_hexagons = rng.randi_range(0, 1)
		ll_hexagon["vertex_number"] = ll_hexagon["vertex_positions"].size() + n_more_hexagons

		while ll_hexagon["vertex_positions"].size() < ll_hexagon["vertex_number"]:
			var position = valid_positions[rng.randi_range(0, valid_positions.size() - 1)]
			if not ll_hexagon["vertex_positions"].has(position):
				ll_hexagon["vertex_positions"].append(position)

	if lr_hexagon["vertex_positions"].has(5):
		ll_hexagon["vertex_positions"].append(2)
		ll_hexagon["vertex_number"] += 1

	# LEFT
	if mid_hexagon["vertex_positions"].has(5):
		l_hexagon["vertex_positions"].append(2)
		l_hexagon["vertex_number"] += 1

	if ul_hexagon["vertex_positions"].has(4):
		l_hexagon["vertex_positions"].append(1)
		l_hexagon["vertex_number"] += 1

	if ll_hexagon["vertex_positions"].has(6):
		l_hexagon["vertex_positions"].append(3)
		l_hexagon["vertex_number"] += 1

	mid_hexagon["vertex_positions"].sort()
	ul_hexagon["vertex_positions"].sort()
	ur_hexagon["vertex_positions"].sort()
	r_hexagon["vertex_positions"].sort()
	lr_hexagon["vertex_positions"].sort()
	ll_hexagon["vertex_positions"].sort()
	l_hexagon["vertex_positions"].sort()

	hexagon_array.append(mid_hexagon)
	hexagon_array.append(ul_hexagon)
	hexagon_array.append(ur_hexagon)
	hexagon_array.append(r_hexagon)
	hexagon_array.append(lr_hexagon)
	hexagon_array.append(ll_hexagon)
	hexagon_array.append(l_hexagon)
