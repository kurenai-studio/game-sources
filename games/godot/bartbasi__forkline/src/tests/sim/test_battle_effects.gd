# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Twist, card and risk effects in battle (docs/ARCHITECTURE.md 2.8; RULES 11, 13,
## 14.4 to 14.6), and the stars a battle can still earn (RULES 10).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const ALL_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _level(grid: Array, waves: Array, changes: Dictionary = {}) -> LevelData:
	var all: Dictionary = {"start_gold": 1000, "towers": ALL_TOWERS}
	all.merge(changes, true)
	return Fx.level(grid, waves, all, catalog)


func _twist(effects: Array, grid: Array = [], waves: Array = [], changes: Dictionary = {}, relaxed: bool = false) -> Battle:
	var list: Array = waves if not waves.is_empty() else [{"groups": [Fx.group("scamp", 2, 0, 500)]}]
	var map_grid: Array = grid if not grid.is_empty() else Fx.LINE_GRID
	return Battle.create(_level(map_grid, list, changes), catalog, relaxed, _effects(effects))


func _effects(list: Array) -> Array[Dictionary]:
	var typed: Array[Dictionary] = []
	for effect: Dictionary in list:
		typed.append(effect)
	return typed


# Twists (RULES 13).

func test_thin_purse_halves_the_gold_then_relaxed_applies_rules_13_and_11() -> void:
	for pair: Array in [[250, false, 120], [250, true, 180], [200, false, 100], [1000, true, 750]]:
		var b: Battle = _twist([{"type": "start_gold_pct", "pct": 50}], Fx.LINE_GRID, [], {"start_gold": pair[0]}, pair[1])
		assert_eq(b.gold, pair[2], "%d gold, relaxed %s" % [pair[0], pair[1]])


func test_five_lives_then_relaxed_rules_13_and_11() -> void:
	assert_eq(_twist([{"type": "set_lives", "lives": 5}]).lives, 5)
	var relaxed: Battle = _twist([{"type": "set_lives", "lives": 5}], Fx.LINE_GRID, [], {}, true)
	assert_eq([relaxed.lives, relaxed.start_lives], [10, 10])


func test_no_gates_and_one_gate_rules_13() -> void:
	var none: Battle = _twist([{"type": "set_gates", "count": 0}], Fx.FORK_GRID, [], {"gates": 1})
	assert_eq(none.gates_in_hand, 0)
	assert_eq(none.place_gate(Vector2i(1, 3)), &"no_gates_left")
	var one: Battle = _twist([{"type": "set_gates", "count": 1}], Fx.TRIPLE_GRID, [], {"gates": 3})
	assert_eq(one.gates_in_hand, 1)


func test_stuck_gates_start_placed_and_cannot_move_rules_13() -> void:
	var b: Battle = _twist([{"type": "fixed_gates", "cells": [[1, 3]]}], Fx.FORK_GRID, [], {"gates": 1})
	assert_eq(b.gates.size(), 1)
	assert_true(b.gates[0].fixed)
	assert_eq(b.gates_in_hand, 0, "it comes out of the level's gates")
	assert_eq(b.move_gate(Vector2i(1, 3), Vector2i(5, 5)), &"fixed_gate")
	assert_eq(b.remove_gate(Vector2i(1, 3)), &"fixed_gate")
	assert_eq(b.closed_cells(), [Vector2i(1, 3)] as Array[Vector2i])
	assert_eq(b.routes(b.closed_cells())[0]["walk"][3], Vector2i(4, 2), "the route goes around it")
	assert_null(_twist([{"type": "fixed_gates", "cells": [[1, 3], [5, 5]]}], Fx.FORK_GRID, [], {"gates": 2}), "fixed gates that seal every road are refused")


func test_a_banned_tower_cannot_be_built_rules_13() -> void:
	var b: Battle = _twist([{"type": "ban_tower", "tower": "pumpkin_catapult"}])
	assert_eq(b.place_tower(Vector2i(2, 1), &"pumpkin_catapult"), &"not_offered")
	for option: Dictionary in b.build_options(Vector2i(2, 1)):
		assert_ne(option["tower"], &"pumpkin_catapult")
	assert_eq(b.place_tower(Vector2i(2, 1), &"sling_post"), Battle.DONE)


func test_tier_caps_rules_13() -> void:
	var one: Battle = _twist([{"type": "tier_cap", "tier": 1}])
	one.place_tower(Vector2i(2, 1), &"sling_post")
	assert_eq(one.upgrade_tower(Vector2i(2, 1)), &"tier_cap", "No Upgrades")
	var two: Battle = _twist([{"type": "tier_cap", "tier": 2}])
	two.place_tower(Vector2i(2, 1), &"sling_post")
	assert_eq(two.upgrade_tower(Vector2i(2, 1)), Battle.DONE)
	assert_eq(two.upgrade_tower(Vector2i(2, 1), 0), &"tier_cap", "Tier 2 Cap")
	assert_eq(two.upgrade_options(Vector2i(2, 1))[0]["refusal"], &"tier_cap")


func test_no_selling_rules_13() -> void:
	var b: Battle = _twist([{"type": "no_selling"}])
	b.place_tower(Vector2i(2, 1), &"sling_post")
	var gold: int = b.gold
	assert_eq(b.sell_tower(Vector2i(2, 1)), &"no_selling")
	assert_eq(b.gold, gold)
	assert_not_null(b.tower_at(Vector2i(2, 1)))


