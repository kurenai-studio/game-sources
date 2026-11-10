extends SceneTree
var main
var f := 0
var heroes := [[2, false], [4, false], [3, true]]
var hi := -1
var t0 := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
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
		5:
			main.show_duel_setup()
		8:
			var ds = find(DuelSetup)
			ds._choose_map("test_field", false)
			ds.sel = [2, 3]
			ds._show_picker()
		60: shot("h0_picker")
		62:
			main._on_mode_chosen("inventory")
		66:
			find(InventoryScreen)._select_hero(4)
		72: shot("h0_inventory")
		74:
			Save.reset()
			main._on_mode_chosen("inventory")
		78:
			find(InventoryScreen)._select_hero(3)
		84:
			shot("h0_inventory_locked")
			Save.unlock_all_heroes()
			hi = 0
			start()
	if hi < 0 or hi >= heroes.size():
		return hi >= heroes.size()
	var d := f - t0
	var me: Player = main.duel_players[0]
	var foe: Player = main.duel_players[1]
	me._protect = 1.0
	foe._protect = 0.0
	var tag := "%s%s" % [Characters.LIST[heroes[hi][0]]["rig"], "_mega" if heroes[hi][1] else ""]
	match d:
		200:
			me.position = Vector2(300, 570)
			foe.position = Vector2(760, 570)
			me.facing = 1
		230: shot("u_%s_idle" % tag)
		240:
			if heroes[hi][1]:
				me.add_buff("cooldown", true)
			me.ult_charge = 999
			Input.action_press("p1_ult")
		242: Input.action_release("p1_ult")
		258: shot("u_%s_1" % tag)
		280: shot("u_%s_2" % tag)
		300: shot("u_%s_3" % tag)
		330: shot("u_%s_4" % tag)
		370: shot("u_%s_5" % tag)
		420: shot("u_%s_6" % tag)
		470:
			hi += 1
			if hi < heroes.size():
				start()
	return false
func start():
	main._on_duel_ready("test_field", 9, 99, [heroes[hi][0], 0], {})
	t0 = f
