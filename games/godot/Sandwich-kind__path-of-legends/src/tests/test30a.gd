extends SceneTree
# Проход всей Арены вдвоём: боты убиваются через 2 секунды, герои бессмертны.
var main
var f := 0
var arena: ArenaMode
var seen_stage := {}
var seen_kinds := {}
var age := {}
func _initialize() -> void:
	Save.load_game()
	Save.reset()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 1]
		main.start_arena(true, 1)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
		arena.finished.connect(func(v, w, g): print("FINISHED victory=", v, " waves=", w, " gold=", g))
	if arena == null or not is_instance_valid(arena):
		return f > 200000
	for p in arena.players:
		p._protect = 10.0
	seen_stage[arena.stage] = true
	for b in arena._alive + arena._totems:
		if not is_instance_valid(b): continue
		var k = b.get_meta("kind")
		seen_kinds[k] = true
		age[b] = age.get(b, 0) + 1
		if age[b] > 150:
			if k == "totem" or not b.invulnerable:
				b.invulnerable = false
				b.take_damage(99999)
	if f % 600 == 0:
		print("f=", f, " wave=", arena.wave, " stage=", arena.stage, " alive=", arena._alive.size(), " state=", arena._state, " gold=", Save.gold(), " save=", Save.arena_progress("coop" if true else "solo"))
	if arena._state == "over" or f > 60 * 60 * 40:
		print("END wave=", arena.wave, " stages=", seen_stage.keys(), " kinds=", seen_kinds.keys(), " gold=", Save.gold())
		print("save=", Save.data)
		return true
	return false
