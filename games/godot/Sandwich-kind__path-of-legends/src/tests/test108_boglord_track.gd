extends SceneTree
# Трясинный Владыка: где он в первые секунды боя (герой стоит в центре)
var main
var f := 0
var arena
var boss: Player
var t0 := -1

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 0, 0]
		main.start_arena(false, 60)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	for pl in arena.players:
		pl._protect = 1.0
		pl.hp = pl.max_hp
	if arena._boss == null:
		return false
	var b: Player = arena._boss
	if t0 < 0:
		if f % 20 == 0:
			print("intro f=", f, " boss x=", int(b.global_position.x), " y=", int(b.global_position.y), " frozen=", b.frozen)
		if not b.frozen and not b.cutscene_shield and arena._cut_cam == null:
			t0 = f
			print("FIGHT at f=", f, " boss x=", int(b.global_position.x), " hero x=", int(arena.players[0].global_position.x), " map_w=", b.map_w)
		return false
	var k := f - t0
	b.hp = b.max_hp
	if k % 10 == 0:
		var br = b.get_node_or_null("RaidBrain")
		print("k=", k, " x=", int(b.global_position.x), " y=", int(b.global_position.y), " vx=", int(b.velocity.x),
				" vis=", b.visible, " hide=", br._hide_kind if br else "?", " goal=", int(br._goal_x) if br else -1,
				" target=", (b.target.name if is_instance_valid(b.target) else "none"))
	if k >= 600:
		return true
	return false
