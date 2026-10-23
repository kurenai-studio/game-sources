extends Node
## Root: switches between the menu screens (with the live diorama behind them) and battles.

const TowerScript = preload("res://scripts/battle/tower.gd")


var ui_layer: CanvasLayer
var ui_root: Control
var demo: Node2D
var battle: Node2D
var hud: Control


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("181425"))
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 10
	add_child(ui_layer)
	ui_root = Control.new()
	ui_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui_root.size = Vector2(640, 360)
	ui_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.theme = UI.build_theme()
	ui_layer.add_child(ui_root)
	var args := OS.get_cmdline_user_args()
	if args.has("--sim"):
		_run_sims(args)
		return
	if args.has("--mechtest"):
		_mech_test()
		return
	var i := args.find("--battle")
	if i >= 0 and i + 2 < args.size():
		start_battle(args[i + 1], int(args[i + 2]))
		if args.has("--bot"):
			_bot_drive()
		if args.has("--fxtest"):
			battle.cash = 99999
			for t in [[Vector2i(7, 6), "flamer", 3], [Vector2i(9, 5), "knight", 2], [Vector2i(9, 3), "gunner", 3],
					[Vector2i(6, 3), "soldier", 2], [Vector2i(9, 8), "knight", 3], [Vector2i(9, 13), "garage", 3],
					[Vector2i(7, 10), "soldier", 3]]:
				var tw = battle.place_tower(t[1], t[0])
				for k in t[2]:
					battle.upgrade_tower(tw)
			for k in 12:
				battle.start_wave()
				battle.spawning = false
			battle.spawn_queue = []
			for k in 14:
				battle.spawn_enemy(["goblin", "ironclad", "imp", "wolf", "shaman", "ogre"][k % 6], 0, 60.0 + k * 9.0)
			battle.wave = battle.total_waves
			var boss = battle.spawn_enemy("golem", 0, 20.0)
			boss.final_boss = true
			boss.hp *= 0.7
		if args.has("--newfx"):
			battle.cash = 99999
			for t in [[Vector2i(7, 6), "sniper", 3], [Vector2i(9, 5), "knight", 1], [Vector2i(9, 3), "gunner", 2],
					[Vector2i(6, 3), "sniper", 0], [Vector2i(9, 8), "flamer", 1], [Vector2i(9, 13), "garage", 1],
					[Vector2i(11, 13), "necro", 2]]:
				var tw = battle.place_tower(t[1], t[0])
				if tw == null:
					continue
				for k in t[2]:
					battle.upgrade_tower(tw)
			for k in 12:
				battle.start_wave()
				battle.spawning = false
			battle.spawn_queue = []
			var kinds := ["ghost", "bat", "harpy", "skeleton", "berserker", "bat", "ghost", "skeleton", "bat"]
			for k in kinds.size():
				var e = battle.spawn_enemy(kinds[k], 0, 40.0 + k * 14.0)
				if kinds[k] == "berserker":
					e.hp *= 0.4
			for tw in battle.towers.values():   # show a few raised undead next to the necromancer
				if tw.type == "necro":
					for k in 3:
						var dead = battle.spawn_enemy(["goblin", "ironclad", "wolf"][k], 0, 260.0 + k * 14.0)
						dead.alive = false
						battle.raise_dead(tw, dead)
	elif args.has("--maps"):
		show_map_select()
	elif args.has("--towers"):
		show_towers()
	else:
		show_menu()
	if args.has("--force-win") and battle:
		battle.wave = battle.total_waves
		battle.kills = 1234
		battle._finish(true)
	if args.has("--pause") and hud:
		hud.toggle_pause()
	var tv := args.find("--tower-view")
	if tv >= 0:
		for c in ui_root.get_children():
			if c.has_method("_open_tower"):
				c._open_tower(args[tv + 1])
				if tv + 2 < args.size() and args[tv + 2].is_valid_int():
					c._select_level(int(args[tv + 2]))
	if args.has("--erupt") and battle:
		battle.cash = 99999
		for t in [Vector2i(17, 7), Vector2i(19, 7), Vector2i(22, 10), Vector2i(10, 8), Vector2i(7, 9)]:
			battle.place_tower(["gunner", "soldier", "knight", "flamer", "gunner"][t.x % 5], t)
		battle.start_wave()
		battle.eruption_t = 0.3
	if args.has("--maps-page2"):
		for c in ui_root.get_children():
			if c.has_method("_show_page"):
				c._show_page(1)
	if args.has("--changelog"):
		for c in ui_root.get_children():
			if c.has_method("_open_changelog"):
				c._open_changelog()
	if args.has("--bestiary"):
		for c in ui_root.get_children():
			if c.has_method("_build_enemies"):
				c._show(false)
	if args.has("--settings"):
		for c in ui_root.get_children():
			if c.has_method("_open_settings"):
				c._open_settings()
	if args.has("--zoom") and battle:
		battle.zoom_at(2, Vector2(150, 110))
	if args.has("--popup"):
		for c in ui_root.get_children():
			if c.has_method("_open_difficulty"):
				c._open_difficulty("gas_station")
	if args.has("--uitest"):
		_ui_test()
	var s := args.find("--shot")
	if s >= 0:
		_shot(args[s + 1], float(args[s + 2]))


