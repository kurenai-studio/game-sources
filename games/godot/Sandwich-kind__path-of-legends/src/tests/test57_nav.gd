extends SceneTree
# Навигация ботов: доходят ли от ворот до героя на каждой раскладке Колизея
var main
var f := 0
var arena
var stats := {}
var si := 0
var t0 := 0
const KINDS := ["grunt", "soldier", "tank", "gladiator", "colossus", "fighter", "murmillo", "thrower"]
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
	arena._build_stage(i)
	stats.clear()
	var gi := 0
	for k in KINDS:
		var g = arena.info["gates"][gi % 2]
		gi += 1
		var sz: Vector2 = Bots.TYPES[k]["size"]
		var b = arena._make_bot(k, Vector2(g.x, g.y - sz.y / 2 - 2))
		b.max_hp = 99999
		b.hp = 99999
		stats[b] = {"kind": k, "start": b.position, "best": 1e9, "high": 0}
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
	var d := f - t0
	for p in arena.players:
		p._protect = 5.0
		p.frozen = false
		p.position = Vector2(1300 + (p.index * 2 - 1) * 60, Colosseum.FLOOR_Y - 32)
		if d > 900:
			p.position = Vector2(1300, Colosseum.FLOOR_Y - Colosseum.STEP * 2 - 40)   # герой наверху башни
	for b in stats:
		if is_instance_valid(b) and b.is_alive():
			var dd: float = absf(b.position.x - 1300.0)
			stats[b]["best"] = minf(stats[b]["best"], dd)
			if b.position.y < Colosseum.FLOOR_Y - 140 - b.body_size.y / 2:
				stats[b]["high"] += 1
	if d == 900:
		var line := "stage %d ground: " % si
		for b in stats:
			line += "%s=%d " % [stats[b]["kind"], int(stats[b]["best"])]
			stats[b]["best"] = 1e9
		print(line)
	if d == 1500:
		var line2 := "stage %d tower: " % si
		for b in stats:
			line2 += "%s=%d/%s " % [stats[b]["kind"], int(stats[b]["best"]), "H" if stats[b]["high"] > 0 else "-"]
		print(line2)
		si += 1
		if si > 3:
			return true
		setup(si)
	return false
