extends SceneTree
var main
var f := 0
var hi := -1
var t0 := 0
var held := {}
const HEROES := [0, 6, 1, 8]
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	if f == 4:
		Save.unlock_all_heroes()
		hi = 0
		start()
	if hi < 0 or hi >= HEROES.size():
		return hi >= HEROES.size()
	var d := f - t0
	var me: Player = main.duel_players[0]
	var foe: Player = main.duel_players[1]
	me._protect = 1.0
	foe._protect = 0.0
	if foe.hp < 60: foe.hp = foe.max_hp
	if d == 200:
		me.position = Vector2(300, 570)
		me.facing = 1
		foe.position = Vector2(840, 570)
	var h: int = HEROES[hi]
	match h:
		0:
			if d == 230: me.ult_charge = 999; press("p1_ult", 2)
			if d in [350, 370, 390, 420]: shot("fx_hunter_%d" % d)
		6:
			if d == 230: me.ult_charge = 999; press("p1_ult", 2)
			if d in [262, 275, 282, 300]: shot("fx_mortis_%d" % d)
		1:
			if d == 230: press("p1_a2", 2)
			if d == 236: shot("fx_smith_fall")
			if d == 270: shot("fx_smith_wall")
			if d == 280: me.position = Vector2(300, 570); press("p1_right", 100)
			if d == 300: press("p1_jump", 3)
			if d == 330: press("p1_jump", 3)
			if d in [315, 345, 380]: shot("fx_smith_climb_%d" % d)
		8:
			if d == 205: foe.position = Vector2(420, 570)
			if d == 230: press("p1_shoot", 110)
			for k in 12:
				if d == 236 + k * 8: shot("fx_sam_%02d" % k)
			if d == 380: me._cd = [0.0, 0.0, 0.0]; press("p1_a1", 2)
			if d in [390, 397, 403, 412]: shot("fx_sam_wide_%d" % d)
	if d == 440:
		hi += 1
		if hi < HEROES.size():
			start()
	return false
func start():
	main._on_duel_ready("test_field", 9, 99, [HEROES[hi], 1], {})
	t0 = f
