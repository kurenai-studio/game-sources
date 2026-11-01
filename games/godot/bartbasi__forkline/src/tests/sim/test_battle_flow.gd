# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Battle phases, waves, strength, spawns, movement, lives, win and loss, economy,
## early calls, refunds, stars and events (RULES 4, 6.4, 6.5, 7.3, 8.1, 10, 11).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _one_wave(groups: Array, changes: Dictionary = {}) -> Battle:
	return Fx.battle(Fx.LINE_GRID, [{"groups": groups}], changes, catalog)


## Steps until the phase leaves WAVE, logging [tick, event] pairs.
func _log(b: Battle, limit: int = 5000) -> Array:
	var out: Array = []
	var ran: int = 0
	while b.phase == Battle.Phase.WAVE and ran < limit:
		var at: int = b.tick
		b.step()
		for event: Dictionary in b.take_events():
			out.append([at, event])
		ran += 1
	return out


func _ticks_of(log: Array, kind: StringName) -> Array[int]:
	var out: Array[int] = []
	for entry: Array in log:
		if entry[1]["kind"] == kind:
			out.append(entry[0])
	return out


func test_create_sets_starting_numbers_rules_4_1_and_11() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 1)], {"start_gold": 250, "gates": 0})
	assert_eq(b.phase, Battle.Phase.BUILD, "a level starts in a build phase")
	assert_eq([b.gold, b.lives, b.start_lives, b.tick, b.waves_started], [250, 20, 20, 0, 0])
	assert_eq(b.wave_count(), 1)
	# RULES 11 and 12.3: Relaxed lives 40, gold 1.5 times rounded up to a multiple of 10.
	for pair: Array in [[200, 300], [250, 380], [300, 450], [350, 530], [800, 1200], [0, 0], [7, 20]]:
		var relaxed: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"start_gold": pair[0]}, catalog, true)
		assert_eq(relaxed.gold, pair[1], "Relaxed gold from %d" % pair[0])
		assert_eq(relaxed.lives, 40)
		assert_true(relaxed.relaxed)
	var gated: Battle = Fx.battle(Fx.FORK_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"gates": 2}, catalog)
	assert_eq(gated.gates_in_hand, 2)


func test_create_checks_its_inputs_contract_3_1() -> void:
	var level: LevelData = Fx.level(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {}, catalog)
	assert_null(Battle.create(null, catalog, false, []))
	assert_null(Battle.create(level, null, false, []))
	assert_null(Battle.create(level, catalog, false, [{"type": "gates_stay"}] as Array[Dictionary]), "a card effect is not a Twist")
	assert_null(Battle.create(level, catalog, false, [{"type": "no_selling", "extra": 1}] as Array[Dictionary]), "exact fields")
	assert_null(Battle.create(level, catalog, false, [{"type": "fixed_gates", "cells": [[3, 2]]}] as Array[Dictionary]), "a fixed gate needs a socket and a gate to give")
	assert_not_null(Battle.create(level, catalog, false, [{"type": "no_selling"}] as Array[Dictionary]))
	var b: Battle = Battle.create(level, catalog, false, [])
	assert_eq(b.add_effects([{"type": "no_selling"}] as Array[Dictionary], false), &"bad_effect", "a Twist effect is not a card")
	assert_eq(b.add_effects([] as Array[Dictionary], false), &"bad_effect", "a card has effects")
	assert_eq(b.card_effects.size(), 0)


func test_nothing_moves_in_a_build_phase_rules_4_2() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 3)])
	Fx.steps(b, 50)
	assert_eq(b.tick, 0)
	assert_eq(b.enemies.size(), 0)
	assert_eq(b.take_events().size(), 0)


