extends SceneTree
# Горение дерева и ракеты сквозь дерево
var main
var f := 0
var tr
var p2
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func trees() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Destructible and n.flammable:
			r.append(n)
	return r
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main._on_map_chosen("two_houses", 2, 5)
		main._start_game()
	if f == 10:
		tr = trees()[0]
		var fz := FireZone.new()
		fz.team = 0
		fz.position = tr.global_position + Vector2(0, 60)   # середина ствола
		main.world.add_child(fz)
		print("tree cells=", tr.cells.size())
	if f in [60, 120, 240, 400]:
		var ts := trees()
		var fallen := 0
		var total := 0
		for t in ts:
			total += t.cells.size()
			if not t.background:
				fallen += 1
		print("t=", (f - 10) / 60.0, "s burning=", tr._burning.size() if is_instance_valid(tr) else -1,
				" tree0 cells=", tr.cells.size() if is_instance_valid(tr) else -1, " fallen pieces=", fallen)
	if f == 410:
		# залп по второму дереву: ракеты не должны взрываться о дерево
		for n in main.world.get_children():
			if n is Player and n.index == 1: p2 = n
			if n is Player and n.index == 0: n.position = Vector2(300, 1215)
		p2.position = Vector2(3700, 1215)
		p2.facing = -1
		p2._barrage()
	if f == 600:
		var t2 = null
		for t in trees():
			if t.global_position.x > 3000:
				t2 = t
		print("tree at x=3180 cells after barrage=", t2.cells.size(), " (было 86)")
		return true
	return false
