extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game._select_stage(3)
	game._start_game()
	assert(game.STAGE_DATA.size() == 5)
	assert(game.WEAPON_DATA.size() == 18)
	assert(game.EVOLUTION_DATA.size() == 18)
	assert(game.WEAPON_SYNERGIES.size() == 13)
	assert(game.pixel_assets["bosses"].size() == 5)
	assert(game.pixel_assets["floors"].size() == 5)

	for slot in game.meta.SLOT_ORDER:
		for template in range(6, 9):
			var item := {"slot": slot, "template": template}
			assert(game._equipment_icon(item) != null)

	game.enemies.clear()
	for enemy_type in ["algae_drowned", "river_lantern", "headless_boatman", "soul_netter", "leech_medium"]:
		game._spawn_regular_enemy(enemy_type, game.player_position + Vector2(320, 0))
	assert(game.enemies.size() == 5)
	game.enemies[1]["attack_timer"] = 0.0
	game.enemies[2]["dash_timer"] = 0.3
	game.enemies[3]["control_timer"] = 0.0
	game.enemies[4]["heal_timer"] = 0.0
	game._update_enemies(0.05)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "aimed"))
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph.get("effect", "")) == "snare"))
	assert(game.area_effects.any(func(effect): return String(effect["kind"]) == "heal"))
	game._kill_enemy(0)
	assert(game.area_effects.any(func(effect): return String(effect["kind"]) == "algae_pool"))

	game.enemies.clear()
	game.attack_telegraphs.clear()
	game._select_stage(4)
	for enemy_type in ["snow_stalker", "ice_coffin", "gale_wraith", "frost_jailer"]:
		game._spawn_regular_enemy(enemy_type, game.player_position + Vector2(320, 0))
	assert(game.enemies.size() == 4)
	game.enemies[0]["dash_timer"] = 0.3
	game.enemies[2]["attack_timer"] = 0.0
	game._update_enemies(0.05)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "aimed"))
	game._kill_enemy(1)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "ice_burst"))

	game.attack_telegraphs.clear()
	game.wave = 9
	game._queue_avalanche_event()
	assert(game.attack_telegraphs.size() == 2)
	game._select_stage(3)
	game.attack_telegraphs.clear()
	game._queue_tide_event()
	assert(game.attack_telegraphs.size() == 4)

	print("扩展测试通过：双章节、八法器、八联动、九敌人和十八装备模板正常")
	quit()
