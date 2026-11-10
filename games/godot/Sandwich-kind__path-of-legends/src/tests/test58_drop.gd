extends SceneTree
# Бот на платформе, герой внизу — бот должен спуститься
var main
var f := 0
var arena
var bots := []
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
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
		for b in arena._alive:
			if is_instance_valid(b): b.queue_free()
		arena._alive.clear()
		for n in main.world.get_children():
			if not n.is_in_group("persist"): n.queue_free()
		arena._build_stage(0)
	if f == 15:
		var k := 0
		for kind in ["gladiator", "colossus", "fighter", "thrower"]:
			var sz: Vector2 = Bots.TYPES[kind]["size"]
			var top: float = Colosseum.FLOOR_Y - Colosseum.STEP * 3 - sz.y / 2 - 15
			var b = arena._make_bot(kind, Vector2(1300 + (k - 1.5) * 60, top))
			b.max_hp = 99999; b.hp = 99999
			bots.append(b)
			k += 1
	if arena == null or f < 15:
		return false
	for p in arena.players:
		p._protect = 5.0
		p.frozen = false
		p.position = Vector2(400 + p.index * 60, Colosseum.FLOOR_Y - 32)
	if f % 120 == 0:
		var line := "t=%.0fs " % (f / 60.0)
		for b in bots:
			line += "%s y=%d x=%d | " % [b.get_meta("kind"), int(b.position.y), int(b.position.x)]
		print(line)
	return f > 15 + 60 * 10
