extends SceneTree
var main
var f := 0
var arena
var shop
var t := {}
func _initialize() -> void:
	Save.load_game()
	Save.reset()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func find(cls):
	for n in main.world.get_children():
		if is_instance_of(n, cls): return n
	return null
func start(wave: int, coop := false):
	main.sel = [0, 1]
	main.start_arena(coop, wave)
	arena = find(ArenaMode)
func _physics_process(_d: float) -> bool:
	f += 1
	if arena and is_instance_valid(arena):
		for p in arena.players: p._protect = 5.0
	match f:
		5: shot("a1_menu")
		6: main._on_mode_chosen("shop")
		12:
			shop = find(ShopScreen)
			shot("b1_shop")
		50: shot("b2_shop_breath")
		52: shop._select(1)
		70: shot("b3_shop_swap")
		100: shot("b4_shop_swap2")
		130: shot("b5_shop_items")
		132: shop._select(3)
		200: shot("b6_shop_chests")
		202: main._on_mode_chosen("bestiary")
		210: shot("c1_bestiary_empty")
		212:
			Save.see("fighter"); Save.see("lion"); Save.see("gladiator")
			main._on_mode_chosen("bestiary")
		220: shot("c2_bestiary_some")
		222:
			Save.see_all()
			var bs = find(BestiaryScreen)
			bs._tab = 2
			bs._sel = 7
			bs._refresh()
		240: shot("c3_bestiary_caves")
		242:
			var bs = find(BestiaryScreen)
			bs._tab = 0
			bs._sel = 7
			bs._refresh()
		260: shot("c4_bestiary_col")
		262: main.show_arena_setup()
		268: find(ArenaSetup)._go(false)
		330: shot("d1_lift_picker")
		332: find(ArenaSetup)._picker.go_pressed.emit()
		350: shot("d2_lift_up")
		420: shot("d3_arena_lift")
		440: shot("d4_arena_lift2")
		460:
			return true
		600: start(5)
		700: shot("e1_glad_gate")
		760: shot("e2_glad_out")
		830: shot("e3_glad_name")
		1000: shot("e4_glad_fight")
		1002: start(10)
		1180: shot("e5_colossus")
		1240: shot("e6_colossus_name")
		1402: start(20)
		1530: shot("f1_sprout")
		1600: shot("f2_treant_grow")
		1700: shot("f3_treant_name")
		1802: start(25)
		1930: shot("g1_queen_drop")
		2010: shot("g2_queen_name")
		2202: start(30)
		2330: shot("h1_king_throne")
		2400: shot("h2_king_stand")
		2480: shot("h3_king_walk")
		2560: shot("h4_king_name")
		2800: shot("h5_king_fight")
		2802: start(23, true)
		3200: shot("i1_caves_fight")
		3202: start(28)
		3600:
			shot("i2_kingdom_fight")
			return true
	return false