func test_twice_the_wings_doubles_flyer_groups_only_rules_13() -> void:
	var waves: Array = [{"groups": [Fx.group("flitter", 3, 0, 300), Fx.group("scamp", 3, 0, 300)]}]
	var b: Battle = _twist([{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false}], Fx.LINE_GRID, waves)
	var preview: Array[Dictionary] = b.wave_preview(0)
	assert_eq([preview[0]["count"], preview[1]["count"]], [6, 3])
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 3000)
	var flitters: int = 0
	var scamps: int = 0
	for entry: Array in Fx.of_kind(log, &"spawned"):
		if entry[1]["enemy"] == &"flitter":
			flitters += 1
		else:
			scamps += 1
	assert_eq([flitters, scamps], [6, 3])


func test_double_trouble_doubles_the_final_wave_rules_13() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 2)]}, {"groups": [Fx.group("grumblesack", 1), Fx.group("scamp", 3)]}]
	var b: Battle = _twist([{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}], Fx.LINE_GRID, waves)
	assert_eq(b.wave_preview(0)[0]["count"], 2, "not the first wave")
	assert_eq([b.wave_preview(1)[0]["count"], b.wave_preview(1)[1]["count"]], [2, 6], "two bosses")


func test_hurry_makes_every_creature_faster_rules_13() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 1), Fx.group("flitter", 1)]}]
	var b: Battle = _twist([{"type": "speed_pct", "pct": 120}], Fx.LINE_GRID, waves)
	b.start_next_wave()
	b.step()
	var scamp: EnemyState = b.enemy_with_id(0)
	var flitter: EnemyState = b.enemy_with_id(1)
	assert_eq(scamp.pos - Sim.center(Vector2i(3, 0)), Vector2i(0, catalog.enemy(&"scamp").speed * 12))
	assert_eq(flitter.flown, catalog.enemy(&"flitter").speed * 12)
	assert_eq(b.enemy_numbers(0)["speed"], catalog.enemy(&"scamp").speed * 120 / 100)


func test_thick_shells_add_armor_rules_13() -> void:
	var b: Battle = _twist([{"type": "armor_add", "amount": 2}], Fx.LINE_GRID, [{"groups": [Fx.group("shellback", 1)]}])
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq(e.armor, catalog.enemy(&"shellback").armor + 2)
	assert_eq(e.max_health - e.health, 1, "6 damage against armor 6: at least 1 gets through")


func test_bubble_night_gives_every_creature_a_bubble_rules_13() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 1), Fx.group("grumblesack", 1)]}]
	var b: Battle = _twist([{"type": "all_bubbles"}], Fx.LINE_GRID, waves)
	b.start_next_wave()
	b.step()
	assert_true(b.enemy_with_id(0).bubble)
	assert_true(b.enemy_with_id(1).bubble, "bosses too")
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy, "a bubble on a Scamp saves under Bubble Night")


func test_quick_crashers_break_gates_faster_rules_13() -> void:
	var b: Battle = _twist([{"type": "break_ms", "enemy": "gatecrasher", "ms": 2000}], Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 3000)
	var started: int = Fx.of_kind(log, &"break_started")[0][0]
	var broken: int = Fx.of_kind(log, &"gate_broken")[0][0]
	assert_eq(broken - started, 2000 / Sim.MS_PER_TICK)


# Cards (RULES 14.5, 14.6).

func _run_battle(effects: Array = [], waves: Array = [], grid: Array = [], changes: Dictionary = {}) -> Battle:
	var list: Array = waves if not waves.is_empty() else [{"groups": [Fx.group("scamp", 2, 0, 500)]}, {"groups": [Fx.group("scamp", 2, 0, 500)]}]
	var all: Dictionary = {"towers": ["sling_post"]}
	all.merge(changes, true)
	var map_grid: Array = grid if not grid.is_empty() else Fx.LINE_GRID
	var b: Battle = Battle.create(_level(map_grid, list, all), catalog, false, [])
	if not effects.is_empty():
		assert_eq(b.add_effects(_effects(effects), false), Battle.DONE, str(effects))
	return b


func test_a_tower_card_adds_the_tower_rules_14_5() -> void:
	var b: Battle = _run_battle()
	assert_eq(b.place_tower(Vector2i(2, 1), &"bakery"), &"not_offered")
	assert_eq(b.add_effects(_effects([{"type": "add_tower", "tower": "bakery"}]), false), Battle.DONE)
	assert_eq(b.build_options(Vector2i(2, 1)).back()["tower"], &"bakery")
	assert_eq(b.place_tower(Vector2i(2, 1), &"bakery"), Battle.DONE)


func test_tower_perks_change_every_tier_and_path_rules_14_5() -> void:
	var b: Battle = _run_battle([{"type": "tower_add", "tower": "sling_post", "stat": "damage", "amount": 2}])
	for key: Array in [[1, -1], [2, -1], [3, 0], [3, 1]]:
		assert_eq(b._tower_stats(&"sling_post", key[0], key[1]).damage, Fx.stats(catalog, &"sling_post", key[0], key[1]).damage + 2, "Sharp Pebbles at %s" % str(key))
	b.place_tower(Vector2i(2, 1), &"sling_post")
	assert_eq(b.tower_numbers(Vector2i(2, 1))["damage"], Fx.stats(catalog, &"sling_post", 1).damage + 2)
	assert_eq(Fx.stats(catalog, &"sling_post", 1).damage, 6, "the catalog itself is unchanged")


