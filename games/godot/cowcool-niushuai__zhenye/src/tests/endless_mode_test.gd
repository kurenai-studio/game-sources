extends SceneTree

const TEST_SAVE := "user://zhenye_endless_mode_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)

	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.meta = MetaProgression.new(TEST_SAVE, false)
	game.selected_stage = 2
	game.selected_endless_mode = true
	game._start_game()
	assert(game.endless_mode)
	assert(game.arena_size == game.ENDLESS_ARENA_SIZE)
	assert(game.WEAPON_DATA.size() == 18)
	assert(game.EVOLUTION_DATA.size() == 18)
	assert(game.WEAPON_SYNERGIES.size() == 13)
	assert(game.PASSIVE_DATA.size() == 8)

	game.wave = 4
	game.endless_wave_started_at = 0.0
	game.elapsed = game._wave_duration() + 0.1
	game._update_wave()
	assert(game.wave == 5)
	assert(game._is_boss_wave(game.wave))
	assert(game.shopping)
	game._close_shop()
	game._update_spawning(0.016)
	var boss_index: int = game.enemies.size() - 1
	assert(bool(game.enemies[boss_index]["boss"]))
	assert(String(game.enemies[boss_index]["boss_modifier"]) == "frenzy")
	game._damage_enemy(boss_index, 10000000.0, "judge_brush")
	assert(game.state == game.GameState.RUNNING)
	assert(not game.pending_victory)
	assert(game.endless_bosses_defeated == 1)
	assert(game.endless_boss_cleared_wave == 5)
	game._update_wave()
	assert(game.wave == 6)
	assert(game._content_stage_index() == 3)

	game.enemies.clear()
	var warded: Dictionary = game._make_enemy(game.player_position + Vector2(180, 0), 20.0, 0.0, 500.0, 0.0, 1, Color.WHITE)
	warded["modifier"] = "warded"
	warded["ward_charges"] = 1
	game.enemies.append(warded)
	game._damage_enemy(0, 100.0, "sword")
	assert(is_equal_approx(float(game.enemies[0]["hp"]), 500.0))
	game._damage_enemy(0, 100.0, "sword")
	assert(is_equal_approx(float(game.enemies[0]["hp"]), 400.0))

	game.enemies.clear()
	var target: Dictionary = game._make_enemy(game.player_position + Vector2(240, 0), 24.0, 0.0, 100000.0, 0.0, 1, Color.WHITE)
	game.enemies.append(target)
	game._cast_judge_brush(5)
	game._cast_soul_lantern(5)
	assert(float(game.run_weapon_damage.get("judge_brush", 0.0)) > 0.0)
	assert(float(game.run_weapon_damage.get("soul_lantern", 0.0)) > 0.0)

	game.passive_levels["soul_feast"] = 3
	game.health = 50.0
	game.enemies.clear()
	game.enemies.append(game._make_enemy(game.player_position + Vector2(100, 0), 16.0, 0.0, 1.0, 0.0, 1, Color.WHITE))
	game._damage_enemy(0, 10.0, "judge_brush")
	assert(game.health > 50.0)

	game._leave_current_run()
	assert(game.run_settled)
	assert(game.state == game.GameState.LOST)
	assert("无尽镇守" in game.result_title.text)
	assert(game.meta.first_clears.is_empty())

	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)
	print("无尽模式测试通过：大地图、周期首领、轮换地域、敌人词缀、新法器与主动结算正常")
	quit()
