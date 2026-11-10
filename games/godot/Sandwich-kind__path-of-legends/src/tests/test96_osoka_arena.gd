extends SceneTree
# Осока на Арене: МЕГА-пузырь глотает до 3 врагов, к боссу прилипает; язык ловит двоих; ульта с руками.
var main
var f := 0
var t0 := -1
var arena
var p: Player
var bots: Array = []
var boss: Player
var hp0 := 0
var y0 := {}
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png("/tmp/claude-0/st/osa_%s.png" % n)
func line_up(dxs: Array) -> void:
	for i in bots.size():
		var b: Player = bots[i]
		if not is_instance_valid(b):
			continue
		if i < dxs.size():
			b.global_position = Vector2(p.global_position.x + dxs[i], p.global_position.y + p.body_size.y / 2 - b.body_size.y / 2 - 1)
			b.velocity = Vector2.ZERO
		else:
			b.global_position = Vector2(200, p.global_position.y)
func _physics_process(_d: float) -> bool:
	f += 1
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]:
		Input.action_release(a)
	if f == 3:
		main.sel = [11, 0]
		main.start_arena(false, 2)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null: return false
	if t0 < 0:
		if arena._state == "fight" and not arena.players[0].frozen:
			t0 = f
			p = arena.players[0]
			arena._queue = []
			arena._spawn_t = 999.0
			for b in arena._alive.duplicate():
				if is_instance_valid(b): b.queue_free()
			arena._alive.clear()
			for k in 3:
				var b := Bots.create("grunt", 2, Vector2(400 + k * 60, 800), p, 2600.0)
				b.max_hp = 2000
				b.hp = 2000
				main.world.add_child(b)
				arena._alive.append(b)
				bots.append(b)
			arena._queue = ["grunt"]
		return false
	var k := f - t0
	p._protect = 2.0
	p.global_position.x = 900.0
	p.facing = 1
	for b in bots:
		if is_instance_valid(b):
			b.frozen = true
			b.hp = maxi(b.hp, 1500)
	# 1. МЕГА-пузырь глотает троих
	if k < 20: line_up([200, 250, 300])
	if k == 20:
		p.mega_mode = true
		p._cd = [0.0, 0.0, 0.0]
		Input.action_press("p1_a2")
	if k == 30:
		for b in bots: y0[b] = b.global_position.y
	if k == 150:
		var caught := 0
		for b in bots:
			if b.global_position.y < y0[b] - 20.0: caught += 1
		print("mega bubble arena: lifted ", caught, " of 3")
		shot("1_trap3")
	# 2. язык ловит двоих (без МЕГА)
	if k >= 200 and k < 220: line_up([330, 400, -600])
	if k == 220:
		p.mega_mode = false
		p._cd = [0.0, 0.0, 0.0]
		Input.action_press("p1_a3")
	if k == 228: shot("2_tongue2")
	if k == 270:
		print("tongue arena: dx = ", (bots[0].global_position.x - p.global_position.x), ", ", (bots[1].global_position.x - p.global_position.x))
	# 3. босс: МЕГА-пузырь прилипает
	if k == 300:
		boss = Bots.create("gladiator", 45, Vector2(1200, 800), p, 2600.0)
		boss.max_hp = 9999
		boss.hp = 9999
		main.world.add_child(boss)
		arena._alive.append(boss)
	if k > 300 and k < 330 and is_instance_valid(boss):
		boss.frozen = true
		boss.global_position = Vector2(p.global_position.x + 280, p.global_position.y + p.body_size.y / 2 - boss.body_size.y / 2 - 1)
		line_up([-700, -760, -820])
	if k == 330:
		hp0 = boss.hp
		p.mega_mode = true
		p._cd = [0.0, 0.0, 0.0]
		Input.action_press("p1_a2")
	if k > 330 and k < 520 and is_instance_valid(boss):
		boss.frozen = true
	if k == 360: shot("3_boss_bubble")
	if k == 520:
		print("boss bubble: boss lifted? y=", boss.global_position.y, " hp ", hp0, " -> ", boss.hp, " frozen_by_bubble=", false)
		boss.queue_free()
	# 4. ульта на Арене
	if k >= 560 and k < 580: line_up([250, 420, -300])
	if k == 580:
		p.mega_mode = false
		p.ult_charge = 9999
		Input.action_press("p1_ult")
	if k > 580 and k < 1150 and k % 20 == 0: line_up([250, 420, -300])
	if k == 700: shot("4_wake")
	if k == 760: shot("5_wake_hand")
	if k == 900:
		var rooted := 0
		for b in bots:
			if b._root_t > 0.0: rooted += 1
		print("arena wake: dur=", p.kit._wake.dur if is_instance_valid(p.kit._wake) else -1.0, " rooted now=", rooted, " slowed=", bots[0]._slow_t > 0.0)
		for b in bots:
			print("   bot dx=", b.global_position.x - p.global_position.x, " in=", p.kit._wake.is_in(b) if is_instance_valid(p.kit._wake) else false, " slow_t=", b._slow_t, " feet=", b.global_position.y + b.body_size.y / 2, " p_feet=", p.global_position.y + p.body_size.y / 2)
	if k == 1300:
		print("DONE")
		return true
	return false
