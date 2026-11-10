extends SceneTree
# Трясинный Владыка: ищем резкие «телепорты» (скачок по x больше 250 за кадр).
var main
var f := 0
var arena
var boss: Player
var p: Player
var t0 := -1
var last_x := 0.0
var jumps := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
		main.start_arena(OS.get_environment("COOP") == "1", int(OS.get_environment("WAVE")) if OS.get_environment("WAVE") != "" else 60)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	if t0 < 0:
		if arena._boss and is_instance_valid(arena._boss) and not arena._boss.frozen and not arena._boss.cutscene_shield:
			boss = arena._boss
			p = arena.players[0]
			t0 = f
			last_x = boss.global_position.x
		return false
	var k := f - t0
	for pl in arena.players:
		pl._protect = 1.0
		pl.hp = pl.max_hp
	if OS.get_environment("WAVE") == "": boss.hp = boss.max_hp
	# герой бегает по правой половине и прыгает
	for a in ["p1_left", "p1_right", "p1_jump"]:
		Input.action_release(a)
	Input.action_press("p1_right" if (k / 120) % 2 == 0 else "p1_left")
	if k % 90 < 6:
		Input.action_press("p1_jump")
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult", "p1_shoot"]:
		Input.action_release(a)
	if k % 150 == 0:
		p._cd = [0.0, 0.0, 0.0]
		p.ult_charge = 9999
		Input.action_press(["p1_a1", "p1_a2", "p1_a3", "p1_ult"][(k / 150) % 4])
	if k % 30 < 15:
		Input.action_press("p1_shoot")
	var x := boss.global_position.x
	if absf(x - last_x) > 250.0:
		jumps += 1
		var br = boss.get_node_or_null("RaidBrain")
		print("JUMP k=", k, " from ", int(last_x), " to ", int(x), " hero x=", int(p.global_position.x), " target=", boss.target.name if is_instance_valid(boss.target) else "none",
				" hide=", br._hide_kind if br else "?", " goal=", int(br._goal_x) if br else -1)
	last_x = x
	if k % 600 == 0:
		print("k=", k, " boss x=", int(x), " hero x=", int(p.global_position.x))
	if k == 3600:
		print("jumps=", jumps)
		return true
	return false
