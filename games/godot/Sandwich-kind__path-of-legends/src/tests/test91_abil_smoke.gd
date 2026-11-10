extends SceneTree
# Все легенды: каждая способность (обычная и МЕГА) в Дуэли и на Арене.
# Ищем ошибки скриптов и сравниваем, сколько всего появилось в мире после применения.
var main
var f := 0
var heroes := [0, 1, 4, 5, 6, 7, 8, 9, 10]
var hi := 0
var phase := "duel"          # duel → arena → следующий герой
var t0 := 0
var arena
var p: Player
var foe: Player
var counts := {}
var acts := ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]
var base_n := 0

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	if OS.get_environment("HEROES") != "":
		heroes = Array(OS.get_environment("HEROES").split(",")).map(func(x): return int(x))

func _start() -> void:
	t0 = f
	p = null
	foe = null
	arena = null
	var h: int = heroes[hi]
	if phase == "duel":
		main._on_duel_ready("arena_eerie" if hi % 2 == 0 else "arena_swamp", 3, 99, [h, 0], {})
	else:
		main.sel = [h, 0]
		main.start_arena(false, 3)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n

func _count() -> int:
	var n := 0
	for c in main.world.get_children():
		if not (c is CanvasLayer):
			n += 1 + c.get_child_count()
	return n

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_start()
	if f < 4:
		return false
	var lt := f - t0
	if lt < 260:
		return false
	if p == null:
		for n in main.world.get_children():
			if n is Player and not n.is_bot and n.prefix == "p1":
				p = n
		for n in main.world.get_children():
			if n is Player and n != p and n.team != p.team:
				foe = n
		if phase == "arena" and arena:
			arena._spawn_t = 999.0
	if p == null:
		return false
	p._protect = 5.0
	p.hp = p.max_hp
	if phase == "arena" and arena:
		arena._queue = ["grunt"] if arena._queue.is_empty() else arena._queue
		arena._spawn_t = maxf(arena._spawn_t, 5.0)
		foe = null
		for b in arena._alive:
			if is_instance_valid(b) and b.is_alive():
				foe = b
				break
		if foe == null and lt % 120 == 0:
			arena._spawn("grunt")
	if is_instance_valid(foe):
		foe.hp = foe.max_hp
		foe.frozen = true
		foe.global_position = p.global_position + Vector2(260 * p.facing, 0)
	var k := lt - 260
	for a in acts:
		Input.action_release(a)
	var slot := (k / 70) % 4
	var mega := (k / 280) % 2 == 1
	if k % 70 == 0 and k < 560:
		p._cd = [0.0, 0.0, 0.0]
		p.ult_charge = 9999
		p.mega_mode = mega
		base_n = _count()
		Input.action_press(acts[slot])
	if k % 70 == 30 and k < 560:
		var key := "%d %s %s%s" % [heroes[hi], phase, ["Q", "E", "C", "ULT"][slot], " MEGA" if mega else ""]
		counts[key] = _count() - base_n
	if k % 40 < 20:
		Input.action_press("p1_shoot")
	else:
		Input.action_release("p1_shoot")
	if k >= 640:
		for a in acts:
			Input.action_release(a)
		Input.action_release("p1_shoot")
		if phase == "duel":
			phase = "arena"
		else:
			phase = "duel"
			hi += 1
			if hi >= heroes.size():
				var keys := counts.keys()
				keys.sort()
				for key in keys:
					print(key, " -> +", counts[key])
				print("DONE")
				return true
		main.show_menu()
		_start()
	return false
