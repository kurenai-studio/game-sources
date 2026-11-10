extends SceneTree


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	OS.set_environment("ZHENYE_CAPTURE", "1")
	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	var arguments := OS.get_cmdline_user_args()
	var output := "/tmp/opencode/zhenye-ui.png"
	if "--stages" in arguments:
		game._open_stage_select()
		output = "/tmp/opencode/zhenye-stages.png"
	elif "--endless-stage" in arguments:
		game._open_stage_select()
		game._toggle_endless_mode()
		output = "/tmp/opencode/zhenye-endless-stage.png"
	elif "--endless-battle" in arguments:
		game._select_stage(1)
		game.selected_endless_mode = true
		game._start_game()
		game.max_health = 100000.0
		game.health = game.max_health
		game.wave = 5
		game.weapon_levels = {"judge_brush": 5, "soul_lantern": 5, "talisman": 3, "bell": 3}
		game.evolved_weapons = {"judge_brush": true, "soul_lantern": true}
		game.enemies.clear()
		for index in 20:
			game._spawn_regular_enemy(game.ENDLESS_ENEMY_POOL[index % game.ENDLESS_ENEMY_POOL.size()], game.player_position + Vector2.from_angle(TAU * float(index) / 20.0) * (220.0 + index % 3 * 80.0))
			game.enemies[-1]["modifier"] = game.ENDLESS_ENEMY_MODIFIERS[index % game.ENDLESS_ENEMY_MODIFIERS.size()]
			if String(game.enemies[-1]["modifier"]) == "warded":
				game.enemies[-1]["ward_charges"] = 1
		game._spawn_boss()
		game.enemies[-1]["position"] = game.player_position + Vector2(420, -180)
		game._cast_judge_brush(5)
		game._cast_soul_lantern(5)
		game.game_paused = true
		game.banner_timer = 0.0
		game.banner_label.hide()
		game._update_hud()
		output = "/tmp/opencode/zhenye-endless-battle.png"
	elif "--talents-top" in arguments:
		game.meta.currencies["incense"] = 200
		game.meta.talents["vitality"] = 3
		game._open_talent_tree()
		game.talent_tree_scroll.set_deferred("scroll_horizontal", 534)
		game.talent_tree_scroll.set_deferred("scroll_vertical", 0)
		output = "/tmp/opencode/zhenye-talents-top.png"
	elif "--talents-middle" in arguments:
		game.meta.currencies["incense"] = 200
		game.meta.talents["vitality"] = 3
		game._open_talent_tree()
		game.talent_tree_scroll.set_deferred("scroll_horizontal", 220)
		game.talent_tree_scroll.set_deferred("scroll_vertical", 370)
		output = "/tmp/opencode/zhenye-talents-middle.png"
	elif "--talents" in arguments:
		game.meta.currencies["incense"] = 200
		game.meta.talents["vitality"] = 3
		game._open_talent_tree()
		output = "/tmp/opencode/zhenye-talents.png"
	elif "--inventory-filter" in arguments:
		game._open_inventory()
		game._select_equipped_slot("charm")
		output = "/tmp/opencode/zhenye-inventory-filter.png"
	elif "--inventory-detail" in arguments:
		game.meta.inventory[0]["stats"] = {"damage": 0.12, "cooldown": 0.08, "experience": 0.1, "pickup": 0.15}
		game.meta.inventory[0]["rule"] = game.meta.SLOT_RULE_AFFIX[String(game.meta.inventory[0]["slot"])]
		game._open_inventory()
		game._select_inventory_item(int(game.meta.inventory[0]["uid"]))
		output = "/tmp/opencode/zhenye-inventory-detail.png"
	elif "--inventory" in arguments:
		game._open_inventory()
		output = "/tmp/opencode/zhenye-inventory.png"
	elif "--new-equipment" in arguments:
		game.meta.inventory.clear()
		var uid := 1
		for slot in game.meta.SLOT_ORDER:
			game.meta.equipped[slot] = 0
			for template in range(6, 9):
				var item := {"uid": uid, "slot": slot, "name": game.meta.ITEM_NAMES[slot][template], "template": template, "rarity": 3, "level": 0, "stats": {}, "source_stage": 3, "rule": game.meta.SLOT_RULE_AFFIX[slot]}
				if slot == "weapon":
					item["weapon_key"] = game.meta.WEAPON_KEYS[template]
				game.meta.inventory.append(item)
				uid += 1
		game._open_inventory()
		game._select_inventory_item(1)
		output = "/tmp/opencode/zhenye-new-equipment.png"
	elif "--pause" in arguments:
		game._start_game()
		game.weapon_levels = {"sword": 3, "mirror": 3, "talisman": 2, "banner": 3, "thunder": 1}
		game._pause_game()
		output = "/tmp/opencode/zhenye-pause.png"
	elif "--upgrade" in arguments:
		game._start_game()
		game.pending_upgrades = 1
		game.weapon_levels = {"sword": 3, "mirror": 3, "talisman": 2, "banner": 3, "thunder": 1}
		game._show_upgrade_choices()
		output = "/tmp/opencode/zhenye-upgrade.png"
	elif "--result" in arguments:
		game._start_game()
		game.run_settled = true
		game.elapsed = 247.0
		game.level = 18
		game.defeated = 426
		game.run_damage_dealt = 128640.0
		game.run_damage_taken = 83.0
		game.run_weapon_damage = {"mirror": 47280.0, "sword": 31600.0}
		game._finish_game(false)
		output = "/tmp/opencode/zhenye-result.png"
	elif "--roles" in arguments:
		game._select_stage(1)
		game._start_game()
		game.weapon_levels = {"sword": 3, "mirror": 3, "thunder": 3, "chain": 3}
		game.enemies.clear()
		game._spawn_regular_enemy("paper_summoner", game.player_position + Vector2(-260, -80))
		game._spawn_regular_enemy("revenant", game.player_position + Vector2(0, -210))
		game._kill_enemy(1)
		game._spawn_regular_enemy("warden", game.player_position + Vector2(270, -60))
		game._queue_area_telegraph(game.player_position + Vector2(170, 120), 105.0, 0.0, 0.9, "snare", int(game.enemies[2]["id"]))
		game.weapon_timers = {"sword": 999.0, "mirror": 999.0, "thunder": 999.0, "chain": 999.0}
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-roles.png"
	elif "--ten-weapons" in arguments:
		game._start_game()
		for weapon in game.WEAPON_DATA.keys():
			game.weapon_levels[weapon] = 5
			game.evolved_weapons[weapon] = true
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-ten-weapons.png"
	elif "--large-map" in arguments:
		game._select_stage(1)
		game._start_game()
		game.player_position = game.ARENA_SIZE - Vector2(700, 500)
		game.camera.position = game.player_position
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-large-map.png"
	elif "--boss-eye" in arguments:
		game._select_stage(0)
		game._start_game()
		game.enemies.clear()
		game._spawn_boss()
		game.enemies[0]["position"] = game.player_position + Vector2(300, -170)
		game._queue_eye_cross(game.player_position, 3, int(game.enemies[0]["id"]), PI * 0.25)
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-boss-eye.png"
	elif "--boss-bone" in arguments:
		game._select_stage(1)
		game._start_game()
		game.enemies.clear()
		game._spawn_boss()
		game.enemies[0]["position"] = game.player_position + Vector2(300, -170)
		game._queue_bone_cage(game.player_position, 3, int(game.enemies[0]["id"]), 2)
		game._spawn_bone_guards(Vector2(game.enemies[0]["position"]), 3)
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-boss-bone.png"
	elif "--boss-wheel" in arguments:
		game._select_stage(2)
		game._start_game()
		game.enemies.clear()
		game._spawn_boss()
		game.enemies[0]["position"] = game.player_position + Vector2(300, -170)
		game._queue_void_wheel(Vector2(game.enemies[0]["position"]), 3, int(game.enemies[0]["id"]))
		game._spawn_array_eyes(Vector2(game.enemies[0]["position"]), 3)
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-boss-wheel.png"
	elif "--water-battle" in arguments:
		game._select_stage(3)
		game._start_game()
		game.max_health = 100000.0
		game.health = game.max_health
		game.experience_needed = 999999
		game.pending_upgrades = 0
		game.weapon_levels = {"tide_gourd": 3, "ferry_oar": 3, "nether_lotus": 3, "talisman": 3, "bell": 3, "banner": 3}
		game.weapon_timers.clear()
		for index in 35:
			game._spawn_regular_enemy(["algae_drowned", "river_lantern", "headless_boatman", "soul_netter", "leech_medium"][index % 5])
		for frame in 100:
			game._physics_process(1.0 / 60.0)
		game._queue_tide_event()
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-water-battle.png"
	elif "--snow-battle" in arguments:
		game._select_stage(4)
		game._start_game()
		game.max_health = 100000.0
		game.health = game.max_health
		game.experience_needed = 999999
		game.pending_upgrades = 0
		game.weapon_levels = {"ice_needles": 3, "frost_stele": 3, "snow_umbrella": 3, "thunder": 3, "chain": 3, "mirror": 3}
		game.weapon_timers.clear()
		for index in 32:
			game._spawn_regular_enemy(["snow_stalker", "ice_coffin", "gale_wraith", "frost_jailer"][index % 4])
		for frame in 100:
			game._physics_process(1.0 / 60.0)
		game._queue_avalanche_event()
		game.game_paused = true
		game._update_hud()
		output = "/tmp/opencode/zhenye-snow-battle.png"
	elif "--hero" in arguments:
		game._select_stage(2)
		game._start_game()
		game.max_health = 100000.0
		game.health = game.max_health
		game.experience_needed = 999999
		game.wave = 4
		game.weapon_levels = {"sword": 5, "thunder": 5, "talisman": 5, "bell": 5, "orb": 5, "mirror": 5}
		game.evolved_weapons = {"sword": true, "thunder": true, "talisman": true}
		game.weapon_timers.clear()
		for index in 38:
			game._spawn_regular_enemy(["ghost", "paper", "stone", "lantern", "jiangshi", "splitter"][index % 6], game.player_position + Vector2.from_angle(TAU * float(index) / 38.0 + sin(float(index) * 1.7) * 0.5) * (150.0 + fmod(float(index) * 137.0, 470.0)))
		for frame in 140:
			game._physics_process(1.0 / 60.0)
		game.elapsed = game._wave_duration() * 3.0 + 0.5
		game._update_wave()
		game.max_health = 180.0
		game.health = 137.0
		game.experience_needed = 6
		game.experience = 3
		game.pending_upgrades = 0
		game.shopping = false
		game.shop_panel.hide()
		game.upgrade_panel.hide()
		game.game_paused = true
		game.banner_timer = 0.0
		game.banner_label.hide()
		game._update_hud()
		output = "/tmp/opencode/zhenye-hero.png"
	elif "--battle" in arguments:
		game._start_game()
		game.weapon_levels = {"sword": 3, "talisman": 3, "thunder": 3, "bell": 3, "orb": 3, "mirror": 3}
		game.weapon_timers.clear()
		for index in 45:
			game._spawn_regular_enemy(["ghost", "paper", "stone", "lantern", "jiangshi", "splitter"][index % 6])
		for frame in 120:
			game._physics_process(1.0 / 60.0)
		for index in 7:
			var angle := TAU * float(index) / 7.0
			var origin: Vector2 = game.player_position + Vector2.from_angle(angle) * 240.0
			game._spawn_aimed_shot(origin, (game.player_position - origin).normalized(), 40.0, 8.0, 9.0)
		var warning_origin: Vector2 = game.player_position + Vector2(330.0, -170.0)
		game._spawn_boss()
		game.enemies[game.enemies.size() - 1]["position"] = warning_origin
		game.enemies[game.enemies.size() - 1]["cast_timer"] = 0.78
		game._queue_boss_telegraph(warning_origin, 2, 1, (game.player_position - warning_origin).normalized(), int(game.enemies[game.enemies.size() - 1]["id"]))
		game._update_hud()
		output = "/tmp/opencode/zhenye-battle.png"
	await process_frame
	await process_frame
	var image := root.get_texture().get_image()
	image.save_png(output)
	if game.music_player != null:
		game.music_player.stop()
	if game.ambient_player != null:
		game.ambient_player.stop()
	for player in game.sfx_players.values():
		player.stop()
	game.free()
	OS.set_environment("ZHENYE_CAPTURE", "")
	await process_frame
	quit()