func test_a_reload_card_caps_timers_at_the_new_reload_when_taken_rules_5_2() -> void:
	# Steady Aim: Longbow reloads 20% shorter. A Longbow that just fired holds more than
	# the new reload; taking the card drops it to the new reload, at once.
	var b: Battle = _run_battle([{"type": "add_tower", "tower": "longbow_loft"}], [{"groups": [Fx.group("shellback", 1)]}])
	b.place_tower(Vector2i(2, 1), &"longbow_loft")
	b.start_next_wave()
	b.step()
	var bow: TowerState = b.tower_at(Vector2i(2, 1))
	var old: int = Fx.stats(catalog, &"longbow_loft", 1).reload_ms
	assert_eq(bow.reload, old * 100 - Sim.MS_PER_TICK * 100, "fired on its first tick")
	assert_eq(b.add_effects(_effects([{"type": "tower_pct", "tower": "longbow_loft", "stat": "reload_ms", "pct": 80}]), false), Battle.DONE)
	var new_reload: int = Sim.pct_half_up(old, 80)
	assert_eq(bow.stats.reload_ms, new_reload)
	assert_eq(bow.reload, new_reload * 100)


func test_twin_pebbles_hits_two_targets_for_less_rules_14_6() -> void:
	var b: Battle = _run_battle([{"type": "tower_add", "tower": "sling_post", "stat": "targets", "amount": 1},
		{"type": "tower_add", "tower": "sling_post", "stat": "damage", "amount": -2}], [{"groups": [Fx.group("shellback", 2, 0, 100)]}])
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.start_next_wave()
	Fx.steps(b, 2)
	b.tower_at(Vector2i(2, 1)).reload = 0
	b.take_events()
	b.step()
	assert_eq(Fx.events_of(b.take_events(), &"fired")[0]["targets"].size(), 2)
	assert_eq(b.tower_numbers(Vector2i(2, 1))["damage"], Fx.stats(catalog, &"sling_post", 1).damage - 2)


func test_frost_chime_lets_every_bell_slow_flyers_with_a_shorter_ring_rules_14_6() -> void:
	var b: Battle = _run_battle([{"type": "add_tower", "tower": "lullaby_bell"},
		{"type": "tower_hits_air", "tower": "lullaby_bell"},
		{"type": "tower_add", "tower": "lullaby_bell", "stat": "reach", "amount": -50}], [{"groups": [Fx.group("flitter", 1)]}])
	b.place_tower(Vector2i(2, 1), &"lullaby_bell")
	var numbers: Dictionary = b.tower_numbers(Vector2i(2, 1))
	assert_eq([numbers["hits_air"], numbers["reach"]], [true, Fx.stats(catalog, &"lullaby_bell", 1).reach - 50])
	b.start_next_wave()
	Fx.steps(b, 3)
	assert_eq(b.enemy_with_id(0).slow_pct, Fx.stats(catalog, &"lullaby_bell", 1).slow_pct)


func test_warm_ovens_and_spice_rack_change_bakeries_rules_14_5_and_14_6() -> void:
	var b: Battle = _run_battle([{"type": "add_tower", "tower": "bakery"}], [], Fx.CLUSTER_GRID, {"start_gold": 2000})
	b.place_tower(Vector2i(2, 2), &"bakery")
	b.place_tower(Vector2i(4, 2), &"sling_post")
	b.place_tower(Vector2i(5, 1), &"sling_post")
	assert_eq(b.tower_numbers(Vector2i(4, 2))["got_pct"], 0, "2 tiles away: out of 1.5")
	assert_eq(b.add_effects(_effects([{"type": "tower_add", "tower": "bakery", "stat": "reach", "amount": 100}]), false), Battle.DONE)
	var boost: int = Fx.stats(catalog, &"bakery", 1).boost_pct
	assert_eq(b.tower_numbers(Vector2i(4, 2))["got_pct"], boost, "Warm Ovens: in 2.5")
	assert_eq(b.tower_numbers(Vector2i(5, 1))["got_pct"], 0, "3.16 tiles: still out")
	b.add_effects(_effects([{"type": "tower_add", "tower": "bakery", "stat": "boost_damage", "amount": 2},
		{"type": "tower_add", "tower": "bakery", "stat": "boost_pct", "amount": -10}]), false)
	var numbers: Dictionary = b.tower_numbers(Vector2i(4, 2))
	assert_eq([numbers["got_pct"], numbers["got_damage"]], [boost - 10, 2], "Spice Rack: 15% becomes 5%, plus 2 damage")


