extends Node


static func create_zero_matrix(dimension: Vector2):
	var array = []
	for x in range(dimension.x):
		array.append([])
		for _y in range(dimension.y):
			#map_array[x].append(0)
			array[x].append(0)
	return array

static func matrix_expansion(matrix_left, matrix_right):
	#both matrices must be square
	var left_size = len(matrix_left)
	var right_size = len(matrix_right)
	var dimension = left_size*right_size
	
	var base = create_zero_matrix(dimension)

	for L_X in range(left_size):
		for L_Y in range(left_size):
			for R_X in range(right_size):
				for R_Y in range(right_size):
					var val = matrix_left[L_Y][L_X] * matrix_right[R_Y][R_X]
					var pos_x = L_X * right_size + R_X
					var pos_y = L_Y * right_size + R_Y
					base[pos_y][pos_x] = val
	return base