func test_groups_spawn_on_their_ticks_rules_12_5_and_8_1() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 3, 500, 1000), Fx.group("pip", 2, 0, 50)])
	assert_eq(b.start_next_wave(), Battle.DONE)
	var log: Array = _log(b)
	var spawned: Array[int] = _ticks_of(log, &"spawned")
	assert_eq(spawned, [0, 1, 10, 30, 50] as Array[int], "pips at 0 and 1, scamps at 0.5, 1.5, 2.5 s")
	var ids: Array[int] = []
	var kinds: Array[StringName] = []
	for entry: Array in log:
		if entry[1]["kind"] == &"spawned":
			ids.append(entry[1]["id"])
			kinds.append(entry[1]["enemy"])
	assert_eq(ids, [0, 1, 2, 3, 4] as Array[int], "every creature gets the next spawn number")
	assert_eq(kinds, [&"pip", &"pip", &"scamp", &"scamp", &"scamp"] as Array[StringName])
	assert_eq(log[0][1]["kind"], &"wave_started")
	assert_eq(log[1][1]["pos"], Sim.center(Vector2i(3, 0)), "walkers appear at their entrance center")


func test_same_tick_groups_spawn_in_wave_data_order_rules_8_1() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 1), Fx.group("pip", 1), Fx.group("scamp", 1)])
	b.start_next_wave()
	b.step()
	var types: Array[StringName] = []
	for e: EnemyState in b.enemies:
		types.append(e.type)
	assert_eq(types, [&"scamp", &"pip", &"scamp"] as Array[StringName])


func test_strength_scales_health_and_bounty_not_armor_or_speed_rules_6_4() -> void:
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"strength": 150, "groups": [Fx.group("shellback", 1), Fx.group("scamp", 1)]}], {}, catalog)
	var preview: Array[Dictionary] = b.wave_preview(0)
	assert_eq(preview[0], {"enemy": &"shellback", "count": 1, "entrance": 1, "health": 135, "bounty": 18, "heal": 0})
	assert_eq(preview[1]["bounty"], 8, "7.5 rounds half up to 8")
	assert_eq(b.wave_preview(1).size(), 0)
	b.start_next_wave()
	b.step()
	var shell: Dictionary = b.enemy_numbers(0)
	assert_eq([shell["health"], shell["max_health"], shell["armor"], shell["base_speed"], shell["lives"], shell["bounty"]], [135, 135, 4, 70, 2, 18])
	var mender: Battle = Fx.battle(Fx.LINE_GRID, [{"strength": 150, "groups": [Fx.group("mender", 1)]}], {}, catalog)
	assert_eq(mender.wave_preview(0)[0]["heal"], 12, "heal scales with strength")


func test_walkers_move_exactly_at_their_speed_rules_7_3() -> void:
	# A Scamp walks 1 tile a second: 1000 sub-units a tick, 7 tiles in 140 ticks.
	var b: Battle = _one_wave([Fx.group("scamp", 1), Fx.group("pip", 1)])
	b.start_next_wave()
	Fx.steps(b, 10)
	var scamp: EnemyState = b.enemy_with_id(0)
	assert_eq(scamp.pos, Sim.center(Vector2i(3, 0)) + Vector2i(0, 10000))
	assert_eq(scamp.prev_pos, Sim.center(Vector2i(3, 0)) + Vector2i(0, 9000))
	assert_eq(scamp.from_cell, Vector2i(3, 0))
	assert_eq(scamp.to_cell, Vector2i(3, 1))
	assert_eq(scamp.progress, 10000)
	var log: Array = _log(b)
	var leaked: Array[int] = _ticks_of(log, &"leaked")
	# The Pip (1200 a tick) reaches the base center after 117 moves, the Scamp after 140.
	assert_eq(leaked, [116, 139] as Array[int])
	assert_eq(b.lives, 18)


