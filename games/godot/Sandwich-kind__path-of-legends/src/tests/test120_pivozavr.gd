extends SceneTree
# Легенда ПИВОЗАВР в Дуэли: меч, Шаг тени, Затмение, Чёрное солнце, Осколок сердца, ульта (и МЕГА).
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
		img.save_png(shots + "pivo_%s.png" % n)
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
			if Characters.LIST[i]["name"] == "ПИВОЗАВР":
				zi = i
		print("pivo index=", zi, " order=", Characters.display_order())
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
	# 1. крышки
	if g >= 40 and g <= 50: place(420)
	if g == 51: hp0 = p2.hp
	if g > 51 and g < 200:
		if g % 12 < 2: press("p1_shoot")
		else: Input.action_release("p1_shoot")
	if g == 80: shot("1_caps")
	if g == 200:
		Input.action_release("p1_shoot")
		print("caps: p2 ", hp0, " -> ", p2.hp, " burn=", p2._burn_t > 0.0, " poison=", p2._poison_t > 0.0, " slow=", p2._slow_t > 0.0)
	# 2. бутылка
	if g >= 240 and g <= 250: place(330)
	if g == 251:
		hp0 = p2.hp
		press("p1_a1")
	if g == 290: shot("2_bottle")
	if g == 330:
		shot("2b_puddle")
		print("bottle: p2 ", hp0, " -> ", p2.hp, " slip=", p2.slip_t > 0.0)
	# 3. напиток
	if g == 400:
		p1.hp = 60
		press("p1_a2")
	if g == 420:
		shot("3_drink")
		print("drink: hp=", p1.hp, " drink_t=", snappedf(p1.kit._drink_t, 0.1))
	# 4. отрыжка
	if g >= 520 and g <= 530: place(260)
	if g == 531:
		hp0 = p2.hp
		press("p1_a3")
	if g == 600: shot("4_burp")
	if g == 700: print("burp: p2 ", hp0, " -> ", p2.hp, " poison=", p2._poison_t > 0.0)
	# 5. ульта
	if g >= 760 and g <= 770: place(500)
	if g == 772:
		hp0 = p2.hp
		p1.ult_charge = 9999
		press("p1_ult")
	if g == 840: shot("5_kids")
	if g == 880: shot("5b_kids")
	if g == 1000: print("kids: p2 ", hp0, " -> ", p2.hp)
	# МЕГА
	if g == 1050:
		p1.add_buff("boost")
		p2.hp = p2.max_hp
	if g >= 1060 and g <= 1070: place(450)
	if g == 1071: press("p1_a1")
	if g == 1120: shot("6_mega_bottles")
	if g >= 1200 and g <= 1210: place(260)
	if g == 1211: press("p1_a3")
	if g == 1355: shot("7_mega_burp")
	if g >= 1400 and g <= 1410: place(600)
	if g == 1411:
		p1.add_buff("boost")
		p1.ult_charge = 9999
		press("p1_ult")
	if g == 1500: shot("8_mega_kids")
	if g == 1650: shot("8b_mega_kids")
	if g == 1700:
		print("done")
		quit()
	return false
