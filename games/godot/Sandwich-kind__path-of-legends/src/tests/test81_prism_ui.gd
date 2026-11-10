extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null
func shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/%s.png" % n)
func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main.show_duel_setup()
		8:
			var ds = find(DuelSetup)
			ds._choose_map("test_field", false)
			ds._show_picker()
		12:
			var lp = null
			for n in main.world.get_children():
				for c in n.get_children() + [n]:
					if c is LegendPicker: lp = c
			if lp == null:
				for n in root.get_tree().get_nodes_in_group("pad_modal") : pass
			print("picker=", lp)
			if lp:
				lp.sel = [9, 0]
				lp._refresh()
		60: shot("ui_picker")
		62: main._on_mode_chosen("inventory")
		66: find(InventoryScreen)._select_hero(9)
		80:
			shot("ui_inventory")
			return true
	return false
