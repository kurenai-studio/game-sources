extends SceneTree
# Легенда АССАСИН в Дуэли: вихрь клинков, бомба, прыжок с кунаями, ульта (обычная и МЕГА).
var main
var f := 0
var shots := "/tmp/claude-0/st/"
var p1: Player
var p2: Player
var hp0 := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String) -> void:
	Input.action_press(a)
func shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(shots + "asn_%s.png" % n)
func place(dx: float) -> void:
	p1.global_position.x = 1000
	p2.global_position = Vector2(1000 + dx, p1.global_position.y)
	p1.facing = 1
	p2.facing = 1
	p1.velocity = Vector2.ZERO
	p2.velocity = Vector2.ZERO
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]:
		Input.action_release(a)
	if f == 3:
		main._on_duel_ready("test_buffs", 9, 99, [9, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		print("kit=", p1.kit.get_class(), " abil=", p1.abilities, " ult_need=", p1.ult_need)
		p2.max_hp = 1000
		p2.hp = 1000
	if f < 30: return false
	p1._protect = 2.0
	if f % 60 == 0: p1._cd = [0.0, 0.0, 0.0]
	if f >= 280 and f <= 300: place(90)
	if f == 310:
		hp0 = p2.hp
		press("p1_a1")
	if f == 350: shot("1_storm")
	if f == 420:
		print("storm: p2 ", hp0, " -> ", p2.hp)
		p2.hp = p2.max_hp
	if f >= 440 and f <= 450: place(300)
	if f == 455: press("p1_a2")
	if f == 500:
		print("bomb: p2 stunned=", p2._stun_t > 0.0)
		shot("2_bomb")
	if f == 560: press("p1_a3")
	if f == 590: shot("3_leap")
	if f == 615: shot("4_kunai")
	if f >= 700 and f <= 710: place(500)
	if f == 712:
		p1.ult_charge = 9999
		press("p1_ult")
	if f == 760: print("mark_t=", p1.kit._mark_t, " ult_charge=", p1.ult_charge)
	if f == 765:
		hp0 = p2.hp
		press("p1_ult")
	if f == 790: shot("5_behind")
	if f == 800: shot("6_slash")
	if f == 840: print("ult: p2 ", hp0, " -> ", p2.hp, " p1x=", p1.global_position.x, " p2x=", p2.global_position.x)
	# МЕГА
	if f == 900:
		p1.mega_mode = true
		p2.hp = p2.max_hp
	if f >= 900 and f <= 910: place(100)
	if f == 912: press("p1_a1")
	if f == 960: shot("7_mega_storm")
	if f >= 1080 and f <= 1090: place(450)
	if f == 1092:
		p1.ult_charge = 9999
		press("p1_ult")
	if f == 1140:
		hp0 = p2.hp
		press("p1_ult")
	if f == 1165: shot("8_clones")
	if f == 1185: shot("9_mega_slash")
	if f == 1260:
		print("mega ult: p2 ", hp0, " -> ", p2.hp, " shadow=", p1.kit._shadow_t, " move_mult=", p1.move_mult)
	if f >= 1265 and f <= 1300: press("p1_right")
	if f == 1290: shot("10_shadow_form")
	if f == 1301: Input.action_release("p1_right")
	if f == 1340: return true
	return false
