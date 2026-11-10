extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://main.tscn") as PackedScene
	assert(scene != null)
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame

	game._start_game()
	assert(game.state == game.GameState.RUNNING)
	assert(game.MAX_WEAPONS == 18)
	assert(game.ARENA_SIZE.x >= 3600.0 and game.ARENA_SIZE.y >= 2400.0)
	var early_spawn_interval: float = game._current_spawn_interval()
	game._spawn_regular_enemy("ghost", game.player_position + Vector2(320, 0))
	var early_enemy: Dictionary = game.enemies[0].duplicate()
	game.enemies.clear()
	game.wave = game._boss_wave() - 1
	var late_spawn_interval: float = game._current_spawn_interval()
	game._spawn_regular_enemy("ghost", game.player_position + Vector2(320, 0))
	var late_enemy: Dictionary = game.enemies[0].duplicate()
	assert(early_spawn_interval > 1.0)
	assert(late_spawn_interval < 0.3)
	assert(float(late_enemy["hp"]) > float(early_enemy["hp"]) * 3.5)
	assert(float(late_enemy["damage"]) > float(early_enemy["damage"]) * 1.5)
	assert(float(late_enemy["speed"]) > float(early_enemy["speed"]))
	game.enemies.clear()
	game.wave = 1
	game.elapsed = 0.0
	game.stage_event_timer = float(game._stage_data()["event_interval"]) * 0.75
	for weapon in game.WEAPON_DATA.keys():
		assert(game.pixel_assets["audio"].has("weapon_%s" % weapon))
		assert(game.pixel_assets["audio"]["weapon_%s" % weapon] != null)
	assert(game.pixel_assets["audio"]["stage_music"].size() == 5)
	assert(game.pixel_assets["audio"]["stage_ambient"].size() == 5)
	for stage_audio in game.pixel_assets["audio"]["stage_music"] + game.pixel_assets["audio"]["stage_ambient"]:
		assert(stage_audio != null)
	game.elapsed = 0.0
	game._play_weapon_sfx("sword")
	game._play_weapon_sfx("coin")
	assert(game.weapon_sfx_last_played.has("sword"))
	assert(not game.weapon_sfx_last_played.has("coin"))
	game.elapsed = 0.2
	game._play_weapon_sfx("coin")
	assert(game.weapon_sfx_last_played.has("coin"))
	game.elapsed = 0.0
	game.weapon_sfx_last_played.clear()
	game.weapon_sfx_global_time = -100.0
	game.emergency_guard_charges = 1
	game.health = 10.0
	game._take_damage(20.0, "projectile")
	assert(game.health == 1.0)
	assert(game.emergency_guard_charges == 0)
	game.health = game.max_health
	game.pending_upgrades = 0

	game._spawn_regular_enemy()
	assert(game.enemies.size() == 1)
	game.enemies[0]["position"] = game.player_position + Vector2(120.0, 0.0)
	game.enemies[0]["hp"] = 1.0
	for frame in 30:
		game._physics_process(0.05)
	assert(game.defeated >= 1)

	game._gain_experience(game.experience_needed)
	assert(game.level == 2)
	assert(game.pending_upgrades == 1)
	game._show_upgrade_choices()
	assert(game.upgrade_choices.size() == 3)
	assert("剑镜同辉" in game.upgrade_synergy_codex.get_parsed_text())
	game._on_upgrade_pressed(0)
	assert(game.pending_upgrades == 0)
	game.run_copper = 200
	game._show_shop()
	assert(game.shop_goods.size() == 4)
	var locked_choice: String = game.shop_goods[0]["choice"]
	game.shop_lock_buttons[0].button_pressed = true
	game._reroll_shop()
	assert(String(game.shop_goods[0]["choice"]) == locked_choice)
	game.shop_lock_buttons[1].button_pressed = true
	var next_wave_choice: String = game.shop_goods[1]["choice"]
	var next_wave_cost: int = game.shop_goods[1]["cost"]
	game._buy_shop_good(0)
	assert(bool(game.shop_goods[0]["sold"]))
	game._close_shop()
	assert(not game.shopping)
	game._show_shop()
	assert(String(game.shop_goods[1]["choice"]) == next_wave_choice)
	assert(int(game.shop_goods[1]["cost"]) == next_wave_cost)
	assert(game.shop_lock_buttons[1].button_pressed)
	game._close_shop()
	game.loot_orbs.append({"position": game.player_position, "source": "elite"})
	game._update_loot_orbs(0.016)
	assert(game.run_loot.size() == 1)

	game.weapon_levels.clear()
	for weapon in game.WEAPON_DATA.keys():
		game.weapon_levels[weapon] = 3
	game.weapon_timers = {}
	assert(game.weapon_levels.size() == game.MAX_WEAPONS)
	for index in 14:
		game._spawn_regular_enemy()
	for enemy in game.enemies:
		enemy["hp"] = 1000.0
		enemy["max_hp"] = 1000.0
	game._fire_swords(3)
	game._fire_talismans(3)
	game._cast_thunder(3)
	game._ring_bell(3)
	game._throw_coins(3)
	game._spin_orbs(3)
	game._cast_chain(3)
	game._cast_banner(3)
	game._release_paper_dolls(3)
	game._cast_mirror(3)
	game._cast_tide_gourd(3)
	game._swing_ferry_oar(3)
	game._cast_nether_lotus(3)
	game._fire_ice_needles(3)
	game._cast_frost_stele(3)
	game._spin_snow_umbrella(3)
	game._cast_judge_brush(3)
	game._cast_soul_lantern(3)
	assert(game.projectiles.size() >= 3)
	assert(game.area_effects.size() >= 4)
	assert(not game._weapon_rank_effect("mirror", 5).is_empty())
	assert(not game._weapon_rank_effect("talisman", 3).is_empty())

	for weapon in game.WEAPON_DATA.keys():
		game.weapon_levels[weapon] = 5
	for passive in game.PASSIVE_DATA.keys():
		game.passive_levels[passive] = 3
	for weapon_index in range(6, game.WEAPON_ORDER.size()):
		var removed_weapon: String = game.WEAPON_ORDER[weapon_index]
		game.weapon_levels.erase(removed_weapon)
		game.evolved_weapons.erase(removed_weapon)
	for weapon in game.weapon_levels.keys():
		game.evolved_weapons[weapon] = true
	var copper_before_remaining_weapons: int = game.run_copper
	game.pending_upgrades = 1
	game._show_upgrade_choices()
	assert(game.choosing_upgrade)
	assert(game.upgrade_panel.visible)
	assert(game.run_copper == copper_before_remaining_weapons)
	for choice in game.upgrade_choices:
		assert(choice.begins_with("weapon:"))
	game.choosing_upgrade = false
	game.upgrade_panel.hide()
	game.evolved_weapons.clear()
	for weapon in game.WEAPON_DATA.keys():
		game.weapon_levels[weapon] = 5
	game.passive_levels = {"sword_art": 1, "flame_heart": 1, "breathing": 1, "vitality": 1, "magnet": 1, "footwork": 1, "insight": 1, "soul_feast": 1}
	for weapon in game.WEAPON_DATA.keys():
		assert(game._can_evolve_weapon(weapon))
		assert(game._shop_candidates().has("evolve:%s" % weapon))
		game._apply_upgrade("evolve:%s" % weapon)
	assert(game.evolved_weapons.size() == 18)
	game.projectiles.clear()
	game._throw_coins(5)
	assert(game.projectiles.size() == 5)
	assert(game._orb_positions(5).size() == 10)
	game.projectiles.clear()
	game._release_paper_dolls(5)
	assert(game.projectiles.size() == 5)
	game.area_effects.clear()
	game._cast_mirror(5)
	assert(game.area_effects.size() == 6)
	assert(game._active_weapon_synergies().size() == 13)
	game._update_hud()
	assert(game.synergy_label.visible)
	assert("全部激活" in game.synergy_label.text)
	assert("剑镜同辉" in game._weapon_synergy_hint("sword"))
	var active_codex: String = game._synergy_codex_text()
	assert("已激活" in active_codex)
	assert("镜光伤害+25%" in active_codex)
	game.weapon_levels = {"sword": 3, "mirror": 3, "talisman": 2, "banner": 3, "thunder": 1}
	var mixed_codex: String = game._synergy_codex_text()
	assert("已激活" in mixed_codex)
	assert("可激活" in mixed_codex)
	assert("待收集" in mixed_codex)
	assert("缚妖索未有" in mixed_codex)
	game._refresh_synergy_codex()
	assert("雷索天引" in game.pause_synergy_codex.get_parsed_text())
	for weapon in game.WEAPON_DATA.keys():
		game.weapon_levels[weapon] = 5
	game.choosing_upgrade = false
	game.upgrade_panel.hide()

	assert(game.STAGE_DATA.size() == 5)
	game.enemies.clear()
	game._spawn_regular_enemy("paper_summoner", game.player_position + Vector2(320, 0))
	game.enemies[0]["summon_timer"] = 0.0
	game._update_enemies(0.01)
	assert(game.enemies.size() == 4)
	game.enemies.clear()
	game._spawn_regular_enemy("revenant", game.player_position + Vector2(320, 0))
	game._kill_enemy(0)
	assert(game.enemies.size() == 1)
	assert(float(game.enemies[0]["revive_timer"]) > 0.0)
	game._update_enemies(1.7)
	assert(float(game.enemies[0]["hp"]) > 1.0)
	game._kill_enemy(0)
	assert(game.enemies.is_empty())
	game.attack_telegraphs.clear()
	game._spawn_regular_enemy("warden", game.player_position + Vector2(360, 0))
	game.enemies[0]["control_timer"] = 0.0
	game._update_enemies(0.01)
	assert(not game.attack_telegraphs.is_empty())
	game._update_attack_telegraphs(1.0)
	assert(game.player_slow_timer > 0.0)
	game.enemies.clear()
	game.attack_telegraphs.clear()
	game._select_stage(1)
	game.wave = 2
	game.stage_event_timer = 0.0
	game._update_stage_events(0.1)
	var grave_warning_found := false
	for index in game.attack_telegraphs.size():
		if String(game.attack_telegraphs[index]["kind"]) == "area":
			game.attack_telegraphs[index]["position"] = game.player_position
			grave_warning_found = true
			break
	assert(grave_warning_found)
	var health_before_grave: float = game.health
	game.hurt_timer = 0.0
	game._update_attack_telegraphs(1.1)
	assert(game.health < health_before_grave)
	game.attack_telegraphs.clear()
	game._select_stage(2)
	game.stage_event_timer = 0.0
	var projectile_count_before_event: int = game.enemy_projectiles.size()
	var telegraph_count_before_event: int = game.attack_telegraphs.size()
	game._update_stage_events(0.1)
	assert(game.attack_telegraphs.size() > telegraph_count_before_event)
	assert(game.enemy_projectiles.size() == projectile_count_before_event)
	game._update_attack_telegraphs(1.0)
	assert(game.enemy_projectiles.size() > projectile_count_before_event)
	game.enemies.clear()
	for enemy_type in ["algae_drowned", "river_lantern", "headless_boatman", "soul_netter", "leech_medium", "snow_stalker", "ice_coffin", "gale_wraith", "frost_jailer"]:
		game._spawn_regular_enemy(enemy_type, game.player_position + Vector2(320, 0))
	assert(game.enemies.size() == 9)
	game.attack_telegraphs.clear()
	game._select_stage(3)
	game.wave = 4
	game.stage_event_timer = 0.0
	game._update_stage_events(0.1)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "tide_lane"))
	game.attack_telegraphs.clear()
	game._select_stage(4)
	game.wave = 9
	game.stage_event_timer = 0.0
	game._update_stage_events(0.1)
	assert(game.attack_telegraphs.any(func(telegraph): return String(telegraph["kind"]) == "avalanche"))
	game.enemies.clear()
	game.attack_telegraphs.clear()
	game._select_stage(2)
	game.elapsed = game._wave_duration() * float(game._boss_wave() - 1) + 0.1
	game._update_wave()
	game._update_spawning(0.016)
	assert(game.wave == game._boss_wave())
	assert(game.boss_spawned)
	var boss_id: int = game.enemies[game.enemies.size() - 1]["id"]
	var boss_index: int = game._enemy_index_from_id(boss_id)
	game.enemies[boss_index]["hp"] = float(game.enemies[boss_index]["max_hp"]) * 0.6
	game._update_enemies(0.016)
	boss_index = game._enemy_index_from_id(boss_id)
	assert(int(game.enemies[boss_index]["boss_phase"]) == 2)
	game.enemies[boss_index]["hp"] = float(game.enemies[boss_index]["max_hp"]) * 0.25
	game._update_enemies(0.016)
	boss_index = game._enemy_index_from_id(boss_id)
	assert(int(game.enemies[boss_index]["boss_phase"]) == 3)
	game._update_hud()
	assert(game.boss_health_bar.visible)
	assert("第 3 阶段" in game.boss_health_label.text)
	game.queue_redraw()
	await process_frame

	print("冒烟测试通过：十八法器、五章节、无尽模式、十八类敌人和首领流程初始化成功")
	quit()
