extends SceneTree
# Зарница на Арене (Храм шторма): способности против настоящих врагов.
var main
var f := 0
var arena
var t0 := -1
var shots := "/tmp/claude-0/st/"
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "zara_%s.png" % n)
func press(a: String) -> void:
	Input.action_press(a)
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_right", "p1_left"]:
		Input.action_release(a)
	if f == 3:
		main.sel = [12, 0]
		main.start_arena(false, int(OS.get_environment("WAVE")) if OS.get_environment("WAVE") != "" else 67)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	var hero: Player = arena.players[0]
	hero._protect = 1.0
	hero.hp = hero.max_hp
	if t0 < 0:
		if arena._state == "fight" and arena._alive.size() >= 3:
			t0 = f
		return false
	var k := f - t0
	# враги сбиваются к герою, чтобы было по кому бить
	if k % 30 == 0:
		var i := 0
		for b in arena._alive:
			if is_instance_valid(b) and b.is_alive():
				b.global_position = Vector2(hero.global_position.x + 260.0 + i * 90.0, arena.info["floor"] - b.body_size.y / 2 - 2)
				i += 1
		hero.facing = 1
		hero._cd = [0.0, 0.0, 0.0]
	if k > 10 and k < 120 and k % 16 < 2:
		press("p1_shoot")
	else:
		Input.action_release("p1_shoot")
	if k == 60:
		shot("1_sparks")
		var foes: Array = arena._alive.filter(func(x): return is_instance_valid(x) and x.is_alive())
		if foes.size() >= 2:
			var hp0: Array = foes.map(func(x): return x.hp)
			for i in 3:
				hero.kit._spark_hit(foes[0])
			print("chain test: hp before=", hp0, " after=", foes.map(func(x): return x.hp))
	if k == 130: press("p1_a1")
	if k == 134: shot("2_gale")
	if k == 200: press("p1_a2")
	if k == 260: shot("3_rod")
	if k == 330:
		press("p1_right")
		press("p1_a3")
	if k == 336: shot("4_dash")
	if k == 420:
		hero.ult_charge = 9999
		press("p1_ult")
	if k == 470: shot("5_storm")
	if k == 520: shot("5b_storm")
	if k == 600:
		hero.mega_mode = true
		press("p1_a1")
	if k == 640: shot("6_mega_wall")
	if k == 700:
		hero.ult_charge = 9999
		press("p1_ult")
	if k == 790:
		shot("7_mega_storm")
		print("hits=", hero.kit._hits, " kills=", arena.kills)
		quit()
	return false
