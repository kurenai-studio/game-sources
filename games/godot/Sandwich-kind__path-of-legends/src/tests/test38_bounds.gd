extends SceneTree
# Новые противники: появляются, двигаются, не вылезают за рамки арены.
var main
var f := 0
var arena
var stats := {}
var stage := 0
const SETS := [[0, ["fighter", "thrower", "slinger", "retiarius", "murmillo", "lion"]],
		[4, ["skeleton", "skel_sword", "skel_thrower", "necromancer", "bat", "spider"]],
		[5, ["spider_queen", "skeleton_king", "bat", "bat", "spider"]]]
var si := 0
var t0 := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func setup(i):
	for b in arena._alive:
		if is_instance_valid(b): b.queue_free()
	arena._alive.clear()
	for n in main.world.get_children():
		if not n.is_in_group("persist"): n.queue_free()
	arena._build_stage(SETS[i][0])
	var gi := 0
	for k in SETS[i][1]:
		var g = arena.info["gates"][gi % 2]
		gi += 1
		var sz: Vector2 = Bots.TYPES[k]["size"]
		var b = arena._make_bot(k, Vector2(g.x, g.y - sz.y / 2 - 2))
		stats[b] = {"kind": k, "out": 0, "minx": 1e9, "maxx": -1e9, "miny": 1e9, "maxy": -1e9, "start": b.position}
	t0 = f
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.start_arena(true, 1)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if f == 10:
		for t in arena.get_children(): t.queue_free()
		arena._state = "test"
	if f == 20:
		setup(0)
	if arena == null or f < 20:
		return false
	for p in arena.players:
		p._protect = 5.0
		p.frozen = false
	# герои бегают туда-сюда, чтобы враги за ними ходили
	arena.players[0].position.x = 1300 + sin(f * 0.01) * 900
	for b in stats.keys():
		if not is_instance_valid(b): continue
		var s = stats[b]
		var p: Vector2 = b.global_position
		s["minx"] = minf(s["minx"], p.x); s["maxx"] = maxf(s["maxx"], p.x)
		s["miny"] = minf(s["miny"], p.y); s["maxy"] = maxf(s["maxy"], p.y)
		if p.x < Colosseum.WALL or p.x > Colosseum.W - Colosseum.WALL or p.y > Colosseum.FLOOR_Y + 5 or p.y < 0:
			s["out"] += 1
	if f - t0 == 60 * 40:
		for b in stats.keys():
			var s = stats[b]
			print("%-14s out=%d x=[%d..%d] y=[%d..%d] alive=%s" % [s["kind"], s["out"], s["minx"], s["maxx"], s["miny"], s["maxy"], is_instance_valid(b)])
		stats.clear()
		si += 1
		if si >= SETS.size():
			return true
		print("---")
		setup(si)
	return false