func test_fat_bounties_and_feast_days_rules_14_5() -> void:
	var b: Battle = _run_battle([{"type": "bounty_pct", "pct": 120}, {"type": "clear_bonus_pct", "pct": 150}],
		[{"strength": 150, "groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("scamp", 1)]}], Fx.LINE_GRID, {"start_gold": 1000})
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.upgrade_tower(Vector2i(2, 1))
	b.upgrade_tower(Vector2i(2, 1), 1)
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 500)
	var bounty: int = Sim.pct_half_up(Sim.pct_half_up(catalog.enemy(&"scamp").bounty, 150), 120)
	assert_eq(Fx.of_kind(log, &"defeated")[0][1]["gold"], bounty, "strength first, then the card")
	var clear: int = Sim.pct_half_up(Sim.pct_half_up(catalog.rules.clear_bonus + catalog.rules.clear_bonus_per_wave, 150), 150)
	assert_eq(Fx.of_kind(log, &"wave_cleared")[0][1]["gold"], clear)


func test_fair_trade_refunds_90_percent_rules_14_5() -> void:
	var b: Battle = _run_battle([{"type": "refund_pct", "pct": 90}])
	b.place_tower(Vector2i(2, 1), &"sling_post")
	assert_eq(b.sell_value(Vector2i(2, 1)), 100, "this build phase: in full")
	b.start_next_wave()
	assert_eq(b.sell_value(Vector2i(2, 1)), 90)


func test_bargain_changes_prices_and_refunds_use_the_price_paid_rules_14_6_and_4_6() -> void:
	var b: Battle = _run_battle()
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.start_next_wave()
	assert_eq(b.add_effects(_effects([{"type": "cost_add", "build": 20, "upgrade": -20}]), false), Battle.DONE)
	assert_eq(b.build_options(Vector2i(4, 1))[0]["cost"], Fx.stats(catalog, &"sling_post", 1).cost + 20)
	assert_eq(b.upgrade_options(Vector2i(2, 1))[0]["cost"], Fx.stats(catalog, &"sling_post", 2).cost - 20)
	assert_eq(b.sell_value(Vector2i(2, 1)), Fx.stats(catalog, &"sling_post", 1).cost * catalog.rules.refund_pct / 100, "paid before the card")
	var gold: int = b.gold
	b.upgrade_tower(Vector2i(2, 1))
	assert_eq(gold - b.gold, Fx.stats(catalog, &"sling_post", 2).cost - 20)


func test_piggy_bank_pays_interest_at_each_build_phase_rules_14_6() -> void:
	for start: int in [300, 1000]:
		var b: Battle = _run_battle([{"type": "interest", "pct": 10, "max": 50}], [], Fx.LINE_GRID, {"start_gold": start})
		b.start_next_wave()
		var log: Array = Fx.log_ticks(b, 1000)
		var gold_before: int = start
		for entry: Array in Fx.of_kind(log, &"wave_cleared"):
			gold_before += int(entry[1]["gold"])
		var interest: Array = Fx.of_kind(log, &"interest")
		assert_eq(interest.size(), 1)
		assert_eq(interest[0][1]["gold"], mini(gold_before * 10 / 100, 50), "from %d gold" % start)
		assert_eq(b.gold, gold_before + interest[0][1]["gold"])


func test_iron_gate_locks_placed_gates_when_a_wave_starts_rules_14_6() -> void:
	var b: Battle = _run_battle([], [], Fx.TRIPLE_GRID, {"gates": 1})
	assert_eq(b.add_effects(_effects([{"type": "add_gates", "count": 2}, {"type": "gates_stay"}]), false), Battle.DONE)
	assert_eq(b.gates_in_hand, 3, "gain 2 gates, up to 3")
	assert_eq(b.card_effects.size(), 1, "the instant part is not kept")
	b.place_gate(Vector2i(0, 3))
	assert_eq(b.move_gate(Vector2i(0, 3), Vector2i(3, 3)), Battle.DONE, "nothing locks when it is taken")
	b.start_next_wave()
	Fx.run_wave(b)
	assert_eq(b.move_gate(Vector2i(3, 3), Vector2i(0, 3)), &"fixed_gate", "locked for good")
	assert_eq(b.place_gate(Vector2i(0, 3)), Battle.DONE, "gates in the tray stay free")
	assert_eq(b.remove_gate(Vector2i(0, 3)), Battle.DONE)
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy)
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b))


func test_instant_cards_rules_14_5() -> void:
	var b: Battle = _run_battle([], [], Fx.FORK_GRID, {"gates": 1, "start_gold": 300})
	b.start_next_wave()
	Fx.run_wave(b)
	var gold: int = b.gold
	assert_eq(b.add_effects(_effects([{"type": "add_gold", "amount": 100, "per_wave": 10}]), false), Battle.DONE)
	assert_eq(b.gold, gold + 110, "100 plus 10 for the one wave cleared")
	b.lives = b.start_lives - 10
	b.add_effects(_effects([{"type": "add_lives", "amount": 5}]), false)
	assert_eq(b.lives, b.start_lives - 5)
	b.add_effects(_effects([{"type": "add_gates", "count": 1}]), false)
	b.add_effects(_effects([{"type": "add_gates", "count": 1}]), false)
	b.add_effects(_effects([{"type": "add_gates", "count": 1}]), false)
	assert_eq(b.gates_in_hand, catalog.rules.max_gates, "never more than max_gates")
	assert_eq(b.card_effects.size(), 0, "instant effects are not kept")
	assert_not_null(Fx.restored(b), "the gained gates save")


func _tea_break(b: Battle, lives: int) -> int:
	b.lives = lives
	assert_eq(b.add_effects(_effects([{"type": "add_lives", "amount": 5}]), false), Battle.DONE)
	return b.lives


func test_tea_break_never_lifts_lives_above_the_start_rules_4_4() -> void:
	var b: Battle = _run_battle()
	assert_eq(b.start_lives, 20)
	assert_eq(_tea_break(b, 20), 20, "at full lives it does nothing")
	assert_eq(_tea_break(b, 18), 20, "18 gives 20, not 23")
	assert_eq(_tea_break(b, 15), 20, "15 gives 20")
	assert_eq(_tea_break(b, 10), 15, "10 gives the full 5")
	b.lives = 15
	b.add_effects(_effects([{"type": "add_lives", "amount": 0}]), false)
	assert_eq(b.lives, 15, "0 adds nothing")
	var relaxed: Battle = Battle.create(_level(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 2, 0, 500)]}], {"towers": ["sling_post"]}), catalog, true, [])
	assert_eq(relaxed.start_lives, 40)
	assert_eq(_tea_break(relaxed, 40), 40, "Relaxed caps at 40")
	assert_eq(_tea_break(relaxed, 38), 40)
	assert_eq(_tea_break(relaxed, 30), 35)


