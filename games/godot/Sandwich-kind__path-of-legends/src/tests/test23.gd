extends SceneTree
# Колосс против игрока: применяет ли все 4 способности; не застревают ли боты
var main
var f := 0
var arena: ArenaMode
var boss: Player
var seen := {}
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena()
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if f == 250:
		arena._queue.clear()
		boss = Bots.create("colossus", 20, Vector2(2400, 800), arena.player, Colosseum.W)
		main.world.add_child(boss)
		arena._alive.append(boss)
		arena._boss = boss
		for k in ["soldier", "tank", "gunner", "breacher", "runner"]:
			var b := Bots.create(k, 5, Vector2(300 + randf() * 200, 850), arena.player, Colosseum.W)
			main.world.add_child(b)
			arena._alive.append(b)
	if f > 250:
		arena.player.hp = arena.player.max_hp
		for n in main.world.get_children():
			if n is Grenade and n.team == 1: seen["grenade"] = true
			if n is Shell and n.team == 1: seen["shell"] = true
			if n is Mortar and n.team == 1: seen["barrage"] = true
			if n is Eruptor and n.team == 1: seen["quake"] = true
			if n is Destructible and n.shield_team == 1: seen["shield"] = true
	if f % 300 == 0 and f > 250:
		var xs := []
		for b in arena._alive:
			if is_instance_valid(b):
				xs.append([b.get_meta("kind"), int(b.position.x)])
		print("t=", (f - 250) / 60, "s bots: ", xs, " used: ", seen.keys(), " player hp=", arena.player.hp)
	if f == 250 + 60 * 25:
		return true
	return false
