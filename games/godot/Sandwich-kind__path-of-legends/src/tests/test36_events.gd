extends SceneTree
var main
var f := 0
var maps := ["test_field", "two_houses", "mountain"]
var mi := 0
var start_f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3 or (mi > 0 and f - start_f == 60 * 40):
		if mi > 0:
			var ev = main.events
			var orbs := 0
			for n in main.world.get_children():
				if n is Pickup: orbs += 1
			print(maps[mi - 1], ": doom=", ev.doom, " kills=", main.kills, " hp=", main.duel_players[0].hp, "/", main.duel_players[1].hp,
				" orbs_on_map=", orbs, " lava_y=", ev.lava_y, " p0=", main.duel_players[0].position)
		if mi >= maps.size():
			return true
		main._on_duel_ready(maps[mi], 9, 99, [0, 1], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 10})
		mi += 1
		start_f = f
	return false
