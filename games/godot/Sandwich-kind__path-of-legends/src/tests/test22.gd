extends SceneTree
# Арена: все 20 волн. Игрок бессмертен, боты убиваются тестом через несколько
# секунд после появления — чтобы успели применить способности.
var main
var f := 0
var arena: ArenaMode
var seen := {}           # какие способности применялись (по созданным объектам)
var kinds_seen := {}
var log_waves := {}
var max_alive := 0
var errors := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [1, 0]
		main.start_arena()
		for n in main.world.get_children():
			if n is ArenaMode:
				arena = n
	if arena == null or f < 5:
		return false
	var p: Player = arena.player
	if is_instance_valid(p):
		p.hp = p.max_hp            # игрок бессмертен в тесте
	# отмечаем способности ботов по снарядам на сцене
	for n in main.world.get_children():
		if n is Grenade and n.team == 1: seen["grenade"] = true
		if n is Shell and n.team == 1: seen["shell"] = true
		if n is Mortar and n.team == 1: seen["barrage"] = true
		if n is Eruptor and n.team == 1: seen["quake"] = true
		if n is Destructible and n.shield_team == 1: seen["shield"] = true
		if n is Player and n.is_bot:
			kinds_seen[n.get_meta("kind")] = true
			if not n.has_meta("born"):
				n.set_meta("born", f)
			elif f - int(n.get_meta("born")) > 420:      # 7 секунд жизни — и хватит
				n.take_damage(99999, p)
	max_alive = maxi(max_alive, arena._alive.size())
	if not log_waves.has(arena.wave) and arena._state == "fight":
		log_waves[arena.wave] = true
		var night := false
		for n in main.world.get_children():
			if n is CanvasModulate: night = true
		var obst := 0
		for n in main.world.get_children():
			if n is Destructible: obst += 1
		print("wave ", arena.wave, " queue=", arena._queue, " night=", night, " obstacles=", obst, " player at ", Vector2i(p.position))
	if arena._state == "over":
		print("RESULT state=over wave=", arena.wave, " kills=", arena.kills, " lives=", arena.lives)
		print("kinds seen: ", kinds_seen.keys())
		print("abilities used by bots: ", seen.keys())
		print("max alive at once: ", max_alive)
		return true
	if f > 60 * 60 * 25:
		print("TIMEOUT at wave ", arena.wave, " state ", arena._state, " queue ", arena._queue, " alive ", arena._alive.size())
		return true
	return false
