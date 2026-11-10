extends SceneTree

const TEST_SAVE := "user://zhenye_flow_test.json"


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

	var meta := MetaProgression.new(TEST_SAVE, false)
	var weapon_item := {
		"uid": 1,
		"slot": "weapon",
		"name": "五帝钱串",
		"template": 4,
		"rarity": 2,
		"level": 0,
		"stats": {"damage": 0.2},
		"source_stage": 0,
		"weapon_key": "coin",
		"rule": "opening_purse",
	}
	var head_item := {
		"uid": 2,
		"slot": "head",
		"name": "七星道冠",
		"template": 0,
		"rarity": 1,
		"level": 0,
		"stats": {"health": 0.1},
		"source_stage": 0,
		"rule": "free_reroll",
	}
	meta.next_uid = 3
	meta.currencies["incense"] = 100
	meta.add_item(weapon_item)
	meta.add_item(head_item)
	meta.equip_item(1)
	meta.equip_item(2)
	game.meta = meta
	assert(game.ready_overlay.visible)
	assert(not game.stage_overlay.visible)
	assert(not game.inventory_overlay.visible)
	game._open_stage_select()
	assert(game.stage_overlay.visible)
	assert(not game.ready_overlay.visible)
	game._close_stage_select()
	assert(game.ready_overlay.visible)
	game._open_talent_tree()
	assert(game.talent_overlay.visible)
	assert(not game.ready_overlay.visible)
	game._upgrade_selected_talent()
	assert(meta.talent_rank("vitality") == 1)
	assert(int(meta.currencies["incense"]) == 88)
	game._close_talent_tree()
	assert(game.ready_overlay.visible)
	game._open_inventory()
	assert(game.inventory_overlay.visible)
	assert(not game.ready_overlay.visible)
	assert(game.inventory_slot_buttons[0].icon != null)
	assert(game.inventory_grid.get_child_count() == 2)
	assert(game.inventory_grid.get_child(0).icon != null)
	game._select_inventory_item(1)
	assert(game.inventory_detail_icon.texture != null)
	game._select_equipped_slot("weapon")
	assert(game.inventory_filter_slot == "weapon")
	assert(game.inventory_grid.get_child_count() == 1)
	assert(String(game.inventory_grid.get_child(0).get_meta("item_slot")) == "weapon")
	game._set_inventory_filter("")
	assert(game.inventory_grid.get_child_count() == 2)
	game._close_inventory()
	assert(game.ready_overlay.visible)
	game._start_game()
	assert(game.weapon_levels.has("coin"))
	assert(game.equipment_damage_bonus >= 0.2)
	assert(game.max_health >= 114.9)
	assert(game.run_copper == 20)
	var cancel_event := InputEventAction.new()
	cancel_event.action = "ui_cancel"
	cancel_event.pressed = true
	var elapsed_before_pause: float = game.elapsed
	game._unhandled_input(cancel_event)
	assert(game.game_paused)
	assert(game.pause_overlay.visible)
	assert("财气两仪" in game.pause_synergy_codex.get_parsed_text())
	assert("阴阳玉未有" in game.pause_synergy_codex.get_parsed_text())
	game._physics_process(0.5)
	assert(is_equal_approx(game.elapsed, elapsed_before_pause))
	game._unhandled_input(cancel_event)
	assert(not game.game_paused)
	assert(not game.pause_overlay.visible)

	game._spawn_elite()
	var elite_index: int = game.enemies.size() - 1
	game._kill_enemy(elite_index)
	assert(game.loot_orbs.size() == 1)
	game.loot_orbs[0]["position"] = game.player_position
	game._update_loot_orbs(0.016)
	assert(game.run_loot.size() == 1)

	game.run_copper = 200
	game.elapsed = game._wave_duration() + 0.1
	game._update_wave()
	assert(game.shopping)
	assert(game.wave_records.size() == 1)
	assert(int(game.wave_records[0]["wave"]) == 1)
	assert(game.wave_records[0].has("damage_dealt"))
	assert(game.shop_free_reroll_available)
	game._reroll_shop()
	assert(game.run_copper == 200)
	assert(not game.shop_free_reroll_available)
	game._buy_shop_good(0)
	game._close_shop()
	assert(not game.shopping)
	game._finish_game(false)
	assert(FileAccess.file_exists(TEST_SAVE))
	assert(meta.inventory.size() >= 2)
	assert("总输出" in game.result_detail.text)
	assert("主力" in game.result_detail.text)
	game._return_to_lobby()
	game._open_inventory()
	assert(game.inventory_overlay.visible)
	game._close_inventory()

	DirAccess.remove_absolute(absolute_path)
	print("流程测试通过：装备加成、战斗掉落、鬼市、结算和道观背包闭环正常")
	quit()
