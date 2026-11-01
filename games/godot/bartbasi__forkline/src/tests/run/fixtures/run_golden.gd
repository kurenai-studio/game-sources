# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## What the tier 0 golden test pins (docs/ARCHITECTURE.md 14.13): the run plan and the
## SHA-256 of the assembled level for run seeds 1 to 200 and for the daily seeds of 30
## days from 2026-10-28, plus the card pools. compute() works it out from the real files;
## tests/run/fixtures/tier0_golden.json holds what the build before regions 5 to 8 gave.

const RUN_PATH: String = "res://data/runs/run.json"
const CARDS_PATH: String = "res://data/cards/cards.json"
const SEGMENT_DIR: String = "res://data/segments/"
const STATS_DIR: String = "res://data/stats/"
const GOLDEN_PATH: String = "res://tests/run/fixtures/tier0_golden.json"
const SEEDS: int = 200
const FIRST_DAY: String = "2026-10-28"
const DAYS: int = 30
## Counter values high enough to open every unlock.
const EVERY_UNLOCK: Dictionary = {
	"best_run_wave": 1000, "runs_won": 1000, "runs_won_normal": 1000, "dailies_finished": 1000,
	"risky_wins": 1000, "stars": 1000, "twists_cleared": 1000,
}


static func _read(path: String, cap: int) -> Variant:
	var got: Dictionary = JsonFile.read(path, cap)
	return got["data"]


static func catalog() -> Catalog:
	return Catalog.from_data(_read(STATS_DIR + "towers.json", 262144), _read(STATS_DIR + "enemies.json", 262144), _read(STATS_DIR + "rules.json", 262144))


## Every real run file, keyed as RunData takes them (2.12).
static func real_files() -> Dictionary:
	var files: Dictionary = {
		"runs/run.json": _read(RUN_PATH, 16384), "cards/cards.json": _read(CARDS_PATH, 262144),
		"segments/index.json": _read(SEGMENT_DIR + "index.json", 16384),
		"segments/packs.json": _read(SEGMENT_DIR + "packs.json", 262144),
	}
	var index: Dictionary = files["segments/index.json"]
	for id: Variant in index["segments"]:
		files["segments/%s.json" % id] = _read(SEGMENT_DIR + "%s.json" % id, 16384)
	return files


## The day keys of the 30 days from 2026-10-28.
static func days() -> Array[String]:
	var out: Array[String] = []
	var month_days: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	var year: int = 2026
	var month: int = 10
	var day: int = 28
	for i: int in DAYS:
		out.append("%04d-%02d-%02d" % [year, month, day])
		day += 1
		if day > month_days[month - 1]:
			day = 1
			month += 1
			if month > 12:
				month = 1
				year += 1
	return out


static func _ids(list: Array[StringName]) -> Array[String]:
	var out: Array[String] = []
	for id: StringName in list:
		out.append(String(id))
	return out


## {"plan": {...}, "hash": String} for one seed at tier 0, or {} when the run cannot be built.
static func entry(run_seed: int, data: RunData, catalog_value: Catalog) -> Dictionary:
	var picks: Dictionary = MapAssembler.plan(run_seed, data)
	var level: LevelData = MapAssembler.assemble(run_seed, data, catalog_value)
	if picks.is_empty() or level == null:
		return {}
	var packs: Array[StringName] = picks["packs"]
	return {
		"plan": {
			"boss": String(picks["boss"]), "top": String(picks["top"]), "middle": String(picks["middle"]),
			"bottom": String(picks["bottom"]), "packs": _ids(packs),
		},
		"hash": JSON.stringify(level.to_data()).sha256_text(),
	}


## The real files plus the stand-ins tier 1 needs while the level designer's region 5 packs and
## segments are missing: a tunnel segment cut from the real mid_split, a band 2 pack that uses a
## Mossbud and a band 6 pack for Burrowbelly, both cut from real packs and put first in the
## file. Ids are the stand-ins' own, so real tier 1 content can join them without a clash.
## Adding tier 1 things never changes a tier 0 run (RULES 14.9).
static func with_tier_1(files: Dictionary) -> Dictionary:
	var out: Dictionary = files.duplicate(true)
	var index: Dictionary = out["segments/index.json"]
	var split: Dictionary = out["segments/mid_split.json"]
	var grid: Array = (split["grid"] as Array).duplicate()
	var row: String = grid[1]
	grid[1] = row.substr(0, 3) + "T" + row.substr(4)
	out["segments/mid_tunnel_stand_in.json"] = {"format": 1, "id": "mid_tunnel_stand_in", "kind": "middle", "grid": grid}
	(index["segments"] as Array).insert((index["segments"] as Array).find("mid_split") + 1, "mid_tunnel_stand_in")
	var packs: Dictionary = out["segments/packs.json"]
	var by_id: Dictionary = {}
	for item: Dictionary in packs["packs"]:
		by_id[item["id"]] = item
	var mossbud: Dictionary = (by_id["b2_quick_feet"] as Dictionary).duplicate(true)
	mossbud["id"] = "b2_mossbud_stand_in"
	mossbud["waves"][0]["groups"][0]["enemy"] = "mossbud"
	var burrow: Dictionary = (by_id["b6_grumble_hill"] as Dictionary).duplicate(true)
	burrow["id"] = "b6_burrowbelly_stand_in"
	burrow["boss"] = "burrowbelly"
	burrow["waves"][2]["groups"][0]["enemy"] = "burrowbelly"
	(packs["packs"] as Array).insert(0, burrow)
	# The real run.json lists more tiers, and each tier boss needs a band 6 pack until the real ones
	# exist. A stand-in is cut from a real tier 0 pack for every listed boss that has none.
	var has_boss: Dictionary = {}
	for item: Dictionary in packs["packs"]:
		has_boss[String(item["boss"])] = true
	for tier: Dictionary in (out["runs/run.json"] as Dictionary)["tiers"]:
		for boss: String in tier["bosses"]:
			if has_boss.has(boss):
				continue
			has_boss[boss] = true
			var made: Dictionary = (by_id["b6_tusk_charge"] as Dictionary).duplicate(true)
			made["id"] = "b6_%s_stand_in" % boss
			made["boss"] = boss
			made["waves"][2]["strength"] = 140
			for group: Dictionary in made["waves"][2]["groups"]:
				if group["enemy"] == "old_tusk":
					group["enemy"] = boss
			(packs["packs"] as Array).insert(0, made)
	(packs["packs"] as Array).insert(0, mossbud)
	return out


## Everything the golden file pins, as plain values that survive a trip through JSON.
## files: the run files to build from, the real ones when empty.
static func compute(files: Dictionary = {}) -> Dictionary:
	var cat: Catalog = catalog()
	var data: RunData = RunData.from_data(real_files() if files.is_empty() else files, cat)
	if data == null:
		return {}
	var runs: Dictionary = {}
	for run_seed: int in range(1, SEEDS + 1):
		runs[str(run_seed)] = entry(run_seed, data, cat)
	var dailies: Dictionary = {}
	for day: String in days():
		var item: Dictionary = entry(RunSeeds.daily_seed(day), data, cat)
		item["seed"] = RunSeeds.daily_seed(day)
		dailies[day] = item
	return {
		"format": 1,
		"pool_none": _ids(data.pool({})),
		"pool_every": _ids(data.pool(EVERY_UNLOCK)),
		"card_ids": _ids(data.card_ids()),
		"runs": runs,
		"dailies": dailies,
	}
