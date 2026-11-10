extends SceneTree
# Легенда РАССВЕТ в Дуэли: меч, Шаг тени, Затмение, Чёрное солнце, Осколок сердца, ульта (и МЕГА).
var main
var f := 0
var shots := "/tmp/claude-0/st/"
var p1: Player
var p2: Player
var hp0 := 0
var x0 := 0.0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String) -> void:
	Input.action_press(a)
func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "ras_%s.png" % n)
func place(dx: float) -> void:
	p1.global_position.x = 1000
	p2.global_position = Vector2(1000 + dx, p1.global_position.y)
	p1.facing = 1
	p2.facing = -1
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_right"]:
		Input.action_release(a)
	if f == 3:
		var zi := -1
		for i in Characters.LIST.size():
			if Characters.LIST[i]["name"] == "РАССВЕТ":
				zi = i
		print("rassvet index=", zi, " order=", Characters.display_order())
		main._on_duel_ready("test_buffs", 9, 99, [zi, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		print("kit=", p1.kit.get_script().get_global_name(), " abil=", p1.abilities, " hp=", p1.max_hp)
		p2.max_hp = 2000
		p2.hp = 2000
	if f < 230: return false
	var g := f - 200
	p2._protect = 0.0
	if g % 60 == 0: p1._cd = [0.0, 0.0, 0.0]
	if g < 1000: p1._protect = 2.0
	# 1. меч
	if g >= 40 and g <= 50: place(140)
	if g == 51: hp0 = p2.hp
	if g > 51 and g < 160:
		if g % 14 < 2: press("p1_shoot")
		else: Input.action_release("p1_shoot")
	if g == 90: shot("1_sword")
	if g == 160:
		Input.action_release("p1_shoot")
		print("sword: p2 ", hp0, " -> ", p2.hp)
	# 2. шаг тени
	if g >= 200 and g <= 210: place(400)
	if g == 211:
		hp0 = p2.hp
		x0 = p1.global_position.x
		press("p1_a1")
	if g == 214:
		shot("2_step")
		print("step: moved ", p1.global_position.x - x0, " behind=", p1.global_position.x > p2.global_position.x, " p2 ", hp0, " -> ", p2.hp)
	if g == 260: shot("2b_boom")
	# 3. затмение
	if g >= 300 and g <= 310: place(180)
	if g == 311: press("p1_a2")
	if g == 360: shot("3_eclipse")
	if g == 361: print("eclipse: p2 slowed=", p2._slow_t > 0.0)
	# 4. чёрное солнце
	if g >= 560 and g <= 570: place(420)
	if g == 571:
		hp0 = p2.hp
		x0 = p2.global_position.x
		press("p1_a3")
	if g == 640: shot("4_sun")
	if g == 700: print("sun: p2 ", hp0, " -> ", p2.hp, " pulled ", x0 - p2.global_position.x)
	# 5. ульта
	if g >= 760 and g <= 770: place(300)
	if g == 772:
		p1.ult_charge = 9999
		press("p1_ult")
	if g > 780 and g < 1000:
		if g % 14 < 2: press("p1_shoot")
		else: Input.action_release("p1_shoot")
		if g < 830: press("p1_jump")
		else: Input.action_release("p1_jump")
	if g == 850: shot("5_dawn")
	if g == 1150:
		Input.action_release("p1_shoot")
		print("dawn over: ulting=", p1.kit.ulting(), " fly_free=", p1.fly_free, " on_floor=", p1.is_on_floor())
	# 6. Осколок сердца
	if g == 1200:
		p1._protect = 0.0
		p1._invuln = 0.0
		p1.hp = 10
		p1.take_damage(500)
	if g == 1203:
		shot("6_shard")
		print("shard: alive=", p1.is_alive(), " hp=", p1.hp, " invuln=", p1._invuln)
	if g == 1300:
		p1._invuln = 0.0
		p1.take_damage(9999)
		print("second lethal: alive=", p1.is_alive())
	# МЕГА
	if g == 1500:
		p1.add_buff("boost")
		print("boost: mega_ab=", p1._mega_ab(), " buffs=", p1.buffs)
	if g >= 1510 and g <= 1520: place(500)
	if g == 1521:
		p1._protect = 2.0
		press("p1_a1")
	if g == 1560: shot("7_mega_step")
	if g >= 1600 and g <= 1610: place(420)
	if g == 1611: press("p1_a3")
	if g == 1680: shot("8_mega_sun")
	if g == 1760:
		p1.add_buff("cooldown")
		print("cd speed normal=", p1._cd_speed())
		p1.add_buff("cooldown")
		print("cd speed mega=", p1._cd_speed())
		p1.add_buff("boost")
		print("cd speed mega+double boost=", p1._cd_speed(), " buffs=", p1.buffs.keys())
		print("done")
		quit()
	return false