func test_flyers_fly_straight_over_roads_and_gates_rules_6_5() -> void:
	var b: Battle = Fx.battle(Fx.TRIPLE_GRID, [{"groups": [Fx.group("flitter", 1)]}], {"gates": 2}, catalog)
	assert_eq(b.place_gate(Vector2i(0, 3)), Battle.DONE)
	b.start_next_wave()
	b.step()
	var flyer: EnemyState = b.enemy_with_id(0)
	assert_true(flyer.flying)
	assert_eq(flyer.fly_from, Sim.center(Vector2i(0, 0)))
	assert_eq(flyer.fly_to, Sim.center(Vector2i(3, 9)))
	assert_eq(flyer.fly_length, Sim.isqrt(60000 * 60000 + 180000 * 180000))
	Fx.steps(b, 50)
	assert_eq(flyer.flown, 1200 * 51)
	var expected: Vector2i = flyer.fly_from + Vector2i(60000 * flyer.flown / flyer.fly_length, 180000 * flyer.flown / flyer.fly_length)
	assert_eq(flyer.pos, expected, "on the straight line")
	var log: Array = _log(b)
	assert_eq(_ticks_of(log, &"leaked"), [158] as Array[int], "189736 sub-units at 1200 a tick")


func test_leaks_cost_lives_and_zero_loses_at_once_rules_4_4() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 25, 0, 50)])
	b.start_next_wave()
	var log: Array = _log(b)
	assert_eq(b.phase, Battle.Phase.LOST)
	assert_eq(b.lives, 0)
	assert_eq(_ticks_of(log, &"leaked").size(), 20, "the 20th leak ends it")
	assert_eq(_ticks_of(log, &"lost").size(), 1)
	assert_eq(log.back()[1]["kind"], &"lost", "the tick ends at the loss")
	var tick_then: int = b.tick
	b.step()
	assert_eq(b.tick, tick_then, "a lost battle does not step")
	assert_eq(b.place_tower(Vector2i(2, 1), &"sling_post"), &"over")
	assert_eq(b.start_next_wave(), &"over")
	assert_eq(b.place_gate(Vector2i(1, 1)), &"over")
	assert_eq(b.result(), {"won": false, "stars": 0, "lives_left": 0, "waves_cleared": 0})


func test_boss_leak_costs_20_lives_rules_4_4() -> void:
	var b: Battle = _one_wave([Fx.group("grumblesack", 1)], {}, )
	b.start_next_wave()
	var log: Array = _log(b, 10000)
	assert_eq(b.phase, Battle.Phase.LOST, "a boss that gets through loses a Normal game")
	var boss_leaks: int = 0
	for entry: Array in log:
		if entry[1]["kind"] == &"leaked" and entry[1]["enemy"] == &"grumblesack":
			boss_leaks += 1
			assert_eq(entry[1]["lives"], 20)
	assert_eq(boss_leaks, 1)


func test_clear_bonus_build_phases_and_win_rules_4_1_and_4_5() -> void:
	var waves: Array = []
	for i: int in 10:
		waves.append({"groups": [Fx.group("pip", 1)]})
	waves[9]["strength"] = 150
	var b: Battle = Fx.battle(Fx.LINE_GRID, waves, {"start_gold": 0}, catalog)
	var bonuses: Array[int] = []
	for w: int in 10:
		assert_eq(b.phase, Battle.Phase.BUILD)
		assert_eq(b.start_next_wave(), Battle.DONE)
		var log: Array = _log(b)
		for entry: Array in log:
			if entry[1]["kind"] == &"wave_cleared":
				bonuses.append(entry[1]["gold"])
				assert_eq(entry[1]["wave"], w)
			if entry[1]["kind"] == &"build_started":
				assert_eq(entry[1]["wave"], w + 1, "build_started names the next wave")
	# Wave 1 at 100 pays 25; wave 10 at 150 pays (20 + 50) * 1.5 = 105.
	assert_eq(bonuses, [25, 30, 35, 40, 45, 50, 55, 60, 65, 105] as Array[int])
	assert_eq(b.gold, 510, "a creature that gets through pays no bounty")
	assert_eq(b.phase, Battle.Phase.WON)
	assert_eq(b.result(), {"won": true, "stars": 1, "lives_left": 10, "waves_cleared": 10})
	assert_eq(b.start_next_wave(), &"over")