func test_a_restored_battle_above_its_start_keeps_its_lives_contract_2_8() -> void:
	# An older build let cards bank lives. Such a save loads as it was, and a gain never lowers it.
	var b: Battle = _run_battle()
	b.lives = 25
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy, "lives above the start are not refused")
	assert_eq([copy.lives, copy.start_lives], [25, 20], "nor clamped")
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b))
	assert_eq(_tea_break(copy, 25), 25, "Tea Break does not lower them")


func test_add_effects_refusals_contract_2_8() -> void:
	var b: Battle = _run_battle()
	assert_eq(b.add_effects(_effects([{"type": "add_gold", "amount": 1}]), false), &"bad_effect", "missing field")
	assert_eq(b.add_effects(_effects([{"type": "gates_open"}]), false), &"bad_effect", "a risk effect as a card")
	assert_eq(b.add_effects(_effects([{"type": "add_group", "enemy": "pip", "count": 2, "entrance": 2, "at_ms": 0, "every_ms": 300, "after_last": false}]), true), &"bad_effect", "an entrance the map does not have")
	assert_eq(b.add_effects(_effects([{"type": "gates_open"}]), true), Battle.DONE)
	assert_eq(b.add_effects(_effects([{"type": "reward_gold", "amount": 10}]), true), &"risk_waiting")
	var many: Array = []
	for i: int in Modifiers.MAX_KEPT:
		many.append({"type": "gates_stay"})
	assert_eq(b.add_effects(_effects(many), false), Battle.DONE)
	assert_eq(b.add_effects(_effects([{"type": "gates_stay"}]), false), &"bad_effect", "at most 64 kept")
	for item: Array in Fx.GAINS:
		var gold: int = b.gold
		var lives: int = b.lives
		assert_eq(b.add_effects(_effects([Fx.gain_effect(item, -1)]), item[0] == "risk"), &"bad_effect", "%s with -1" % str(item[1]))
		assert_eq([b.gold, b.lives], [gold, lives], "a refusal changes nothing")
	b.start_next_wave()
	b.lives = 1
	while b.phase == Battle.Phase.WAVE:
		b.step()
	assert_eq(b.phase, Battle.Phase.LOST)
	assert_eq(b.add_effects(_effects([{"type": "add_lives", "amount": 5}]), false), &"over")


# Risk cards (RULES 14.5, 14.6).

func _risky(effects: Array, waves: Array = [], grid: Array = [], changes: Dictionary = {}) -> Battle:
	var b: Battle = _run_battle([], waves, grid, changes)
	assert_eq(b.add_effects(_effects(effects), true), Battle.DONE)
	return b


