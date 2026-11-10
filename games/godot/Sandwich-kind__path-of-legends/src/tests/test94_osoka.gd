extends SceneTree
# Легенда ОСОКА в Дуэли: комья тины, Нырок, Пузырь, Язык Квака, ульта (обычные и МЕГА).
var main
var f := 0
var shots := "/tmp/claude-0/st/"
var p1: Player
var p2: Player
var hp0 := 0
var y0 := 0.0
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
		img.save_png(shots + "oso_%s.png" % n)
func place(dx: float) -> void:
	p1.global_position.x = 1000
	p2.global_position = Vector2(1000 + dx, p1.global_position.y)
	p1.facing = 1
	p2.facing = -1
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
func puddles() -> int:
	var n := 0
	for c in main.world.get_children():
		if c is SwampBits.MudPuddle and c.team == p1.team:
			n += 1
	return n
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_right"]:
		Input.action_release(a)
	if f == 3:
		main._on_duel_ready("test_buffs", 9, 99, [11, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		print("kit=", p1.kit.get_script().get_global_name(), " abil=", p1.abilities, " ult_need=", p1.ult_need, " hp=", p1.max_hp)
		p2.max_hp = 1000
		p2.hp = 1000
	if f < 30: return false
	p1._protect = 2.0
	if f % 60 == 0: p1._cd = [0.0, 0.0, 0.0]
	# 1. комья тины
	if f >= 40 and f <= 50: place(380)
	if f == 51: hp0 = p2.hp
	if f > 51 and f < 200:
		if f % 30 < 2: press("p1_shoot")
		else: Input.action_release("p1_shoot")
	if f == 120: shot("1_lumps")
	if f == 200:
		Input.action_release("p1_shoot")
		print("lumps: p2 ", hp0, " -> ", p2.hp, " own puddles=", puddles())
	# своя трясина: встать в свою лужу
	if f == 205:
		var pud := SwampBits.MudPuddle.new()
		pud.width = 200.0
		pud.life = 3.0
		pud.team = p1.team
		pud.position = Vector2(1000, p1.global_position.y + p1.body_size.y / 2)
		main.world.add_child(pud)
	if f >= 205 and f < 230: p1.global_position.x = 1000
	if f == 230: print("mud bonus: move_mult=", p1.move_mult, " bonus=", p1.bonus_mult, " slowed=", p1._slow_t > 0.0)
	# 2. Нырок
	if f >= 260 and f <= 270: place(160)
	if f == 271:
		hp0 = p2.hp
		press("p1_a1")
	if f > 271 and f < 300: press("p1_right")
	if f == 285:
		shot("2_dive")
		print("dive: invuln=", p1._invuln > 0.0, " rig alpha=", p1._rig_root.modulate.a if p1._rig_root else -1.0)
	if f == 350: shot("3_geyser")
	if f == 352: print("geyser: p2 ", hp0, " -> ", p2.hp, " p2 vy=", p2.velocity.y)
	# 3. Пузырь
	if f >= 420 and f <= 430: place(320)
	if f == 431:
		hp0 = p2.hp
		press("p1_a2")
	if f == 450: shot("4_bubble")
	if f == 490: shot("5_cloud")
	if f == 600: print("bubble: p2 ", hp0, " -> ", p2.hp)
	# 4. Язык
	if f >= 640 and f <= 650: place(470)
	if f == 651:
		hp0 = p2.hp
		press("p1_a3")
	if f == 660: shot("6_tongue")
	if f == 700: print("tongue: p2 dx=", p2.global_position.x - p1.global_position.x, " stunned=", p2._stun_t > 0.0, " hp ", hp0, " -> ", p2.hp)
	# 5. Ульта
	if f >= 760 and f <= 770: place(260)
	if f == 772:
		hp0 = p2.hp
		p1.ult_charge = 9999
		press("p1_ult")
	if f == 830: shot("7_wake")
	if f > 772 and f < 1200 and f % 20 == 0:
		p2.global_position.x = p1.global_position.x + 260
	if f == 900: print("wake: p2 slowed=", p2._slow_t > 0.0, " no_jump=", p2._no_jump_t > 0.0, " p1 move_mult=", p1.move_mult, " ulting=", p1.kit.ulting())
	if f == 1200: print("wake: p2 ", hp0, " -> ", p2.hp, " ulting=", p1.kit.ulting())
	# МЕГА
	if f == 1250:
		p1.mega_mode = true
		p2.hp = p2.max_hp
	if f >= 1260 and f <= 1270: place(300)
	if f == 1271:
		hp0 = p2.hp
		press("p1_a2")
	if f == 1320:
		y0 = p2.global_position.y
	if f == 1380:
		print("mega bubble: captured frozen=", p2.frozen, " lifted=", y0 - p2.global_position.y, " stunned=", p2._stun_t > 0.0)
		shot("8_trap")
	if f == 1450: print("mega bubble after: frozen=", p2.frozen, " hp ", hp0, " -> ", p2.hp)
	if f >= 1460 and f <= 1470: place(420)
	if f == 1471:
		hp0 = p2.hp
		press("p1_a3")
	if f == 1530: shot("9_frog")
	if f == 1600: print("mega tongue: p2 ", hp0, " -> ", p2.hp)
	if f >= 1640 and f <= 1650: place(380)
	if f == 1652:
		hp0 = p2.hp
		p1.ult_charge = 9999
		press("p1_ult")
	if f > 1652 and f < 2000 and f % 20 == 0:
		p2.global_position.x = p1.global_position.x + 380
	if f == 1760: shot("10_shadow")
	if f == 1745: shot("10a_shadow")
	if f == 1900: print("mega wake: p2 ", hp0, " -> ", p2.hp)
	if f >= 2000 and f <= 2010: place(150)
	if f == 2011:
		hp0 = p2.hp
		press("p1_a1")
	if f == 2160:
		print("mega dive: p2 ", hp0, " -> ", p2.hp)
		shot("11_mega_dive")
	if f >= 2200 and f <= 2210: place(380)
	if f == 2211: hp0 = p2.hp
	if f > 2211 and f < 2400:
		if f % 30 < 2: press("p1_shoot")
		else: Input.action_release("p1_shoot")
	if f == 2280: shot("12_lumps")
	if f == 2400:
		Input.action_release("p1_shoot")
		print("lumps: p2 ", hp0, " -> ", p2.hp, " own puddles=", puddles())
	if f == 2420:
		print("DONE")
		return true
	return false
