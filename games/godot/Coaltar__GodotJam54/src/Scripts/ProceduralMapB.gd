extends Node


const bottom_corners = [
	[1,1],
	[1,1],
	[1,1],
	[1,1],
	]
	 
###########
#Left Walls
###########
const wall_left_1 = [
	[1,0],
	[1,0],
	[1,0],
	[0,0],
	]
	
const wall_left_2 = [
	[0,0],
	[1,1],
	[1,0],
	[1,0],
	]

const wall_left_3 = [
	[0,0],
	[1,0],
	[1,'r'],
	[1,0],
	]

const left_walls = [
	wall_left_1,
	wall_left_2,
	wall_left_3
]

###########
#Right Walls
###########
const wall_right_1 = [
	[0,1],
	[0,1],
	[0,1],
	[0,0],
	]
	

const wall_right_2 = [
	[0,0],
	[0,1],
	['r',1],
	[0,1],
	]
	
const right_walls = [
	wall_right_1,
	wall_right_2
]

###########
#Floors
###########


 

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
