extends SceneTree
var main
var f := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main._on_map_chosen("two_houses", 2, 2)
		main._start_game()
	if f == 10:
		var space = main.world.get_world_2d().direct_space_state
		for x in [2500.0, 3000.0, 3700.0]:
			var spots = Spawner._spots_on_line(space, x, -100.0, 1300.0)
			print("x=", x, " spots=", spots)
			for s in spots:
				print("   free=", Spawner._is_free(space, s))
		return true
	return false