# ---------------------------------------------------------------- debug helpers (CLI only)
func _shot(path: String, secs: float) -> void:
	await get_tree().create_timer(secs).timeout
	if OS.get_cmdline_user_args().has("--hover"):
		var e = battle.enemies[0] if battle and battle.enemies.size() > 0 else null
		var hi := OS.get_cmdline_user_args().find("--hover-type")
		if hi >= 0:
			for x in battle.enemies:
				if x.alive and x.type == OS.get_cmdline_user_args()[hi + 1]:
					e = x
					break
		if OS.get_cmdline_user_args().has("--hover-friendly"):
			for x in battle.enemies:
				if x.is_friendly:
					e = x
		if e:
			Input.warp_mouse(e.position * 2.0 + Vector2(0, -6))
			await get_tree().create_timer(0.2).timeout
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()


func _click(p: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	# viewport (640x360) -> window coordinates; a window of another aspect gets black bars around the game
	var ws := Vector2(get_window().size)
	var k := minf(ws.x / 640.0, ws.y / 360.0)
	if ProjectSettings.get_setting("display/window/stretch/scale_mode") == "integer":
		k = maxf(1.0, floorf(k))
	var wp := p * k + (ws - Vector2(640, 360) * k) / 2.0
	Input.warp_mouse(wp)
	var mv := InputEventMouseMotion.new()
	mv.position = wp
	Input.parse_input_event(mv)
	await get_tree().create_timer(0.15).timeout
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = button
		ev.pressed = pressed
		ev.position = wp
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().create_timer(0.3).timeout


func _key(code: int) -> void:
	for pressed in [true, false]:
		var ev := InputEventKey.new()
		ev.keycode = code
		ev.physical_keycode = code
		ev.pressed = pressed
		Input.parse_input_event(ev)
		await get_tree().process_frame
	await get_tree().create_timer(0.1).timeout


func _wheel(p: Vector2, button: int) -> void:
	var scale := Vector2(get_window().size) / Vector2(640, 360)
	var wp := p * minf(scale.x, scale.y)
	Input.warp_mouse(wp)
	var mv := InputEventMouseMotion.new()
	mv.position = wp
	Input.parse_input_event(mv)
	await get_tree().create_timer(0.1).timeout
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	ev.pressed = true
	ev.position = wp
	Input.parse_input_event(ev)
	await get_tree().create_timer(0.2).timeout


func _find_button(root: Node, text: String) -> Button:
	for c in root.find_children("*", "Button", true, false):
		if c is Button and c.is_visible_in_tree() and (c as Button).text.begins_with(text):
			return c
	return null


func _btn_center(b: Control) -> Vector2:
	return b.get_global_rect().get_center()


func _ui_test() -> void:
	await get_tree().create_timer(0.5).timeout
	await _click(_btn_center(_find_button(ui_root, "PLAY")))
	print("UITEST after PLAY: ", ui_root.get_child(ui_root.get_child_count() - 1).get_script().resource_path)
	await _click(Vector2(100, 90))  # first map card
	var b := _find_button(ui_root, "")
	await _click(Vector2(450, 110))  # MEDIUM button in popup
	print("UITEST battle started: ", battle != null, " map=", battle.map_id if battle else "", " diff=", battle.diff_idx if battle else -1)
	var shop: Button = hud.shop_buttons["gunner"]
	await _click(_btn_center(shop))
	print("UITEST placing: ", battle.placing)
	await _click(Vector2(10 * 16 + 8, 6 * 16 + 8))
	print("UITEST towers: ", battle.towers.size(), " cash=", battle.cash, " selected=", battle.selected != null)
	await _click(_btn_center(hud.up_btn))
	print("UITEST level after upgrade: ", battle.selected.level if battle.selected else -1)
	await _click(_btn_center(hud.target_btn))
	print("UITEST target mode: ", battle.selected.target_mode if battle.selected else -1)
	await _click(Vector2(300, 300), MOUSE_BUTTON_RIGHT)
	print("UITEST deselected: ", battle.selected == null)
	await _click(_btn_center(hud.start_btn))
	print("UITEST wave: ", battle.wave)
	var ev := InputEventKey.new()
	ev.keycode = KEY_2
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	print("UITEST key 2 -> placing: ", battle.placing)
	await _key(KEY_ESCAPE)
	battle.cash = 5000
	var tpos := Vector2(10 * 16 + 8, 6 * 16 + 8)
	await _click(tpos)
	var lv0: int = battle.selected.level if battle.selected else -1
	await _key(KEY_E)
	print("UITEST E upgrade: ", lv0, " -> ", battle.selected.level if battle.selected else -1)
	await _wheel(tpos, MOUSE_BUTTON_WHEEL_UP)
	print("UITEST zoom: ", battle.scale.x, " tile under cursor ", battle.hover_tile, " pos ", battle.position, " local ", battle.get_local_mouse_position(), " vp ", get_viewport().get_mouse_position())
	var zpos: Vector2 = battle.position + (Vector2(12 * 16 + 8, 8 * 16 + 8)) * battle.scale.x
	battle.begin_place("gunner")
	await _click(zpos)
	print("UITEST placed at zoom: ", battle.towers.has(Vector2i(12, 8)), " towers=", battle.towers.size())
	await _wheel(zpos, MOUSE_BUTTON_WHEEL_DOWN)
	print("UITEST zoom back: ", battle.scale.x, " pos ", battle.position)
	await _click(tpos)
	await _key(KEY_X)
	print("UITEST X sell -> towers: ", battle.towers.size())
	Game.bind_key("upgrade", KEY_Q)
	await _click(Vector2(12 * 16 + 8, 8 * 16 + 8))
	var lv1: int = battle.selected.level
	await _key(KEY_E)
	var lv2: int = battle.selected.level
	await _key(KEY_Q)
	print("UITEST rebind upgrade->Q: E gives ", lv2 - lv1, ", Q gives ", battle.selected.level - lv2, " label ", Game.key_label("upgrade"))
	Game.reset_keys()
	await get_tree().create_timer(4.0).timeout
	print("UITEST enemies on field: ", battle.enemies.size(), " kills=", battle.kills)
	get_tree().quit()


## Headless checks of invisible / flying / revive / rage / sniper rules.
func _mech_test() -> void:
	var b := Battle.new()
	b.headless = true
	add_child(b)
	b.setup("meadow", 1)
	b.cash = 999999
	var pth: Dictionary = b.paths[0]
	var mid: Vector2 = b.path_point(0, 120.0)[0]
	var spot := Vector2i(-1, -1)
	for y in Battle.ROWS:
		for x in Battle.COLS:
			var t := Vector2i(x, y)
			if b.can_place(t) and b.tile_center(t).distance_to(mid) < 28.0:
				spot = t
	var fails := []   # lambdas capture locals by value, so collect failures in an array
	var check := func(name: String, cond: bool) -> void:
		print("MECH %s %s" % ["ok  " if cond else "FAIL", name])
		if not cond:
			fails.append(name)
	var gun = b.place_tower("gunner", spot)
	var ghost = b.spawn_enemy("ghost", 0, 120.0)
	var bat = b.spawn_enemy("bat", 0, 120.0)
	check.call("gunner lv0 can't see ghost", not gun.can_target(ghost))
	check.call("gunner lv0 hits bat", gun.can_target(bat))
	b.upgrade_tower(gun)
	b.upgrade_tower(gun)
	check.call("gunner Hollow Points sees ghost", gun.can_target(ghost))
	var kn = TowerScript.new()
	kn.setup("knight", b, 0)
	check.call("knight can't hit bat", not kn.can_target(bat))
	check.call("knight can't see ghost", not kn.can_target(ghost))
	var so = TowerScript.new()
	so.setup("soldier", b, 0)
	check.call("soldier lv0 can't see ghost", not so.can_target(ghost))
	so.level = 1
	so.recompute()
	check.call("soldier AP Rounds sees ghost", so.can_target(ghost))
	var sn = TowerScript.new()
	sn.setup("sniper", b, 0)
	check.call("sniper sees ghost and bat", sn.can_target(ghost) and sn.can_target(bat))
	# flamer: can't aim at a lone ghost, but burns it next to a goblin
	b.sell_tower(gun)
	ghost.alive = false
	bat.alive = false
	b.enemies.clear()
	var fl = b.place_tower("flamer", spot)
	var g2 = b.spawn_enemy("ghost", 0, 120.0)
	g2.position = fl.position + Vector2(20, 0)
	for k in 30:
		fl.update(Battle.STEP, b.enemies)
	check.call("flamer ignores lone ghost", g2.hp == g2.max_hp)
	var gob = b.spawn_enemy("goblin", 0, 120.0)
	gob.position = fl.position + Vector2(22, 0)
	var bt = b.spawn_enemy("bat", 0, 120.0)
	bt.position = fl.position + Vector2(20, 2)
	for k in 30:
		fl.update(Battle.STEP, b.enemies)
	check.call("flamer burns ghost near goblin", g2.hp < g2.max_hp)
	check.call("flamer can't hit bat", bt.hp == bt.max_hp)
	b.sell_tower(fl)
	b.enemies.clear()
	# cars: run over ghosts, drive under bats
	var car = b.spawn_enemy("car", 0, 200.0, 1.0, true, {"car_hp": 50000, "car_speed": 70})
	var g3 = b.spawn_enemy("ghost", 0, 196.0)
	var b3 = b.spawn_enemy("bat", 0, 198.0)
	b.stats_changed.connect(func(): pass)
	b._tick_friendly(car, Battle.STEP)
	check.call("car hits ghost", not g3.alive)
	check.call("car misses bat", b3.alive and b3.hp == b3.max_hp)
	b.enemies.clear()
	# skeleton
	var sk = b.spawn_enemy("skeleton", 0, 50.0)
	b.damage_enemy(sk, 999.0, "physical", null)
	check.call("skeleton falls apart", sk.alive and sk.downed_t > 0.0 and sk.hp == sk.max_hp * 0.5)
	check.call("bones can't be targeted", not sn.can_target(sk))
	check.call("bones don't move", sk.current_speed() == 0.0)
	for k in 120:
		sk.tick_status(Battle.STEP)
	check.call("skeleton gets back up", sk.current_speed() > 0.0)
	b.damage_enemy(sk, 999.0, "physical", null)
	check.call("skeleton dies the second time", not sk.alive)
	# berserker
	var be = b.spawn_enemy("berserker", 0, 50.0)
	var s0: float = be.current_speed()
	b.damage_enemy(be, be.max_hp * 0.6, "pure", null)
	check.call("berserker enrages", absf(be.current_speed() - s0 * 2.0) < 0.01)
	# sniper headshot never on bosses
	sn.level = 3
	sn.recompute()
	var gol = b.spawn_enemy("golem", 0, 50.0)
	gol.position = sn.position + Vector2(30, 0)
	sn.target_mode = 2
	for k in 400:
		sn.update(Battle.STEP, b.enemies)
	check.call("sniper hurts boss, no headshot", gol.alive and gol.hp < gol.max_hp)
	# necromancer: raises what its bolts kill, as friendly undead with part of the max HP
	for tw in b.towers.values():
		b.sell_tower(tw)
	for e in b.enemies:
		e.alive = false
	b.enemies.clear()
	b.bullets.clear()
	var nc = b.place_tower("necro", spot)
	var undead_of := func() -> Array:
		return b.enemies.filter(func(x): return x.alive and x.is_friendly and x.owner_tower == nc)
	var gob2 = b.spawn_enemy("goblin", 0, 120.0)
	gob2.position = nc.position + Vector2(20, 0)
	gob2.hp = 1.0
	for k in 60:
		nc.update(Battle.STEP, b.enemies)
		b._tick_bullets(Battle.STEP)
	var raised: Array = undead_of.call()
	check.call("necro raises the goblin it killed", not gob2.alive and raised.size() == 1)
	check.call("undead keeps 20% max HP", raised.size() == 1 and absf(raised[0].max_hp - roundf(gob2.max_hp * 0.2)) < 0.01)
	var wolf = b.spawn_enemy("wolf", 0, 120.0)
	wolf.position = nc.position + Vector2(20, 0)
	wolf.hp = 1.0
	var bat2 = b.spawn_enemy("bat", 0, 120.0)
	bat2.position = nc.position + Vector2(20, 0)
	bat2.hp = 1.0
	for k in 120:
		nc.update(Battle.STEP, b.enemies)
		b._tick_bullets(Battle.STEP)
	check.call("lv0 doesn't raise class II or flyers", not wolf.alive and not bat2.alive and undead_of.call().size() == 1)
	nc.level = 1
	nc.recompute()
	for k in 5:
		var g = b.spawn_enemy("wolf", 0, 120.0)
		g.position = nc.position + Vector2(20, 0)
		g.hp = 1.0
		for j in 60:
			nc.update(Battle.STEP, b.enemies)
			b._tick_bullets(Battle.STEP)
	check.call("Dark Pact raises class II, no cap", undead_of.call().size() == 6)
	check.call("undead rise on the road in range",
		undead_of.call().all(func(x): return x.position.distance_to(nc.position) <= nc.range_px() + 0.5))
	var ug = undead_of.call()[0]
	var ogre = b.spawn_enemy("ogre", 0, ug.dist)
	ogre.position = ug.position
	var oh: float = ogre.hp
	b._tick_friendly(ug, Battle.STEP)
	check.call("undead crashes into enemies", not ug.alive and ogre.hp < oh)
	# freezer: chill builds into a freeze, slower on higher classes; water and fire cancel out
	for tw in b.towers.values():
		b.sell_tower(tw)
	for e in b.enemies:
		e.alive = false
	b.enemies.clear()
	var fz = b.place_tower("freezer", spot)
	var cold_gob = b.spawn_enemy("goblin", 0, 120.0)
	cold_gob.position = fz.position + Vector2(20, 0)
	var cold_gol = b.spawn_enemy("golem", 0, 120.0)
	cold_gol.position = fz.position + Vector2(22, 0)
	var gob_speed: float = cold_gob.current_speed()
	for k in 60:
		fz.update(Battle.STEP, b.enemies)
	check.call("freezer chills and slows", cold_gob.chill > 0.0 and cold_gob.current_speed() < gob_speed)
	check.call("lv0 freezer does no damage", cold_gob.hp == cold_gob.max_hp)
	check.call("boss chills 5x slower", absf(cold_gol.chill - cold_gob.chill * 0.2) < 0.01)
	for k in 120:
		fz.update(Battle.STEP, b.enemies)
	check.call("goblin freezes solid", cold_gob.frozen_t > 0.0 and cold_gob.current_speed() == 0.0)
	var fl2 = TowerScript.new()
	fl2.position = fz.position
	fl2.setup("flamer", b, 0)
	fl2.update(Battle.STEP, b.enemies)
	check.call("fire melts the ice", cold_gob.frozen_t <= 0.0 and cold_gob.chill == 0.0 and cold_gob.burn_t > 0.0)
	for k in 180:   # let the freeze immunity run out
		cold_gob.tick_status(Battle.STEP)
	fz.flame_tick = 0.0
	fz.update(Battle.STEP, b.enemies)
	check.call("water puts out the fire", cold_gob.burn_t <= 0.0 and cold_gob.chill > 0.0)
	fz.level = 4
	fz.recompute()
	var iron = b.spawn_enemy("ironclad", 0, 120.0)
	iron.position = fz.position + Vector2(20, 1)
	var ih: float = iron.hp
	fz.flame_tick = 0.0
	fz.update(Battle.STEP, b.enemies)
	check.call("liquid nitrogen ignores armor", absf(ih - iron.hp - float(fz.stats["damage"])) < 0.01)
	# acid: damage over time through armor, eats armor while it lasts
	for tw in b.towers.values():
		b.sell_tower(tw)
	for e in b.enemies:
		e.alive = false
	b.enemies.clear()
	var ac = b.spawn_enemy("ironclad", 0, 120.0)
	var arm0: float = ac.armor
	ac.apply_acid(10.0, 1.0, 2.0, null)
	check.call("acid eats armor", ac.cur_armor() == arm0 - 2.0)
	var ah: float = ac.hp
	for k in 30:
		b._tick_enemies(Battle.STEP)
	check.call("acid hurts through armor", absf(ah - ac.hp - 5.0) < 0.2)
	for k in 60:
		b._tick_enemies(Battle.STEP)
	check.call("armor comes back after the acid", ac.acid_t <= 0.0 and ac.cur_armor() == arm0)
	for e in b.enemies:
		e.alive = false
	b.enemies.clear()
	var tg = b.place_tower("toxic", spot)
	var tgt = b.spawn_enemy("ogre", 0, 120.0)
	tgt.position = tg.position + Vector2(30, 0)
	for k in 60:
		tg.update(Battle.STEP, b.enemies)
		b._tick_bullets(Battle.STEP)
	check.call("toxic gunner puts acid on", tgt.acid_t > 0.0)
	b.sell_tower(tg)
	var asn = b.place_tower("assassin", spot)
	var abat = b.spawn_enemy("bat", 0, 120.0)
	abat.position = asn.position + Vector2(40, 0)
	check.call("assassin blades can't hit flyers", not asn.can_target(abat))
	for k in 60:
		asn.update(Battle.STEP, b.enemies)
		b._tick_bullets(Battle.STEP)
	check.call("no daggers before level 4", abat.hp == abat.max_hp)
	asn.level = 3
	asn.recompute()
	for k in 60:
		asn.update(Battle.STEP, b.enemies)
		b._tick_bullets(Battle.STEP)
	check.call("level 4 daggers hit flyers", abat.hp < abat.max_hp or not abat.alive)
	# Holy Champion aura: towers nearby deal 15% more; Cryo Cannon: its frozen enemies take 25% more
	for tw in b.towers.values():
		b.sell_tower(tw)
	for e in b.enemies:
		e.alive = false
	b.enemies.clear()
	b.cash = 999999
	var near: Array = []
	for y in Battle.ROWS:
		for x in Battle.COLS:
			var tt := Vector2i(x, y)
			if b.can_place(tt) and b.tile_center(tt).distance_to(b.tile_center(spot)) <= Battle.AURA_RANGE:
				near.append(tt)
	var holy = b.place_tower("knight", near[0])
	var buddy = b.place_tower("gunner", near[1])
	check.call("no aura before Holy Champion", is_equal_approx(buddy.buff, 1.0))
	for k in 6:
		b.upgrade_tower(holy)
	check.call("Holy Champion aura +15%", is_equal_approx(buddy.buff, 1.15))
	var holy2 = b.place_tower("knight", near[2])
	for k in 6:
		b.upgrade_tower(holy2)
	check.call("auras don't stack", is_equal_approx(buddy.buff, 1.15))
	var bz = b.spawn_enemy("goblin", 0, 120.0)
	bz.frozen_t = 2.0
	bz.brittle = 0.25
	var bh: float = bz.hp
	b.damage_enemy(bz, 100.0, "pure", null)
	check.call("brittle ice: +25% damage while frozen", absf(bh - bz.hp - 125.0) < 0.01)
	# fixed HP per enemy type: handmade waves only ever spawn x1 or Bloated (x2)
	var fixed := true
	for d in Defs.DIFFICULTIES:
		for w in range(1, Waves.count(d["id"]) + 1):
			for sp in Waves.build(d["id"], w)["spawns"]:
				fixed = fixed and float(sp[2]) == (Defs.BLOATED_HP if sp[3].has("bloated") else 1.0)
	check.call("handmade waves: fixed HP, Bloated x2", fixed and Waves.count("light") == 20 and Waves.count("ultracore") == 40)
	b.enemies.clear()
	var fat = b.spawn_enemy("ogre", 0, 120.0, Defs.BLOATED_HP, false, {}, ["bloated"])
	check.call("Bloated Ogre: x2 HP, same sprite", fat.max_hp == Defs.ENEMIES["ogre"]["hp"] * Defs.BLOATED_HP
		and fat.display_name() == "Bloated Ogre" and fat.tex_normal.resource_path.ends_with("ogre.png"))
	var troll = b.spawn_enemy("troll", 0, 120.0, 1.0)
	troll.hp = troll.max_hp * 0.5
	var regen: float = troll.max_hp * float(Defs.ENEMIES["troll"]["regen"])
	b._tick_enemies(1.0)
	check.call("troll regenerates", absf(troll.hp - (troll.max_hp * 0.5 + regen)) < 0.01)
	troll.apply_burn(0.0, 3.0, 0.0, null)
	b._tick_enemies(1.0)
	check.call("no regen while burning", absf(troll.hp - (troll.max_hp * 0.5 + regen)) < 0.01)
	var dragon = b.spawn_enemy("bone_dragon", 0, 120.0, 1.0)
	b.damage_enemy(dragon, dragon.max_hp + 1.0, "pure", null)
	check.call("Bone Dragon gets back up with 30%", dragon.alive and absf(dragon.hp - dragon.max_hp * 0.3) < 0.01)
	# lead: only towers that pierce lead hurt it; fire and acid always do; cars crash into it, undead don't
	b.enemies.clear()
	var lg = b.spawn_enemy("goblin", 0, 120.0, 1.0, false, {}, ["lead"])
	check.call("Lead Goblin: own sprite", lg.display_name() == "Lead Goblin"
		and lg.tex_normal.resource_path.ends_with("goblin_lead.png"))
	check.call("gunslinger and knight can't aim at lead", not buddy.can_target(lg) and not holy.can_target(lg))
	b.damage_enemy(lg, 5.0, "physical", buddy)
	check.call("lead shrugs off bullets", lg.hp == lg.max_hp)
	b.damage_enemy(lg, 5.0, "fire", null)
	b.damage_enemy(lg, 5.0, "acid", null)
	check.call("fire and acid hurt lead", lg.hp == lg.max_hp - 10.0)
	var free_t := Vector2i(-1, -1)
	for y in Battle.ROWS:
		for x in Battle.COLS:
			if free_t.x < 0 and b.can_place(Vector2i(x, y)):
				free_t = Vector2i(x, y)
	var ap = b.place_tower("soldier", free_t)
	check.call("soldier lv0 can't hurt lead", not ap.can_target(lg))
	b.upgrade_tower(ap)
	check.call("AP Rounds pierce lead", ap.can_target(lg))
	var lh: float = lg.hp
	b.damage_enemy(lg, 5.0, "physical", ap)
	check.call("AP bullets hurt lead", lg.hp < lh)
	var bouncer = b.spawn_enemy("ogre", 0, lg.dist, 1.0, true, {"undead": true, "car_hp": 500, "car_speed": 0})
	bouncer.owner_tower = buddy
	lh = lg.hp
	b._tick_friendly(bouncer, Battle.STEP)
	check.call("undead bounce off lead", bouncer.alive and lg.hp == lh)
	check.call("Ultracore needs Hardcore beaten on the map", not Game.is_diff_open("nope", 4) and Game.is_diff_open("nope", 3))
	# towers: beating the map puts them on sale, then they're bought with paper maps (never touches the save)
	var keep := {"no_save": Game._no_save, "beaten": Game.beaten.duplicate(true), "bought": Game.bought_towers.duplicate(),
		"paper": Game.paper_maps, "all": Game.all_maps_open}
	Game._no_save = true
	Game.all_maps_open = false
	Game.beaten = {}
	Game.bought_towers = []
	Game.paper_maps = 30
	check.call("soldier on sale from the start", Game.is_tower_for_sale("soldier") and not Game.is_tower_unlocked("soldier"))
	check.call("sniper locked before Difficult is beaten", not Game.is_tower_for_sale("sniper"))
	Game.record_win("meadow", 2)
	check.call("a win puts the sniper on sale", Game.is_tower_for_sale("sniper") and not Game.is_tower_unlocked("sniper"))
	Game.paper_maps = Game.tower_price("sniper") - 1
	check.call("can't buy without enough paper maps", not Game.buy_tower("sniper"))
	Game.paper_maps = Game.tower_price("sniper")
	check.call("bought sniper is unlocked", Game.buy_tower("sniper") and Game.is_tower_unlocked("sniper") and Game.paper_maps == 0)
	Game.beaten = keep["beaten"]
	Game.bought_towers = keep["bought"]
	Game.paper_maps = keep["paper"]
	Game.all_maps_open = keep["all"]
	Game._no_save = keep["no_save"]
	# farm: pays its income at the end of every wave, at most 8 of them
	for tw in b.towers.values():
		b.sell_tower(tw)
	b.cash = 999999
	var farm_tiles: Array = []
	for y in Battle.ROWS:
		for x in Battle.COLS:
			if b.can_place(Vector2i(x, y)):
				farm_tiles.append(Vector2i(x, y))
	var farm = b.place_tower("farm", farm_tiles[0])
	b.upgrade_tower(farm)
	var before_cash: int = b.cash
	b.bonus_pending = true
	b._award_bonus()
	var bonus := roundi(Defs.wave_bonus(b.wave) * b.diff["bonus_multi"])
	check.call("farm pays $110 at the end of the wave", b.cash - before_cash == bonus + 110 and farm.earned == 110)
	for k in range(1, 9):
		b.place_tower("farm", farm_tiles[k])
	check.call("at most 8 farms", b.tower_count("farm") == 8)
	# minigun: spins up while it shoots, winds down with nothing in range
	b.enemies.clear()
	var mg = b.place_tower("minigun", farm_tiles[9])
	var tank = b.spawn_enemy("golem", 0, 120.0, 1.0)
	tank.position = mg.position + Vector2(20, 0)
	var shots0: int = b.bullets.size()
	for k in 30:
		mg.update(Battle.STEP, b.enemies)
	var cold_shots: int = b.bullets.size() - shots0
	for k in 200:
		mg.update(Battle.STEP, b.enemies)
	check.call("minigun spins up", is_equal_approx(mg.spin, 1.0))
	shots0 = b.bullets.size()
	for k in 30:
		mg.update(Battle.STEP, b.enemies)
	check.call("spun up it fires ~4x faster", b.bullets.size() - shots0 >= cold_shots * 3)
	b.enemies.clear()
	for k in 120:
		mg.update(Battle.STEP, b.enemies)
	check.call("minigun winds down with nothing to shoot", mg.spin < 0.4)
	# tower limits: 10 of a type, 50 in all
	for tw in b.towers.values():
		b.sell_tower(tw)
	b.cash = 999999
	var free_tiles: Array = []
	for y in Battle.ROWS:
		for x in Battle.COLS:
			if b.can_place(Vector2i(x, y)):
				free_tiles.append(Vector2i(x, y))
	for k in 10:
		b.place_tower("gunner", free_tiles[k])
	check.call("10 gunslingers fit", b.tower_count("gunner") == 10)
	check.call("no 11th gunslinger", b.place_tower("gunner", free_tiles[10]) == null and b.limit_reason("gunner") != "")
	var k2 := 10
	for t in ["knight", "soldier", "sniper", "necro"]:
		for j in 10:
			b.place_tower(t, free_tiles[k2])
			k2 += 1
	check.call("50 towers in all, then no more", b.towers.size() == 50 and b.place_tower("flamer", free_tiles[k2]) == null)
	print("MECH RESULT ", "PASS" if fails.is_empty() else "FAIL")
	get_tree().quit()


func _bot_drive() -> void:
	var Bot = load("res://scripts/debug/bot.gd")
	var bot = Bot.new(battle, ["gunner", "knight", "flamer"])
	battle.speed = 3
	while is_instance_valid(battle) and not battle.over:
		bot.step()
		await get_tree().create_timer(0.25).timeout


func _run_sims(args: Array) -> void:
	var Bot = load("res://scripts/debug/bot.gd")
	var Defs = load("res://scripts/data/defs.gd")
	var MapsData = load("res://scripts/data/maps_data.gd")
	var only_map := ""
	var k := args.find("--map")
	if k >= 0:
		only_map = args[k + 1]
	var sets := [["gunner", "knight"], ["gunner", "knight", "soldier"], ["gunner", "knight", "soldier", "garage"],
		["gunner", "knight", "soldier", "garage", "flamer"], ["flamer", "gunner", "knight"], ["gunner", "flamer", "knight"], ["flamer"], ["gunner"],
		["gunner", "knight", "sniper"], ["gunner", "knight", "soldier", "garage", "flamer", "sniper"],
		["gunner", "knight", "necro"], ["gunner", "knight", "freezer"],
		["gunner", "knight", "soldier", "garage", "flamer", "sniper", "freezer"]]
	var si := args.find("--sets")
	if si >= 0:
		var chosen: Array = []
		for ks in String(args[si + 1]).split(","):
			chosen.append(sets[int(ks)])
		sets = chosen
	for knob in ["BUDGET_MULT", "HP_GROWTH", "BOUNTY_MULT"]:
		var ki := args.find("--" + knob)
		if ki >= 0:
			Defs.set(knob, float(args[ki + 1]))
	var only_diff := -1
	if args.find("--diff") >= 0:
		only_diff = int(args[args.find("--diff") + 1])
	for m in MapsData.ORDER:
		if only_map != "" and m != only_map:
			continue
		for d in 4:
			if only_diff >= 0 and d != only_diff:
				continue
			for allowed in sets:
				var b = Battle.new()
				b.headless = true
				add_child(b)
				b.setup(m, d)
				var bot = Bot.new(b, allowed)
				var t := 0.0
				while not b.over and t < 3600.0:
					if int(t * 60.0) % 15 == 0:
						bot.step()
					b.tick(Battle.STEP)
					t += Battle.STEP
				if args.has("--dmg"):
					var per := {}
					var spent := {}
					var cnt := {}
					for tw in b.towers.values():
						per[tw.type] = per.get(tw.type, 0) + int(tw.damage_dealt)
						spent[tw.type] = spent.get(tw.type, 0) + tw.spent
						cnt[tw.type] = cnt.get(tw.type, 0) + 1
					var out := ""
					for kk in per:
						out += "%s x%d %.1f/$  " % [kk, cnt[kk], float(per[kk]) / maxf(1.0, spent[kk])]
					print("    dmg by type: ", out)
				print("%-12s %-9s %-22s %s  wave %2d/%d  lives %3d  cash %5d  towers %d  time %ds" % [m,
					Defs.DIFFICULTIES[d]["name"], ",".join(allowed), "WIN " if b.lives > 0 and b.over else "LOSE",
					b.wave, b.total_waves, b.lives, b.cash, b.towers.size(), int(t)])
				b.queue_free()
	get_tree().quit()


func _clear_ui() -> void:
	for c in ui_root.get_children():
		c.queue_free()
	hud = null


func _ensure_demo() -> void:
	if battle:
		battle.queue_free()
		battle = null
	if demo == null:
		demo = Battle.new()
		add_child(demo)
		move_child(demo, 0)
		demo.setup("menu", 1, true)
		# warm up so the diorama is already busy
		for k in 600:
			demo.tick(Battle.STEP)


func show_menu() -> void:
	Music.back_to_playlist()
	_ensure_demo()
	_clear_ui()
	var s := MenuScreen.new()
	s.main = self
	ui_root.add_child(s)


func show_map_select() -> void:
	_ensure_demo()
	_clear_ui()
	var s := MapSelect.new()
	s.main = self
	ui_root.add_child(s)


func show_towers() -> void:
	_ensure_demo()
	_clear_ui()
	var s := TowersScreen.new()
	s.main = self
	ui_root.add_child(s)


func start_battle(map_id: String, diff: int) -> void:
	Music.back_to_playlist()
	Game.selected_map = map_id
	Game.selected_difficulty = diff
	_clear_ui()
	if demo:
		demo.queue_free()
		demo = null
	if battle:
		battle.queue_free()
	battle = Battle.new()
	add_child(battle)
	move_child(battle, 0)
	battle.setup(map_id, diff)
	hud = Hud.new()
	ui_root.add_child(hud)
	hud.cheats = Game.cheats
	hud.setup(battle)
	hud.quit_to_menu.connect(show_menu)
	hud.restart.connect(func(): start_battle(map_id, diff))
	hud.continue_after_win.connect(continue_battle_after_win)
	
func continue_battle_after_win():
	hud.end_layer.queue_free()
	hud.end_layer = null
	battle.over = false
	battle.continued = true
