extends SceneTree
# Появление и смерть боссов: снимки во время кат-сцены и после последнего удара.
var main
var f := 0
var arena
var waves := [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60]
var wi := -1
var t0 := 0
var cut0 := -1
var fight0 := -1
var dead0 := -1
var kills := 0
var shots := "/tmp/claude-0/st/"

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	if OS.get_environment("WAVES") != "":
		waves = Array(OS.get_environment("WAVES").split(",")).map(func(x): return int(x))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + "bs_w%d_%s.png" % [waves[wi], n])

func _next() -> bool:
	wi += 1
	if wi >= waves.size():
		return false
	t0 = f
	cut0 = -1
	fight0 = -1
	dead0 = -1
	kills = 0
	main.sel = [0, 0]
	main.start_arena(OS.get_environment("COOP") == "1", waves[wi])
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
	return true

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_next()
	if arena == null or not is_instance_valid(arena):
		return false
	for p in arena.players:
		p._protect = 1.0
		p.hp = p.max_hp
	# все, кроме босса, сразу погибают
	for b in arena._alive.duplicate():
		if is_instance_valid(b) and b.is_alive() and b != arena._boss and not Bots.is_boss(b.get_meta("kind")):
			b.take_damage(99999)
	for t in arena._totems:                      # тотемы Энта ломаем сразу, иначе он неуязвим
		if is_instance_valid(t) and t.is_alive():
			t.invulnerable = false
			t.take_damage(99999)
	var lt := f - t0
	if cut0 < 0 and arena._cut_cam != null and is_instance_valid(arena._cut_cam):
		cut0 = f
	if cut0 >= 0 and fight0 < 0:
		var k := f - cut0
		if k in [60, 120, 170, 230]:
			shot("in_%d" % k)
		if arena._boss and is_instance_valid(arena._boss) and not arena._boss.frozen and not arena._boss.cutscene_shield and arena._cut_cam == null:
			fight0 = f
	if fight0 >= 0 and dead0 < 0 and f - fight0 == 60:
		var b: Player = arena._boss
		if b and is_instance_valid(b):
			b.take_damage(99999999, arena.players[0])
			kills += 1
			if b.is_alive():
				print("w", waves[wi], ": boss survived lethal hit (вторая фаза)")
				fight0 = f + 330                  # подождать пробуждение
			else:
				dead0 = f
	if dead0 >= 0:
		var k2 := f - dead0
		if k2 in [8, 40, 90, 140, 200]:
			shot("die_%d" % k2)
		if k2 == 230:
			print("w", waves[wi], ": done, state=", arena._state)
			if not _next():
				print("DONE")
				return true
	if lt > 60 * (70 if waves[wi] == 80 else 40):
		print("w", waves[wi], ": TIMEOUT cut0=", cut0, " fight0=", fight0)
		if not _next():
			return true
	return false
