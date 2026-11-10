extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	assert(scene != null)
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame

	var enemy_types := ["ghost", "paper", "stone", "lantern", "jiangshi", "splitter", "algae_drowned", "river_lantern", "headless_boatman", "soul_netter", "leech_medium", "snow_stalker", "ice_coffin", "gale_wraith", "frost_jailer"]

	for stage_index in game.STAGE_DATA.size():
		game._select_stage(stage_index)
		game._start_game()
		game.max_health = 1000000.0
		game.health = game.max_health
		game.experience_needed = 999999
		game.wave = game._boss_wave() - 1
		game.elapsed = float(game.wave - 1) * game._wave_duration() + 0.1
		game.weapon_levels.clear()
		game.weapon_timers.clear()
		for weapon in game.WEAPON_DATA.keys():
			game.weapon_levels[weapon] = 5
			game.weapon_timers[weapon] = 0.0
		game.passive_levels = {
			"sword_art": 3,
			"flame_heart": 3,
			"footwork": 3,
			"vitality": 3,
			"magnet": 3,
			"breathing": 3,
			"insight": 3,
			"soul_feast": 3,
		}
		game.evolved_weapons.clear()
		for weapon in game.weapon_levels:
			if game.EVOLUTION_RECIPES.has(weapon):
				game.evolved_weapons[weapon] = true

		for enemy_index in 180:
			game._spawn_regular_enemy(enemy_types[enemy_index % enemy_types.size()])
		for frame in 600:
			game._physics_process(1.0 / 60.0)
		assert(game.state == game.GameState.RUNNING)
		assert(game.enemies.size() <= game.MAX_ENEMIES)

		game.enemies.clear()
		game.projectiles.clear()
		game.enemy_projectiles.clear()
		game.attack_telegraphs.clear()
		game._spawn_boss()
		for frame in 180:
			game._update_enemies(1.0 / 60.0)
			game._update_attack_telegraphs(1.0 / 60.0)
			game._update_enemy_projectiles(1.0 / 60.0)
		assert(game.enemy_projectiles.size() > 0)
		game.queue_redraw()
		await process_frame

	print("压力测试通过：五个章节在高密度敌潮和十八法器构筑下运行正常")
	quit()
