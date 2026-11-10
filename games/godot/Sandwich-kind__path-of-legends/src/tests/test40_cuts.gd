extends SceneTree
var main
var f := 0
var arena
var waves := [10, 20, 25, 30]
var wi := -1
var cut_f := -1
var start_f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func find(cls):
	for n in main.world.get_children():
		if is_instance_of(n, cls): return n
	return null
func next():
	wi += 1
	if wi >= waves.size():
		return false
	main.sel = [0, 1]
	main.start_arena(false, waves[wi])
	arena = find(ArenaMode)
	cut_f = -1
	start_f = f
	return true
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		next()
	if arena == null: return false
	for p in arena.players: p._protect = 5.0
	if f - start_f == 60: shot("L%d_lift" % waves[wi])
	if cut_f < 0 and arena._state == "cutscene":
		cut_f = f
	if cut_f > 0:
		var d := f - cut_f
		var w: int = waves[wi]
		for pair in [[110, "a"], [170, "b"], [230, "c"], [300, "d"], [420, "e"], [560, "f"]]:
			if d == pair[0]:
				shot("K%d_%s" % [w, pair[1]])
		if d == 600:
			if not next():
				return true
	return false
