extends SceneTree
# Атаман (10) и Колосс (50): способности, фазы Колосса.
var main
var f := 0
var arena
var waves := [10, 50]
var wi := -1
var t0 := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _next() -> void:
	wi += 1
	t0 = f
	main.sel = [9, 0]
	main.start_arena(false, waves[wi])
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3: _next()
	if arena == null: return false
	var lt := f - t0
	for p in arena.players:
		p._protect = 5.0
		p.hp = p.max_hp
	var b = arena._boss
	if lt % 60 == 0 and b and is_instance_valid(b):
		var rb = b.get_node_or_null("RaidBrain")
		print("w", waves[wi], " t=", lt / 60, " hp=", b.hp, "/", b.max_hp, " stun=", b._stun_t > 0.0, " phase=", rb._phase if rb else -1, " cds=", b._bot_cd)
	if waves[wi] == 50 and b and is_instance_valid(b):
		if lt == 60 * 22: b.hp = int(b.max_hp * 0.6)
		if lt == 60 * 32: b.hp = int(b.max_hp * 0.3)
	if lt in [60 * 12, 60 * 15, 60 * 18, 60 * 21, 60 * 25, 60 * 29, 60 * 34, 60 * 38]:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/boss%d_%d.png" % [waves[wi], lt / 60])
	if lt == 60 * (24 if waves[wi] == 10 else 40):
		if wi + 1 >= waves.size(): return true
		_next()
	return false