func test_bounties_are_paid_on_defeat_rules_4_5() -> void:
	# A fixture Pip with an odd bounty, so the strength scaling has a half to round.
	var odd: Catalog = Fx.catalog_with_enemy("pip", {"health": 12, "bounty": 3})
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"strength": 150, "groups": [Fx.group("pip", 1)]}], {"start_gold": 100}, odd)
	assert_eq(b.place_tower(Vector2i(2, 1), &"sling_post"), Battle.DONE)
	assert_eq(b.gold, 0)
	b.start_next_wave()
	var log: Array = _log(b)
	var defeated: Array = []
	for entry: Array in log:
		if entry[1]["kind"] == &"defeated":
			defeated.append(entry[1])
	assert_eq(defeated.size(), 1)
	assert_eq(defeated[0]["gold"], 5, "3 x 1.5 = 4.5, rounded half up")
	assert_eq(defeated[0]["enemy"], &"pip")
	assert_eq(b.gold, 5 + 38, "bounty plus clear bonus 25 x 1.5 = 37.5, rounded half up")


func test_final_wave_win_waits_for_every_running_wave_rules_4_1() -> void:
	# RULES 4.1: won when every started wave is gone and the final wave was among them.
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("pip", 1)]}], {}, catalog)
	b.start_next_wave()
	b.step()
	assert_eq(b.start_next_wave(), Battle.DONE, "the final wave can be called early")
	var log: Array = _log(b)
	var cleared: Array = []
	for entry: Array in log:
		if entry[1]["kind"] == &"wave_cleared":
			cleared.append([entry[0], entry[1]["wave"]])
	assert_eq(cleared, [[117, 1], [139, 0]], "the final wave clears first")
	assert_eq(_ticks_of(log, &"won"), [139] as Array[int], "the win comes when the last wave on the map clears")


func test_early_calls_rules_4_9() -> void:
	var waves: Array = [
		{"groups": [Fx.group("scamp", 3, 0, 1000)]},
		{"groups": [Fx.group("scamp", 1)]},
		{"groups": [Fx.group("scamp", 1)]},
	]
	var b: Battle = Fx.battle(Fx.LINE_GRID, waves, {"start_gold": 0}, catalog)
	assert_eq(b.next_wave_info(), {"refusal": &"", "early": false, "bonus": 0})
	b.start_next_wave()
	assert_eq(b.take_events()[0], {"kind": &"wave_started", "wave": 0, "early": false})
	assert_eq(b.start_next_wave(), &"still_spawning", "before the first spawn")
	Fx.steps(b, 40)
	assert_eq(b.start_next_wave(), &"still_spawning", "the third Scamp comes on tick 40")
	b.step()
	# Three Scamps on the map: half of 15, rounded up.
	assert_eq(b.next_wave_info(), {"refusal": &"", "early": true, "bonus": 8})
	assert_eq(b.start_next_wave(), Battle.DONE)
	assert_eq(b.gold, 8)
	assert_eq(b.waves_started, 2)
	assert_eq(b.running, [0, 1] as Array[int])
	var started: Array[Dictionary] = Fx.events_of(b.take_events(), &"wave_started")
	assert_eq(started[0], {"kind": &"wave_started", "wave": 1, "early": true})
	b.step()
	assert_eq(b.start_next_wave(), &"too_many_waves", "at most 2 waves at once")
	Fx.run_wave(b)
	assert_eq(b.phase, Battle.Phase.BUILD)
	b.start_next_wave()
	assert_eq(b.next_wave_info()["refusal"], &"no_more_waves")
	assert_eq(b.start_next_wave(), &"no_more_waves")
	assert_eq(b._early_calls, 1)


