extends SceneTree
# Тёмный Лорд в трёх фазах: тронный зал → вершина цитадели → Воплощение Тьмы.
# HERO — номер легенды (по умолчанию Зарница), COOP=1 — вдвоём.
var main
var f := 0
var arena
var shots := "/tmp/claude-0/st/lord/"
var stage := "p1"
var t0 := 0
var av: DarkAvatar

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	DirAccess.make_dir_recursive_absolute(shots)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "%s.png" % n)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		var hero := int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 12
		var coop := OS.get_environment("COOP") == "1"
		main.sel = [hero, 0]
		main.start_arena(coop, 80)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null or not is_instance_valid(arena):
		return false
	for p in arena.players:
		p.hp = p.max_hp
		p._protect = 1.0
	var b: Player = arena._boss
	var k := f - t0
	match stage:
		"p1":
			if b and is_instance_valid(b) and not b.frozen and not b.cutscene_shield and arena._cut_cam == null:
				stage = "p1_fight"
				t0 = f
				print("phase1 hp=", b.max_hp, " place=", arena.place_name)
		"p1_fight":
			if k == 60:
				shot("01_throne")
				b.hp = 1
				b.take_damage(50, arena.players[0])
				print("lethal1: hp=", b.hp, " shield=", b.cutscene_shield)
				stage = "p1_to_p2"
				t0 = f
		"p1_to_p2":
			if k in [40, 150, 215, 245, 300, 330, 345, 375, 395, 420, 445]:
				shot("02_tr_%03d" % k)
			if k == 330:
				print("relocated: place=", arena.place_name, " floor=", arena.info["floor"], " boss pos=", b.global_position)
			if k == 470:
				print("phase2: max_hp=", b.max_hp, " hp=", b.hp, " title=", b.get_meta("title", ""), " frozen=", b.frozen, " shield=", b.cutscene_shield)
			if b and not b.frozen and not b.cutscene_shield and arena._cut_cam == null and k > 300:
				stage = "p2_fight"
				t0 = f
		"p2_fight":
			if k == 120:
				shot("03_citadel_fight")
			if k == 200:
				b.hp = 1
				b.take_damage(50, arena.players[0])
				stage = "p2_to_p3"
				t0 = f
				for n in main.world.get_children():
					if n is DarkAvatar: av = n
				print("lethal2: avatar=", av != null)
		"p2_to_p3":
			if k in [30, 90, 140, 180, 240, 290, 330, 380, 430]:
				shot("04_tr_%03d" % k)
			if av and av._state == "fight" and arena._cut_cam == null:
				stage = "p3"
				t0 = f
				var hd: Player = av.head
				print("phase3: boss is head=", arena._boss == hd, " head hp=", hd.max_hp, " hand hp=", av.hands[0].p.max_hp,
						" title=", hd.get_meta("title", ""), " alive list=", arena._alive.size(), " stage_cam=", arena.stage_cam != null,
						" cam current=", main.world.get_viewport().get_camera_2d() == arena.stage_cam)
		"p3":
			var hero: Player = arena.players[0]
			if k < 30:
				return false
			# сценарий: кулак, взгляд, пасть, град, хлопок, сломать обе руки, добить голову
			if k == 30:
				av._pace = 999.0
				for h in av.hands: h.cd = 999.0
				hero.global_position = Vector2(900, arena.info["floor"] - hero.body_size.y / 2 - 2)
				av._hand_choose(av.hands[0])
				print("slam state=", av.hands[0].state)
			if k == 75: shot("05_slam_shadow")
			if k == 98: shot("06_slam_hit")
			if k == 104: shot("06b_wave")
			if k == 200:
				hero.global_position = Vector2(1500, arena.info["floor"] - hero.body_size.y / 2 - 2)
				av._start_gaze()
			if k == 250: shot("07_gaze_aim")
			if k == 300: shot("08_gaze_fire")
			if k == 380:
				av._start_maw()
			if k == 420: shot("09_maw_warn")
			if k == 480: shot("10_maw_fire")
			if k == 560:
				av._start_orbs()
			if k == 620: shot("11_orbs")
			if k == 700:
				hero.global_position = Vector2(1300, arena.info["floor"] - hero.body_size.y / 2 - 2)
				av._start_clap()
			if k == 740: shot("12_clap_wind")
			if k == 772: shot("13_clap")
			if k == 860:
				for h in av.hands:
					h.p.take_damage(99999, hero)
				print("hands broken: ", av.hands.map(func(h): return h.broken), " state=", av._state, " head stunned=", av.head.is_stunned())
			if k == 930: shot("14_exposed")
			if k == 1000:
				var hp0: int = av.head.hp
				av.head.take_damage(100, hero)
				print("exposed dmg: ", hp0 - av.head.hp, " (x2 expected)")
			if k == 1350:
				print("recovered: state=", av._state, " hands alive=", av.hands.map(func(h): return h.p.is_alive()))
				shot("15_recovered")
			if k == 1400:
				av._start_call()
			if k == 1460:
				shot("16_call")
				print("summoned=", arena._alive.filter(func(x): return is_instance_valid(x) and x.has_meta("summoned")).size())
			if k == 1500:
				av.head.hp = 1
				av.head.take_damage(500, hero)
				print("head killed: alive=", av.head.is_alive() if is_instance_valid(av.head) else false)
			if k in [1530, 1590, 1650, 1720, 1800]:
				shot("17_death_%04d" % k)
			if k == 1900:
				print("end: state=", arena._state, " progress=", Save.arena_progress("solo"), " unlocked lord=", Save.hero_unlocked("dark_lord"))
				print("done")
				quit()
	return false
