extends SceneTree
var main
var f := 0
var arena: ArenaMode
var tag := ""
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + tag + "_" + name + ".png")
	print("shot ", name)
func spawn_all(wave: int) -> void:
	var x := 600.0
	for k in ["grunt", "runner", "soldier", "tank", "gunner", "breacher"]:
		var b := Bots.create(k, wave, Vector2(x, 850), arena.player, Colosseum.W)
		b.frozen = true
		main.world.add_child(b)
		arena._alive.append(b)
		x += 130.0
func _process(_d: float) -> bool:
	f += 1
	if f == 2:
		tag = str(int(root.get_visible_rect().size.x))
	match f:
		20: shot("t1_title")
		22:
			main.sel = [0, 1]
			main.start_arena()
			for n in main.world.get_children():
				if n is ArenaMode: arena = n
		40: shot("t2_arena_countdown")
		240:
			arena._queue.clear()
			arena.player.position = Vector2(1100, 900)
			spawn_all(1)
		290: shot("t3_arena_day_bots")
		300:
			for b in arena._alive:
				if is_instance_valid(b): b.queue_free()
			arena._alive.clear()
			arena.wave = 10
			arena._rebuild(2)
		400:
			arena.player.position = Vector2(900, 900)
			spawn_all(11)
			var boss := Bots.create("warden", 10, Vector2(1450, 800), arena.player, Colosseum.W)
			boss.frozen = true
			main.world.add_child(boss)
			arena._alive.append(boss)
			arena._boss = boss
		460: shot("t4_arena_night")
		470:
			for b in arena._alive:
				if is_instance_valid(b): b.queue_free()
			arena._alive.clear()
			arena._rebuild(3)
		560:
			var boss := Bots.create("colossus", 20, Vector2(1500, 800), arena.player, Colosseum.W)
			boss.frozen = true
			main.world.add_child(boss)
			arena._alive.append(boss)
			arena._boss = boss
			arena.player.position = Vector2(1150, 900)
			for k in 3:
				var b := Bots.create("runner", 20, Vector2(2400 + k * 40, 900), arena.player, Colosseum.W)
				b.frozen = true
				main.world.add_child(b)
				arena._alive.append(b)
		620: shot("t5_colossus")
		630:
			main.sel = [0, 1]
			main._on_map_chosen("two_houses", 3, 5)
			main._start_game()
		800: shot("t6_two_houses")
		810: return true
	return false
