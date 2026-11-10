extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	var collected = get_node("/root/root").get_lights_count()
	var total = get_node("/root/root").total_lights
	var p = float(collected) / total
	if p > .1:
		turn_lights_on(1)
	if p > .2:
		turn_lights_on(2)
	if p > .4:
		turn_lights_on(3)
	if p > .6:
		turn_lights_on(4)
	if p == 1:
		turn_lights_on(5)


func turn_lights_on(part):
	for n in get_node("lights/p" + str(part)).get_children():
		n.visible = true;
		n.light_up()
	if part == 5:
		get_node("lights/thanks").visible = true
