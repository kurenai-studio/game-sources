# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The campaign's design rules on the real level files (RULES 3.1, 3.4, 10.3, 12.2 to
## 12.5; docs/ARCHITECTURE.md 2.4, 2.7, 10). Tests compare ids and numbers, never names.

const Files: GDScript = preload("res://tests/levels/fixtures/level_files.gd")
const Rules: GDScript = preload("res://tests/levels/fixtures/map_rules.gd")

## RULES 12.3 and 12.4, one row per level in play order:
## gates, sockets, waves, strength, Normal starting gold, star 3 kind and value,
## and the kind of cell the hint highlights ("none" for a level with no hint).
## Region 3's third stars changed on 2026-10-25 (TUNING_CAMPAIGN.md).
## 2-2's star 3 is "Use no gates" (TUNING_R2.md, 2026-10-24). 6-1's is "No tower above tier 2." (RULES 12.4, 2026-10-28).
const PLAN: Dictionary = {
	"r1_l1": {"gates": 0, "sockets": 0, "waves": 8, "strength": 100, "gold": 200, "star3": ["tier_at_most", 1], "highlight": "spot"},
	"r1_l2": {"gates": 1, "sockets": 2, "waves": 8, "strength": 100, "gold": 250, "star3": ["tier_at_most", 1], "highlight": "socket"},
	"r1_l3": {"gates": 1, "sockets": 2, "waves": 9, "strength": 100, "gold": 250, "star3": ["towers_at_most", 2], "highlight": "spot"},
	"r1_l4": {"gates": 1, "sockets": 3, "waves": 9, "strength": 100, "gold": 300, "star3": ["tier_at_most", 1], "highlight": "spot"},
	"r1_l5": {"gates": 1, "sockets": 3, "waves": 10, "strength": 100, "gold": 300, "star3": ["tier_at_most", 2], "highlight": "spot"},
	"r1_l6": {"gates": 1, "sockets": 3, "waves": 10, "strength": 100, "gold": 350, "star3": ["gates_at_most", 0], "highlight": "spot"},
	"r2_l1": {"gates": 1, "sockets": 3, "waves": 10, "strength": 130, "gold": 350, "star3": ["early_calls_at_least", 6], "highlight": "call"},
	"r2_l2": {"gates": 1, "sockets": 3, "waves": 10, "strength": 135, "gold": 400, "star3": ["gates_at_most", 0], "highlight": "spot"},
	"r2_l3": {"gates": 1, "sockets": 3, "waves": 10, "strength": 140, "gold": 400, "star3": ["tier_at_most", 2], "highlight": "spot"},
	"r2_l4": {"gates": 2, "sockets": 4, "waves": 11, "strength": 145, "gold": 450, "star3": ["gates_at_most", 1], "highlight": "socket"},
	"r2_l5": {"gates": 2, "sockets": 4, "waves": 11, "strength": 150, "gold": 450, "star3": ["tower_ban", "longbow_loft"], "highlight": "spot"},
	"r2_l6": {"gates": 2, "sockets": 5, "waves": 12, "strength": 160, "gold": 500, "star3": ["kinds_at_most", 3], "highlight": "spot"},
	"r3_l1": {"gates": 2, "sockets": 4, "waves": 11, "strength": 170, "gold": 500, "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
	"r3_l2": {"gates": 2, "sockets": 4, "waves": 11, "strength": 175, "gold": 550, "star3": ["tier_at_most", 2], "highlight": "spot"},
	"r3_l3": {"gates": 3, "sockets": 5, "waves": 12, "strength": 180, "gold": 550, "star3": ["towers_at_most", 5], "highlight": "socket"},
	"r3_l4": {"gates": 2, "sockets": 5, "waves": 12, "strength": 185, "gold": 600, "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
	"r3_l5": {"gates": 3, "sockets": 6, "waves": 12, "strength": 190, "gold": 600, "star3": ["tier_at_most", 2], "highlight": "none"},
	"r3_l6": {"gates": 3, "sockets": 6, "waves": 12, "strength": 200, "gold": 650, "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
	"r4_l1": {"gates": 2, "sockets": 5, "waves": 12, "strength": 210, "gold": 650, "star3": ["towers_at_most", 6], "highlight": "spot"},
	"r4_l2": {"gates": 2, "sockets": 5, "waves": 12, "strength": 220, "gold": 700, "star3": ["tower_ban", "pumpkin_catapult"], "highlight": "spot"},
	"r4_l3": {"gates": 3, "sockets": 6, "waves": 12, "strength": 230, "gold": 700, "star3": ["gates_whole", 0], "highlight": "socket"},
	"r4_l4": {"gates": 3, "sockets": 6, "waves": 12, "strength": 240, "gold": 750, "star3": ["kinds_at_most", 3], "highlight": "none"},
	"r4_l5": {"gates": 3, "sockets": 6, "waves": 12, "strength": 250, "gold": 750, "star3": ["early_calls_at_least", 6], "highlight": "none"},
	"r4_l6": {"gates": 3, "sockets": 6, "waves": 12, "strength": 260, "gold": 800, "star3": ["no_lives_lost", 0], "highlight": "spot"},
	"r5_l1": {"gates": 2, "sockets": 5, "waves": 12, "strength": 230, "gold": 700, "star3": ["towers_at_most", 4], "highlight": "socket"},
	"r5_l2": {"gates": 2, "sockets": 5, "waves": 12, "strength": 235, "gold": 750, "star3": ["tier_at_most", 2], "highlight": "spot"},
	"r5_l3": {"gates": 2, "sockets": 5, "waves": 12, "strength": 240, "gold": 750, "star3": ["towers_at_most", 4], "highlight": "spot"},
	"r5_l4": {"gates": 3, "sockets": 6, "waves": 12, "strength": 245, "gold": 800, "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
	"r5_l5": {"gates": 3, "sockets": 6, "waves": 12, "strength": 250, "gold": 800, "star3": ["kinds_at_most", 3], "highlight": "none"},
	"r5_l6": {"gates": 3, "sockets": 6, "waves": 12, "strength": 255, "gold": 850, "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
	"r6_l1": {"gates": 2, "sockets": 5, "waves": 12, "strength": 245, "gold": 750, "star3": ["tier_at_most", 2], "highlight": "socket"},
	"r6_l2": {"gates": 2, "sockets": 5, "waves": 12, "strength": 250, "gold": 800, "star3": ["towers_at_most", 6], "highlight": "spot"},
	"r6_l3": {"gates": 3, "sockets": 6, "waves": 12, "strength": 255, "gold": 800, "star3": ["tower_ban", "longbow_loft"], "highlight": "spot"},
	"r6_l4": {"gates": 3, "sockets": 6, "waves": 12, "strength": 260, "gold": 850, "star3": ["tier_at_most", 2], "highlight": "spot"},
	"r6_l5": {"gates": 3, "sockets": 6, "waves": 12, "strength": 265, "gold": 850, "star3": ["early_calls_at_least", 6], "highlight": "none"},
	"r6_l6": {"gates": 3, "sockets": 6, "waves": 12, "strength": 270, "gold": 900, "star3": ["no_lives_lost", 0], "highlight": "spot"},
	"r7_l1": {"gates": 2, "sockets": 5, "waves": 12, "strength": 255, "gold": 800, "star3": ["towers_at_most", 6], "highlight": "socket"},
	"r7_l2": {"gates": 2, "sockets": 5, "waves": 12, "strength": 260, "gold": 850, "star3": ["tower_ban", "pumpkin_catapult"], "highlight": "spot"},
	"r7_l3": {"gates": 3, "sockets": 6, "waves": 12, "strength": 265, "gold": 850, "star3": ["gates_at_most", 0], "highlight": "spot"},
	"r7_l4": {"gates": 3, "sockets": 6, "waves": 12, "strength": 270, "gold": 900, "star3": ["towers_at_most", 7], "highlight": "spot"},
	"r7_l5": {"gates": 3, "sockets": 7, "waves": 12, "strength": 275, "gold": 900, "star3": ["tier_at_most", 2], "highlight": "none"},
	"r7_l6": {"gates": 3, "sockets": 7, "waves": 12, "strength": 280, "gold": 950, "star3": ["kinds_at_most", 3], "highlight": "spot"},
	"r8_l1": {"gates": 2, "sockets": 5, "waves": 12, "strength": 265, "gold": 850, "star3": ["towers_at_most", 6], "highlight": "socket"},
	"r8_l2": {"gates": 3, "sockets": 6, "waves": 12, "strength": 270, "gold": 900, "star3": ["tower_ban", "sling_post"], "highlight": "spot"},
	"r8_l3": {"gates": 3, "sockets": 6, "waves": 12, "strength": 275, "gold": 900, "star3": ["tier_at_most", 2], "highlight": "spot"},
	"r8_l4": {"gates": 3, "sockets": 7, "waves": 12, "strength": 280, "gold": 950, "star3": ["tower_ban", "lullaby_bell"], "highlight": "spot"},
	"r8_l5": {"gates": 3, "sockets": 7, "waves": 12, "strength": 290, "gold": 950, "star3": ["kinds_at_most", 3], "highlight": "none"},
	"r8_l6": {"gates": 3, "sockets": 7, "waves": 12, "strength": 300, "gold": 1000, "star3": ["no_lives_lost", 0], "highlight": "spot"},
}

## docs/ARCHITECTURE.md 2.8 and RULES 13: each level's Twist as effects. The level designer picks
## the sockets of Stuck Gate and Stuck Gates. 1-3 is Tier 2 Cap (DM decision, 2026-10-24),
## because No Upgrades could not be won on Normal (TUNING_R1.md S4).
const TWISTS: Dictionary = {
	"r1_l1": [{"type": "start_gold_pct", "pct": 50}],
	"r1_l2": [{"type": "fixed_gates", "cells": [[6, 5]]}],
	"r1_l3": [{"type": "tier_cap", "tier": 2}],
	"r1_l4": [{"type": "ban_tower", "tower": "pumpkin_catapult"}],
	"r1_l5": [{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false}],
	"r1_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
	"r2_l1": [{"type": "speed_pct", "pct": 120}],
	"r2_l2": [{"type": "ban_tower", "tower": "lullaby_bell"}],
	"r2_l3": [{"type": "armor_add", "amount": 2}],
	"r2_l4": [{"type": "set_gates", "count": 0}],
	"r2_l5": [{"type": "all_bubbles"}],
	"r2_l6": [{"type": "fixed_gates", "cells": [[1, 3], [5, 8]]}],
	"r3_l1": [{"type": "ban_tower", "tower": "firework_tower"}],
	"r3_l2": [{"type": "ban_tower", "tower": "pumpkin_catapult"}],
	"r3_l3": [{"type": "set_gates", "count": 1}],
	"r3_l4": [{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false}],
	"r3_l5": [{"type": "tier_cap", "tier": 2}],
	"r3_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
	"r4_l1": [{"type": "start_gold_pct", "pct": 50}],
	"r4_l2": [{"type": "ban_tower", "tower": "longbow_loft"}],
	"r4_l3": [{"type": "break_ms", "enemy": "gatecrasher", "ms": 2000}],
	"r4_l4": [{"type": "no_selling"}],
	"r4_l5": [{"type": "set_lives", "lives": 5}],
	"r4_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
	"r5_l1": [{"type": "set_gates", "count": 1}],
	"r5_l2": [{"type": "ban_tower", "tower": "pumpkin_catapult"}],
	"r5_l3": [{"type": "tier_cap", "tier": 2}],
	"r5_l4": [{"type": "set_gates", "count": 0}],
	"r5_l5": [{"type": "set_lives", "lives": 5}],
	"r5_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
	"r6_l1": [{"type": "fixed_gates", "cells": [[5, 5], [3, 8]]}],
	"r6_l2": [{"type": "ban_tower", "tower": "lullaby_bell"}],
	"r6_l3": [{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false}],
	"r6_l4": [{"type": "no_selling"}],
	"r6_l5": [{"type": "start_gold_pct", "pct": 50}],
	"r6_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
	"r7_l1": [{"type": "set_gates", "count": 0}],
	"r7_l2": [{"type": "ban_tower", "tower": "longbow_loft"}],
	"r7_l3": [{"type": "speed_pct", "pct": 120}],
	"r7_l4": [{"type": "armor_add", "amount": 2}],
	"r7_l5": [{"type": "all_bubbles"}],
	"r7_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
	"r8_l1": [{"type": "set_gates", "count": 1}],
	"r8_l2": [{"type": "ban_tower", "tower": "firework_tower"}],
	"r8_l3": [{"type": "ban_tower", "tower": "lullaby_bell"}],
	"r8_l4": [{"type": "count_pct", "pct": 200, "flyers": true, "last_wave": false}],
	"r8_l5": [{"type": "set_lives", "lives": 5}],
	"r8_l6": [{"type": "count_pct", "pct": 200, "flyers": false, "last_wave": true}],
}

## RULES 12.2: the towers each level brings.
const NEW_TOWERS: Dictionary = {
	"r1_l1": ["sling_post", "pumpkin_catapult"],
	"r2_l2": ["lullaby_bell"],
	"r2_l3": ["longbow_loft"],
	"r3_l1": ["firework_tower"],
	"r4_l1": ["bakery"],
	"r5_l2": ["bramble_cottage"],
	"r6_l2": ["scarecrow"],
	"r7_l2": ["snow_fort"],
	"r8_l2": ["moth_lantern"],
}

## RULES 12.2 and 12.3: the creature each level brings and its first wave, 1 based.
const NEW_CREATURES: Dictionary = {
	"r1_l1": ["scamp", 1],
	"r1_l4": ["pip", 3],
	"r1_l5": ["flitter", 3],
	"r1_l6": ["grumblesack", 10],
	"r2_l1": ["skitter", 2],
	"r2_l3": ["shellback", 3],
	"r2_l5": ["bubbler", 2],
	"r2_l6": ["ironshell", 12],
	"r3_l2": ["puffball", 2],
	"r3_l4": ["dusk_moth", 3],
	"r3_l6": ["moon_moth", 12],
	"r4_l2": ["mender", 2],
	"r4_l3": ["gatecrasher", 3],
	"r4_l6": ["old_tusk", 12],
	"r5_l3": ["mossbud", 2],
	"r5_l4": ["mistwisp", 3],
	"r5_l6": ["burrowbelly", 12],
	"r6_l3": ["gleamer", 2],
	"r6_l4": ["sleepyhead", 3],
	"r6_l6": ["old_hayrick", 12],
	"r7_l3": ["snowroller", 2],
	"r7_l4": ["yawner", 3],
	"r7_l6": ["snowsnore", 12],
	"r8_l3": ["blinker", 2],
	"r8_l4": ["hootling", 3],
	"r8_l6": ["glimmertoad", 12],
}

## RULES 3.5 and 12.1: the kind of map feature each region brings (map_rules.gd FEATURE_KINDS). Regions 1 to 4 have none.
const REGION_FEATURES: Dictionary = {"lantern_hill": "", "millbrook": "", "willow_fen": "", "moonspire_keep": "", "hollow_lanes": "tunnel",
	"russet_orchards": "bridge", "frostpine_ridge": "slide", "starglen": "stump"}
## RULES 3.5 and 12.3: levels 5 and 6 of regions 6 to 8 may add one earlier feature, never two. 7-5 adds tunnels, 8-5 a bridge.
const EXTRA_FEATURES: Dictionary = {"r7_l5": "tunnel", "r8_l5": "bridge"}
## RULES 12.2: the level where each feature first appears, as that region's first level.
const NEW_FEATURES: Dictionary = {"tunnel": "r5_l1", "bridge": "r6_l1", "slide": "r7_l1", "stump": "r8_l1"}
## RULES 12.5: at most 6 of each of these creatures in one wave, with the level's Twist, boss summons not counted.
const CAPPED_CREATURES: Array[StringName] = [&"mistwisp", &"hootling"]
const CAPPED_MOST: int = 6

## RULES 3.1 and 3.4: map rows and build spots per region, and entrances per region (12.3).
const REGION_ROWS: Dictionary = {"lantern_hill": [8, 11], "millbrook": [10, 13], "willow_fen": [10, 13], "moonspire_keep": [10, 13], "hollow_lanes": [10, 13], "russet_orchards": [10, 13],
	"frostpine_ridge": [10, 13], "starglen": [10, 13]}
const REGION_SPOTS: Dictionary = {"lantern_hill": [5, 7], "millbrook": [7, 9], "willow_fen": [8, 10], "moonspire_keep": [9, 11], "hollow_lanes": [9, 11], "russet_orchards": [10, 12],
	"frostpine_ridge": [10, 12], "starglen": [11, 12]}
const REGION_ENTRANCES: Dictionary = {"lantern_hill": [1, 1], "millbrook": [1, 2], "willow_fen": [1, 2], "moonspire_keep": [2, 3], "hollow_lanes": [1, 2], "russet_orchards": [1, 2],
	"frostpine_ridge": [1, 2], "starglen": [1, 3]}
## RULES 12.3: region 5 has one entrance, then two from 5-5. Regions 6 and 7 have one on their first level, then two.
## Region 8 has one on 8-1, then two, and three on 8-5.
const LEVEL_ENTRANCES: Dictionary = {"r5_l1": 1, "r5_l2": 1, "r5_l3": 1, "r5_l4": 1, "r5_l5": 2, "r5_l6": 2,
	"r6_l1": 1, "r6_l2": 2, "r6_l3": 2, "r6_l4": 2, "r6_l5": 2, "r6_l6": 2,
	"r7_l1": 1, "r7_l2": 2, "r7_l3": 2, "r7_l4": 2, "r7_l5": 2, "r7_l6": 2,
	"r8_l1": 1, "r8_l2": 2, "r8_l3": 2, "r8_l4": 2, "r8_l5": 3, "r8_l6": 2}

## RULES 12.5: a new creature's first wave holds 3 to 5 of it. A boss comes alone.
const FIRST_WAVE_COUNT: Array[int] = [3, 5]
## docs/ARCHITECTURE.md 2.4 spawn bound, and RULES 12.5's aim for a readable screen.
const SPAWN_BOUND: int = 120
const SPAWN_AIM: int = 80
## RULES 12.5: a level lasts 5 to 10 minutes at 1x, counting the wave phases with no
## early calls plus 15 s for each build phase. Only the floor is checked here.
const LENGTH_MS: Array[int] = [5 * 60 * 1000, 10 * 60 * 1000]
const BUILD_MS: int = 15 * 1000

var catalog: Catalog = null
var order: PackedStringArray = PackedStringArray()
var levels: Dictionary = {}


func before_each() -> void:
	catalog = Files.catalog()
	order = Files.campaign_order()
	for id: String in order:
		var level: LevelData = Files.level(id, catalog)
		if level == null:
			fail("%s does not load" % id)
			continue
		levels[id] = level


func _level(id: String) -> LevelData:
	return levels.get(id, null) as LevelData


## The creature kinds in one wave, in group order, without repeats.
func _kinds(wave: WaveData) -> Array[StringName]:
	var out: Array[StringName] = []
	for group: WaveGroup in wave.groups:
		if not out.has(group.enemy):
			out.append(group.enemy)
	return out


func test_every_campaign_level_has_a_plan_row() -> void:
	var planned: Array = PLAN.keys()
	assert_eq(PackedStringArray(planned), order, "PLAN rows match the campaign order")


func test_numbers_follow_rules_12_3() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or not PLAN.has(id):
			continue
		var plan: Dictionary = PLAN[id]
		assert_eq(level.gates, plan["gates"], "%s gates" % id)
		assert_eq(level.sockets.size(), plan["sockets"], "%s sockets" % id)
		assert_eq(level.waves.size(), plan["waves"], "%s waves" % id)
		assert_eq(level.strength, plan["strength"], "%s strength" % id)
		assert_eq(level.start_gold, plan["gold"], "%s starting gold" % id)


func test_map_size_spots_and_entrances_by_region() -> void:
	var regions: Dictionary = Files.region_of()
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var region: String = regions.get(id, "")
		assert_true(REGION_ROWS.has(region), "%s: region %s is known" % [id, region])
		if not REGION_ROWS.has(region):
			continue
		var rows: Array = REGION_ROWS[region]
		var spots: Array = REGION_SPOTS[region]
		assert_eq(level.grid.size(), level.rows, "%s rows" % id)
		for line: String in level.grid:
			assert_eq(line.length(), Sim.MAP_COLUMNS, "%s: every row is 7 columns" % id)
		assert_true(level.rows >= int(rows[0]) and level.rows <= int(rows[1]), "%s: %d rows, region allows %s" % [id, level.rows, rows])
		assert_true(level.spots.size() >= int(spots[0]) and level.spots.size() <= int(spots[1]), "%s: %d build spots, region allows %s" % [id, level.spots.size(), spots])
		if REGION_ENTRANCES.has(region):
			var entrances: Array = REGION_ENTRANCES[region]
			assert_true(level.entrances.size() >= int(entrances[0]) and level.entrances.size() <= int(entrances[1]), "%s: %d entrances" % [id, level.entrances.size()])


func test_towers_are_every_tower_brought_by_then() -> void:
	var brought: Array[StringName] = []
	for id: String in order:
		for tower: String in NEW_TOWERS.get(id, []):
			assert_not_null(catalog.tower(StringName(tower)), "%s brings a known tower %s" % [id, tower])
			brought.append(StringName(tower))
		var level: LevelData = _level(id)
		if level == null:
			continue
		var offered: Array[StringName] = level.towers.duplicate()
		offered.sort()
		var expected: Array[StringName] = brought.duplicate()
		expected.sort()
		assert_eq(offered, expected, "%s offers exactly the towers brought by then (RULES 12.2)" % id)


func test_only_creatures_brought_by_then() -> void:
	var brought: Array[StringName] = []
	for id: String in order:
		if NEW_CREATURES.has(id):
			brought.append(StringName(NEW_CREATURES[id][0]))
		var level: LevelData = _level(id)
		if level == null:
			continue
		for i: int in level.waves.size():
			for group: WaveGroup in level.waves[i].groups:
				assert_true(brought.has(group.enemy), "%s wave %d: %s is brought by then" % [id, i + 1, group.enemy])


func test_each_new_creature_comes_alone_first_in_its_planned_wave() -> void:
	var seen: Array[StringName] = []
	var met: Dictionary = {}
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		for i: int in level.waves.size():
			var wave: WaveData = level.waves[i]
			var kinds: Array[StringName] = _kinds(wave)
			var fresh: Array[StringName] = []
			for kind: StringName in kinds:
				if not seen.has(kind):
					fresh.append(kind)
			assert_true(fresh.size() <= 1, "%s wave %d: never two new things in one wave, got %s" % [id, i + 1, fresh])
			if fresh.is_empty():
				continue
			var kind: StringName = fresh[0]
			met[String(kind)] = [id, i + 1]
			assert_eq(kinds.size(), 1, "%s wave %d: %s's first wave holds only it, got %s" % [id, i + 1, kind, kinds])
			var count: int = 0
			for group: WaveGroup in wave.groups:
				count += group.count
			if catalog.enemy(kind) != null and catalog.enemy(kind).boss:
				assert_eq(count, 1, "%s wave %d: a boss comes alone" % [id, i + 1])
			else:
				assert_true(count >= FIRST_WAVE_COUNT[0] and count <= FIRST_WAVE_COUNT[1], "%s wave %d: %d of the new %s, RULES 12.5 asks 3 to 5" % [id, i + 1, count, kind])
			for k: StringName in kinds:
				seen.append(k)
	for id: String in NEW_CREATURES:
		var planned: Array = NEW_CREATURES[id]
		assert_eq(met.get(str(planned[0]), []), [id, int(planned[1])], "%s first appears in %s wave %d" % [planned[0], id, planned[1]])


func test_bosses_only_in_the_final_wave_of_a_regions_last_level() -> void:
	var data: Variant = Files.campaign()
	var last_levels: Array[String] = []
	if data is Dictionary and data.get("regions") is Array:
		for region: Variant in data["regions"]:
			var region_levels: Array = region.get("levels", [])
			if not region_levels.is_empty():
				last_levels.append(str(region_levels[region_levels.size() - 1]))
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var final_has_boss: bool = false
		for i: int in level.waves.size():
			for group: WaveGroup in level.waves[i].groups:
				var enemy: EnemyType = catalog.enemy(group.enemy)
				if enemy == null or not enemy.boss:
					continue
				assert_eq(i, level.waves.size() - 1, "%s: boss %s only in the final wave" % [id, group.enemy])
				assert_true(last_levels.has(id), "%s: a boss only in a region's last level" % id)
				if i == level.waves.size() - 1:
					final_has_boss = true
		if last_levels.has(id):
			assert_true(final_has_boss, "%s: a region's last level is its boss level" % id)


func test_no_group_of_puffs() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		for i: int in level.waves.size():
			for group: WaveGroup in level.waves[i].groups:
				assert_ne(group.enemy, &"puff", "%s wave %d: Puffs come only from Puffballs" % [id, i + 1])


func test_spawn_bound_holds() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		for i: int in level.waves.size():
			var total: int = 0
			for group: WaveGroup in level.waves[i].groups:
				var enemy: EnemyType = catalog.enemy(group.enemy)
				var split: int = 0 if enemy == null else enemy.split_count
				total += group.count * (1 + split)
			assert_true(total <= SPAWN_BOUND, "%s wave %d spawns %d, the bound is %d" % [id, i + 1, total, SPAWN_BOUND])
			assert_true(total <= SPAWN_AIM, "%s wave %d spawns %d, RULES 12.5 aims for %d or fewer" % [id, i + 1, total, SPAWN_AIM])


## Every way to place up to `left` gates on the sockets, the empty set included.
func _gate_sets(sockets: Array[Vector2i], left: int, start: int, current: Array, out: Array[Array]) -> void:
	out.append(current.duplicate())
	if left == 0:
		return
	for i: int in range(start, sockets.size()):
		var next: Array = current.duplicate()
		next.append(sockets[i])
		_gate_sets(sockets, left - 1, i + 1, next, out)


## The most steps from each entrance to the base, over every gate placement the level
## allows that seals nothing. Index 0 is entrance 1.
func _longest_steps(level: LevelData) -> Array[int]:
	var map: RoadMap = RoadMap.new(level)
	var out: Array[int] = []
	for i: int in level.entrances.size():
		out.append(0)
	var sets: Array[Array] = []
	_gate_sets(level.sockets, level.gates, 0, [], sets)
	for placed: Array in sets:
		var closed: Array[Vector2i] = []
		closed.assign(placed)
		if map.seals(closed):
			continue
		var dist: PackedInt32Array = map.distances(closed)
		for i: int in level.entrances.size():
			out[i] = maxi(out[i], map.route(level.entrances[i], dist).size() - 1)
	return out


## Milliseconds to walk `steps` road cells, unslowed. Speed is hundredths of a tile a second.
func _walk_ms(speed: int, steps: int) -> int:
	return 0 if speed <= 0 else steps * 100 * 1000 / speed


## The latest a creature, and anything it releases, can still be on the map after it
## appears: it walks the whole route, waits out every gate if it breaks gates, and its
## last release walks the whole route again.
func _stay_ms(enemy: EnemyType, steps: int, gates: int) -> int:
	var own: int = _walk_ms(enemy.speed, steps) + enemy.break_ms * gates
	var after: int = 0
	if not enemy.summon.is_empty():
		var summoned: EnemyType = catalog.enemy(enemy.summon["enemy"])
		if summoned != null:
			after = maxi(after, (int(enemy.summon["count"]) - 1) * int(enemy.summon["gap_ms"]) + _walk_ms(summoned.speed, steps))
	if not enemy.release.is_empty():
		var released: EnemyType = catalog.enemy(enemy.release["enemy"])
		if released != null:
			after = maxi(after, (int(enemy.release["count"]) - 1) * int(enemy.release["gap_ms"]) + _walk_ms(released.speed, steps))
	if enemy.split_into != &"":
		var split: EnemyType = catalog.enemy(enemy.split_into)
		if split != null:
			after = maxi(after, (enemy.split_count - 1) * enemy.split_gap_ms + _walk_ms(split.speed, steps))
	return own + after


## RULES 12.5. The longest a level can last at 1x when nothing is slowed: no creature is
## popped, each walks the longest route the gates can make (a flyer's straight line is
## never longer), and every wave starts when the one before it ends. Under 5 minutes every
## play would be too short. This bound counts no kills at all, so on the long roads and slow
## creatures of region 2 it runs past any real play; the smoke test checks the 10 minute
## ceiling on the plain mixed recipe's real win instead (RULES 12.6).
func test_longest_unslowed_play_is_at_least_5_minutes() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var longest: Array[int] = _longest_steps(level)
		var total_ms: int = BUILD_MS * level.waves.size()
		for wave: WaveData in level.waves:
			var end_ms: int = 0
			for group: WaveGroup in wave.groups:
				var enemy: EnemyType = catalog.enemy(group.enemy)
				if enemy == null or group.entrance < 0 or group.entrance >= longest.size():
					fail("%s: a group names an unknown creature or entrance" % id)
					continue
				var last_ms: int = (group.at_tick + (group.count - 1) * group.every_ticks) * Sim.MS_PER_TICK
				end_ms = maxi(end_ms, last_ms + _stay_ms(enemy, longest[group.entrance], level.gates))
			total_ms += end_ms
		assert_true(total_ms >= LENGTH_MS[0], "%s: the longest unslowed play is %.1f min, RULES 12.5 asks at least 5" % [id, total_ms / 60000.0])


func test_star3_follows_rules_12_4() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or not PLAN.has(id):
			continue
		var planned: Array = PLAN[id]["star3"]
		assert_eq(level.star3.get("kind"), StringName(planned[0]), "%s star 3 kind" % id)
		if planned[1] is String:
			assert_eq(level.star3.get("tower", &""), StringName(planned[1]), "%s star 3 tower" % id)
		else:
			assert_eq(level.star3.get("value", 0), int(planned[1]), "%s star 3 value" % id)


func test_star3_leaves_two_kinds_of_attacking_tower_usable() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var kind: StringName = level.star3.get("kind", &"")
		var value: int = level.star3.get("value", 0)
		var usable: Array[StringName] = []
		for tower: StringName in level.towers:
			var type: TowerType = catalog.tower(tower)
			if type == null or type.kind != &"attack":
				continue
			if kind == &"tower_ban" and level.star3.get("tower", &"") == tower:
				continue
			usable.append(tower)
		assert_true(usable.size() >= 2, "%s: star 3 leaves %s as attacking towers" % [id, usable])
		if kind == &"kinds_at_most" or kind == &"towers_at_most":
			assert_true(value >= 2, "%s: star 3 allows two attacking towers" % id)
		if kind == &"tier_at_most":
			assert_true(value >= 1, "%s: star 3 allows building" % id)


func test_hint_highlights_the_planned_kind_of_cell() -> void:
	var kinds: Dictionary = {"spot": LevelData.Kind.SPOT, "socket": LevelData.Kind.SOCKET}
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or not PLAN.has(id):
			continue
		if PLAN[id]["highlight"] == "none":
			# RULES 12.4: a level that brings nothing new, such as 3-5, has no hint and no highlight.
			assert_true(level.hint_text.is_empty(), "%s has no hint" % id)
			assert_eq(level.hint_cell, Vector2i(-1, -1), "%s highlights no cell" % id)
			assert_eq(level.hint_button, &"", "%s highlights no button" % id)
			continue
		assert_false(level.hint_text.is_empty(), "%s has a hint (RULES 9.6)" % id)
		if PLAN[id]["highlight"] == "call":
			# RULES 12.4 and contract 7.4: level 2-1 highlights the call button, not a cell.
			assert_eq(level.hint_button, &"call", "%s highlights the call button" % id)
			assert_eq(level.hint_cell, Vector2i(-1, -1), "%s highlights no cell" % id)
			continue
		assert_eq(level.hint_button, &"", "%s highlights a cell, not a button" % id)
		assert_true(level.hint_cell.x >= 0 and level.hint_cell.y >= 0, "%s highlights a cell" % id)
		var planned: String = PLAN[id]["highlight"]
		assert_eq(level.kind_at(level.hint_cell), kinds[planned], "%s: the hint cell %s is a %s" % [id, level.hint_cell, planned])


## Contract 7.4: the Paused strip and messages never cover the highlighted cell. On the Fold5 cover
## they reach up into map row 9 (measured by tests/ui/real_tree_checks.gd on 2026-10-24, when 4-6
## first glowed on row 9), so a highlighted cell sits in rows 0 to 8. tests/ui/ checks the real layout.
const HIGHLIGHT_LAST_ROW: int = 8


func test_a_highlighted_cell_sits_above_the_paused_strip() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or level.hint_cell.y < 0:
			continue
		assert_true(level.hint_cell.y <= HIGHLIGHT_LAST_ROW, "%s: the highlighted cell %s is in rows 0 to %d" % [id, level.hint_cell, HIGHLIGHT_LAST_ROW])


## RULES 12.4: on 7-4 the highlighted spot is set back from the road, out of a Yawner's yawn reach from every
## road tile, so a tower there stays awake. A tower whose tier 1 reach is no more than that yawn reach never
## touches the road from such a spot, which is the point of the hint.
const SET_BACK_HIGHLIGHT: Dictionary = {"r7_l4": &"yawner"}


## RULES 9.6: a first tower built on a highlighted spot touches the road the creatures walk
## with no gate placed. Every tower that attacks or slows reaches, at tier 1, some cell of an
## entrance's open route outside the tunnels, where a walker can be hit (RULES 3.6). (Level 2-2
## once glowed on a spot that saw road only with a gate on.) On a set-back highlight the towers
## that cannot reach past the yawn are left out (SET_BACK_HIGHLIGHT).
func test_a_highlighted_spot_sees_the_open_route() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or level.hint_cell.x < 0 or level.kind_at(level.hint_cell) != LevelData.Kind.SPOT:
			continue
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var dist: PackedInt32Array = map.distances(none)
		var walked: Array[Vector2i] = []
		for entrance: Vector2i in level.entrances:
			walked.append_array(map.route(entrance, dist))
		var short_reach: int = 0
		if SET_BACK_HIGHLIGHT.has(id) and catalog.enemy(SET_BACK_HIGHLIGHT[id]) != null:
			short_reach = catalog.enemy(SET_BACK_HIGHLIGHT[id]).yawn_reach
		for tower: StringName in level.towers:
			var type: TowerType = catalog.tower(tower)
			if type == null or type.kind == &"boost":
				continue
			var reach: int = type.stats(1, -1).reach
			if reach <= short_reach:
				continue
			var seen: bool = false
			for cell: Vector2i in walked:
				if level.feature_at(cell) == LevelData.Feature.TUNNEL:
					continue
				var dx: int = (cell.x - level.hint_cell.x) * 100
				var dy: int = (cell.y - level.hint_cell.y) * 100
				if dx * dx + dy * dy <= reach * reach:
					seen = true
					break
			assert_true(seen, "%s: a %s on the highlighted spot %s reaches the open route" % [id, tower, level.hint_cell])


## docs/ARCHITECTURE.md 2.4 and 7.4, RULES 3.1: the bottom row of a 13 row map is scenery only,
## so the folded wave preview on the Fold5 cover never hides a spot, socket, entrance or home.
func test_a_13_row_maps_bottom_row_is_scenery() -> void:
	var tall: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or level.rows != Sim.MAP_ROWS_MAX:
			continue
		tall += 1
		assert_eq(level.grid[level.rows - 1], ".".repeat(Sim.MAP_COLUMNS), "%s: the bottom row of a 13 row map is all scenery" % id)
	assert_true(tall >= 1, "some level has 13 rows, so the rule is exercised")


## RULES 13 and docs/ARCHITECTURE.md 2.8: every level has its planned Twist.
func test_every_level_has_its_planned_twist() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		assert_true(TWISTS.has(id), "%s has a planned Twist" % id)
		assert_false(level.twist_name.is_empty(), "%s has a Twist name" % id)
		assert_false(level.twist_text.is_empty(), "%s has a Twist card text" % id)
		if TWISTS.has(id):
			assert_eq(JSON.stringify(level.twist_effects, "", true), JSON.stringify(TWISTS[id], "", true), "%s Twist effects" % id)


## RULES 13: Stuck Gate and Stuck Gates fix every gate the level gives, each on a socket,
## and the fixed gates leave every entrance a way to the base.
func test_stuck_gates_fix_every_gate_on_sockets() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var fixed: Array[Vector2i] = []
		for effect: Dictionary in level.twist_effects:
			if effect["type"] == "fixed_gates":
				for cell: Array in effect["cells"]:
					fixed.append(Vector2i(int(cell[0]), int(cell[1])))
		if fixed.is_empty():
			continue
		assert_eq(fixed.size(), level.gates, "%s: the Twist fixes every gate the level gives" % id)
		for cell: Vector2i in fixed:
			assert_true(level.sockets.has(cell), "%s: fixed gate %s is on a socket" % [id, cell])
		assert_false(RoadMap.new(level).seals(fixed), "%s: the fixed gates seal no entrance" % id)


## docs/ARCHITECTURE.md 2.4: with its Twist applied, a wave spawns at most 120 creatures.
func test_spawn_bound_holds_with_the_twist() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		for i: int in level.waves.size():
			var total: int = 0
			for group: WaveGroup in level.waves[i].groups:
				var enemy: EnemyType = catalog.enemy(group.enemy)
				if enemy == null:
					continue
				var count: int = group.count
				for effect: Dictionary in level.twist_effects:
					if effect["type"] != "count_pct":
						continue
					if bool(effect["flyers"]) and not enemy.flying:
						continue
					if bool(effect["last_wave"]) and i != level.waves.size() - 1:
						continue
					count = ceili(count * int(effect["pct"]) / 100.0)
				total += count * (1 + enemy.split_count)
			assert_true(total <= SPAWN_BOUND, "%s wave %d spawns %d with its Twist, the bound is %d" % [id, i + 1, total, SPAWN_BOUND])


## Contract 7.4: on the Fold5 cover the first hint sits over a band of whole map rows that hold
## nothing to see or tap, when the dock has no room for it under the map. On maps of 12 and 13
## rows it never has room (289 px and 134 px under the map, against a 206 px strip and a 152 px
## hint), so those maps keep at least one such row above the bottom row: no build spot, gate
## socket, entrance, home, highlighted cell, fork or join (a road cell with three or four road
## neighbors). Shorter maps can put the hint in the dock. tests/ui/ checks the real layout.
const FREE_ROW_FROM_ROWS: int = 12


func test_tall_maps_keep_a_free_row_for_the_hint() -> void:
	var tall: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or level.rows < FREE_ROW_FROM_ROWS:
			continue
		tall += 1
		var free: Array[int] = []
		for row: int in level.rows - 1:
			if _row_is_free(level, row):
				free.append(row)
		assert_false(free.is_empty(), "%s keeps a row free for the hint" % id)
	assert_true(tall >= 1, "some level has 12 or more rows, so the rule is exercised")


func _row_is_free(level: LevelData, row: int) -> bool:
	if level.hint_cell.y == row:
		return false
	for column: int in Sim.MAP_COLUMNS:
		var cell: Vector2i = Vector2i(column, row)
		var kind: LevelData.Kind = level.kind_at(cell)
		if kind == LevelData.Kind.SPOT or kind == LevelData.Kind.SOCKET or kind == LevelData.Kind.ENTRANCE or kind == LevelData.Kind.BASE:
			return false
		if level.is_road(cell):
			var near: int = 0
			for step: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				if level.is_road(cell + step):
					near += 1
			if near >= 3:
				return false
	return true


## The first map with a second entrance brings it in gently (brief: never two new things in one
## wave): wave 1 comes only from entrance A, and the first wave from entrance B comes from B
## alone and brings no creature the player has not met.
func test_a_second_entrance_comes_in_gently() -> void:
	_new_entrance_comes_in_gently(1, "B")


## The first map with a third entrance (4-4) brings it in the same way: wave 1 uses only
## entrances A and B, and the first wave from entrance C comes from C alone and brings no
## creature the player has not met.
func test_a_third_entrance_comes_in_gently() -> void:
	_new_entrance_comes_in_gently(2, "C")


## `index` is the entrance, 0 based. Checks the first level in play order that has it.
func _new_entrance_comes_in_gently(index: int, letter: String) -> void:
	var seen: Array[StringName] = []
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		if level.entrances.size() <= index:
			for wave: WaveData in level.waves:
				for group: WaveGroup in wave.groups:
					if not seen.has(group.enemy):
						seen.append(group.enemy)
			continue
		for group: WaveGroup in level.waves[0].groups:
			assert_true(group.entrance < index, "%s wave 1 does not use entrance %s" % [id, letter])
		for i: int in level.waves.size():
			var wave: WaveData = level.waves[i]
			var from_new: bool = false
			for group: WaveGroup in wave.groups:
				if group.entrance == index:
					from_new = true
			if not from_new:
				for group: WaveGroup in wave.groups:
					if not seen.has(group.enemy):
						seen.append(group.enemy)
				continue
			for group: WaveGroup in wave.groups:
				assert_eq(group.entrance, index, "%s wave %d, the first from entrance %s, comes from %s alone" % [id, i + 1, letter, letter])
				assert_true(seen.has(group.enemy), "%s wave %d, the first from entrance %s, brings nothing new (%s)" % [id, i + 1, letter, group.enemy])
			return
		fail("%s has entrance %s but no wave uses it" % [id, letter])
		return


## RULES 10.3 "Use every gate and keep them whole" (4-3). The star must ask the player to guard a
## gate: every placement of all the level's gates that seals nothing puts at least one gate on the
## dashed line (the route with no gates placed, RULES 7.7) of every entrance a gate breaker comes
## from. Otherwise the gates could sit off the breakers' way and the star would ask nothing.
func test_gates_whole_always_puts_a_gate_on_the_dashed_line() -> void:
	var checked: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null or level.star3.get("kind", &"") != &"gates_whole":
			continue
		checked += 1
		var breaker_entrances: Array[int] = []
		for wave: WaveData in level.waves:
			for group: WaveGroup in wave.groups:
				var enemy: EnemyType = catalog.enemy(group.enemy)
				if enemy != null and enemy.break_ms > 0 and not breaker_entrances.has(group.entrance):
					breaker_entrances.append(group.entrance)
		assert_false(breaker_entrances.is_empty(), "%s: a gate breaker comes" % id)
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var dist: PackedInt32Array = map.distances(none)
		var sets: Array[Array] = []
		_gate_sets(level.sockets, level.gates, 0, [], sets)
		var full: int = 0
		for placed: Array in sets:
			if placed.size() != level.gates:
				continue
			var closed: Array[Vector2i] = []
			closed.assign(placed)
			if map.seals(closed):
				continue
			full += 1
			for entrance: int in breaker_entrances:
				var dashed: Array[Vector2i] = map.route(level.entrances[entrance], dist)
				var on_line: bool = false
				for cell: Vector2i in closed:
					if dashed.has(cell):
						on_line = true
				assert_true(on_line, "%s: gates %s keep off the dashed line from entrance %d" % [id, closed, entrance + 1])
		assert_true(full >= 1, "%s: all its gates can be placed" % id)
	assert_true(checked >= 1, "some level asks to keep every gate whole, so the rule is exercised")


## RULES 12.3: region 5 has one entrance on its first four levels, then two. Region 6 has one on 6-1, then two.
func test_entrances_per_level() -> void:
	for id: String in LEVEL_ENTRANCES:
		var level: LevelData = _level(id)
		assert_not_null(level, "%s loads" % id)
		if level != null:
			assert_eq(level.entrances.size(), int(LEVEL_ENTRANCES[id]), "%s entrances" % id)


## RULES 3.5 and docs/ARCHITECTURE.md 14.13: each region's levels use its own map feature and no
## other. Levels 5 and 6 of regions 6 to 8 may add one earlier feature (EXTRA_FEATURES), never two.
func test_each_region_uses_its_own_feature() -> void:
	var regions: Dictionary = Files.region_of()
	for id: String in order:
		var level: LevelData = _level(id)
		var region: String = regions.get(id, "")
		if level == null or not REGION_FEATURES.has(region):
			fail("%s: region %s has no planned feature" % [id, region])
			continue
		var wanted: PackedStringArray = PackedStringArray()
		if REGION_FEATURES[region] != "":
			wanted.append(REGION_FEATURES[region])
		if EXTRA_FEATURES.has(id):
			assert_true(id.ends_with("_l5") or id.ends_with("_l6"), "%s: only levels 5 and 6 add an earlier feature" % id)
			assert_true(REGION_FEATURES.values().has(EXTRA_FEATURES[id]) and REGION_FEATURES[region] != EXTRA_FEATURES[id], "%s adds an earlier region's feature" % id)
			wanted.append(EXTRA_FEATURES[id])
		wanted.sort()
		var held: PackedStringArray = Rules.feature_kinds(level.grid)
		held.sort()
		assert_eq(held, wanted, "%s holds the features %s, its region brings %s" % [id, held, wanted])


## RULES 12.2: a feature first appears on its region's first level, and from region 5 on that level
## brings only the feature: one entrance, no new tower and no new creature, so it is the one new idea.
func test_a_feature_comes_alone_on_its_regions_first_level() -> void:
	var met: Dictionary = {}
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		for kind: String in Rules.feature_kinds(level.grid):
			if not met.has(kind):
				met[kind] = id
	for kind: String in NEW_FEATURES:
		var id: String = NEW_FEATURES[kind]
		assert_eq(met.get(kind, ""), id, "%s first appears on %s" % [kind, id])
		var level: LevelData = _level(id)
		if level == null:
			continue
		assert_eq(level.entrances.size(), 1, "%s has one entrance" % id)
		assert_false(NEW_TOWERS.has(id), "%s brings no new tower" % id)
		assert_false(NEW_CREATURES.has(id), "%s brings no new creature" % id)


## RULES 3.6: tunnels are straight runs of 1 to 4 tiles with no fork or bend, at most 6 tiles a map,
## never next to a socket, and at most a quarter of any entrance's shortest route with no gates.
func test_tunnels_follow_rules_3_6() -> void:
	var with_tunnels: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		if not Rules.tunnel_tiles(level).is_empty():
			with_tunnels += 1
		var found: PackedStringArray = Rules.tunnel_problems(level)
		assert_eq(found, PackedStringArray(), "%s: %s" % [id, "; ".join(found)])
	assert_true(with_tunnels >= 6, "the region 5 levels have tunnels, so the rules are exercised")


## The tunnel puzzle (RULES 12.3, 5-1: "Gate them out of it."): on every map with tunnels, some
## placement of the level's gates that seals nothing gives every entrance a route that keeps out of
## every tunnel, so a gate can always bring the walkers back into reach.
func test_a_gate_placement_keeps_every_entrance_out_of_the_tunnels() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var tiles: Array[Vector2i] = Rules.tunnel_tiles(level)
		if tiles.is_empty():
			continue
		var map: RoadMap = RoadMap.new(level)
		var sets: Array[Array] = []
		Rules.gate_sets(level.sockets, level.gates, 0, [], sets)
		var found: bool = false
		for placed: Array in sets:
			var closed: Array[Vector2i] = []
			closed.assign(placed)
			if map.seals(closed):
				continue
			var dist: PackedInt32Array = map.distances(closed)
			var clear: bool = true
			for entrance: Vector2i in level.entrances:
				for cell: Vector2i in map.route(entrance, dist):
					if tiles.has(cell):
						clear = false
			if clear:
				found = true
				break
		assert_true(found, "%s: some placement of its %d gates keeps every entrance out of the tunnels" % [id, level.gates])


## RULES 12.5: at most 6 Mistwisps and 6 Hootlings in a wave, counted as the 120 bound counts them,
## with the level's Twist and without boss summons.
func test_at_most_6_mistwisps_and_hootlings_a_wave() -> void:
	var checked: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		for i: int in level.waves.size():
			for capped: StringName in CAPPED_CREATURES:
				var total: int = 0
				for group: WaveGroup in level.waves[i].groups:
					if group.enemy != capped:
						continue
					checked += 1
					var count: int = group.count
					for effect: Dictionary in level.twist_effects:
						if effect["type"] != "count_pct" or bool(effect["flyers"]):
							continue
						if bool(effect["last_wave"]) and i != level.waves.size() - 1:
							continue
						count = ceili(count * int(effect["pct"]) / 100.0)
					total += count
				assert_true(total <= CAPPED_MOST, "%s wave %d brings %d %s with its Twist, at most %d" % [id, i + 1, total, capped, CAPPED_MOST])
	assert_true(checked >= 1, "some level brings Mistwisps, so the cap is exercised")


## RULES 3.7: every bridge has four road neighbors, so it is never on the map edge; a map has at most 3;
## and a plain road tile lies between two bridges.
func test_bridges_follow_rules_3_7() -> void:
	var with_bridges: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		if not Rules.bridge_tiles(level).is_empty():
			with_bridges += 1
		var found: PackedStringArray = Rules.bridge_problems(level)
		assert_eq(found, PackedStringArray(), "%s: %s" % [id, "; ".join(found)])
	assert_true(with_bridges >= 6, "the region 6 levels have bridges, so the rules are exercised")


## RULES 3.7 level guide: every bridge lies on the shortest route of some placement of the level's gates,
## so it always matters.
func test_every_bridge_lies_on_some_route() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var off: Array[Vector2i] = Rules.bridges_off_every_route(level, level.gates)
		assert_true(off.is_empty(), "%s: the bridges %s lie on no route of any gate placement" % [id, off])


## The bridge lesson (RULES 12.3 and 12.4, 6-1: "A loop passes your towers twice."): on the level that brings
## bridges, a gate on the highlighted socket alone sends the walkers over the bridge and back under it, while
## with no gate they cross it once.
func test_the_first_bridge_level_highlights_the_loop() -> void:
	var id: String = NEW_FEATURES["bridge"]
	var level: LevelData = _level(id)
	assert_not_null(level, "%s loads" % id)
	if level == null:
		return
	assert_eq(level.kind_at(level.hint_cell), LevelData.Kind.SOCKET, "%s highlights a socket" % id)
	var map: RoadMap = RoadMap.new(level)
	var none: Array[Vector2i] = []
	var closed: Array[Vector2i] = [level.hint_cell]
	var open_route: Array[Vector2i] = map.route(level.entrances[0], map.distances(none))
	var gated_route: Array[Vector2i] = map.route(level.entrances[0], map.distances(closed))
	assert_eq(Rules.crossings(level, open_route), PackedStringArray(["over"]), "%s: with no gate the walkers cross the bridge once" % id)
	assert_eq(Rules.crossings(level, gated_route), PackedStringArray(["over", "under"]), "%s: the highlighted socket sends them over the bridge and back under it" % id)


## RULES 3.8: slides are straight runs of 2 or more tiles with every arrow along the run, each arrow points at
## road, and with no gates no slide is a dead end.
func test_slides_follow_rules_3_8() -> void:
	var with_slides: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		if not Rules.slide_tiles(level).is_empty():
			with_slides += 1
		var found: PackedStringArray = Rules.slide_problems(level)
		assert_eq(found, PackedStringArray(), "%s: %s" % [id, "; ".join(found)])
	assert_true(with_slides >= 6, "the region 7 levels have slides, so the rules are exercised")


## RULES 3.8, as for bridges (3.7): every slide tile lies on the shortest route of some placement of the
## level's gates, so it always matters.
func test_every_slide_lies_on_some_route() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var off: Array[Vector2i] = Rules.slides_off_every_route(level, level.gates)
		assert_true(off.is_empty(), "%s: the slides %s lie on no route of any gate placement" % [id, off])


## The slide lesson (RULES 12.3 and 12.4, 7-1: "A gate can send walkers around a loop."): on the level that
## brings slides, with no gate the walkers take no slide, and a gate on the highlighted socket alone sends them
## down two runs of slides or more, the long way round.
func test_the_first_slide_level_highlights_the_loop() -> void:
	var id: String = NEW_FEATURES["slide"]
	var level: LevelData = _level(id)
	assert_not_null(level, "%s loads" % id)
	if level == null:
		return
	assert_eq(level.kind_at(level.hint_cell), LevelData.Kind.SOCKET, "%s highlights a socket" % id)
	var map: RoadMap = RoadMap.new(level)
	var none: Array[Vector2i] = []
	var closed: Array[Vector2i] = [level.hint_cell]
	assert_false(map.seals(closed), "%s: the highlighted socket seals nothing" % id)
	var open_route: Array[Vector2i] = map.route(level.entrances[0], map.distances(none))
	var gated_route: Array[Vector2i] = map.route(level.entrances[0], map.distances(closed))
	assert_eq(Rules.slides_walked(level, open_route), 0, "%s: with no gate the walkers take no slide" % id)
	var runs: int = 0
	for run: Array in Rules.slide_runs(level):
		for cell: Vector2i in run:
			if gated_route.has(cell):
				runs += 1
				break
	assert_true(runs >= 2, "%s: the highlighted socket sends the walkers down %d slide runs" % [id, runs])
	assert_true(gated_route.size() > open_route.size(), "%s: the loop is the long way round" % id)


## RULES 12.4, 7-2: "A spot at the end of a long straight road." The highlighted spot of the Snow Fort level
## lines up with the open route: the tiles in one straight line from it, out to a tier 1 Snow Fort's reach, are
## all on an entrance's route with no gates, so its first snowball rolls down the road.
const LINE_HIGHLIGHT: Dictionary = {"r7_l2": &"snow_fort"}


func test_the_snow_fort_highlight_looks_down_a_straight_road() -> void:
	for id: String in LINE_HIGHLIGHT:
		var level: LevelData = _level(id)
		assert_not_null(level, "%s loads" % id)
		if level == null:
			continue
		var type: TowerType = catalog.tower(LINE_HIGHLIGHT[id])
		assert_true(type != null and level.towers.has(StringName(LINE_HIGHLIGHT[id])), "%s offers the %s" % [id, LINE_HIGHLIGHT[id]])
		if type == null:
			continue
		var tiles: int = type.stats(1, -1).reach / 100
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var dist: PackedInt32Array = map.distances(none)
		var walked: Array[Vector2i] = []
		for entrance: Vector2i in level.entrances:
			walked.append_array(map.route(entrance, dist))
		var lined: bool = false
		for way: Vector2i in Rules.SIDES:
			var all_on: bool = true
			for step: int in range(1, tiles + 1):
				if not walked.has(level.hint_cell + way * step):
					all_on = false
			if all_on:
				lined = true
		assert_true(lined, "%s: the highlighted spot %s looks %d tiles straight down the open route" % [id, level.hint_cell, tiles])


## RULES 12.4: the highlighted spot of the Yawner level is set back, more than a Yawner's yawn reach from
## every road tile, so a tower there stays awake (SET_BACK_HIGHLIGHT).
func test_the_set_back_highlight_is_out_of_yawn_reach() -> void:
	for id: String in SET_BACK_HIGHLIGHT:
		var level: LevelData = _level(id)
		var yawner: EnemyType = catalog.enemy(SET_BACK_HIGHLIGHT[id])
		assert_true(level != null and yawner != null and yawner.yawn_reach > 0, "%s and the %s load" % [id, SET_BACK_HIGHLIGHT[id]])
		if level == null or yawner == null:
			continue
		assert_eq(level.kind_at(level.hint_cell), LevelData.Kind.SPOT, "%s highlights a spot" % id)
		for r: int in level.rows:
			for c: int in Sim.MAP_COLUMNS:
				var cell: Vector2i = Vector2i(c, r)
				if not level.is_road(cell):
					continue
				var dx: int = (c - level.hint_cell.x) * 100
				var dy: int = (r - level.hint_cell.y) * 100
				assert_true(dx * dx + dy * dy > yawner.yawn_reach * yawner.yawn_reach, "%s: road %s is within a yawn of the highlighted spot" % [id, cell])


## RULES 12.4, 7-3 and 7-6: "A spot near the entrance." The highlighted spot is within a tier 1 Sling Post's
## reach of an entrance, where Snowrollers and Snowsnore are still small.
const NEAR_ENTRANCE_HIGHLIGHT: Array[String] = ["r7_l3", "r7_l6"]


func test_the_near_entrance_highlights_are_near_an_entrance() -> void:
	var reach: int = catalog.tower(&"sling_post").stats(1, -1).reach
	for id: String in NEAR_ENTRANCE_HIGHLIGHT:
		var level: LevelData = _level(id)
		assert_not_null(level, "%s loads" % id)
		if level == null:
			continue
		assert_eq(level.kind_at(level.hint_cell), LevelData.Kind.SPOT, "%s highlights a spot" % id)
		var near: bool = false
		for entrance: Vector2i in level.entrances:
			var dx: int = (entrance.x - level.hint_cell.x) * 100
			var dy: int = (entrance.y - level.hint_cell.y) * 100
			if dx * dx + dy * dy <= reach * reach:
				near = true
		assert_true(near, "%s: the highlighted spot %s is within %d hundredths of a tile of an entrance" % [id, level.hint_cell, reach])


## RULES 12.4, 7-3: "Use no gates." asks the player to win on the short road. With no gates every entrance's
## route is as short as any gate placement makes it, and some placement makes a route longer.
const SHORT_OPEN_ROAD: Array[String] = ["r7_l3"]


func test_the_open_road_is_the_short_one() -> void:
	for id: String in SHORT_OPEN_ROAD:
		var level: LevelData = _level(id)
		assert_not_null(level, "%s loads" % id)
		if level == null:
			continue
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var open_dist: PackedInt32Array = map.distances(none)
		var longer: bool = false
		var sets: Array[Array] = []
		Rules.gate_sets(level.sockets, level.gates, 0, [], sets)
		for placed: Array in sets:
			var closed: Array[Vector2i] = []
			closed.assign(placed)
			if map.seals(closed):
				continue
			var dist: PackedInt32Array = map.distances(closed)
			for entrance: Vector2i in level.entrances:
				var open_steps: int = map.route(entrance, open_dist).size()
				var steps: int = map.route(entrance, dist).size()
				assert_true(steps >= open_steps, "%s: gates %s make the road from %s shorter" % [id, placed, entrance])
				if steps > open_steps:
					longer = true
		assert_true(longer, "%s: some gate placement makes a road longer" % id)


## RULES 3.9: stumps come in pairs, one letter each, at most 2 pairs a map, and twins are never next to each other.
func test_stumps_follow_rules_3_9() -> void:
	var with_stumps: int = 0
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		if not Rules.stump_tiles(level).is_empty():
			with_stumps += 1
		var found: PackedStringArray = Rules.stump_problems(level)
		assert_eq(found, PackedStringArray(), "%s: %s" % [id, "; ".join(found)])
	assert_true(with_stumps >= 6, "the region 8 levels have stumps, so the rules are exercised")


## RULES 3.9 level guide: each pair of stumps lies on the shortest route of some placement of the level's gates: some
## entrance's route takes its twin step, so it always matters.
func test_every_stump_pair_lies_on_some_route() -> void:
	for id: String in order:
		var level: LevelData = _level(id)
		if level == null:
			continue
		var off: Array[Vector2i] = Rules.stump_pairs_off_every_route(level, level.gates)
		assert_true(off.is_empty(), "%s: the stump pairs at %s lie on no route of any gate placement" % [id, off])


## The stump lesson (RULES 12.3 and 12.4, 8-1: "Twin stumps join far roads. Close the way in."): on the level that
## brings stumps, with no gate the walkers take a twin step, and a gate on the highlighted socket alone closes the way
## in, so they walk the long way, in reach the whole time.
func test_the_first_stump_level_highlights_the_way_in() -> void:
	var id: String = NEW_FEATURES["stump"]
	var level: LevelData = _level(id)
	assert_not_null(level, "%s loads" % id)
	if level == null:
		return
	assert_eq(level.kind_at(level.hint_cell), LevelData.Kind.SOCKET, "%s highlights a socket" % id)
	var map: RoadMap = RoadMap.new(level)
	var none: Array[Vector2i] = []
	var closed: Array[Vector2i] = [level.hint_cell]
	assert_false(map.seals(closed), "%s: the highlighted socket seals nothing" % id)
	var open_route: Array[Vector2i] = map.route(level.entrances[0], map.distances(none))
	var gated_route: Array[Vector2i] = map.route(level.entrances[0], map.distances(closed))
	assert_true(Rules.twin_steps(open_route) >= 1, "%s: with no gate the walkers take a twin step" % id)
	assert_eq(Rules.twin_steps(gated_route), 0, "%s: the highlighted socket closes the way into the stumps" % id)
	assert_true(gated_route.size() > open_route.size(), "%s: the way round is the long way" % id)


## RULES 12.4, 8-2 and 8-6: "A spot under the flight line". The highlighted spot's center lies within half a tile of the
## straight line from some entrance to the base, where flyers pass. On 8-2 it sits beside other build spots, where the
## ground towers go; on 8-6 it sits beside the boss's route with no gates, from entrance A (FLIGHT_HIGHLIGHT).
const FLIGHT_HIGHLIGHT: Dictionary = {"r8_l2": "spots", "r8_l6": "route"}
const FLIGHT_NEAR: float = 0.5


func test_the_flight_line_highlights_sit_under_a_flight_line() -> void:
	for id: String in FLIGHT_HIGHLIGHT:
		var level: LevelData = _level(id)
		assert_not_null(level, "%s loads" % id)
		if level == null:
			continue
		var cell: Vector2i = level.hint_cell
		assert_eq(level.kind_at(cell), LevelData.Kind.SPOT, "%s highlights a spot" % id)
		var near: float = 1000.0
		for entrance: Vector2i in level.entrances:
			near = minf(near, _distance_to_line(Vector2(cell), Vector2(entrance), Vector2(level.base)))
		assert_true(near <= FLIGHT_NEAR, "%s: the highlighted spot %s is %.2f tiles from every flight line" % [id, cell, near])
		var beside: bool = false
		if FLIGHT_HIGHLIGHT[id] == "spots":
			for other: Vector2i in level.spots:
				if other != cell and absi(other.x - cell.x) <= 1 and absi(other.y - cell.y) <= 1:
					beside = true
		else:
			var map: RoadMap = RoadMap.new(level)
			var none: Array[Vector2i] = []
			for step: Vector2i in map.route(level.entrances[0], map.distances(none)):
				if absi(step.x - cell.x) <= 1 and absi(step.y - cell.y) <= 1:
					beside = true
		assert_true(beside, "%s: the highlighted spot %s sits beside the %s" % [id, cell, FLIGHT_HIGHLIGHT[id]])


## The distance in tiles from `point` to the segment from `from` to `to`.
static func _distance_to_line(point: Vector2, from: Vector2, to: Vector2) -> float:
	var along: Vector2 = to - from
	var t: float = clampf((point - from).dot(along) / along.length_squared(), 0.0, 1.0)
	return point.distance_to(from + along * t)
