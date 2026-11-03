extends GutTest


func test_arena_is_deterministic() -> void:
	assert_eq(ArenaGenerator.generate(42), ArenaGenerator.generate(42))


func test_different_seeds_differ() -> void:
	assert_ne(ArenaGenerator.generate(1)["obstacles"], ArenaGenerator.generate(2)["obstacles"])


func test_spawn_area_is_clear() -> void:
	for seed_value in 25:
		var a := ArenaGenerator.generate(seed_value)
		var center: Vector2 = (a["size"] as Vector2) / 2.0
		for o: Rect2 in a["obstacles"]:
			var closest := Vector2(clampf(center.x, o.position.x, o.end.x), clampf(center.y, o.position.y, o.end.y))
			assert_gte(closest.distance_to(center), ArenaGenerator.SAFE_RADIUS)


func test_obstacles_in_bounds_and_separate() -> void:
	for seed_value in 25:
		var a := ArenaGenerator.generate(seed_value)
		var bounds := Rect2(Vector2.ZERO, a["size"])
		var obs: Array[Rect2] = a["obstacles"]
		assert_gte(obs.size(), 5)
		for i in obs.size():
			assert_true(bounds.encloses(obs[i]))
			for j in range(i + 1, obs.size()):
				assert_false(obs[i].intersects(obs[j]))


func test_hazards_match_theme_and_avoid_obstacles() -> void:
	for seed_value in 25:
		var a := ArenaGenerator.generate(seed_value)
		var expected: int = ArenaGenerator.THEMES[a["theme"]]["hazard"]
		for h: Dictionary in a["hazards"]:
			assert_eq(int(h["type"]), expected)
			for o: Rect2 in a["obstacles"]:
				assert_false((h["rect"] as Rect2).intersects(o))


func test_point_blocked() -> void:
	var obs: Array[Rect2] = [Rect2(0, 0, 10, 10)]
	assert_true(ArenaGenerator.point_blocked(Vector2(5, 5), obs))
	assert_false(ArenaGenerator.point_blocked(Vector2(20, 20), obs))
	assert_true(ArenaGenerator.point_blocked(Vector2(12, 5), obs, 5.0))


func test_boss_every_fifth_wave() -> void:
	assert_false(WaveDirector.is_boss_wave(4))
	assert_true(WaveDirector.is_boss_wave(5))
	assert_true(WaveDirector.is_boss_wave(10))
	assert_false(WaveDirector.is_boss_wave(0))


func test_compose_respects_budget_and_min_wave() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var ids := WaveDirector.compose(1, rng, GameState.enemies)
	var spent := 0
	for id in ids:
		var e: EnemyData = GameState.enemies[id]
		assert_lte(e.min_wave, 1)
		spent += e.cost
	assert_gte(spent, WaveDirector.budget(1))
	assert_false(ids.has(&"tank"))


func test_boss_wave_contains_one_boss_first() -> void:
	var rng := RandomNumberGenerator.new()
	var ids := WaveDirector.compose(5, rng, GameState.enemies)
	assert_eq(ids[0], &"boss")
	assert_eq(ids.count(&"boss"), 1)


func test_later_waves_unlock_types_and_scale() -> void:
	var types := WaveDirector.eligible(6, GameState.enemies).map(func(e: EnemyData) -> StringName: return e.id)
	assert_true(types.has(&"tank"))
	assert_true(types.has(&"exploder"))
	assert_false(types.has(&"boss"))
	assert_gt(WaveDirector.health_scale(6), WaveDirector.health_scale(1))
	assert_lt(WaveDirector.spawn_interval(10), WaveDirector.spawn_interval(1))
