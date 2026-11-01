# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## The creatures and bosses of regions 5 to 8 as test data, with the numbers of RULES
## 6.1 and 6.3, added to the real stat files and the four expansion towers. data/stats/
## gets them in E5.1 to E8.1 (game designer); until then the rules are proven on this
## test-only catalog (docs/ARCHITECTURE.md 14.4).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")

const NEW: Array = ["mossbud", "mistwisp", "gleamer", "sleepyhead", "burrowbelly", "old_hayrick"]
const LATE: Array = ["snowroller", "yawner", "blinker", "hootling", "snowsnore", "glimmertoad"]


## RULES 6.1 and 6.3, in the file's units.
static func enemies() -> Array:
	return [
		{"id": "mossbud", "name": "Mossbud", "info": "Regrows.", "health": 80, "armor": 0, "speed": 80, "lives": 1, "bounty": 10,
			"regrow": 4, "regrow_ms": 1000},
		{"id": "mistwisp", "name": "Mistwisp", "info": "Hides others.", "health": 50, "armor": 0, "speed": 100, "lives": 1, "bounty": 10,
			"mist": true},
		{"id": "gleamer", "name": "Gleamer", "info": "Dazzles.", "health": 160, "armor": 0, "speed": 80, "lives": 2, "bounty": 18,
			"dazzle": true},
		{"id": "sleepyhead", "name": "Sleepyhead", "info": "Naps once.", "health": 90, "armor": 0, "speed": 90, "lives": 1, "bounty": 12,
			"nap_ms": 2000},
		{"id": "burrowbelly", "name": "Burrowbelly", "info": "Digs.", "health": 3200, "armor": 2, "speed": 40, "lives": 20, "bounty": 300,
			"boss": true, "dig_first_ms": 6000, "dig_every_ms": 8000, "dig_ms": 2000,
			"summon": {"enemy": "mistwisp", "count": 2, "every_ms": 8000, "gap_ms": 300}},
		{"id": "old_hayrick", "name": "Old Hayrick", "info": "Dazzles and naps.", "health": 2600, "armor": 0, "speed": 40, "lives": 20,
			"bounty": 300, "boss": true, "dazzle": true, "nap_ms": 3000},
		{"id": "snowroller", "name": "Snowroller", "info": "Grows.", "health": 40, "armor": 0, "speed": 100, "lives": 1, "bounty": 8,
			"grow_pct": 10, "grow_cap_pct": 300},
		{"id": "yawner", "name": "Yawner", "info": "Yawns.", "health": 110, "armor": 2, "speed": 70, "lives": 2, "bounty": 15,
			"yawn_ms": 4000, "yawn_reach": 150, "doze_ms": 2000},
		{"id": "blinker", "name": "Blinker", "info": "Blinks.", "health": 60, "armor": 0, "speed": 90, "lives": 1, "bounty": 9,
			"blink_ms": 3000, "blink_tiles": 2},
		{"id": "hootling", "name": "Hootling", "info": "Keeps others awake.", "health": 80, "armor": 1, "speed": 90, "lives": 1, "bounty": 11,
			"wake_reach": 150},
		{"id": "snowsnore", "name": "Snowsnore", "info": "Grows and yawns.", "health": 3400, "armor": 3, "speed": 35, "lives": 20,
			"bounty": 350, "boss": true, "grow_pct": 2, "grow_cap_pct": 150, "yawn_ms": 6000, "yawn_reach": 200, "doze_ms": 3000},
		{"id": "glimmertoad", "name": "Glimmertoad", "info": "Hops and wakes.", "health": 3600, "armor": 4, "speed": 35, "lives": 20,
			"bounty": 400, "boss": true, "blink_ms": 6000, "blink_tiles": 3, "wake_reach": 200,
			"release": {"at_pct": 50, "enemy": "flitter", "count": 6, "gap_ms": 300}},
	]


## The real stat files with the four towers and these creatures added. A creature the real
## files already hold (from E5.1 on) gives way to this file's copy.
static func stats_files() -> Array:
	var files: Array = Tx.stats_files()
	files[1]["enemies"] = Tx.replaced(files[1]["enemies"], enemies())
	return files


static func catalog() -> Catalog:
	var files: Array = stats_files()
	return Catalog.from_data(files[0], files[1], files[2])


## A catalog with one creature's fields changed (a null value removes the key).
static func catalog_with(id: String, changes: Dictionary) -> Catalog:
	var files: Array = stats_files()
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == id:
			for key: String in changes:
				if changes[key] == null:
					item.erase(key)
				else:
					item[key] = changes[key]
	return Catalog.from_data(files[0], files[1], files[2])


## A battle offering every tower, old and new.
static func battle(grid: Array, waves: Array, changes: Dictionary = {}, stats: Catalog = null) -> Battle:
	return Tx.battle(grid, waves, changes, stats if stats != null else catalog())