func test_crowded_night_changes_the_next_wave_only_rules_14_5() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 3, 0, 300), Fx.group("pip", 5, 0, 300)]}, {"groups": [Fx.group("scamp", 3, 0, 300)]}]
	var b: Battle = _risky([{"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false}], waves)
	assert_eq([b.wave_preview(0)[0]["count"], b.wave_preview(0)[1]["count"]], [5, 8], "50% more, rounded up")
	assert_eq(b.wave_preview(1)[0]["count"], 3)
	b.start_next_wave()
	assert_eq(b.risk_waiting.size(), 0, "the card is used by the wave that starts")
	var log: Array = Fx.log_ticks(b, 3000)
	assert_eq(Fx.of_kind(log, &"spawned").size(), 13)
	b.start_next_wave()
	assert_eq(Fx.of_kind(Fx.log_ticks(b, 3000), &"spawned").size(), 3, "the wave after is normal")


func test_thick_hides_and_moonlit_wager_raise_health_rules_14_5_and_14_6() -> void:
	var b: Battle = _risky([{"type": "health_pct", "pct": 150}], [{"strength": 130, "groups": [Fx.group("shellback", 1)]}])
	var expected: int = Sim.pct_half_up(Sim.pct_half_up(catalog.enemy(&"shellback").health, 130), 150)
	assert_eq(b.wave_preview(0)[0]["health"], expected)
	b.start_next_wave()
	b.step()
	assert_eq(b.enemy_with_id(0).max_health, expected)


func test_hurry_night_speeds_its_wave_rules_14_5() -> void:
	var b: Battle = _risky([{"type": "speed_pct", "pct": 125}], [{"groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("scamp", 1)]}])
	b.start_next_wave()
	b.step()
	assert_eq(b.enemy_with_id(0).pos.y - Sim.center(Vector2i(3, 0)).y, catalog.enemy(&"scamp").speed * 10 * 125 / 100)
	Fx.run_wave(b)
	b.start_next_wave()
	b.step()
	assert_eq(b.enemy_with_id(1).pos.y - Sim.center(Vector2i(3, 0)).y, catalog.enemy(&"scamp").speed * 10)


func test_gateless_night_opens_every_gate_until_the_next_build_phase_rules_14_5() -> void:
	var waves: Array = [{"groups": [Fx.group("gatecrasher", 1), Fx.group("scamp", 3, 0, 500)]}, {"groups": [Fx.group("scamp", 6, 0, 500)]}, {"groups": [Fx.group("scamp", 1)]}]
	var b: Battle = _run_battle([], waves, Fx.FORK_GRID, {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	assert_eq(b.routes(b.closed_cells())[0]["walk"][3], Vector2i(4, 2))
	b.add_effects(_effects([{"type": "gates_open"}, {"type": "reward_gold", "amount": 120}]), true)
	var lines: Array[Dictionary] = b.routes(b.closed_cells())
	assert_eq(lines[0]["walk"][3], Vector2i(2, 2), "the route line already shows every gate open")
	assert_eq(lines[0]["cracks"].size(), 0)
	b.start_next_wave()
	assert_true(b.gates_open)
	assert_eq(b.closed_cells().size(), 0)
	var west: bool = false
	while b.phase == Battle.Phase.WAVE:
		if b.waves_started == 1 and b.next_wave_info()["refusal"] == &"":
			b.start_next_wave()                        # an early call during it finds the gates open too
		b.step()
		for event: Dictionary in b.take_events():
			assert_ne(event["kind"], &"break_started", "Gatecrashers walk through without stopping")
			assert_ne(event["kind"], &"gate_broken")
		for e: EnemyState in b.enemies:
			if e.to_cell == Vector2i(1, 3):
				west = true
	assert_true(west, "walkers went through the open socket")
	assert_eq(b.phase, Battle.Phase.BUILD)
	assert_false(b.gates_open, "closed again when the build phase begins")
	assert_eq(b.closed_cells(), [Vector2i(1, 3)] as Array[Vector2i])
	assert_false(b.gates[0].broken)


func test_flock_adds_a_group_after_the_last_group_starts_rules_14_5() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 2, 0, 500), Fx.group("pip", 2, 1500, 500)]}]
	var b: Battle = _risky([{"type": "add_group", "enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 2000, "every_ms": 400, "after_last": true},
		{"type": "reward_gold", "amount": 80}], waves, Fx.LINE_GRID, {"strength": 150})
	var preview: Array[Dictionary] = b.wave_preview(0)
	assert_eq(preview.back()["enemy"], &"flitter")
	assert_eq(preview.back()["count"], 8)
	assert_true(b.routes(b.closed_cells())[0]["fly"], "the flyers' line shows")
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 5000)
	var ticks: Array[int] = []
	for entry: Array in Fx.of_kind(log, &"spawned"):
		if entry[1]["enemy"] == &"flitter":
			ticks.append(entry[0])
	var first: int = (1500 + 2000) / Sim.MS_PER_TICK
	assert_eq(ticks.size(), 8)
	assert_eq([ticks[0], ticks[1], ticks.back()], [first, first + 8, first + 7 * 8])
	var clear: Dictionary = Fx.of_kind(log, &"wave_cleared")[0][1]
	var bonus: int = Sim.pct_half_up(catalog.rules.clear_bonus + catalog.rules.clear_bonus_per_wave, 150)
	assert_eq(clear["gold"], bonus + Sim.pct_half_up(80, 150), "the reward is paid with the clear bonus, at the wave's strength")


func test_count_changes_skip_added_groups_rules_14_3() -> void:
	# Twice the Wings (a Twist) and a 150% risk count change both reach the wave's own
	# groups. The groups the risk card adds keep the counts their card states.
	var waves: Array = [{"groups": [Fx.group("scamp", 2, 0, 300), Fx.group("flitter", 3, 0, 300)]}]
	var b: Battle = _twist([{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false}, {"type": "set_lives", "lives": 100}], Fx.LINE_GRID, waves)
	assert_eq(b.add_effects(_effects([
		{"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false},
		{"type": "add_group", "enemy": "pip", "count": 3, "entrance": 1, "at_ms": 500, "every_ms": 300, "after_last": false},
		{"type": "add_group", "enemy": "flitter", "count": 4, "entrance": 1, "at_ms": 500, "every_ms": 300, "after_last": false},
	]), true), Battle.DONE)
	var counts: Array = []
	for row: Dictionary in b.wave_preview(0):
		counts.append([row["enemy"], row["count"]])
	assert_eq(counts, [[&"scamp", 3], [&"flitter", 9], [&"pip", 3], [&"flitter", 4]], "own groups 2 x 1.5 and 3 x 2 x 1.5; added groups as stated")
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 20)
	var copy: Battle = Fx.restored(b)
	assert_not_null(copy)
	log.append_array(Fx.log_ticks(b, 3000))
	assert_eq(b.phase, Battle.Phase.WON, "the one wave ran to its end")
	var tally: Dictionary = {}
	for entry: Array in Fx.of_kind(log, &"spawned"):
		tally[entry[1]["enemy"]] = int(tally.get(entry[1]["enemy"], 0)) + 1
	assert_eq(tally, {&"scamp": 3, &"flitter": 13, &"pip": 3})
	Fx.run_wave(copy)
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b), "a restored wave spawns the same counts")


func test_a_waiting_risk_card_saves_and_its_wave_keeps_it_rules_14_4() -> void:
	var b: Battle = _risky([{"type": "health_pct", "pct": 200}, {"type": "reward_gold", "amount": 250}], [{"groups": [Fx.group("scamp", 4, 0, 500)]}, {"groups": [Fx.group("scamp", 1)]}])
	var copy: Battle = Fx.restored(b)
	assert_eq(copy.risk_waiting, b.risk_waiting)
	b.start_next_wave()
	Fx.steps(b, 30)
	copy = Fx.restored(b)
	assert_not_null(copy)
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b))
	Fx.run_wave(b)
	Fx.run_wave(copy)
	assert_eq(Fx.snapshot(copy), Fx.snapshot(b), "the restored wave pays the same reward")


# Stars still possible (RULES 10, FUN_REVIEW_R1 item 2).

