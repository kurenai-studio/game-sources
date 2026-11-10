extends SceneTree
# Скриншоты стартовых легенд: атаки, способности, ульты (обычные и МЕГА)
var main
var f := 0
var hi := -1
var t0 := 0
var held := {}
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func find(cls):
	for n in main.world.get_children():
		if is_instance_of(n, cls): return n
	return null
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	match f:
		5: main.show_duel_setup()
		8:
			var ds = find(DuelSetup)
			ds._choose_map("test_field", false)
			ds._show_picker()
		60: shot("s0_picker")
		62: main._on_mode_chosen("inventory")
		66: find(InventoryScreen)._select_hero(1)
		72:
			shot("s0_inventory")
			hi = 0
			start()
	if hi < 0 or hi > 1:
		return hi > 1
	var d := f - t0
	var me: Player = main.duel_players[0]
	var foe: Player = main.duel_players[1]
	me._protect = 1.0
	foe._protect = 0.0
	if foe.hp < 60: foe.hp = foe.max_hp
	var tag := "hunter" if hi == 0 else "smith"
	if d == 200:
		me.position = Vector2(300, 570)
		foe.position = Vector2(760 if hi == 0 else 520, 570)
		me.facing = 1
	if d in [230]: shot("%s_idle" % tag)
	if hi == 0:
		match d:
			240: press("p1_shoot", 50)
			275: shot("hunter_draw")
			296: shot("hunter_arrow")
			320: me._cd = [0.0, 0.0, 0.0]; press("p1_a1", 2)
			328: shot("hunter_roll1")
			334: shot("hunter_roll2")
			360: shot("hunter_enchanted"); press("p1_shoot", 3)
			366: shot("hunter_pierce")
			380: me.position = Vector2(300, 570); press("p1_a2", 2)
			386: shot("hunter_trap1")
			420: shot("hunter_trap2"); foe.position = Vector2(me.position.x + 110, 570)
			430: shot("hunter_trap3")
			440: me.position = Vector2(300, 570); foe.position = Vector2(760, 570); press("p1_a3", 2)
			450: shot("hunter_hook1")
			462: shot("hunter_hook2")
			472: shot("hunter_hook3")
			500: me.position = Vector2(300, 570); me.ult_charge = 999; press("p1_ult", 2)
			525: shot("hunter_ult1")
			550: shot("hunter_ult2")
			575: shot("hunter_ult3")
			620: shot("hunter_ult4")
			650: shot("hunter_ult5")
			690: shot("hunter_ult6")
			740:
				me.add_buff("cooldown", true)
				me._cd = [0.0, 0.0, 0.0]
				press("p1_a1", 2)
			775: shot("hunter_mega_enchanted"); press("p1_shoot", 3)
			790: shot("hunter_mega_trail1")
			860: shot("hunter_mega_trail2")
			866: shot("hunter_mega_trail3")
			880: me.position = Vector2(300, 570); me.facing = 1; me._cd = [0.0, 0.0, 0.0]; press("p1_a3", 2)
			912: shot("hunter_mega_hook")
			940: me.position = Vector2(300, 570); me.ult_charge = 999; press("p1_ult", 2)
			1060: shot("hunter_mega_ult1")
			1120: shot("hunter_mega_ult2")
			1132: shot("hunter_mega_ult3")
			1145: shot("hunter_mega_ult4")
			1200:
				hi = 1
				start()
	else:
		match d:
			240: press("p1_shoot", 90)
			252: shot("smith_hit1")
			262: shot("smith_hit1b")
			280: shot("smith_hit2")
			300: shot("smith_hit3a")
			318: shot("smith_hit3b")
			340: me.position = Vector2(200, 570); me._cd = [0.0, 0.0, 0.0]; press("p1_a1", 2)
			360: shot("smith_leap1")
			380: shot("smith_leap2")
			392: shot("smith_leap3")
			420: me.position = Vector2(300, 570); me.facing = 1; press("p1_a2", 2)
			428: shot("smith_wall1")
			445: shot("smith_wall2")
			470: foe.position = Vector2(760, 570); press("p1_a3", 2)
			482: shot("smith_throw1")
			500: shot("smith_throw2")
			520: shot("smith_throw3")
			560:
				me.add_buff("cooldown", true)
				me._cd = [0.0, 0.0, 0.0]
			570: me.position = Vector2(300, 570); me.facing = 1; press("p1_a2", 2)
			585: shot("smith_anvil1")
			600: shot("smith_anvil2")
			630: shot("smith_anvil3")
			650: me.position = Vector2(150, 570); me.facing = 1; foe.position = Vector2(650, 570); me._cd = [0.0, 0.0, 0.0]; press("p1_a3", 2)
			672: shot("smith_mhammer1")
			695: shot("smith_mhammer2")
			720: shot("smith_mhammer3")
			745: shot("smith_mhammer4")
			770: me.position = Vector2(300, 570); foe.position = Vector2(470, 570); me.ult_charge = 999; press("p1_ult", 2)
			790: shot("smith_ult1")
			805: shot("smith_ult2")
			830: shot("smith_ult3")
			870: press("p1_shoot", 60); shot("smith_ult4")
			905: shot("smith_ult5")
			1268: shot("smith_fin1")
			1290: shot("smith_fin2")
			1320: shot("smith_fin3")
			1350: shot("smith_fin4")
			1400: hi = 2
	return false
func start():
	main._on_duel_ready("test_field", 9, 99, [hi, 1 - hi], {})
	t0 = f
