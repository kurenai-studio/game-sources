extends SceneTree
var main
var f := 0
var p
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main._on_map_chosen("two_houses", 2, 2)
		main._start_game()
	if f == 200:
		for n in main.world.get_children():
			if n is Player and n.index == 0: p = n
		p.position = main.map_info["sky"][0]
		p.velocity = Vector2.ZERO
		p._para = 1
	if f > 200 and f % 6 == 0 and p._para != 0:
		print(f - 200, " y=", int(p.position.y), " vy=", int(p.velocity.y), " state=", p._para, " h=", int(p._height_above_ground()))
	if f > 200 and p._para == 0 and f < 500:
		print("landed at f", f - 200, " y=", int(p.position.y))
		return true
	return f > 600
