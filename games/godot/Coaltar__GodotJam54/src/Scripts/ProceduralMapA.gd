extends Node

const MatrixFunctions = preload("MatrixFunctions.gd")



#####
##### Some constants

const chunk0 = [
	[0,1],
	[1,1],
	]
	
const chunk1 = [
	[1,0],
	[1,1],
	]
const chunk2 = [
	[1,1],
	[0,1],
	]
const chunk3 = [
	[1,1],
	[1,0],
	]

const chunks = [chunk0, chunk1, chunk2, chunk3]

static func get_test_map(base_dim, expanded_dim):
	var map_array = MatrixFunctions.create_zero_matrix(base_dim)
	randomize()
	for x in range(base_dim):
		for y in range(base_dim):
			var rand = randi() % 2
			map_array[x][y] = rand
	
	var base = map_array
	for _i in range(expanded_dim):
		var rand = randi() % 4
		var chunk = chunks[rand] 
		base = MatrixFunctions.matrix_expansion(base, chunk)
		
	return base
		
