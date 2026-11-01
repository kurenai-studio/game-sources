# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## RunPacks.spawn_total: the creatures one wave spawns (docs/ARCHITECTURE.md 2.8, 2.9, 3.4).

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _effects(list: Array) -> Array[Dictionary]:
	return Modifiers.normalize_all(list)


func _group(enemy: String, count: int) -> Dictionary:
	return Fx.group(enemy, count)


func test_plain_groups_add_up_and_a_puffball_counts_its_puffs() -> void:
	var none: Array[Dictionary] = []
	assert_eq(RunPacks.spawn_total([_group("scamp", 7), _group("pip", 5)], catalog, none), 12)
	var split: int = catalog.enemy(&"puffball").split_count
	assert_true(split > 0, "a Puffball splits")
	assert_eq(RunPacks.spawn_total([_group("puffball", 4)], catalog, none), 4 * (1 + split))
	assert_eq(RunPacks.spawn_total([], catalog, none), 0)


func test_count_pct_scales_the_waves_own_groups_rounded_up() -> void:
	var crowd: Array[Dictionary] = _effects([
		{"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false},
		{"type": "reward_gold", "amount": 100},
	])
	assert_eq(RunPacks.spawn_total([_group("scamp", 5)], catalog, crowd), 8, "5 x 1.5 = 7.5 rounds up")
	var split: int = catalog.enemy(&"puffball").split_count
	assert_eq(RunPacks.spawn_total([_group("puffball", 3)], catalog, crowd), 5 * (1 + split))


func test_flyers_only_count_pct_leaves_walkers_alone() -> void:
	var wings: Array[Dictionary] = _effects([
		{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false},
		{"type": "reward_gold", "amount": 50},
	])
	assert_eq(RunPacks.spawn_total([_group("scamp", 5), _group("flitter", 4)], catalog, wings), 5 + 8)


## An added group comes at its card's count. count_pct does not reach it (2.8).
func test_an_added_group_keeps_its_cards_count() -> void:
	var flock: Array[Dictionary] = _effects([
		{"type": "add_group", "enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 2000, "every_ms": 400, "after_last": true},
		{"type": "reward_gold", "amount": 80},
	])
	assert_eq(RunPacks.spawn_total([_group("scamp", 5)], catalog, flock), 13)
	var both: Array[Dictionary] = _effects([
		{"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false},
		{"type": "add_group", "enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 2000, "every_ms": 400, "after_last": true},
		{"type": "reward_gold", "amount": 80},
	])
	assert_eq(RunPacks.spawn_total([_group("scamp", 5)], catalog, both), 8 + 8, "the scamps scale, the added flitters do not")
	assert_eq(RunPacks.spawn_total([_group("flitter", 4)], catalog, both), 6 + 8, "a flitter group of the wave scales, the added one does not")


func test_an_added_splitter_still_counts_its_puffs() -> void:
	var split: int = catalog.enemy(&"puffball").split_count
	var added: Array[Dictionary] = _effects([
		{"type": "add_group", "enemy": "puffball", "count": 3, "entrance": 1, "at_ms": 0, "every_ms": 500, "after_last": false},
		{"type": "reward_gold", "amount": 10},
		{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": false},
	])
	assert_eq(RunPacks.spawn_total([], catalog, added), 3 * (1 + split))
