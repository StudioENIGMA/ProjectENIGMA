extends Node2D

const INITIAL_WIDTH: int = 13
const INITIAL_HEIGHT: int = 13
const BLOCKED_WALL_ID: int = 0
const HIDDEN_PATH_ID: int = 1
const ALLOWED_PATH_ID: int = 2

enum Directions{
	UP = 1,
	DOWN = 2,
	LEFT = 3,
	RIGHT = 4
}

@export var tilemap: TileMapLayer

var map_width: int = INITIAL_WIDTH
var map_height: int = INITIAL_HEIGHT
var tile_size: int = 20
var map_y_offset: int = 10
var map_x_offset: int = 2

var maze: Array[Array] = []
var player_init_position: Vector2i
var maze_end_point: Vector2i

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	generate_maze_size()
	create_maze()

	print(maze)

	draw_maze()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

#Initialize the matrix and fill of zeros
func generate_maze_size() -> void:
	for i in range(map_height):
		var row: Array = []
		row.resize(map_width)

		maze.append(row)

	for i in range(map_height):
		for j in range(map_width):
			maze[i][j] = 0


func draw_maze() -> void:
	for i in range(map_height):
		for j in range(map_width):
			if maze[i][j] == 1:
				#Insert wall tile at position inside the vector
				tilemap.set_cell(Vector2i(j + map_x_offset, i + map_y_offset), BLOCKED_WALL_ID, Vector2i(0, 0), 0)
			if maze[i][j] == 0:
				#Insert path tile at position inside the vector 
				tilemap.set_cell(Vector2i(j + map_x_offset, i + map_y_offset), ALLOWED_PATH_ID, Vector2i(0, 0), 0)
			

func create_maze() -> void:
	for i in range(map_height):
		for j in range(map_width):
			maze[i][j] = 1	
	
	#Randomize the initial position during maze generation
	var start_x: int = range(1, map_height - 2, 2).pick_random()
	var start_y: int = range(1, map_width - 2, 2).pick_random()

	generator(start_x, start_y, maze)

	maze_end_point = Vector2i(int(float(map_width) / 2), map_height)

	#for i in range(map_height):
		#for j in range(map_width):
			#if maze[i][j] == -1:
				#maze[i][j] = 0
				
func generator(cx: int, cy: int, grid: Array[Array]) -> void:
	# Mark current cell as visited
	grid[cx][cy] = 0
	
	var dirs = [Directions.UP, Directions.DOWN, Directions.LEFT, Directions.RIGHT]
	dirs.shuffle() # Randomize the order of directions to try

	for dir in dirs:
		var nx: int = cx
		var ny: int = cy
		var mx: int = cx
		var my: int = cy

		match dir:
			Directions.UP:
				nx = cx; ny = cy - 2; mx = cx; my = cy - 1
			Directions.DOWN:
				nx = cx; ny = cy + 2; mx = cx; my = cy + 1
			Directions.LEFT:
				nx = cx - 2; ny = cy; mx = cx - 1; my = cy
			Directions.RIGHT:
				nx = cx + 2; ny = cy; mx = cx + 1; my = cy

		if is_in_bounds(nx, ny) and grid[nx][ny] == 1:
			grid[mx][my] = 0
			generator(nx, ny, grid)

func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < map_height and y >= 0 and y < map_width
