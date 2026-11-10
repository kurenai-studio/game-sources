extends Node


var lights_collected = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	lights_collected = 0
	pass # Replace with function body.


func on_light_collect():
	lights_collected += 1
