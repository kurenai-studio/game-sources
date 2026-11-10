extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func cells() -> int:
	var c := 0
	for n in main.world.get_children():
		if n is Destructible and not n.background: c += n.cells.size()
	return c
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("two_houses", 9, 99, [0, 1], {"sd": true, "sd_time": 1})
	if f % 60 == 0:
		var bs := []
		for n in main.world.get_children():
			if n is SkyBomb: bs.append(n.position.round())
		print("bombs ", bs, " doom=", main.events.doom, " active=", main.events.active, " t=", main.events.time_left)
	if f % 300 == 0:
		print(f / 60, "s cells=", cells(), " hp=", main.duel_players[0].hp, "/", main.duel_players[1].hp, " kills=", main.kills)
	return f > 60 * 40
