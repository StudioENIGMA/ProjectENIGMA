extends Node2D

const INITIAL_WIDTH: int = 16
const INITIAL_HEIGHT: int = 24
const BLOCKED_WALL_ID: int = 0
const HIDDEN_PATH_ID: int = 1
const ALLOWED_PATH_ID: int = 2

@export var tilemap: TileMapLayer

var map_width: int = INITIAL_WIDTH
var map_height: int = INITIAL_HEIGHT
var tile_size: int = 20
var map_offset: int = 1

var maze: Array[Array] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_maze_size()
	generate_walls()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func generate_maze_size() -> void:
	for i in range(map_height):
		var row: Array = []
		row.resize(map_width)

		maze.append(row)

	for i in range(map_height):
		for j in range(map_width):
			maze[i][j] = 0

func define_initial_and_final_position() -> void:
	var initial_posiition: int = 0
	var final_position: int = 0

	

func generate_walls() -> void:
	for x in range(map_width):
		for y in range(map_height):
			if x == 0 or x == map_width-1 or y == 0 or y == map_height-1:
				tilemap.set_cell(Vector2i(x + map_offset, y + map_offset), BLOCKED_WALL_ID, Vector2i(0, 0), 0)

	tilemap.set_cell(Vector2i(map_width-1 + map_offset, map_height-1 + map_offset), HIDDEN_PATH_ID, Vector2i(0, 0), 0)
