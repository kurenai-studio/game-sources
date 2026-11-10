extends SceneTree
var main
var f := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [1, 0]
		main._on_map_chosen("test_field", 1, 3)
		main._start_game()
	if f == 200:
		for team in 2:
			var p: Player = main.duel_players[team]
			var xs := []
			var para := 0
			var base := 0
			for k in 30:
				var r: Dictionary = main._pick_spawn(p)
				xs.append(Vector2i(r["pos"]))
				if r["parachute"]: para += 1
				if p.last_spawn_kind == "base": base += 1
			print("team ", team, " parachute=", para, " fallback=", base, " sample=", xs.slice(0, 8))
		return true
	return false
