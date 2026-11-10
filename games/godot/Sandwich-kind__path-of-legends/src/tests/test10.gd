extends SceneTree
# Где падают снаряды залпа на большой карте
var main
var f := 0
var p2
var hits: Array = []
var last := {}

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.map_id = "two_houses"
		main.start_duel()
	if f == 5:
		for n in main.world.get_children():
			if n is Destructible:
				n.queue_free()
			if n is Player and n.index == 0:
				n.position = Vector2(3700, 1215)
			if n is Player and n.index == 1:
				p2 = n
		p2.position = Vector2(600, 1215)
		p2.facing = 1
	if f == 10:
		p2._barrage()
	if f > 10 and f < 300:
		var alive := {}
		for n in main.world.get_children():
			if n is Mortar:
				alive[n.get_instance_id()] = true
				last[n.get_instance_id()] = n.global_position
		for id in last.keys():
			if not alive.has(id):
				hits.append(Vector2i(int(last[id].x - 600), int(last[id].y)))
				last.erase(id)
	if f == 300:
		print("BARRAGE landing (dx from hero, y): ", hits)
		return true
	return false
