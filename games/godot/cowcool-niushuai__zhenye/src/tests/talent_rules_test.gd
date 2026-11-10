extends SceneTree

const TEST_SAVE := "user://zhenye_talent_rules_test.json"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var absolute_path := ProjectSettings.globalize_path(TEST_SAVE)
	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)
	var meta := MetaProgression.new(TEST_SAVE, false)
	assert(meta.TALENT_ORDER.size() == 17)
	for talent_id in meta.TALENT_ORDER:
		meta.talents[talent_id] = int(meta.TALENT_DATA[talent_id]["max_rank"])
	var stats := meta.aggregate_stats()
	assert(float(stats["damage_reduction"]) >= 0.125)
	assert(float(stats["copper_bonus"]) >= 0.4)
	assert(is_equal_approx(float(stats["health_regen"]), 0.5))
	for rule in ["opening_arsenal", "boss_hunter", "rebirth", "soul_vacuum", "shop_discount", "unbound_evolution"]:
		assert(rule in stats["rules"])

	var scene := load("res://main.tscn") as PackedScene
	var game := scene.instantiate()
	root.add_child(game)
	await process_frame
	game.meta = meta
	game._start_game()
	assert(game.weapon_levels.size() == 4)
	assert(game.damage_reduction >= 0.125)
	assert(game.copper_bonus >= 0.4)
	assert(is_equal_approx(game.health_regen, 0.5))
	assert(game.rebirth_available)
	assert(game._shop_good_cost("weapon:sword") == 20)
	game.health = 50.0
	game._physics_process(1.0)
	assert(is_equal_approx(game.health, 50.5))

	game.weapon_levels["sword"] = 5
	game.passive_levels.clear()
	assert(game._can_evolve_weapon("sword"))

	game.enemies.clear()
	var boss: Dictionary = game._make_enemy(game.player_position + Vector2(200, 0), 40.0, 0.0, 100.0, 0.0, 0, Color.WHITE, "boss")
	boss["boss"] = true
	game.enemies.append(boss)
	game._damage_enemy(0, 20.0, "sword")
	assert(is_equal_approx(float(game.enemies[0]["hp"]), 75.0))

	game.xp_orbs.clear()
	game.xp_orbs.append({"position": game.player_position + Vector2(1000, 0), "value": 1})
	var orb_distance: float = Vector2(game.xp_orbs[0]["position"]).distance_to(game.player_position)
	game._update_xp_orbs(0.5)
	assert(Vector2(game.xp_orbs[0]["position"]).distance_to(game.player_position) < orb_distance)

	game.emergency_guard_charges = 0
	game.health = 10.0
	game._take_damage(100.0, "boss")
	assert(not game.rebirth_available)
	assert(is_equal_approx(game.health, game.max_health * 0.35))
	assert(game.hurt_timer >= 1.9)

	if FileAccess.file_exists(TEST_SAVE):
		DirAccess.remove_absolute(absolute_path)
	print("命盘神通测试通过：持续回血、开局法器、鬼市折扣、首领增伤、全图摄魂、自由进化和复生正常")
	quit()
