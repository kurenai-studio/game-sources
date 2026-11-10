extends SceneTree
# Колосс: вторая фаза. Повергнуть → пробуждение (сцена) → новые атаки и горящее небо → окончательная победа.
var main
var f := 0
var arena
var boss: Player
var p: Player
var t0 := -1
var shots := "/tmp/claude-0/st/"
var order := ["fire_dash", "meteor_leap", "lava_volley", "core_nova", "shockwave"]
var ai := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "c2_" + n + ".png")

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
		main.start_arena(false, 50)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	if t0 < 0:
		if arena._boss and is_instance_valid(arena._boss) and not arena._boss.frozen and not arena._boss.cutscene_shield:
			boss = arena._boss
			p = arena.players[0]
			t0 = f
			print("phase1: hp=", boss.hp, "/", boss.max_hp, " front_armor=", boss.front_armor)
		return false
	var k := f - t0
	if is_instance_valid(p):
		p._protect = 1.0
		p.hp = p.max_hp
	if k == 30:
		boss.take_damage(9999999, p)
		print("lethal hit: alive=", boss.is_alive(), " hp=", boss.hp, " shield=", boss.cutscene_shield, " time_scale=", Engine.time_scale)
	if k == 50: shot("1_kneel")
	if k == 130: shot("2_cracks")
	if k == 200: shot("3_burst")
	if k == 300:
		shot("4_phase2")
		print("phase2: hp=", boss.hp, "/", boss.max_hp, " title=", boss.get_meta("title", ""), " armor=", boss.front_armor,
				" speed=", boss.speed, " abil=", boss.bot_abilities.keys(), " frozen=", boss.frozen, " shield=", boss.cutscene_shield)
	# по очереди заставляем каждую атаку сработать
	if k >= 320 and is_instance_valid(boss) and boss.is_alive():
		var slot := (k - 320) / 300
		if slot < order.size():
			var ab: String = order[slot]
			for a in boss._bot_cd.keys():
				boss._bot_cd[a] = 999.0
			if (k - 320) % 300 == 0:
				boss._bot_cd[ab] = 0.0
				boss.hp = boss.max_hp
				boss._stun_t = 0.0
				# герой — на расстоянии, на земле
				p.global_position = Vector2(boss.global_position.x + (420.0 if boss.global_position.x < 1300 else -420.0), p.global_position.y)
				print("try ", ab, " at k=", k)
			if (k - 320) % 300 == 60: shot("5_%s_a" % ab)
			if (k - 320) % 300 == 130: shot("5_%s_b" % ab)
			if (k - 320) % 300 == 299:
				print("   ", ab, ": boss cd now=", snappedf(boss._bot_cd.get(ab, -1.0), 0.1), " meteors_seen=", main.world.get_children().filter(func(n): return n is InfernoSky.Meteor).size(),
						" sky=", main.world.get_children().filter(func(n): return n is InfernoSky).size(), " stunned=", boss.is_stunned())
		elif slot == order.size() and (k - 320) % 300 == 0:
			shot("6_meteors")
			boss.take_damage(9999999, p)
			print("final hit: alive=", boss.is_alive())
	if k == 320 + 300 * order.size() + 200:
		print("end: state=", arena._state, " champion unlocked=", Save.hero_unlocked("colossus"), " sky=", main.world.get_children().filter(func(n): return n is InfernoSky).size())
		shot("7_end")
		return true
	return false
