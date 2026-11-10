extends SceneTree

const TEST_SAVE := "user://zhenye_full_run_test.json"


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)

	var scene: PackedScene = load("res://main.tscn")
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame

	var meta := MetaProgression.new(TEST_SAVE, false)
	meta.talents = {
		"vitality": 3,
		"power": 3,
		"stride": 2,
		"cooldown": 2,
		"spirit": 2,
		"magnet": 2,
		"mastery": 3,
		"fortune": 0,
	}
	meta.add_item({
		"uid": 1,
		"slot": "robe",
		"name": "护命法袍",
		"template": 0,
		"rarity": 3,
		"level": 0,
		"stats": {"health": 0.25},
		"rule": "emergency_guard",
		"source_stage": 0,
	})
	meta.next_uid = 2
	meta.equip_item(1)
	game.meta = meta
	game._select_stage(0)
	game._start_game()
	game.rng.seed = 20260721

	for step in 5200:
		if game.state != game.GameState.RUNNING:
			break
		if game.choosing_upgrade:
			_choose_upgrade(game)
			continue
		if game.shopping:
			_use_shop(game)
			game._close_shop()
			continue

		_move_player(game, 0.1)
		if game.ability_timer <= 0.0 and not game.enemies.is_empty():
			game._use_pulse()
		game._physics_process(0.1)

	if game.state != game.GameState.WON:
		print("完整跑局未通关：状态 %d，时间 %.1f，波次 %d，生命 %.1f，敌人 %d，等级 %d，法器 %s" % [
			game.state,
			game.elapsed,
			game.wave,
			game.health,
			game.enemies.size(),
			game.level,
			str(game.weapon_levels),
		])
		_cleanup(absolute_path)
		quit(1)
		return
	assert(game.wave_records.size() >= game._boss_wave() - 1)
	assert(game.run_damage_dealt > 0.0)
	assert(game.defeated > 0)
	assert(game.run_copper >= 100)
	for record in game.wave_records:
		assert(record.has("level"))
		assert(record.has("copper"))
		assert(record.has("damage_dealt"))
		assert(record.has("damage_taken"))
		assert(record.has("main_damage_source"))

	print("完整跑局通过：%s，%d 波，等级 %d，击杀 %d，输出 %d，承伤 %d" % [
		game._stage_data()["name"],
		game.wave_records.size(),
		game.level,
		game.defeated,
		roundi(game.run_damage_dealt),
		roundi(game.run_damage_taken),
	])
	print("逐波数据：", JSON.stringify(game.wave_records))
	_cleanup(absolute_path)
	quit()


func _choose_upgrade(game: Node) -> void:
	var preferred_weapons := ["sword", "mirror", "talisman", "banner", "thunder", "chain"]
	var preferred_passives := ["damage", "cooldown", "health", "move", "pickup", "experience"]
	var best_index := 0
	var best_score := -1
	for index in game.upgrade_choices.size():
		var choice: String = game.upgrade_choices[index]
		var parts := choice.split(":")
		var score := 0
		if parts[0] == "evolution":
			score = 1000
		elif parts[0] == "weapon":
			var weapon_index := preferred_weapons.find(parts[1])
			score = 600 - weapon_index * 15 if weapon_index >= 0 else 300
			score += int(game.weapon_levels.get(parts[1], 0)) * 25
		elif parts[0] == "passive":
			var passive_index := preferred_passives.find(parts[1])
			score = 450 - passive_index * 12 if passive_index >= 0 else 200
		if score > best_score:
			best_score = score
			best_index = index
	game._on_upgrade_pressed(best_index)


func _use_shop(game: Node) -> void:
	for index in game.shop_goods.size():
		var good: Dictionary = game.shop_goods[index]
		if good.is_empty() or int(good["cost"]) > game.run_copper:
			continue
		var choice: String = good["choice"]
		var parts := choice.split(":")
		var useful := parts[0] == "passive" and parts[1] in ["health", "damage", "cooldown", "move"]
		useful = useful or (parts[0] == "weapon" and game.weapon_levels.has(parts[1]))
		useful = useful or (parts[0] == "service" and parts[1] in ["heal", "power"])
		if useful:
			game._buy_shop_good(index)


func _move_player(game: Node, delta: float) -> void:
	var avoidance := Vector2.ZERO
	for enemy in game.enemies:
		var offset: Vector2 = game.player_position - Vector2(enemy["position"])
		var distance := maxf(1.0, offset.length())
		if distance < 280.0:
			avoidance += offset.normalized() * (1.0 - distance / 280.0) * 1.4
	for shot in game.enemy_projectiles:
		var shot_offset: Vector2 = game.player_position - Vector2(shot["position"])
		var shot_distance := maxf(1.0, shot_offset.length())
		if shot_distance < 210.0:
			avoidance += shot_offset.normalized() * (1.0 - shot_distance / 210.0) * 2.4
	var center: Vector2 = game.ARENA_SIZE * 0.5
	var from_center: Vector2 = game.player_position - center
	if game.player_position.x < 150.0:
		avoidance.x += (150.0 - game.player_position.x) / 80.0
	elif game.player_position.x > game.ARENA_SIZE.x - 150.0:
		avoidance.x -= (game.player_position.x - (game.ARENA_SIZE.x - 150.0)) / 80.0
	if game.player_position.y < 130.0:
		avoidance.y += (130.0 - game.player_position.y) / 70.0
	elif game.player_position.y > game.ARENA_SIZE.y - 130.0:
		avoidance.y -= (game.player_position.y - (game.ARENA_SIZE.y - 130.0)) / 70.0
	var direction: Vector2
	if avoidance.length() > 0.08:
		direction = avoidance.normalized()
	else:
		direction = Vector2.RIGHT if from_center.length() < 20.0 else from_center.normalized().orthogonal()
		if from_center.length() > 420.0:
			direction = (direction - from_center.normalized() * 0.7).normalized()
	game.player_position += direction * game.move_speed * delta
	game.player_position.x = clampf(game.player_position.x, 45.0, game.ARENA_SIZE.x - 45.0)
	game.player_position.y = clampf(game.player_position.y, 45.0, game.ARENA_SIZE.y - 45.0)


func _cleanup(absolute_path: String) -> void:
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)