func test_early_bonus_counts_only_the_newest_wave_rules_4_9() -> void:
	# A fixture Pip with bounty 2. Any Scamp bounty would raise the bonus if it counted.
	var fixed: Catalog = Fx.catalog_with_enemy("pip", {"bounty": 2})
	var waves: Array = [{"groups": [Fx.group("scamp", 2, 0, 50)]}, {"groups": [Fx.group("pip", 3, 0, 50)]}, {"groups": [Fx.group("pip", 1)]}]
	var b: Battle = Fx.battle(Fx.LINE_GRID, waves, {"start_gold": 0}, fixed)
	b.start_next_wave()
	Fx.steps(b, 2)
	b.start_next_wave()
	Fx.steps(b, 3)
	assert_eq(b.enemies.size(), 5, "both Scamps and all three Pips are on the map")
	# Wave 1 (the newest) holds 3 Pips of bounty 2: half of 6 is 3. Wave 0's Scamps do not count.
	assert_eq(b.next_wave_info()["refusal"], &"too_many_waves")
	assert_eq(b.next_wave_info()["bonus"], 3)


func test_refunds_rules_4_6() -> void:
	var waves: Array = []
	for i: int in 4:
		waves.append({"groups": [Fx.group("pip", 1, 0, 50, 1)]})
	var b: Battle = Fx.battle(Fx.LINE_GRID, waves, {"start_gold": 2000}, catalog)
	# Example 1: built in this build phase and sold before the wave starts refunds 100.
	b.place_tower(Vector2i(2, 1), &"sling_post")
	assert_eq(b.sell_value(Vector2i(2, 1)), 100)
	assert_eq(b.sell_tower(Vector2i(2, 1)), Battle.DONE)
	assert_eq(b.gold, 2000)
	# Example 3 setup: built before wave 2 (here, before wave 1).
	b.place_tower(Vector2i(4, 1), &"sling_post")
	# Example 2 setup: built before wave 3.
	b.start_next_wave()
	Fx.run_wave(b)
	b.start_next_wave()
	Fx.run_wave(b)
	b.place_tower(Vector2i(2, 6), &"sling_post")
	b.start_next_wave()
	b.step()
	assert_eq(b.upgrade_tower(Vector2i(2, 6)), Battle.DONE, "upgraded during wave 3")
	assert_eq(b.sell_value(Vector2i(2, 6)), 147, "70% of 210")
	Fx.run_wave(b)
	assert_eq(b.sell_value(Vector2i(2, 6)), 147, "whenever it is sold")
	# Example 3: upgraded in the build phase before wave 4, sold in that phase.
	assert_eq(b.upgrade_tower(Vector2i(4, 1)), Battle.DONE)
	assert_eq(b.sell_value(Vector2i(4, 1)), 70 + 110)
	var before: int = b.gold
	b.sell_tower(Vector2i(4, 1))
	assert_eq(b.gold, before + 180)
	var sold: Dictionary = Fx.events_of(b.take_events(), &"sold").back()
	assert_eq(sold, {"kind": &"sold", "cell": Vector2i(4, 1), "tower": &"sling_post", "tier": 2, "spec": -1, "gold": 180})


func test_purchases_during_a_wave_never_refund_in_full_rules_4_6() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 1)], {"start_gold": 300})
	b.start_next_wave()
	b.step()
	assert_eq(b.place_tower(Vector2i(2, 1), &"sling_post"), Battle.DONE, "towers can be built during a wave (4.3)")
	assert_eq(b.tower_at(Vector2i(2, 1)).spent_before, 100)
	assert_eq(b.sell_value(Vector2i(2, 1)), 70)


