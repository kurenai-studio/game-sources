# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The Longbow Loft and the Firework Tower with both of their paths, and the armored
## flyer (RULES 5.6, 5.7, 6.1, 6.5, 8.2 to 8.4).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const ALL_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _line(groups: Array) -> Battle:
	return Fx.battle(Fx.LINE_GRID, [{"groups": groups}], {"start_gold": 9000, "towers": ALL_TOWERS}, catalog)


func _build(b: Battle, cell: Vector2i, type: StringName, tier: int = 1, spec: int = -1) -> void:
	assert_eq(b.place_tower(cell, type), Battle.DONE, "build %s" % type)
	if tier >= 2:
		assert_eq(b.upgrade_tower(cell), Battle.DONE)
	if tier >= 3:
		assert_eq(b.upgrade_tower(cell, spec), Battle.DONE)


func test_every_longbow_tier_ignores_armor_rules_5_6_and_8_3() -> void:
	for key: Array in [[1, -1], [2, -1], [3, 0], [3, 1]]:
		var b: Battle = _line([Fx.group("shellback", 1)])
		_build(b, Vector2i(2, 1), &"longbow_loft", key[0], key[1])
		var stats: TowerStats = Fx.stats(catalog, &"longbow_loft", key[0], key[1])
		assert_true(stats.pierce, "tier %d spec %d pierces" % key)
		b.start_next_wave()
		b.step()
		var shell: EnemyState = b.enemy_with_id(0)
		if shell == null:
			assert_true(stats.damage >= catalog.enemy(&"shellback").health, "one arrow defeated it")
		else:
			assert_eq(shell.max_health - shell.health, stats.damage, "the full %d, armor or not" % stats.damage)


func test_longbows_and_catapults_never_hit_flyers_rules_6_5() -> void:
	for type: StringName in [&"longbow_loft", &"pumpkin_catapult"]:
		var b: Battle = _line([Fx.group("flitter", 2, 0, 500)])
		_build(b, Vector2i(2, 3), type)
		b.start_next_wave()
		assert_eq(Fx.of_kind(Fx.log_ticks(b, 300), &"fired").size(), 0, "%s never fires at flyers" % type)


func test_triple_bow_picks_three_different_creatures_in_aim_order_rules_5_6_and_8_2() -> void:
	var stats: TowerStats = Fx.stats(catalog, &"longbow_loft", 3, 1)
	assert_eq(stats.targets, 3)
	var b: Battle = _line([Fx.group("scamp", 4, 0, 500)])
	b.start_next_wave()
	Fx.steps(b, 40)
	_build(b, Vector2i(2, 3), &"longbow_loft", 3, 1)
	b.take_events()
	b.step()
	var fired: Array[Dictionary] = Fx.events_of(b.take_events(), &"fired")
	assert_eq(fired.size(), 1, "one shot")
	assert_eq(fired[0]["targets"], [0, 1, 2] as Array[int], "three arrows, First order")
	assert_eq(fired[0]["spec"], 1)


func test_giant_bow_is_one_giant_arrow_rules_5_6() -> void:
	var stats: TowerStats = Fx.stats(catalog, &"longbow_loft", 3, 0)
	assert_eq(stats.targets, 1)
	var b: Battle = _line([Fx.group("grumblesack", 1)])
	_build(b, Vector2i(2, 1), &"longbow_loft", 3, 0)
	b.start_next_wave()
	b.step()
	var boss: EnemyState = b.enemy_with_id(0)
	assert_eq(boss.max_health - boss.health, stats.damage)


func test_fireworks_hit_only_flyers_and_splash_only_flyers_rules_5_7_and_8_4() -> void:
	# A Flitter flies over a Scamp walking the same road. The burst never touches the Scamp.
	var b: Battle = _line([Fx.group("scamp", 1), Fx.group("flitter", 1)])
	_build(b, Vector2i(2, 1), &"firework_tower")
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 100)
	var fired: Array = Fx.of_kind(log, &"fired")
	assert_true(fired.size() > 0, "it fires at the flyer")
	for entry: Array in fired:
		assert_eq(entry[1]["targets"], [1] as Array[int], "only the Flitter is a target")
	var scamp: EnemyState = b.enemy_with_id(0)
	if scamp != null:
		assert_eq(scamp.health, scamp.max_health, "the Scamp under the burst is untouched")


func test_firework_splash_hits_every_flyer_in_the_radius_rules_5_7() -> void:
	for spec: int in [-1, 0]:
		var b: Battle = _line([Fx.group("flitter", 3, 0, 50)])
		var tier: int = 1 if spec < 0 else 3
		b.start_next_wave()
		Fx.steps(b, 3)
		_build(b, Vector2i(2, 1), &"firework_tower", tier, spec)
		var stats: TowerStats = b.tower_at(Vector2i(2, 1)).stats
		b.step()
		var hurt: int = 0
		for e: EnemyState in b.enemies:
			if e.health < e.max_health:
				hurt += 1
		# Flitters 0.05 s apart at 1.2 tiles a second are 0.06 tiles apart: one burst
		# reaches all three.
		assert_eq(hurt + (3 - b.enemies.size()), 3, "spec %d: the burst reaches the whole flock (splash %d)" % [spec, stats.splash])


func test_skyrocket_is_one_heavy_rocket_that_ignores_armor_rules_5_7() -> void:
	var stats: TowerStats = Fx.stats(catalog, &"firework_tower", 3, 1)
	assert_eq([stats.splash, stats.pierce, stats.hits_ground, stats.hits_air], [0, true, false, true])
	var b: Battle = _line([Fx.group("dusk_moth", 2, 0, 50)])
	b.start_next_wave()
	Fx.steps(b, 2)
	_build(b, Vector2i(2, 1), &"firework_tower", 3, 1)
	b.step()
	var first: EnemyState = b.enemy_with_id(0)
	var second: EnemyState = b.enemy_with_id(1)
	assert_eq(first.max_health - first.health, stats.damage, "armor 5 ignored")
	assert_eq(second.health, second.max_health, "one target only")


func test_dusk_moth_is_an_armored_flyer_rules_6_1() -> void:
	var moth: EnemyType = catalog.enemy(&"dusk_moth")
	assert_true(moth.flying)
	assert_true(moth.armor > 0)
	for key: Array in [[1, -1], [3, 1]]:
		var b: Battle = _line([Fx.group("dusk_moth", 1)])
		_build(b, Vector2i(2, 1), &"sling_post", key[0], key[1])
		var damage: int = b.tower_at(Vector2i(2, 1)).stats.damage
		b.start_next_wave()
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		assert_eq(e.max_health - e.health, maxi(1, damage - moth.armor), "Sling Post tier %d" % key[0])
