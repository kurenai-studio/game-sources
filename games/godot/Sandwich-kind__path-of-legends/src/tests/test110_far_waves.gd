extends SceneTree
# Волны 61–80: снимки локаций и противников в бою (герой бессмертен, стоит у центра)
var main
var f := 0
var arena
var waves := [61, 63, 64, 66, 68, 69, 71, 73, 74, 76, 78, 79]
var wi := -1
var t0 := 0
var shots := "/tmp/claude-0/st/far/"

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
		img.save_png(shots + "w%d_%s.png" % [waves[wi], n])

func _next() -> bool:
	wi += 1
	if wi >= waves.size():
		return false
	t0 = f
	main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
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
	var k := f - t0
	if k in [420, 600, 780]:
		shot("k%d" % k)
		var kinds := {}
		for b in arena._alive:
			if is_instance_valid(b):
				kinds[b.get_meta("kind")] = kinds.get(b.get_meta("kind"), 0) + 1
		print("w", waves[wi], " k=", k, " alive=", kinds, " state=", arena._state, " hero=", arena.players[0].global_position)
	if k == 800:
		if not _next():
			print("DONE")
			return true
	return false
