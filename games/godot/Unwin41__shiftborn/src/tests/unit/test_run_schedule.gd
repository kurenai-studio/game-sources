extends TestCase
## The main scene's wave list against the run structure: normal waves stop
## when the boss arrives, and each mini-boss spawns exactly once.

const MAIN_SCENE := preload("res://scenes/main.tscn")


func _waves() -> Array[SpawnWave]:
	var main := MAIN_SCENE.instantiate()
	var waves: Array[SpawnWave] = (main.get_node("HordeSpawner") as HordeSpawner).waves.duplicate()
	main.free()
	return waves


func test_no_wave_runs_past_the_boss() -> void:
	for wave in _waves():
		assert_true(wave.end_time <= Run.BOSS_TIME + 0.001, "%s ends after the boss arrives" % wave.enemy_scene.resource_path)


func test_mini_bosses_come_in_order_before_the_boss() -> void:
	assert_eq(Run.MINI_BOSSES.size(), 2, "expected two mini-bosses")
	var previous := 0.0
	for entry: Dictionary in Run.MINI_BOSSES:
		assert_true(entry.time > previous and entry.time < Run.BOSS_TIME, "mini-boss at %s is out of order" % entry.time)
		previous = entry.time
		var enemy := (entry.scene as PackedScene).instantiate() as Enemy
		assert_true(enemy.max_health >= 50.0, "mini-boss is too weak")
		enemy.free()


func test_boss_bar_fraction_is_clamped() -> void:
	assert_almost_eq(BossBar.fraction(50.0, 200.0), 0.25)
	assert_almost_eq(BossBar.fraction(-5.0, 200.0), 0.0)
	assert_almost_eq(BossBar.fraction(10.0, 0.0), 0.0)


func test_run_fits_five_minutes_with_boss_at_four_thirty() -> void:
	assert_almost_eq(Run.BOSS_TIME, 270.0)
	assert_almost_eq(Run.MINI_BOSSES[0].time, 105.0)
	assert_almost_eq(Run.MINI_BOSSES[1].time, 195.0)


func test_every_wave_starts_in_the_first_minute_and_a_half() -> void:
	for wave in _waves():
		assert_true(wave.start_time <= 90.0, "%s starts too late for a short run" % wave.enemy_scene.resource_path)
