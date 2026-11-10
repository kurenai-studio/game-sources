extends SceneTree
# Скриншоты Солдата и Самурая, Лавка и кнопка МЕГА
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
	for n in main.get_children():
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
		4:
			Save.data["gold"] = 1000
			Save.data["bought"] = []
			Save.data["megas"] = []
			Characters.mega_on = [false, false]
		5: main._on_mode_chosen("shop")
		90: shot("k0_shop_heroes")
		92:
			var sh = find(ShopScreen)
			print("shop found ", sh != null)
			sh._open_offer(0)
		100: shot("k1_offer")
		102:
			var sh = find(ShopScreen)
			sh._buy(sh._offers[0])
			print("gold after hero ", Save.gold(), " owns soldier ", Save.owns_hero("СОЛДАТ"))
			sh._buy({"kind": "hero", "idx": 8, "price": 300})
		108: shot("k2_bought")
		110: find(ShopScreen)._select(1)
		200: shot("k3_shop_mega")
		202:
			var sh = find(ShopScreen)
			sh._open_offer(7)
		210: shot("k4_mega_offer")
		212:
			var sh = find(ShopScreen)
			sh._buy(sh._offers[7])
			print("gold after mega ", Save.gold(), " mega soldier ", Save.has_mega("СОЛДАТ"))
		220:
			main.show_duel_setup()
		224:
			var ds = find(DuelSetup)
			ds._choose_map("test_field", false)
			ds.sel = [7, 8]
			ds._show_picker()
		280: shot("k5_picker_mega_off")
		282: ds_picker()._toggle_mega(0)
		290: shot("k6_picker_mega_on")
		292:
			Characters.mega_on = [false, false]
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
	var tag := "soldier" if hi == 0 else "samurai"
	if d == 200:
		me.position = Vector2(300, 570)
		foe.position = Vector2(760 if hi == 0 else 520, 570)
		me.facing = 1
	if d == 230: shot("%s_idle" % tag)
	if hi == 0:
		match d:
			240: me.position = Vector2(150, 570); press("p1_right", 30)
			258: shot("soldier_run")
			280: me.position = Vector2(150, 570); press("p1_right", 40); press("p1_shoot", 40)
			300: shot("soldier_shootwalk")
			330: me.position = Vector2(300, 570); me.facing = 1; press("p1_a1", 2)
			334: shot("soldier_pistol1")
			342: shot("soldier_pistol2")
			380: me.position = Vector2(200, 570); press("p1_a2", 2)
			386: shot("soldier_roll1")
			392: shot("soldier_roll2")
			430: shot("soldier_roll3")
			440: me.position = Vector2(300, 570); me.facing = 1; press("p1_a3", 2)
			448: shot("soldier_knife1")
			455: shot("soldier_knife2")
			480: me.ult_charge = 999; press("p1_ult", 2)
			500: shot("soldier_ult1")
			560: shot("soldier_ult2")
			650: shot("soldier_ult3")
			672: shot("soldier_ult4")
			684: shot("soldier_ult5")
			700: shot("soldier_ult6")
			760: me.mega_mode = true; me._cd = [0.0, 0.0, 0.0]; me.position = Vector2(300, 570); me.facing = 1
			770: press("p1_a1", 2)
			782: shot("soldier_mpistol1")
			803: shot("soldier_mpistol2")
			840: me.position = Vector2(150, 570); me.facing = 1; press("p1_a2", 2)
			846: shot("soldier_run1")
			866: shot("soldier_run2")
			900: shot("soldier_run3")
			906: shot("soldier_run4")
			930: me.position = Vector2(300, 570); me.facing = 1; press("p1_a3", 2)
			948: shot("soldier_kbomb1")
			1004: shot("soldier_kbomb2")
			1012: shot("soldier_kbomb3")
			1030: me.ult_charge = 999; press("p1_ult", 2)
			1130: shot("soldier_mult1")
			1180: shot("soldier_mult2")
			1240: shot("soldier_mult3")
			1300: shot("soldier_mult4")
			1340:
				hi = 1
				start()
	else:
		match d:
			240: press("p1_shoot", 75)
			245: shot("samurai_cut1")
			259: shot("samurai_cut2")
			275: shot("samurai_cut3")
			291: shot("samurai_cut4")
			306: shot("samurai_cut5a")
			312: shot("samurai_cut5b")
			340: me.position = Vector2(200, 570); me.facing = 1; press("p1_a1", 2)
			356: shot("samurai_wave1")
			368: shot("samurai_wave2")
			390: press("p1_a2", 2)
			398: shot("samurai_shuriken")
			420: me.position = Vector2(400, 570); me.facing = 1; press("p1_a3", 2)
			426: shot("samurai_dash1")
			434: shot("samurai_dash2")
			470: shot("samurai_dash3")
			500: me.position = Vector2(300, 570); me.facing = 1; me.ult_charge = 999; press("p1_ult", 2)
			515: shot("samurai_ult1")
			545: shot("samurai_ult2")
			560: press("p1_shoot", 40)
			568: shot("samurai_ult3")
			590: shot("samurai_ult4")
			640: me.mega_mode = true; me._cd = [0.0, 0.0, 0.0]; me.position = Vector2(300, 570); foe.position = Vector2(420, 570)
			650: press("p1_a1", 2)
			670: shot("samurai_flurry1")
			700: shot("samurai_flurry2")
			728: shot("samurai_flurry3")
			760: press("p1_a2", 2)
			768: shot("samurai_mshuriken")
			790: me.position = Vector2(300, 570); me.facing = 1; press("p1_a3", 2)
			793: shot("samurai_tp1")
			800: shot("samurai_tp2")
			1100: me.position = Vector2(300, 570); foe.position = Vector2(430, 570); me.ult_charge = 999; press("p1_ult", 2)
			1150: shot("samurai_mult1")
			1160: press("p1_shoot", 30)
			1172: shot("samurai_mult2")
			1200: me._cd = [0.0, 0.0, 0.0]; press("p1_a2", 2)
			1208: shot("samurai_mult3")
			1240: press("p1_a1", 2)
			1262: shot("samurai_mult4")
			1300: hi = 2
	return false
func ds_picker():
	var ds = find(DuelSetup)
	return ds._picker
func start():
	main._on_duel_ready("test_field", 9, 99, [7 + hi, 1], {})
	t0 = f
