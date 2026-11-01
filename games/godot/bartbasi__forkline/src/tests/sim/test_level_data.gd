# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## LevelData.check and from_data: every map rule of docs/ARCHITECTURE.md 2.3 (RULES 3),
## every level field of 2.4, the star 3 kinds of 2.7 (RULES 10.3) and the spawn bound.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _waves() -> Array:
	return [{"groups": [Fx.group("scamp", 3)]}]


func _data(changes: Dictionary = {}) -> Dictionary:
	return Fx.level_data(Fx.FORK_GRID, _waves(), changes)


func _refused(data: Variant, what: String) -> void:
	assert_false(LevelData.check(data, catalog).is_empty(), what)
	assert_null(LevelData.from_data(data, catalog), what + " gives no level")


func _grid_refused(grid: Array, what: String) -> void:
	_refused(_data({"grid": grid}), what)


func test_a_good_level_reads_every_field() -> void:
	var data: Dictionary = _data({"gates": 1, "hint": {"text": "Drop the gate.", "cell": [1, 3]},
		"star3": {"kind": "towers_at_most", "value": 4},
		"waves": [{"groups": [Fx.group("scamp", 6, 0, 1000)]}, {"strength": 110, "groups": [Fx.group("pip", 8, 500, 800)]}]})
	assert_eq(LevelData.check(data, catalog).size(), 0, "; ".join(LevelData.check(data, catalog)))
	var level: LevelData = LevelData.from_data(data, catalog)
	assert_eq(level.id, &"test_map")
	assert_eq(level.rows, 10)
	assert_eq(level.entrances, [Vector2i(3, 0)])
	assert_eq(level.base, Vector2i(3, 9))
	assert_eq(level.sockets, [Vector2i(1, 3), Vector2i(5, 5)], "sockets in cell order")
	assert_eq(level.spots, [Vector2i(0, 1), Vector2i(6, 1), Vector2i(3, 3), Vector2i(3, 5), Vector2i(3, 7), Vector2i(2, 9), Vector2i(4, 9)], "spots in cell order (RULES 3.4)")
	assert_eq(level.gates, 1)
	assert_eq(level.star3, {"kind": &"towers_at_most", "value": 4, "tower": &""})
	assert_eq(level.hint_text, "Drop the gate.")
	assert_eq(level.hint_cell, Vector2i(1, 3))
	assert_eq(level.hint_button, &"")
	assert_eq(level.waves.size(), 2)
	assert_eq(level.waves[0].strength, 100, "a wave without strength takes the level's (RULES 6.4)")
	assert_eq(level.waves[1].strength, 110)
	var g: WaveGroup = level.waves[1].groups[0]
	assert_eq([g.enemy, g.count, g.entrance, g.at_tick, g.every_ticks], [&"pip", 8, 0, 10, 16])
	assert_eq(level.kind_at(Vector2i(3, 0)), LevelData.Kind.ENTRANCE)
	assert_eq(level.kind_at(Vector2i(1, 3)), LevelData.Kind.SOCKET)
	assert_eq(level.kind_at(Vector2i(0, 1)), LevelData.Kind.SPOT)
	assert_eq(level.kind_at(Vector2i(3, 9)), LevelData.Kind.BASE)
	assert_eq(level.kind_at(Vector2i(2, 2)), LevelData.Kind.ROAD)
	assert_eq(level.kind_at(Vector2i(0, 0)), LevelData.Kind.SCENERY)
	assert_eq(level.kind_at(Vector2i(-1, 0)), LevelData.Kind.SCENERY, "outside the map")
	assert_eq(level.kind_at(Vector2i(0, 10)), LevelData.Kind.SCENERY, "outside the map")


func test_to_data_round_trips() -> void:
	var data: Dictionary = _data({"gates": 2, "hint": {"text": "Call it.", "button": "call"},
		"star3": {"kind": "tower_ban", "tower": "sling_post"}})
	var level: LevelData = LevelData.from_data(data, catalog)
	var again: LevelData = LevelData.from_data(level.to_data(), catalog)
	assert_not_null(again)
	assert_eq(JSON.stringify(again.to_data()), JSON.stringify(level.to_data()))
	var through_text: LevelData = LevelData.from_data(JSON.parse_string(JSON.stringify(level.to_data())), catalog)
	assert_eq(JSON.stringify(through_text.to_data()), JSON.stringify(level.to_data()))
	assert_eq(again.hint_button, &"call")
	assert_eq(again.star3["tower"], &"sling_post")


