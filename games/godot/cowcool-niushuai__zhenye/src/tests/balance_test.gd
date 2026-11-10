extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game._start_game()
	game.max_health = 1000000.0
	game.health = game.max_health
	game.passive_levels.clear()
	game.equipment_damage_bonus = 0.0
	game.equipment_cooldown_bonus = 0.0

	var damage_results: Dictionary = {}
	for weapon_key in game.WEAPON_DATA.keys():
		var weapon: String = weapon_key
		game.enemies.clear()
		game.projectiles.clear()
		game.area_effects.clear()
		game.run_damage_dealt = 0.0
		game.run_weapon_damage.clear()
		game.weapon_levels = {weapon: 5}
		game.weapon_timers = {weapon: 0.0}
		game.evolved_weapons = {weapon: true}
		game.orbit_angle = 0.0

		for enemy_index in 30:
			var angle := TAU * float(enemy_index) / 30.0
			var ring := 100.0 + float(enemy_index % 3) * 105.0
			var position: Vector2 = game.player_position + Vector2.from_angle(angle) * ring
			var enemy: Dictionary = game._make_enemy(position, 18.0, 0.0, 1000000.0, 0.0, 0, Color.WHITE, "ghost")
			game.enemies.append(enemy)

		for frame in 480:
			game.elapsed += 1.0 / 60.0
			game._update_weapons(1.0 / 60.0)
			game._update_projectiles(1.0 / 60.0)
			game._update_area_effects(1.0 / 60.0)
		var damage := float(game.run_weapon_damage.get(weapon, 0.0))
		damage_results[weapon] = damage
		assert(damage > 0.0)

	var minimum_damage := INF
	var maximum_damage := 0.0
	for weapon in damage_results:
		minimum_damage = minf(minimum_damage, float(damage_results[weapon]))
		maximum_damage = maxf(maximum_damage, float(damage_results[weapon]))
	print("平衡基准数据：", damage_results)
	assert(maximum_damage / minimum_damage < 12.0)
	print("平衡基准通过：8 秒固定敌阵伤害 ", damage_results)
	quit()
