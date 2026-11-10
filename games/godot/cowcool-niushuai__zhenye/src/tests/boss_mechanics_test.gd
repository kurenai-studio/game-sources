extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.max_health = 10000.0
	game.health = game.max_health
	game.enemies.clear()
	game.attack_telegraphs.clear()
	game.area_effects.clear()

	var cross_health: float = game.health
	game._queue_eye_cross(game.player_position, 3, 0, 0.0)
	assert(String(game.attack_telegraphs[0]["kind"]) == "boss_cross")
	game._update_attack_telegraphs(1.1)
	assert(game.health < cross_health)
	assert(game.area_effects.any(func(effect): return String(effect["kind"]) == "boss_cross"))

	game.attack_telegraphs.clear()
	game.area_effects.clear()
	game._select_stage(1)
	game.wave = game._boss_wave() - 1
	game._queue_bone_cage(game.player_position, 3, 0, 2)
	var bone_warnings: Array = game.attack_telegraphs.filter(func(telegraph): return String(telegraph.get("effect", "")) == "bone_wall")
	assert(bone_warnings.size() >= 12)
	game._update_attack_telegraphs(1.0)
	var bone_walls: Array = game.area_effects.filter(func(effect): return String(effect["kind"]) == "bone_wall")
	assert(bone_walls.size() == bone_warnings.size())
	game.player_position = Vector2(bone_walls[0]["position"])
	game.hurt_timer = 0.0
	var wall_health: float = game.health
	game._update_area_effects(0.01)
	assert(game.health < wall_health)

	game.enemies.clear()
	game._spawn_bone_guards(game.player_position, 3)
	assert(game.enemies.size() == 4)
	for guard in game.enemies:
		assert(bool(guard["boss_guard"]))
		assert(String(guard["role"]) == "revenant")
	game._kill_enemy(0)
	assert(float(game.enemies[0]["revive_timer"]) > 0.0)

	game.enemies.clear()
	game.attack_telegraphs.clear()
	game._select_stage(2)
	game._spawn_array_eyes(game.player_position, 3)
	assert(game.enemies.size() == 5)
	for eye in game.enemies:
		assert(String(eye["role"]) == "array_eye")
	game._update_enemies(0.5)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "aimed"))

	game.enemy_projectiles.clear()
	game.attack_telegraphs.clear()
	game._queue_void_wheel(game.player_position, 3, 0)
	assert(String(game.attack_telegraphs[0]["kind"]) == "boss_wheel")
	var safe_angle := float(game.attack_telegraphs[0]["safe_angle"])
	game._update_attack_telegraphs(1.1)
	assert(game.enemy_projectiles.size() >= 20)
	for projectile in game.enemy_projectiles:
		var shot_angle := Vector2(projectile["velocity"]).angle()
		var angle_distance := absf(wrapf(shot_angle - safe_angle + PI, 0.0, TAU) - PI)
		assert(angle_distance >= 0.25)

	game.enemies.clear()
	game.attack_telegraphs.clear()
	game._select_stage(3)
	game.wave = game._boss_wave()
	game._queue_boss_phase_mechanic(game.player_position + Vector2(300, 0), 3, 3, 0)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "tide_lane"))
	game._update_attack_telegraphs(1.1)
	assert(game.enemies.any(func(enemy): return bool(enemy.get("boss_guard", false)) and String(enemy["kind"]) == "river_lantern"))

	game.enemies.clear()
	game.attack_telegraphs.clear()
	game.enemy_projectiles.clear()
	game._select_stage(4)
	game.wave = game._boss_wave()
	game._queue_boss_phase_mechanic(game.player_position + Vector2(300, 0), 4, 3, 0)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "avalanche"))
	game._update_attack_telegraphs(1.1)
	assert(game.enemies.any(func(enemy): return bool(enemy.get("boss_guard", false)) and String(enemy["kind"]) == "ice_coffin"))
	game._update_attack_telegraphs(1.0)
	assert(game.enemy_projectiles.size() > 0)

	print("首领机制测试通过：五首领的眼阵、骨墙、轮转、潮道和雪崩机制正常")
	quit()
