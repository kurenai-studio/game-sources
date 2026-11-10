extends SceneTree
# Легенда ПРИЗМА в Дуэли: зеркало отражает пули, столбы, приманка, ульта (обычная,
# через зеркало, МЕГА).
var main
var f := 0
var shots := "/tmp/claude-0/st/"
var p1: Player
var p2: Player
var hp_before := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String) -> void:
	Input.action_press(a)
func shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(shots + "prism_%s.png" % n)
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]:
		Input.action_release(a)
	if f == 3:
		main._on_duel_ready("test_buffs", 9, 99, [10, 2], {})
	if f == 30:
		p1 = main.duel_players[0]
		p2 = main.duel_players[1]
		print("p1 kit=", p1.kit, " ult_need=", p1.ult_need, " abil=", p1.abilities)
	if f >= 30 and f < 1640:
		p1._protect = 2.0
		if f % 60 == 0:
			p1._cd = [0.0, 0.0, 0.0]
	if (f >= 280 and f <= 315) or (f >= 940 and f <= 950):
		p1.global_position.x = 1000
		p2.global_position.x = 1450
		p1.facing = 1
		p2.facing = -1
		p1.velocity = Vector2.ZERO
		p2.velocity = Vector2.ZERO
		if f == 280: print("pos y floor test: p1=", p1.global_position, " p2=", p2.global_position)
	# P2 стреляет в P1 — пули должны вернуться
	if f > 330 and f < 440:
		p2.facing = -1
		press("p2_shoot")
	elif f == 440:
		Input.action_release("p2_shoot")
	if f == 325:
		hp_before = p2.hp
		press("p1_a1")
	if f == 365: shot("1_mirror")
	if f == 450:
		print("mirror: p2 hp ", hp_before, " -> ", p2.hp, " walls=", root.get_tree().get_nodes_in_group("mirror_walls").size())
		p2.hp = p2.max_hp
	if f == 480: press("p1_a2")
	if f == 502: shot("2_pillar")
	if f == 570: press("p1_a3")
	if f == 580:
		print("decoys=", root.get_tree().get_nodes_in_group("decoys").size(), " p1x=", p1.global_position.x)
		shot("3_refract")
	if f == 660:
		p1.global_position.x = 900
		p1.facing = 1
		p2.hp = p2.max_hp
		p1.ult_charge = 9999
		press("p1_ult")
	if f == 710: shot("4_ult_prep")
	if f == 780:
		shot("5_ult_laser")
		print("ult laser: p2 hp ", p2.hp, "/", p2.max_hp, " move_mult=", p1.move_mult)
	if f == 800: press("p1_a1")
	if f == 840:
		shot("6_ult_amp")
		print("ult amp: p2 hp ", p2.hp)
	if f == 880:
		print("after ult move_mult=", p1.move_mult)
	if f == 930:
		p1.mega_mode = true
		p2.hp = p2.max_hp
	if f == 960: press("p1_a2")
	if f == 1030: shot("7_mega_pillars")
	if f == 1040:
		var n := 0
		for c in p1.get_parent().get_children():
			if c is Destructible and c.has_meta("prism_pillar"): n += 1
		print("mega pillars=", n, " facing=", p1.facing)
	if f == 1060: press("p1_a3")
	if f == 1070: print("mega crust=", p1.crust)
	if f == 1140:
		p1.global_position.x = 700
		p1.facing = 1
		p1.ult_charge = 9999
		press("p1_ult")
	if f == 1250:
		shot("8_mega_ult")
	if f == 1300:
		p1.mega_mode = true
		p1.kit.use("crystal_pillar")
	if f == 1360:
		var n2 := 0
		for c in p1.get_parent().get_children():
			if c is Destructible and c.has_meta("prism_pillar"): n2 += 1
		print("direct mega pillars=", n2)
		shot("9_mega_pillars")
	if f == 1540:
		return true
	return false
