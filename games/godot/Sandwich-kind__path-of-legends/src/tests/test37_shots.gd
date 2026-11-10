extends SceneTree
var main
var f := 0
var ds
var arena
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
func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main.show_duel_setup()
		10:
			ds = find(DuelSetup)
			ds.opts["heal"] = true
			ds.opts["mega"] = true
			ds.opts["sd"] = true
			ds._update_steppers()
			ds._paper.scroll_to(330, false)
		16: shot("s1_options")
		18: ds._choose_map("two_houses", false)
		20: ds._paper.scroll_to(9999, false)
		30: shot("s2_color_preview")
		32: main._on_duel_ready("test_field", 9, 99, [0, 1], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 1})
		400: shot("s3_knives")
		420: shot("s3b_knives")
		432: main._on_duel_ready("two_houses", 9, 99, [1, 0], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 1})
		434:
			main.duel_players[0].position = Vector2(1800, 1200)
			main.duel_players[1].position = Vector2(2200, 1200)
		800: shot("s4_bombs")
		860: shot("s4b_bombs")
		862: main._on_duel_ready("mountain", 9, 99, [0, 1], {"heal": true, "buffs": true, "mega": true, "sd": true, "sd_time": 1})
		864:
			main.duel_players[0].position = Vector2(2700, 1300)
			main.duel_players[1].position = Vector2(3300, 1300)
		1200: main.events.lava_y = 1500.0
		1350: shot("s5_lava")
		1352:
			main.sel = [0, 1]
			main.start_arena(true, 6)
			arena = find(ArenaMode)
		1650: shot("s6_arena_walk")
		1710: shot("s7_arena_walk2")
		1712:
			main.start_arena(true, 15)
			arena = find(ArenaMode)
		2150:
			shot("s8_chief")
			return true
	if arena and is_instance_valid(arena):
		for p in arena.players: p._protect = 5.0
	return false
