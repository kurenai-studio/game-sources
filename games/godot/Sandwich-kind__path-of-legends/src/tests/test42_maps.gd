extends SceneTree
var main
var f := 0
var ids := []
var mi := 0
var t0 := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_stages()
	for m in Maps.visible_duel_maps(): ids.append(m["id"])
	print("visible: ", ids)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3 or (mi > 0 and f - t0 == 60 * 14):
		if mi > 0:
			var hp := []
			for p in main.duel_players: hp.append(p.hp)
			var cells := 0
			for n in main.world.get_children():
				if n is Destructible: cells += n.cells.size()
			print(ids[mi - 1], ": doom=", main.events.doom, " kills=", main.kills, " hp=", hp, " cells=", cells)
		if mi >= ids.size():
			Save.reset()
			print("after reset visible: ", Maps.visible_duel_maps().size())
			return true
		main._on_duel_ready(ids[mi], 9, 99, [0, 1], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 3})
		mi += 1
		t0 = f
	return false
