extends Node2D

const INITIAL_WIDTH: int = 16
const INITIAL_HEIGHT: int = 24
const BLOCKED_WALL_ID: int = 0
const HIDDEN_PATH_ID: int = 1
const ALLOWED_PATH_ID: int = 2

@export var tilemap: TileMapLayer

var map_width: int = INITIAL_WIDTH
var map_height: int = INITIAL_HEIGHT
var map_offset: int = 1


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_walls()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func generate_walls() -> void:
	for x in range(map_width):
		for y in range(map_height):
			if x == 0 or x == map_width-1 or y == 0 or y == map_height-1:
				tilemap.set_cell(Vector2i(x + map_offset, y + map_offset), BLOCKED_WALL_ID, Vector2i(0, 0), 0)
