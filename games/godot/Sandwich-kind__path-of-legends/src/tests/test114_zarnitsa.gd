extends SceneTree
# Легенда ЗАРНИЦА в Дуэли: искры, Порыв, Громоотвод, Вихрь, планирование, ульта (обычные и МЕГА).
var main
var f := 0
var shots := "/tmp/claude-0/st/"
var p1: Player
var p2: Player
var hp0 := 0
var x0 := 0.0
var y0 := 0.0
var foe_b: Bullet
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
		img.save_png(shots + "zar_%s.png" % n)
func place(dx: float) -> void:
	p1.global_position.x = 1000
	p2.global_position = Vector2(1000 + dx, p1.global_position.y)
	p1.facing = 1
	p2.facing = -1
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
func enemy_bullet() -> Bullet:
	var b := Bullet.new()
	b.shooter = p2
	b.team = p2.team
	b.direction = Vector2.LEFT
	b.speed = 500.0
	b.damage = 10
	b.size = 14.0
	b.style = "dark"
	b.position = p2.global_position + Vector2(-60, -10)
	main.world.add_child(b)
	return b
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_right"]:
		Input.action_release(a)
	if f % 100 == 99: Input.action_release("p1_jump")
	for a in []:
		Input.action_release(a)
	if f == 3:
		var zi := -1
		for i in Characters.LIST.size():
			if Characters.LIST[i]["name"] == "ЗАРНИЦА":
				zi = i
		print("zarnitsa index=", zi, " order=", Characters.display_order())
		main._on_duel_ready("test_buffs", 9, 99, [zi, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		print("kit=", p1.kit.get_script().get_global_name(), " abil=", p1.abilities, " ult_need=", p1.ult_need, " hp=", p1.max_hp)
		p2.max_hp = 2000
		p2.hp = 2000
	if f < 30: return false
	if f < 230: return false
	var g := f - 200
	p1._protect = 2.0
	p2._protect = 0.0
	if g % 60 == 0: p1._cd = [0.0, 0.0, 0.0]
	# 1. искры
	if g >= 40 and g <= 50: place(420)
	if g == 51: hp0 = p2.hp
	if g > 51 and g < 200:
		if g % 16 < 2: press("p1_shoot")
		else: Input.action_release("p1_shoot")
	if g == 70: shot("1_sparks")
	if g == 200:
		Input.action_release("p1_shoot")
		print("sparks: p2 ", hp0, " -> ", p2.hp, " hits=", p1.kit._hits)
	# 2. Порыв: отбрасывает и сдувает снаряд
	if g >= 230 and g <= 240: place(240)
	if g == 241:
		hp0 = p2.hp
		foe_b = enemy_bullet()
	if g == 243:
		press("p1_a1")
	if g == 246:
		shot("2_gale")
		print("gale: p2 vx=", p2.velocity.x, " bullet gone=", not is_instance_valid(foe_b))
	if g == 290: print("gale: p2 pushed to dx=", p2.global_position.x - p1.global_position.x, " hp ", hp0, " -> ", p2.hp)
	# 3. Громоотвод
	if g >= 330 and g <= 340: place(170)
	if g == 341:
		hp0 = p2.hp
		press("p1_a2")
	if g > 341 and g < 600: p2.global_position.x = 1000 + 230
	if g == 400: shot("3_rod")
	if g == 600: print("rod: p2 ", hp0, " -> ", p2.hp)
	# 4. Вихрь вправо и вверх
	if g >= 640 and g <= 650: place(600)
	if g == 651:
		x0 = p1.global_position.x
		press("p1_right")
		press("p1_a3")
	if g == 655: shot("4_dash")
	if g == 670: print("dash right: moved ", p1.global_position.x - x0)
	if g == 700:
		x0 = p1.global_position.x
		y0 = p1.global_position.y
	if g >= 700 and g < 790: press("p1_jump")
	if g == 706:
		press("p1_a3")
	if g == 722: print("dash up: rose ", y0 - p1.global_position.y)
	# 5. Планирование
	if g == 760:
		shot("5_glide")
		print("glide: vy=", p1.velocity.y, " gliding=", p1.kit._gliding)
	if g == 795: print("no glide: vy=", p1.velocity.y)
	# 6. Ульта
	if g >= 860 and g <= 870: place(520)
	if g == 872:
		hp0 = p2.hp
		x0 = p2.global_position.x
		p1.ult_charge = 9999
		press("p1_ult")
	if g == 940: shot("6_storm")
	if g == 1000: print("ult: p2 ", hp0, " -> ", p2.hp, " pulled ", x0 - p2.global_position.x, " ulting=", p1.kit.ulting())
	if g == 1200: print("ult over: ulting=", p1.kit.ulting())
	# МЕГА
	if g == 1250:
		p1.mega_mode = true
		p2.hp = p2.max_hp
	if g >= 1260 and g <= 1270: place(420)
	if g == 1271:
		press("p1_a1")
	if g == 1300:
		foe_b = enemy_bullet()
	if g == 1330:
		shot("7_windwall")
		var walls := get_nodes_in_group("mirror_walls").size()
		print("mega gale: walls=", walls, " bullet team=", foe_b.team if is_instance_valid(foe_b) else -1, " dir=", foe_b.direction if is_instance_valid(foe_b) else Vector2.ZERO)
	if g >= 1420 and g <= 1430: place(170)
	if g == 1431:
		hp0 = p2.hp
		press("p1_a2")
	if g == 1500: shot("8_rod_mega")
	if g >= 1600 and g <= 1610: place(800)
	if g == 1611:
		x0 = p1.global_position.x
		press("p1_right")
		press("p1_a3")
	if g == 1625:
		press("p1_right")
		press("p1_a3")
	if g == 1628: shot("9_dash2")
	if g == 1640: print("mega dash x2: moved ", p1.global_position.x - x0)
	if g >= 1700 and g <= 1710: place(500)
	if g == 1712:
		hp0 = p2.hp
		p1.ult_charge = 9999
		press("p1_ult")
	if g == 1800: shot("10_storm_mega")
	if g == 1950:
		print("mega ult: p2 ", hp0, " -> ", p2.hp)
		print("done")
		quit()
	return false