func test_map_size_rules_3_1() -> void:
	var short: Array = Fx.LINE_GRID.slice(0, 7)
	_grid_refused(short, "7 rows")
	var tall: Array = Fx.FORK_GRID.duplicate()
	for i: int in 4:
		tall.insert(1, "...#...")
	_grid_refused(tall, "14 rows")
	var wide: Array = Fx.FORK_GRID.duplicate()
	wide[4] = ".#...#.."
	_grid_refused(wide, "8 columns")
	var bad_char: Array = Fx.FORK_GRID.duplicate()
	bad_char[4] = ".#.x.#."
	_grid_refused(bad_char, "unknown character")
	var not_string: Array = Fx.FORK_GRID.duplicate()
	not_string[4] = 1234567
	_grid_refused(not_string, "a row that is not a string")


func test_roads_are_one_tile_wide_rules_3_3() -> void:
	var grid: Array = Fx.FORK_GRID.duplicate()
	grid[3] = ".GG..#."
	_grid_refused(grid, "a 2 x 2 block of road")


func test_entrances_and_base_rules_3_2() -> void:
	var two_bases: Array = Fx.FORK_GRID.duplicate()
	two_bases[9] = "..BBo.."
	_grid_refused(two_bases, "two bases")
	var no_base: Array = Fx.FORK_GRID.duplicate()
	no_base[9] = "..o#o.."
	_grid_refused(no_base, "no base")
	var no_entrance: Array = Fx.FORK_GRID.duplicate()
	no_entrance[0] = "...#..."
	_grid_refused(no_entrance, "no entrance")
	var gap: Array = Fx.FORK_GRID.duplicate()
	gap[0] = "...2..."
	_grid_refused(gap, "entrances numbered with a gap")
	var twice: Array = Fx.TRIPLE_GRID.duplicate()
	twice[0] = "1.....1"
	_grid_refused(twice, "entrance 1 twice")
	var inner: Array = Fx.LINE_GRID.duplicate()
	inner[0] = "...#..."
	inner[1] = "..o1o.."
	_grid_refused(inner, "an entrance off the edge")
	var two: Dictionary = Fx.level_data(Fx.TRIPLE_GRID, _waves())
	assert_eq(LevelData.check(two, catalog).size(), 0, "two entrances on the top edge")
	assert_eq(LevelData.from_data(two, catalog).entrances, [Vector2i(0, 0), Vector2i(6, 0)])


func test_every_entrance_must_reach_the_base_rules_3_3() -> void:
	var cut: Array = Fx.LINE_GRID.duplicate()
	cut[4] = "......."
	_grid_refused(cut, "an entrance with no road to the base")


func test_spot_and_socket_limits() -> void:
	var grid: Array = [
		"ooo1ooo", "ooo#ooo", "ooo#ooo", "ooo#ooo", "ooo#ooo", "ooo#ooo", "ooo#ooo", "oooBooo",
	]
	_grid_refused(grid, "more than 24 spots")
	var sockets: Array = ["...1...", "...G...", "...G...", "...G...", "...G...", "...G...", "...G...", "...G...", "...G...", "...G...", "...B..."]
	_grid_refused(sockets, "more than 8 sockets")


