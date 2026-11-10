extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func inside(p) -> bool:
	var q := PhysicsPointQueryParameters2D.new()
	q.position = p.global_position
	q.collision_mask = Layer.WORLD
	return not p.get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("mountain", 9, 99, [0, 1], {"sd": true, "sd_time": 1})
	if f == 400:
		main.events.lava_y = 1150.0
	for k in [500, 800, 1100]:
		if f == k:
			for p in main.duel_players: p.take_damage(9999)
	if f % 60 == 0 and f > 400:
		var s := ""
		for p in main.duel_players:
			s += " %s alive=%s inside=%s para=%d |" % [str(p.position.round()), p.is_alive(), inside(p), p._para]
		print(f, s)
	if f == 1300: Input.action_press("p1_left"); Input.action_press("p2_right")
	if f == 1340:
		Input.action_release("p1_left"); Input.action_release("p2_right")
		print("moved: ", main.duel_players[0].position, main.duel_players[1].position)
	return f > 1350