func test_tower_commands_and_refusals_rules_4_6_and_8_2() -> void:
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"start_gold": 330, "towers": ["sling_post", "pumpkin_catapult", "lullaby_bell"]}, catalog)
	assert_eq(b.place_tower(Vector2i(3, 1), &"sling_post"), &"not_a_spot", "a road cell")
	assert_eq(b.place_tower(Vector2i(0, 0), &"sling_post"), &"not_a_spot", "scenery")
	assert_eq(b.place_tower(Vector2i(2, 1), &"longbow_loft"), &"not_offered")
	assert_eq(b.place_tower(Vector2i(2, 1), &"no_such_tower"), &"not_offered")
	assert_eq(b.place_tower(Vector2i(2, 1), &"sling_post"), Battle.DONE)
	assert_eq(b.place_tower(Vector2i(2, 1), &"sling_post"), &"occupied")
	assert_eq(b.place_tower(Vector2i(4, 1), &"pumpkin_catapult"), Battle.DONE)
	assert_eq(b.place_tower(Vector2i(2, 3), &"pumpkin_catapult"), &"too_poor", "110 gold left")
	assert_eq(b.gold, 110)
	assert_eq(b.upgrade_tower(Vector2i(2, 3)), &"no_tower")
	assert_eq(b.sell_tower(Vector2i(2, 3)), &"no_tower")
	assert_eq(b.upgrade_tower(Vector2i(2, 1), 0), &"bad_spec", "tier 1 to 2 takes -1")
	assert_eq(b.upgrade_tower(Vector2i(2, 1)), Battle.DONE)
	assert_eq(b.upgrade_tower(Vector2i(2, 1)), &"pick_spec")
	assert_eq(b.upgrade_tower(Vector2i(2, 1), 2), &"bad_spec")
	assert_eq(b.upgrade_tower(Vector2i(2, 1), 0), &"too_poor")
	assert_eq(b.set_aim(Vector2i(2, 1), TowerState.Aim.LAST), Battle.DONE)
	assert_eq(b.tower_at(Vector2i(2, 1)).aim, TowerState.Aim.LAST)
	assert_eq(b.set_aim(Vector2i(2, 3), TowerState.Aim.LAST), &"no_tower")
	assert_eq(b.set_aim(Vector2i(2, 1), 7 as TowerState.Aim), &"bad_aim")
	b.gold = 1000
	assert_eq(b.place_tower(Vector2i(2, 3), &"lullaby_bell"), Battle.DONE)
	assert_eq(b.set_aim(Vector2i(2, 3), TowerState.Aim.STRONG), &"no_aim", "Bells have no targeting")
	assert_eq(b.upgrade_tower(Vector2i(2, 1), 1), Battle.DONE)
	assert_eq(b.tower_at(Vector2i(2, 1)).spec, 1)
	assert_eq(b.tower_at(Vector2i(2, 1)).aim, TowerState.Aim.LAST, "targeting stays through upgrades (8.2)")
	assert_eq(b.upgrade_tower(Vector2i(2, 1), 0), &"top_tier")
	var cells: Array[Vector2i] = []
	for t: TowerState in b.towers:
		cells.append(t.cell)
	assert_eq(cells, [Vector2i(2, 1), Vector2i(4, 1), Vector2i(2, 3)] as Array[Vector2i], "towers in spot order (3.4)")
	var events: Array[Dictionary] = b.take_events()
	assert_eq(events[0], {"kind": &"built", "cell": Vector2i(2, 1), "tower": &"sling_post", "tier": 1, "spec": -1, "gold": 100})
	var upgraded: Array[Dictionary] = Fx.events_of(events, &"upgraded")
	assert_eq(upgraded[1], {"kind": &"upgraded", "cell": Vector2i(2, 1), "tower": &"sling_post", "tier": 3, "spec": 1, "gold": 200})