func test_level_fields_are_checked() -> void:
	var cases: Array = [
		{"format": 2}, {"id": "Level 1"}, {"name": ""}, {"start_gold": -10}, {"start_gold": 100001},
		{"gates": 3}, {"gates": -1}, {"strength": 49}, {"strength": 1001},
		{"towers": []}, {"towers": ["sling_post", "sling_post"]}, {"towers": ["tower_x"]},
		{"towers": ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery", "bakery"]},
		{"star3": {"kind": "best"}}, {"star3": {"kind": "towers_at_most"}},
		{"star3": {"kind": "towers_at_most", "value": 101}}, {"star3": {"kind": "gates_at_most", "value": 4}},
		{"star3": {"kind": "tier_at_most", "value": 3}}, {"star3": {"kind": "tower_ban", "tower": "nope"}},
		{"star3": {"kind": "no_lives_lost", "value": 1}},
		{"hint": {"text": ""}}, {"hint": {"text": "x", "cell": [1, 3], "button": "call"}},
		{"hint": {"text": "x", "cell": [7, 3]}}, {"hint": {"text": "x", "button": "pause"}},
		{"waves": []}, {"extra": 1},
	]
	for changes: Dictionary in cases:
		_refused(_data(changes), str(changes))
	var data: Dictionary = _data()
	data.erase("star3")
	_refused(data, "missing star3")


func test_wave_and_group_fields_are_checked() -> void:
	var bad_groups: Array = [
		Fx.group("dragon", 3), Fx.group("scamp", 0), Fx.group("scamp", 201),
		Fx.group("scamp", 3, 25), Fx.group("scamp", 3, 0, 0), Fx.group("scamp", 3, 0, 60050),
		Fx.group("scamp", 3, 600050), Fx.group("scamp", 3, 0, 1000, 2), Fx.group("scamp", 3, 0, 1000, 0),
	]
	for group: Dictionary in bad_groups:
		_refused(_data({"waves": [{"groups": [group]}]}), str(group))
	_refused(_data({"waves": [{"groups": []}]}), "a wave with no groups")
	_refused(_data({"waves": [{"strength": 20, "groups": [Fx.group("scamp", 3)]}]}), "wave strength 20")
	var nine: Array = []
	for i: int in 9:
		nine.append(Fx.group("scamp", 1))
	_refused(_data({"waves": [{"groups": nine}]}), "9 groups")
	var many: Array = []
	for i: int in 41:
		many.append({"groups": [Fx.group("scamp", 1)]})
	_refused(_data({"waves": many}), "41 waves")


func test_spawn_bound_counts_splits_rules_12_5() -> void:
	# docs/ARCHITECTURE.md 2.4, RULES 12.5: at most 120 per wave, a splitter counting its Puffs.
	assert_eq(LevelData.check(_data({"waves": [{"groups": [Fx.group("scamp", 120, 0, 50)]}]}), catalog).size(), 0)
	_refused(_data({"waves": [{"groups": [Fx.group("scamp", 100, 0, 50), Fx.group("pip", 21, 0, 50)]}]}), "121 creatures")
	assert_eq(LevelData.check(_data({"waves": [{"groups": [Fx.group("puffball", 30, 0, 50)]}]}), catalog).size(), 0, "30 Puffballs are 120")
	_refused(_data({"waves": [{"groups": [Fx.group("puffball", 31, 0, 50)]}]}), "31 Puffballs are 124")


func test_twist_shape_and_fixed_gates() -> void:
	var good: Dictionary = _data({"gates": 1, "twist": {"name": "Stuck Gate", "text": "The gate is stuck on its socket.",
		"effects": [{"type": "fixed_gates", "cells": [[5, 5]]}]}})
	assert_eq(LevelData.check(good, catalog).size(), 0, "; ".join(LevelData.check(good, catalog)))
	var level: LevelData = LevelData.from_data(good, catalog)
	assert_eq(level.twist_name, "Stuck Gate")
	assert_eq(level.twist_effects, [{"type": "fixed_gates", "cells": [[5, 5]]}])
	_refused(_data({"gates": 1, "twist": {"name": "X", "text": "Y", "effects": [{"type": "fixed_gates", "cells": [[2, 2]]}]}}), "a fixed gate off a socket")
	_refused(_data({"gates": 1, "twist": {"name": "X", "text": "Y", "effects": [{"type": "fixed_gates", "cells": [[1, 3], [5, 5]]}]}}), "fixed gates that seal")
	_refused(_data({"gates": 0, "twist": {"name": "X", "text": "Y", "effects": [{"type": "fixed_gates", "cells": [[1, 3]]}]}}), "more fixed gates than given")
	_refused(_data({"twist": {"name": "X", "text": "Y", "effects": []}}), "no effects")
	_refused(_data({"twist": {"name": "X", "text": "Y", "effects": [{"type": "add_gold", "amount": 1, "per_wave": 0}]}}), "a card effect in a Twist")
	_refused(_data({"twist": {"name": "X", "text": "Y", "effects": [{"type": "no_selling"}, {"type": "no_selling"}, {"type": "no_selling"}]}}), "3 effects")
	# The spawn bound counts a Twist's count_pct (2.4).
	var doubled: Dictionary = _data({"waves": [{"groups": [Fx.group("scamp", 61, 0, 50)]}],
		"twist": {"name": "Double", "text": "Twice as many.", "effects": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}]}})
	_refused(doubled, "a Twist that doubles 61 creatures")


func test_hostile_input_never_crashes() -> void:
	for value: Variant in [null, 1, "x", [], {}, {"grid": "nope"}, {"id": 5}, {"waves": {"a": 1}}]:
		_refused(value, str(value))
	var data: Dictionary = _data()
	for key: String in data.keys():
		for bad: Variant in [null, -1, 1.5, "x", [], {}, [null], NAN]:
			var copy: Dictionary = data.duplicate(true)
			copy[key] = bad
			LevelData.check(copy, catalog)
	assert_false(LevelData.check(_data(), null).is_empty(), "no catalog")
	var problems: PackedStringArray = LevelData.check(_data({"start_gold": 7}), catalog)
	assert_eq(problems.size(), 0, "start_gold need not be a multiple of 10")
	problems = LevelData.check(_data({"strength": 7}), catalog)
	assert_eq(problems, PackedStringArray(["test_map.json: strength: must be 50 to 1000"]))
