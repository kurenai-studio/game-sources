extends SceneTree
var main
var f := 0
var arena: ArenaMode
var ds
func _initialize() -> void:
	Save.load_game()
	Save.reset()
	Save.add_gold(57)
	Save.set_arena_progress("solo", 7, [1], 2)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func find(cls) :
	for n in main.world.get_children():
		if is_instance_of(n, cls): return n
	return null
func _process(_d: float) -> bool:
	f += 1
	match f:
		8: shot("01_menu")
		10: main._on_mode_chosen("shop")
		16: shot("02_shop")
		18: main._on_mode_chosen("inventory")
		24: shot("03_inventory")
		26: find(InventoryScreen)._select_hero(1)
		30: shot("03b_inventory_uber")
		32: find(InventoryScreen)._select_tab(2)
		36: shot("03c_inventory_tab")
		38: main.show_duel_setup()
		44: shot("04_duel_scroll")
		46:
			ds = find(DuelSetup)
			ds._choose_map("two_houses", true)
		70: shot("05_duel_drawing")
		110: shot("06_duel_houses")
		112: ds._choose_map("mountain", true)
		190: shot("07_duel_mountain")
		192: ds._paper.scroll_to(9999, false)
		196: shot("08_duel_bottom")
		198: ds._on_legends()
		215: shot("09_rolling")
		290: shot("10_legends")
		292: main._on_duel_ready("mountain", 3, 5, [0, 1])
		420: shot("11_mountain_start")
		422:
			main.duel_players[0].position = Vector2(2500, 1500)
			main.duel_players[1].position = Vector2(3300, 1500)
		520: shot("12_mountain_close")
		522:
			main.duel_players[0].position = Vector2(1300, 2500)
			main.duel_players[1].position = Vector2(4300, 1700)
		600: shot("13_mountain_split")
		602: main.show_arena_setup()
		612: shot("14_arena_setup")
		614: find(ArenaSetup)._set_coop(true)
		620: shot("15_arena_setup_coop")
		622:
			main.sel = [0, 1]
			main.start_arena(true, 11)
			arena = find(ArenaMode)
		900:
			shot("16_jungle_day_coop")
			arena._summon("sneak", 1, arena.players[0].position + Vector2(300, 0))
		905:
			for b in arena._alive:
				if b.get_meta("kind") == "sneak": b._throw_spear("smoke")
		960: shot("17_jungle_smoke")
		962:
			main.sel = [1, 0]
			main.start_arena(false, 20)
			arena = find(ArenaMode)
		1300: shot("18_jungle_night_treant")
		1302:
			main.start_arena(false, 10)
			arena = find(ArenaMode)
		1650: shot("19_colosseum_night_colossus")
		1652:
			main.start_arena(false, 5)
			arena = find(ArenaMode)
		1950:
			shot("20_gladiator")
			return true
	if arena and is_instance_valid(arena):
		for p in arena.players: p._protect = 5.0
	return false
