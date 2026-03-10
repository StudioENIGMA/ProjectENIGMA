extends Control

signal hack_concluded

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
@export var maze_player: Node2D
@export var minigame_timer : ProgressBar

var map_width: int = 13
var map_height: int
var tile_size: int = 20
var map_y_offset: int = 3
var map_x_offset: int = 1

var maze: Array[Array] = []
var player_init_position: Vector2i
var maze_end_point: Vector2

## Called when the node enters the scene tree for the first time.
func _ready() -> void:
	maze_player.position_changed.connect(_check_finish)
	#goal_area.body_entered.connect(_on_goal_arrived)

	setup()
	
func setup() -> void:
	define_maze_difficult()
	generate_maze_size()
	create_maze()

	draw_maze()

	#maze_player.position = Vector2(40.0, 29.0 * map_y_offset)
	#print(tilemap.get_cell_source_id(Vector2(40.0, 29.0 * map_y_offset)))

	var start_cell = Vector2i(map_x_offset, map_y_offset)
	var start_global_pos = tilemap.to_global(tilemap.map_to_local(start_cell))
	maze_player.global_position = start_global_pos

	#print("Célula inicial: ", start_cell, " source_id: ", tilemap.get_cell_source_id(start_cell))

	minigame_timer.setup(30)

func define_maze_difficult() -> void:
	var heigth_sizes: Array[int] = [19, 21, 23]
	map_height = heigth_sizes.pick_random()

## Initialize the matrix and fill of zeros
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

			if maze[i][j] == 2:
				tilemap.set_cell(Vector2i(j + map_x_offset, i + map_y_offset), HIDDEN_PATH_ID, Vector2i(0, 0), 0)
		

func create_maze() -> void:
	for i in range(map_height):
		for j in range(map_width):
			maze[i][j] = 1	
	
	# Randomize the initial position during maze generation
	var start_x: int = range(1, map_height - 2, 2).pick_random()
	var start_y: int = range(1, map_width - 2, 2).pick_random()

	generator(start_x, start_y, maze)

	maze_end_point = Vector2(int(floor(float(map_width) / 2)), map_height-1)
	var up_end_point: Vector2i = Vector2i(int(float(map_width) / 2), map_height - 2)

	maze[maze_end_point.y][maze_end_point.x] = 2
	maze[up_end_point.y][up_end_point.x] = 0

	maze_end_point = Vector2(24 * float(map_width+map_x_offset) / 2, 24 * (map_height+map_y_offset))

				
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
				nx = cx 
				ny = cy - 2
				mx = cx 
				my = cy - 1
			Directions.DOWN:
				nx = cx 
				ny = cy + 2
				mx = cx 
				my = cy + 1
			Directions.LEFT:
				nx = cx - 2 
				ny = cy 
				mx = cx - 1 
				my = cy
			Directions.RIGHT:
				nx = cx + 2 
				ny = cy 
				mx = cx + 1 
				my = cy

		if is_in_bounds(nx, ny) and grid[nx][ny] == 1:
			grid[mx][my] = 0
			generator(nx, ny, grid)

## Check if next position is inside the maze
## In other words, check if this position is not out of bound the matrix
func is_in_bounds(x: int, y: int) -> bool:
	return x >= 0 and x < map_height and y >= 0 and y < map_width

#func _on_goal_arrived(body) -> void:
	#print("entrou")
	#if body.name == maze_player:
		#minigame_concluded.emit()
		#print("Goal arrived!")

func _check_finish():
	if tilemap == null:
		return

	# Converte a posição global do player para coordenadas de célula no tilemap
	var player_global_pos = maze_player.player_body.global_position
	print(player_global_pos)
	var cell = tilemap.local_to_map(tilemap.to_local(player_global_pos))

	# Obtém o source_id do tile na célula
	var source_id = tilemap.get_cell_source_id(cell)

	# Compara com o ID do tile final (HIDDEN_PATH_ID = 1)
	if source_id == HIDDEN_PATH_ID:
		hack_concluded.emit()
		maze_player.position_changed.disconnect(_check_finish)

func _on_time_finished() -> void:
	setup()