func test_stars_possible_rules_10() -> void:
	var waves: Array = [{"groups": [Fx.group("pip", 1)]}, {"groups": [Fx.group("pip", 1)]}, {"groups": [Fx.group("pip", 1)]}]
	var tiers: Battle = Battle.create(_level(Fx.LINE_GRID, waves, {"star3": {"kind": "tier_at_most", "value": 1}}), catalog, false, [])
	assert_eq(tiers.stars_possible(), 7)
	tiers.place_tower(Vector2i(2, 1), &"sling_post")
	tiers.upgrade_tower(Vector2i(2, 1))
	assert_eq(tiers.stars_possible(), 3, "a tier 2 tower loses star 3 at once")
	tiers.lives = catalog.rules.star2_lives - 1
	assert_eq(tiers.stars_possible(), 1, "too few lives for star 2")
	var relaxed: Battle = Battle.create(_level(Fx.LINE_GRID, waves), catalog, true, [])
	assert_eq(relaxed.stars_possible(), 1, "Relaxed earns star 1 only")
	var early: Battle = Battle.create(_level(Fx.LINE_GRID, waves, {"star3": {"kind": "early_calls_at_least", "value": 2}}), catalog, false, [])
	assert_eq(early.stars_possible() & 4, 4, "waves 2 and 3 can still be called early")
	early.start_next_wave()
	Fx.run_wave(early)
	assert_eq(early.stars_possible() & 4, 0, "from a build phase only wave 3 could still be early")
	var gates: Battle = Battle.create(_level(Fx.FORK_GRID, waves, {"gates": 1, "star3": {"kind": "gates_at_most", "value": 0}}), catalog, false, [])
	gates.place_gate(Vector2i(1, 3))
	assert_eq(gates.stars_possible() & 4, 4, "a gate counts only when a wave starts")
	gates.start_next_wave()
	assert_eq(gates.stars_possible() & 4, 0)
	var lost: Battle = Battle.create(_level(Fx.LINE_GRID, [{"groups": [Fx.group("pip", 1)]}]), catalog, false, [])
	lost.lives = 1
	lost.start_next_wave()
	Fx.run_wave(lost)
	assert_eq(lost.phase, Battle.Phase.LOST)
	assert_eq(lost.stars_possible(), 0, "a lost battle earns nothing")
	var won: Battle = Battle.create(_level(Fx.LINE_GRID, [{"groups": [Fx.group("pip", 1)]}]), catalog, false, [])
	won.place_tower(Vector2i(2, 1), &"sling_post")
	won.start_next_wave()
	Fx.run_wave(won)
	assert_eq(won.phase, Battle.Phase.WON)
	assert_eq(won.stars_possible(), won.result()["stars"])


## A level on the fork with this star 3 rule and two waves.
func _star_battle(star3: Dictionary, changes: Dictionary = {}, effects: Array = []) -> Battle:
	var waves: Array = [{"groups": [Fx.group("pip", 1)]}, {"groups": [Fx.group("pip", 1)]}, {"groups": [Fx.group("pip", 1)]}]
	var all: Dictionary = {"gates": 1, "star3": star3}
	all.merge(changes, true)
	return Battle.create(_level(Fx.FORK_GRID, waves, all), catalog, false, _effects(effects))


func test_both_star_queries_for_every_star3_kind_contract_3_1() -> void:
	# no_lives_lost: a leak loses it; no action warns.
	var lives: Battle = _star_battle({"kind": "no_lives_lost"})
	assert_eq(lives.stars_possible(), 7)
	for action: StringName in [&"build", &"upgrade", &"gate"]:
		assert_false(lives.loses_star3(action, &"sling_post", 3))
	lives.lives -= 1
	assert_eq(lives.stars_possible(), 3)
	# towers_at_most 2: the third tower warns; selling never brings the star back.
	var count: Battle = _star_battle({"kind": "towers_at_most", "value": 2})
	count.place_tower(Vector2i(0, 1), &"sling_post")
	assert_false(count.loses_star3(&"build", &"sling_post"))
	count.place_tower(Vector2i(6, 1), &"sling_post")
	assert_true(count.loses_star3(&"build", &"pumpkin_catapult"))
	assert_false(count.loses_star3(&"upgrade", &"", 3), "upgrades do not count towers")
	count.place_tower(Vector2i(3, 3), &"sling_post")
	assert_eq(count.stars_possible() & 4, 0)
	count.sell_tower(Vector2i(3, 3))
	assert_eq(count.stars_possible() & 4, 0, "never more than N at any time")
	assert_false(count.loses_star3(&"build", &"sling_post"), "nothing left to lose")
	# tower_ban: only the banned tower warns.
	var ban: Battle = _star_battle({"kind": "tower_ban", "tower": "pumpkin_catapult"})
	assert_true(ban.loses_star3(&"build", &"pumpkin_catapult"))
	assert_false(ban.loses_star3(&"build", &"sling_post"))
	ban.place_tower(Vector2i(0, 1), &"pumpkin_catapult")
	ban.sell_tower(Vector2i(0, 1))
	assert_eq(ban.stars_possible() & 4, 0, "built once is enough")
	# gates_at_most 0: placing warns; the star goes only when a wave starts.
	var gate: Battle = _star_battle({"kind": "gates_at_most", "value": 0})
	assert_true(gate.loses_star3(&"gate"))
	gate.place_gate(Vector2i(1, 3))
	assert_eq(gate.stars_possible() & 4, 4)
	gate.remove_gate(Vector2i(1, 3))
	gate.start_next_wave()
	assert_eq(gate.stars_possible() & 4, 4, "no gate when the wave started")
	Fx.run_wave(gate)
	gate.place_gate(Vector2i(1, 3))
	gate.start_next_wave()
	assert_eq(gate.stars_possible() & 4, 0)
	# tier_at_most 1, with a tower that went above it and was then sold.
	var tier: Battle = _star_battle({"kind": "tier_at_most", "value": 1})
	assert_false(tier.loses_star3(&"upgrade", &"", 1))
	assert_true(tier.loses_star3(&"upgrade", &"", 2))
	tier.place_tower(Vector2i(0, 1), &"sling_post")
	tier.upgrade_tower(Vector2i(0, 1))
	tier.sell_tower(Vector2i(0, 1))
	assert_eq(tier.stars_possible() & 4, 0, "the sold tower still went above the cap")
	assert_false(tier.loses_star3(&"upgrade", &"", 2))
	# early_calls_at_least 1: lost once too few waves are left to call.
	var early: Battle = _star_battle({"kind": "early_calls_at_least", "value": 1})
	assert_eq(early.stars_possible() & 4, 4)
	assert_false(early.loses_star3(&"build", &"sling_post"))
	for w: int in 2:
		early.start_next_wave()
		Fx.run_wave(early)
	assert_eq(early.stars_possible() & 4, 0, "the last wave starts from a build phase")
	# kinds_at_most 1: a second kind warns, more of the same kind does not.
	var kinds: Battle = _star_battle({"kind": "kinds_at_most", "value": 1})
	assert_false(kinds.loses_star3(&"build", &"pumpkin_catapult"), "no kind built yet")
	kinds.place_tower(Vector2i(0, 1), &"sling_post")
	assert_false(kinds.loses_star3(&"build", &"sling_post"))
	assert_true(kinds.loses_star3(&"build", &"pumpkin_catapult"))
	# gates_whole: a wave started without every gate loses it; no action warns.
	var whole: Battle = _star_battle({"kind": "gates_whole"})
	assert_false(whole.loses_star3(&"gate"))
	whole.start_next_wave()
	assert_eq(whole.stars_possible() & 4, 0)
	# Relaxed: star 1 only, and no warnings.
	var relaxed: Battle = Battle.create(_level(Fx.FORK_GRID, [{"groups": [Fx.group("pip", 1)]}], {"gates": 1, "star3": {"kind": "gates_at_most", "value": 0}}), catalog, true, [])
	assert_eq(relaxed.stars_possible(), 1)
	assert_false(relaxed.loses_star3(&"gate"))
	assert_false(count.loses_star3(&"sell"), "an unknown action gives false")


