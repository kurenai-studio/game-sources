extends SceneTree
# Волны 51–60: Жуткий лес и Болото, Ведьма и Трясинный Владыка.
var main
var f := 0
var arena
var waves := ([55, 60] if OS.get_environment("BOSS") != "" else [51, 53, 55, 56, 58, 60]) if OS.get_environment("WAVES") == "" else Array(OS.get_environment("WAVES").split(",")).map(func(x): return int(x))
var wi := -1
var t0 := 0
var shots := "/tmp/claude-0/st/"
var seen := {}
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _next() -> void:
	wi += 1
	t0 = f
	main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
	main.start_arena(false, waves[wi])
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3: _next()
	if arena == null or not is_instance_valid(arena): return false
	var lt := f - t0
	for p in arena.players:
		p._protect = 5.0
		p.hp = p.max_hp
	for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]: Input.action_release(a)
	if lt % 90 == 0:
		var acts := ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]
		Input.action_press(acts[(lt / 90) % 4])
		arena.players[0]._cd = [0.0, 0.0, 0.0]
		arena.players[0].ult_charge = 9999
		arena.players[0].mega_mode = (lt / 360) % 2 == 1
	if lt % 40 < 25: Input.action_press("p1_shoot")
	else: Input.action_release("p1_shoot")
	for b in arena._alive:
		if is_instance_valid(b):
			var k: String = b.get_meta("kind", "")
			if not seen.has(k):
				seen[k] = true
				print("wave ", arena.wave, " spawned ", k, " hp=", b.max_hp)
	if lt == 60 * 9 or lt == 60 * 16 or lt == 60 * 24:
		root.get_viewport().get_texture().get_image().save_png(shots + "w%d_%d.png" % [waves[wi], lt / 60])
		print("w", waves[wi], " t=", lt / 60, " state=", arena._state, " alive=", arena._alive.size(), " boss=", arena._boss != null and is_instance_valid(arena._boss), " q=", arena._queue.size())
	if lt == 60 * 26:
		# добить всех: проверка раскола, золота и смерти боссов
		for b in arena._alive.duplicate():
			if is_instance_valid(b) and b.is_alive():
				b.take_damage(99999, arena.players[0])
	if lt == 60 * 30:
		print("w", waves[wi], " after kill alive=", arena._alive.size(), " state=", arena._state, " wave=", arena.wave)
		for b in arena._alive:
			if is_instance_valid(b):
				print("   left: ", b.get_meta("kind", "?"), " hp=", b.hp, " alive=", b.is_alive(), " inv=", b.invulnerable, " vis=", b.visible, " pos=", b.position)
		if wi + 1 >= waves.size():
			print("SEEN ", seen.keys())
			return true
		_next()
	return false