func test_queries_for_the_ui_rules_9_3_to_9_5() -> void:
	var b: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"start_gold": 110}, catalog)
	var options: Array[Dictionary] = b.build_options(Vector2i(2, 1))
	assert_eq(options.size(), 2)
	assert_eq(options[0]["tower"], &"sling_post")
	assert_eq(options[0]["cost"], 100)
	assert_eq(options[0]["affordable"], true)
	assert_eq(options[1]["affordable"], false, "a Catapult costs 120")
	assert_eq(options[1]["numbers"]["splash"], 75)
	assert_eq(b.build_options(Vector2i(3, 1)).size(), 0, "not a spot")
	b.place_tower(Vector2i(2, 1), &"sling_post")
	assert_eq(b.build_options(Vector2i(2, 1)).size(), 0, "taken")
	var numbers: Dictionary = b.tower_numbers(Vector2i(2, 1))
	assert_eq([numbers["damage"], numbers["reload_ms"], numbers["reach"], numbers["spent"], numbers["sell"], numbers["aim"]], [6, 500, 250, 100, 100, TowerState.Aim.FIRST])
	assert_eq([numbers["got_pct"], numbers["got_damage"], numbers["boosting"]], [0, 0, 0])
	assert_eq(b.tower_numbers(Vector2i(4, 1)), {})
	var up: Array[Dictionary] = b.upgrade_options(Vector2i(2, 1))
	assert_eq(up.size(), 1)
	assert_eq([up[0]["spec"], up[0]["cost"], up[0]["refusal"]], [-1, 110, &"too_poor"])
	assert_eq([up[0]["before"]["damage"], up[0]["after"]["damage"]], [6, 8])
	b.gold = 110
	b.upgrade_tower(Vector2i(2, 1))
	up = b.upgrade_options(Vector2i(2, 1))
	assert_eq(up.size(), 2, "both paths at tier 3")
	assert_eq([up[0]["spec"], up[1]["spec"], up[0]["after"]["reload_ms"], up[1]["after"]["damage"]], [0, 1, 200, 20])
	assert_eq(b.enemy_numbers(0), {})
	b.start_next_wave()
	b.step()
	var creature: Dictionary = b.enemy_numbers(0)
	for key: String in ["health", "max_health", "armor", "speed", "base_speed", "flying", "lives", "bounty", "heal", "slow_pct", "slow_ms", "bubble", "bubble_ms", "breaking_ms"]:
		assert_true(creature.has(key), "enemy_numbers has " + key)


func test_stars_rules_10() -> void:
	# A one wave level the Sling Post at [2, 1] wins with no leak.
	var cases: Array = [
		[{"kind": "no_lives_lost"}, func(_b: Battle) -> void: pass, 7],
		[{"kind": "towers_at_most", "value": 1}, func(b: Battle) -> void:
			b.place_tower(Vector2i(4, 1), &"sling_post")
			b.sell_tower(Vector2i(4, 1)), 3],
		[{"kind": "towers_at_most", "value": 2}, func(b: Battle) -> void:
			b.place_tower(Vector2i(4, 1), &"sling_post"), 7],
		[{"kind": "tower_ban", "tower": "pumpkin_catapult"}, func(b: Battle) -> void:
			b.place_tower(Vector2i(4, 1), &"pumpkin_catapult")
			b.sell_tower(Vector2i(4, 1)), 3],
		[{"kind": "tower_ban", "tower": "pumpkin_catapult"}, func(_b: Battle) -> void: pass, 7],
		[{"kind": "tier_at_most", "value": 1}, func(b: Battle) -> void:
			b.upgrade_tower(Vector2i(2, 1)), 3],
		[{"kind": "tier_at_most", "value": 2}, func(b: Battle) -> void:
			b.upgrade_tower(Vector2i(2, 1)), 7],
		[{"kind": "kinds_at_most", "value": 1}, func(b: Battle) -> void:
			b.place_tower(Vector2i(4, 1), &"pumpkin_catapult"), 3],
		[{"kind": "kinds_at_most", "value": 1}, func(b: Battle) -> void:
			b.place_tower(Vector2i(4, 1), &"sling_post"), 7],
		[{"kind": "early_calls_at_least", "value": 1}, func(_b: Battle) -> void: pass, 3],
	]
	for i: int in cases.size():
		var case: Array = cases[i]
		var b: Battle = _one_wave([Fx.group("pip", 1)], {"star3": case[0], "start_gold": 1000})
		b.place_tower(Vector2i(2, 1), &"sling_post")
		(case[1] as Callable).call(b)
		b.start_next_wave()
		Fx.run_wave(b)
		assert_eq(b.phase, Battle.Phase.WON, "case %d won" % i)
		assert_eq(b.result()["stars"], case[2], "case %d: %s" % [i, str(case[0])])


