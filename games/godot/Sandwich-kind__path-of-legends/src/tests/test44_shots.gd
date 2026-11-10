extends SceneTree
var main
var f := 0
var ds
func _initialize() -> void:
	Save.load_game()
	Save.reset()
	Save.unlock_all_stages()
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
			ds._paper.scroll_to(620, false)
			ds._choose_map("arena_kingdom", false)
		20: shot("m1_maps")
		22: ds._paper.scroll_to(9999, false)
		26: shot("m2_kingdom_preview")
		28: main._on_duel_ready("test_buffs", 9, 99, [0, 1], {})
		30:
			main.duel_players[0].position = Vector2(1400, 780)
			main.duel_players[1].position = Vector2(2200, 780)
		260: shot("m3_test_buffs")
		262: main._on_duel_ready("two_houses", 9, 99, [0, 1], {"sd": true, "sd_time": 1})
		264:
			main.duel_players[0].position = Vector2(300, 1200)
			main.duel_players[1].position = Vector2(700, 1200)
		1400: shot("m4_bombed_house")
		1402: main._on_duel_ready("arena_colosseum_night", 9, 99, [0, 1], {})
		1640: shot("m5_duel_colosseum_night")
		1642: main._on_duel_ready("arena_kingdom", 9, 99, [1, 0], {})
		1880:
			shot("m6_duel_kingdom")
			return true
	return false
