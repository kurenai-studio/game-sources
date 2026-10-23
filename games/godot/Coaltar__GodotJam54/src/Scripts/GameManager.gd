extends Node
const MatrixFunctions = preload("MatrixFunctions.gd")
const ProceduralMapA = preload("ProceduralMapA.gd")
const common_funcs = preload("Common.gd")
var ProceduralMaze = preload("ProceduralMaze.gd")
var goal_tile
var time

const MAP_DIMENSION = 10
var dimension = Vector2(MAP_DIMENSION, MAP_DIMENSION)
var level
var map_array = MatrixFunctions.create_zero_matrix(dimension)
# Called when the node enters the scene tree for the first time.

signal player_found_goal
signal game_over
signal game_start
	
func _ready():
	game_start()

func _process(_delta):
	check_player_win()
	
func game_start():
	$ReplayHud.hide()
	$Player.show()
	emit_signal("game_start")
	level = 1
	dimension = Vector2(MAP_DIMENSION*level, MAP_DIMENSION*level)
	load_level()

func load_level():

	#Load the maze
	var MazeGen = ProceduralMaze.new(dimension)
	
	#Get the goal post
	self.goal_tile = MazeGen.get_goal()
	
	#Start the Player
	var t_size_x = $TileMap.cell_size.x
	var t_size_y = $TileMap.cell_size.x
	var start_pos = Vector2(MazeGen.get_start().x * t_size_x, MazeGen.get_start().y* t_size_y)
	$Player.position = start_pos
	
	set_tilemap(MazeGen.get_maze_matrix(), dimension)



func set_tilemap(matrix, dimension):
	#little bit of spaghetti
	#maze generator represents paths as 1, and zeros as 0
	# but the tilemap represents walls with 1
	var primes = common_funcs.generate_primes(int(dimension.x*dimension.y))
	
	for x in range(dimension.x):
		for y in range(dimension.y):
			var distance = get_distance(Vector2(x,y), goal_tile)
			#set floor
			if(matrix[x][y] == 1):
				$TileMap.set_cell(x, y, 2)
			#set hint
			if(primes[distance] == 1):
				$TileMap.set_cell(x, y, 4)
			#set wall
			if(matrix[x][y] == 0):
				$TileMap.set_cell(x, y, 1)
			
			
	for y in range(-1, dimension.y+1):
		$TileMap.set_cell(-1, y, 1)
		$TileMap.set_cell(dimension.x, y, 1)
	
	for x in range(-1,dimension.x+1):
		$TileMap.set_cell(x, -1, 1)
		$TileMap.set_cell(x, dimension.y, 1)
		
	$TileMap.set_cell(self.goal_tile.x, self.goal_tile.y, 3)
		
		
	$TileMap.get_canvas()

func get_distance(a,b):
	var x = b.x - a.x
	var y = b.y - a.y
	var dist = int(sqrt(x*x+ y*y))
	return dist
	
	
func check_player_win():
	#get player tile
	var tile_pos = $TileMap.world_to_map($Player.position)
	
	#check tile
	if(tile_pos == goal_tile):
		emit_signal("player_found_goal")
		level += 1
		dimension = Vector2(level*MAP_DIMENSION, level*MAP_DIMENSION)
		load_level()
		
	# advance level, restart position and timer, restart score
		


func _on_Player_game_over():
	$ReplayHud.score = $Player.score
	$Player.hide()
	$ReplayHud.show()
	
	emit_signal("game_over")
	
	pass # Replace with function body.



func _on_ReplayButton_pressed():
	game_start()
	pass # Replace with function body.