func test_star_2_and_relaxed_rules_10_2_and_10_4() -> void:
	# 6 leaks leave 14 lives: no star 2. 5 leaks leave 15: star 2.
	for pair: Array in [[6, 1], [5, 3]]:
		var b: Battle = _one_wave([Fx.group("pip", pair[0], 0, 50)], {"star3": {"kind": "early_calls_at_least", "value": 1}})
		b.start_next_wave()
		Fx.run_wave(b)
		assert_eq(b.result()["stars"], pair[1], "%d leaks" % pair[0])
	var relaxed: Battle = Fx.battle(Fx.LINE_GRID, [{"groups": [Fx.group("pip", 1)]}], {"star3": {"kind": "towers_at_most", "value": 0}}, catalog, true)
	relaxed.start_next_wave()
	Fx.run_wave(relaxed)
	assert_eq(relaxed.result(), {"won": true, "stars": 1, "lives_left": 39, "waves_cleared": 1}, "a Relaxed win earns star 1 only")


func test_early_call_and_gate_stars_rules_10_3() -> void:
	var two: Array = [{"groups": [Fx.group("pip", 1)]}, {"groups": [Fx.group("pip", 1)]}]
	var early: Battle = Fx.battle(Fx.FORK_GRID, two, {"star3": {"kind": "early_calls_at_least", "value": 1}, "gates": 1}, catalog)
	early.start_next_wave()
	early.step()
	early.start_next_wave()
	Fx.run_wave(early)
	assert_eq(early.result()["stars"] & 4, 4, "one early call meets early_calls_at_least 1")
	# gates_at_most 0: a gate placed then removed before the wave is fine; one there at a wave start is not.
	var none: Battle = Fx.battle(Fx.FORK_GRID, two, {"star3": {"kind": "gates_at_most", "value": 0}, "gates": 1}, catalog)
	none.place_gate(Vector2i(1, 3))
	none.remove_gate(Vector2i(1, 3))
	for w: int in 2:
		none.start_next_wave()
		Fx.run_wave(none)
	assert_eq(none.result()["stars"] & 4, 4)
	var used: Battle = Fx.battle(Fx.FORK_GRID, two, {"star3": {"kind": "gates_at_most", "value": 0}, "gates": 1}, catalog)
	used.start_next_wave()
	Fx.run_wave(used)
	used.place_gate(Vector2i(1, 3))
	used.start_next_wave()
	Fx.run_wave(used)
	assert_eq(used.result()["stars"] & 4, 0)
	# gates_whole: every gate placed at every wave start.
	var whole: Battle = Fx.battle(Fx.FORK_GRID, two, {"star3": {"kind": "gates_whole"}, "gates": 1}, catalog)
	whole.place_gate(Vector2i(5, 5))
	for w: int in 2:
		whole.start_next_wave()
		Fx.run_wave(whole)
	assert_eq(whole.result()["stars"] & 4, 4)
	var late: Battle = Fx.battle(Fx.FORK_GRID, two, {"star3": {"kind": "gates_whole"}, "gates": 1}, catalog)
	late.start_next_wave()
	Fx.run_wave(late)
	late.place_gate(Vector2i(5, 5))
	late.start_next_wave()
	Fx.run_wave(late)
	assert_eq(late.result()["stars"] & 4, 0, "the gate was not placed for wave 1")


func test_events_can_be_switched_off_for_bots_contract_3_3() -> void:
	var b: Battle = _one_wave([Fx.group("scamp", 2)])
	b.record_events = false
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.start_next_wave()
	Fx.run_wave(b)
	assert_eq(b.take_events().size(), 0)
	var c: Battle = _one_wave([Fx.group("scamp", 2)])
	c.start_next_wave()
	c.step()
	assert_true(c.take_events().size() > 0)
	assert_eq(c.take_events().size(), 0, "take_events drains")
