extends SceneTree
# «Мгновенная смерть» в Дуэли: Цитадель во тьме (Воплощение Тьмы) и общий хаос на других картах.
# MAPS — список карт через запятую.
var main
var f := 0
var t0 := 0
var maps := ["arena_citadel", "arena_storm", "two_houses"]
var mi := -1
var shots := "/tmp/claude-0/st/sd/"
var deaths := [0, 0]
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	DirAccess.make_dir_recursive_absolute(shots)
	if OS.get_environment("MAPS") != "":
		maps = Array(OS.get_environment("MAPS").split(","))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "%s_%s.png" % [maps[mi], n])
func _next() -> bool:
	mi += 1
	if mi >= maps.size():
		return false
	t0 = f
	deaths = [0, 0]
	main._on_duel_ready(maps[mi], 9, 99, [12, 14], {"sd": true, "sd_time": 4, "heal": true, "buffs": true, "mega": true})
	return true
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_next()
	if mi < 0:
		return false
	var k := f - t0
	if k == 30:
		for p in main.duel_players:
			p.died.connect(func(i): deaths[i] += 1)
	if k in [60, 400, 520, 700, 900, 1200, 1500, 1900]:
		shot("k%04d" % k)
		var av = main.events._avatar if main.events else null
		print(maps[mi], " k=", k, " doom=", main.events.doom, " deaths=", deaths, " kills=", main.kills,
				" hp=", main.duel_players.map(func(p): return p.hp), " avatar=", av != null and is_instance_valid(av), " state=", av._state if av and is_instance_valid(av) else "-")
	if k == 2000:
		if not _next():
			print("DONE")
			quit()
	return false
