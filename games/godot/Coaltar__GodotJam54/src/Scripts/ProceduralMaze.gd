extends Node
const MatrixFunctions = preload("MatrixFunctions.gd")



var matrix
var start_point
var dimension
var level_goal
var player_start
	
func _init(dimension):
	self.dimension = dimension
	self.matrix = MatrixFunctions.create_zero_matrix(dimension)
	randomize()
	self._generate()

func _generate():
	self._gen_matrix()
	self._gen_goal()
	self._gen_start()
	return matrix
	
func _gen_matrix():
	var maze_start = Vector2(randi() % int(dimension.x), randi() % int(dimension.y))
	var stack = [maze_start]
	var focus = stack[0]
	while(len(stack) > 0):
		self.matrix[focus.x][focus.y] = 1
		var neighbors = self._get_neighbors(focus)
		var unvisited = []
		for n in neighbors:
			if(not _is_wall( n)):
				unvisited.append(n)
		if len(unvisited) > 0:
			focus = unvisited[randi() % len(unvisited)]
			stack.append(focus)
		else:
			focus = stack.pop_back()

func _gen_start():
	self.player_start = self.get_random_path_location(.25*self.dimension,.75*self.dimension)
	return self.player_start
	#select a random location with 
	
func _gen_goal():
	#goal can be anywhere in the map 
	var start = Vector2(0,0)
	var stop = self.dimension
	self.level_goal = get_random_path_location(start, stop)
	return self.level_goal 

func get_maze_matrix():
	return self.matrix
	
func get_goal():
	return self.level_goal

func get_start():
	return self.player_start

func get_random_path_location(start: Vector2, stop: Vector2):
	randomize()

	var x = start.x + (randi() % (int(stop.x) - int(start.x)))
	var y = start.y + (randi() % (int(stop.y) - int(start.y)))
	
	while(self.matrix[x][y] == 0):
		x = start.x + (randi() % (int(stop.x) - int(start.x)))
		y = start.y + (randi() % (int(stop.y) - int(start.y)))
	return Vector2(x,y)
	#gets random location in matrix
	
func _get_neighbors(pos):
	var x_bound = len(self.matrix)
	var y_bound = len(self.matrix[0])
	var neighbors = []
	if(pos.x -1 >= 0):
		neighbors.append(Vector2(pos.x-1,pos.y))
	if(pos.x +1 < x_bound):
		neighbors.append(Vector2(pos.x+1,pos.y))
	if(pos.y -1 >= 0):
		neighbors.append(Vector2(pos.x,pos.y-1))
	if(pos.y + 1 < y_bound):
		neighbors.append(Vector2(pos.x,pos.y+1))
	return neighbors
	
func _is_wall( pos):
	var neighbors = self._get_neighbors(pos)
	var paths = 0
	for pos in neighbors:
		if(self.matrix[pos.x][pos.y] == 1):
			paths += 1
	if paths <= 1:
		return false
	else:
		return true