func test_a_tower_above_a_twist_tier_cap_cannot_exist_contract_3_1() -> void:
	# With the No Upgrades Twist the star 3 tier rule can never break by an upgrade.
	var b: Battle = _star_battle({"kind": "tier_at_most", "value": 1}, {}, [{"type": "tier_cap", "tier": 1}])
	b.place_tower(Vector2i(0, 1), &"sling_post")
	assert_eq(b.upgrade_tower(Vector2i(0, 1)), &"tier_cap")
	assert_eq(b.stars_possible() & 4, 4)


func test_the_early_call_bonus_comes_from_card_bounties_contract_2_8() -> void:
	var b: Battle = _run_battle([{"type": "bounty_pct", "pct": 200}], [{"groups": [Fx.group("scamp", 3, 0, 50)]}, {"groups": [Fx.group("scamp", 1)]}])
	b.start_next_wave()
	Fx.steps(b, 4)
	var bounty: int = Sim.pct_half_up(catalog.enemy(&"scamp").bounty, 200)
	assert_eq(b.next_wave_info()["bonus"], Sim.pct_up(3 * bounty, catalog.rules.early_bonus_pct))


func test_feast_days_never_scale_a_risk_reward_contract_2_8() -> void:
	var b: Battle = _run_battle([{"type": "clear_bonus_pct", "pct": 150}], [{"strength": 120, "groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("scamp", 1)]}])
	b.add_effects(_effects([{"type": "reward_gold", "amount": 100}]), true)
	b.start_next_wave()
	var cleared: Dictionary = Fx.of_kind(Fx.log_ticks(b, 1000), &"wave_cleared")[0][1]
	var clear: int = Sim.pct_half_up(Sim.pct_half_up(catalog.rules.clear_bonus + catalog.rules.clear_bonus_per_wave, 120), 150)
	assert_eq(cleared["gold"], clear + Sim.pct_half_up(100, 120))


func test_effects_reach_released_creatures_but_not_release_counts_contract_2_8() -> void:
	# A Twist's armor and speed reach a boss's summons; Double Trouble doubles groups only.
	var boss: Battle = _twist([{"type": "armor_add", "amount": 3}, {"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
		[], [{"groups": [Fx.group("grumblesack", 1)]}])
	boss.start_next_wave()
	var log: Array = Fx.log_ticks(boss, 160)
	var scamps: int = 0
	for entry: Array in Fx.of_kind(log, &"spawned"):
		var e: EnemyState = boss.enemy_with_id(int(entry[1]["id"]))
		if entry[1]["enemy"] == &"scamp":
			scamps += 1
			assert_eq(e.armor, catalog.enemy(&"scamp").armor + 3, "a summon has the Twist's armor")
	var summon: Dictionary = catalog.enemy(&"grumblesack").summon
	assert_eq(scamps, 2 * int(summon["count"]), "two bosses, each with its data count")
	# A risk card's health reaches the Puffs of its wave.
	var weak: Catalog = Fx.catalog_with_enemy("puffball", {"health": 1})
	var level: LevelData = Fx.level(Fx.LINE_GRID, [{"groups": [Fx.group("puffball", 1)]}], {"towers": ["sling_post"], "start_gold": 500}, weak)
	var b: Battle = Battle.create(level, weak, false, [])
	b.add_effects(_effects([{"type": "health_pct", "pct": 200}]), true)
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.start_next_wave()
	var puff: EnemyState = null
	for i: int in 200:
		b.step()
		for e: EnemyState in b.enemies:
			if puff == null and e.type == &"puff":
				puff = e
	assert_not_null(puff)
	assert_eq(puff.max_health, Sim.pct_half_up(weak.enemy(&"puff").health, 200))
