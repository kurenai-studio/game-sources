# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Fixtures for tests/run/: the real stat files, and small hand-made run plans, cards,
## segments and wave packs. The real segments and packs come from the level designer
## later; these let src/run/ be built and tested without them. Every fixture here is
## valid. A test copies one with duplicate(true) and breaks one thing.

const STATS_DIR: String = "res://data/stats/"
const BOSSES: Array[String] = ["grumblesack", "ironshell", "moon_moth", "old_tusk"]

## Segments in the file shape: id, kind, grid. Rows 4, 5 and 4, as run.json sets.
const SEGMENTS: Dictionary = {
	"top_one": ["top", ["o..1..o", ".o.#.o.", "...#...", "...#..."]],
	"top_pair": ["top", ["..1.2..", "o.#o#.o", "..###..", "...#..."]],
	"top_side": ["top", [".o...o.", "1####..", "..o.#..", "....#.."]],
	"top_twin": ["top", [".1...2.", ".#.o.#.", ".#.o.#.", ".#.o.#."]],
	"mid_split": ["middle", ["o..#..o", ".#####.", ".G.o.G.", ".#####.", "...#..."]],
	"mid_bend": ["middle", ["...#...", ".o.G.o.", "...##..", "..o.G..", "....#.."]],
	"mid_side": ["middle", ["....#.o", ".o..G..", "...##..", "..oG...", "...#..."]],
	"mid_merge": ["middle", [".#...#.", ".G.o.G.", ".#####.", "o..#..o", "...#..."]],
	"bot_home": ["bottom", ["...#...", ".o.#.o.", "..oBo..", "......."]],
	"bot_edge": ["bottom", ["....#..", ".o..#o.", "..o.B..", "......."]],
}
const INDEX_ORDER: Array[String] = [
	"top_one", "mid_split", "bot_home", "top_pair", "mid_bend", "bot_edge",
	"top_side", "mid_side", "top_twin", "mid_merge",
]


static func read(path: String) -> Variant:
	var got: Dictionary = JsonFile.read(path, 262144)
	return got["data"]


## The towers and creatures of regions 1 to 4, which these hand-made cards and packs cover. The
## real files hold regions 5 to 8 too from E5.1 on, and a run with no tiers has none of them.
## Listed by id, so a region added later never leaks into the fixtures.
const REGIONS_1_TO_4: Array[String] = [
	"sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery",
	"scamp", "pip", "skitter", "flitter", "shellback", "bubbler", "puffball", "puff", "mender",
	"gatecrasher", "dusk_moth", "grumblesack", "ironshell", "moon_moth", "old_tusk",
]


## The real stats of regions 1 to 4 only.
static func catalog() -> Catalog:
	var regions_1_to_4: Array[String] = REGIONS_1_TO_4
	var towers: Dictionary = read(STATS_DIR + "towers.json")
	var enemies: Dictionary = read(STATS_DIR + "enemies.json")
	towers["towers"] = (towers["towers"] as Array).filter(func(item: Dictionary) -> bool: return regions_1_to_4.has(item["id"]))
	enemies["enemies"] = (enemies["enemies"] as Array).filter(func(item: Dictionary) -> bool: return regions_1_to_4.has(item["id"]))
	return Catalog.from_data(towers, enemies, read(STATS_DIR + "rules.json"))


## The same shape as data/runs/run.json (2.10), written out so a tuning change to the
## real file does not move the fixtures.
static func run_plan() -> Dictionary:
	return {
		"format": 1, "strength_start": 100, "strength_step": 10, "start_gold": 300, "gates": 1,
		"towers": ["sling_post"], "rows": {"top": 4, "middle": 5, "bottom": 4},
		"spots": [8, 12], "sockets": [2, 5],
		"bands": [
			["scamp", "pip"], ["skitter", "flitter", "shellback"], ["bubbler", "puffball"],
			["mender", "dusk_moth"], ["gatecrasher"], [],
		],
		"weights": {"tower": 30, "perk": 25, "gate": 10, "economy": 20, "risk": 15},
		"tiers": [],
	}


static func segment(id: String) -> Dictionary:
	var item: Array = SEGMENTS[id]
	return {"format": 1, "id": id, "kind": item[0], "grid": (item[1] as Array).duplicate()}


static func index() -> Dictionary:
	var ids: Array = []
	for id: String in INDEX_ORDER:
		ids.append(id)
	return {"format": 1, "segments": ids}


## The creatures the run has met by the start of a band: every band up to and including it.
static func creatures_up_to(band: int) -> Array[String]:
	var plan: Dictionary = run_plan()
	var out: Array[String] = []
	for b: int in band:
		for id: String in plan["bands"][b]:
			out.append(id)
	return out


static func group(enemy: String, count: int, entrance: int = 1, at_ms: int = 0, every_ms: int = 600) -> Dictionary:
	return {"enemy": enemy, "count": count, "entrance": entrance, "at_ms": at_ms, "every_ms": every_ms}


## Four packs in each of bands 1 to 5 and six in band 6 (a boss each, two bosses twice).
## Every pack shows the creature its band adds first in its wave, as RULES 14.3 asks.
static func packs() -> Dictionary:
	var plan: Dictionary = run_plan()
	var list: Array = []
	for band: int in range(1, 7):
		var added: Array = plan["bands"][band - 1]
		var how_many: int = 6 if band == 6 else 4
		for i: int in how_many:
			var boss: String = BOSSES[i % 4] if band == 6 else ""
			var waves: Array = []
			for k: int in 3:
				# Creatures the run has met by this wave: earlier bands, then this band's own up to wave k.
				var met: Array[String] = creatures_up_to(band - 1)
				for j: int in mini(k + 1, added.size()):
					met.append(added[j])
				var count: int = 3 + i + k
				var entrance: int = 1 + (i + k) % 2
				var groups: Array = []
				if band == 6 and k == 2:
					groups.append(group(boss, 1))
				elif k < added.size():
					groups.append(group(added[k], count, entrance))
				else:
					groups.append(group(met[(i + k) % met.size()], count, entrance))
				groups.append(group(met[(i * 2 + k + 1) % met.size()], count, 3 - entrance, 4000))
				if band == 6 and k == 2:
					# The boss wave sets its own strength (2.9): 150, 160, ... by pack.
					waves.append({"groups": groups, "strength": 150 + 10 * i})
				else:
					waves.append({"groups": groups})
			list.append({"id": "band%d_pack%d" % [band, i], "band": band, "boss": boss, "waves": waves})
	return {"format": 1, "packs": list}


static func tower_card(tower: String, name: String) -> Dictionary:
	return {
		"id": "tower_" + tower, "kind": "tower", "tower": tower, "name": name,
		"text": "You can build " + name + "s.", "once": true, "unlock": {},
		"effects": [{"type": "add_tower", "tower": tower}],
	}


static func risk_card(id: String, effects: Array, unlock: Dictionary = {}) -> Dictionary:
	return {
		"id": id, "kind": "risk", "name": id, "text": "A risk card.", "once": false,
		"unlock": unlock, "effects": effects,
	}


## A small set of cards that meets every rule of 2.11: the five tower cards, one perk per
## kind of stat, a gate card, economy cards, risk cards and unlockable cards.
static func cards() -> Dictionary:
	var list: Array = [
		tower_card("pumpkin_catapult", "Pumpkin Catapult"),
		tower_card("lullaby_bell", "Lullaby Bell"),
		tower_card("longbow_loft", "Longbow Loft"),
		tower_card("firework_tower", "Firework Tower"),
		tower_card("bakery", "Bakery"),
		{"id": "sharp_pebbles", "kind": "perk", "tower": "sling_post", "name": "Sharp Pebbles",
			"text": "Sling Posts deal 2 more damage.", "once": true, "unlock": {},
			"effects": [{"type": "tower_add", "tower": "sling_post", "stat": "damage", "amount": 2}]},
		{"id": "deep_lullaby", "kind": "perk", "tower": "lullaby_bell", "name": "Deep Lullaby",
			"text": "Bells slow more.", "once": true, "unlock": {},
			"effects": [{"type": "tower_add", "tower": "lullaby_bell", "stat": "slow_pct", "amount": 10}]},
		{"id": "warm_ovens", "kind": "perk", "tower": "bakery", "name": "Warm Ovens",
			"text": "Bakeries reach further.", "once": true, "unlock": {},
			"effects": [{"type": "tower_add", "tower": "bakery", "stat": "reach", "amount": 100}]},
		{"id": "spare_gate", "kind": "gate", "name": "Spare Gate", "text": "Gain 1 gate.",
			"once": false, "unlock": {}, "effects": [{"type": "add_gates", "count": 1}]},
		{"id": "gold_purse", "kind": "economy", "name": "Gold Purse", "text": "Gain gold.",
			"once": false, "unlock": {}, "effects": [{"type": "add_gold", "amount": 100, "per_wave": 10}]},
		risk_card("crowded_night", [
			{"type": "count_pct", "pct": 150, "flyers": false, "last_wave": false},
			{"type": "reward_gold", "amount": 100},
		]),
		risk_card("flock", [
			{"type": "add_group", "enemy": "flitter", "count": 8, "entrance": 1, "at_ms": 2000, "every_ms": 400, "after_last": true},
			{"type": "reward_gold", "amount": 80},
		]),
		{"id": "twin_pebbles", "kind": "perk", "tower": "sling_post", "name": "Twin Pebbles",
			"text": "Two targets, less damage.", "once": true, "unlock": {"counter": "best_run_wave", "at": 6},
			"effects": [{"type": "tower_add", "tower": "sling_post", "stat": "targets", "amount": 1},
				{"type": "tower_add", "tower": "sling_post", "stat": "damage", "amount": -2}]},
		{"id": "piggy_bank", "kind": "economy", "name": "Piggy Bank", "text": "Interest.",
			"once": true, "unlock": {"counter": "stars", "at": 36},
			"effects": [{"type": "interest", "pct": 10, "max": 50}]},
		risk_card("pip_parade", [
			{"type": "add_group", "enemy": "pip", "count": 24, "entrance": 1, "at_ms": 1000, "every_ms": 300, "after_last": false},
			{"type": "reward_gold", "amount": 100},
		], {"counter": "stars", "at": 72}),
	]
	return {"format": 1, "cards": list}


## All parsed files in the shape RunData.check takes (2.12), as plain GDScript values.
static func files() -> Dictionary:
	var out: Dictionary = {
		"runs/run.json": run_plan(), "cards/cards.json": cards(),
		"segments/index.json": index(), "segments/packs.json": packs(),
	}
	for id: String in INDEX_ORDER:
		out["segments/%s.json" % id] = segment(id)
	return out


## The same files after a trip through the JSON parser, where every number is a float,
## as the game gets them from disk.
static func files_from_json() -> Dictionary:
	var out: Dictionary = {}
	var source: Dictionary = files()
	for key: String in source.keys():
		out[key] = JSON.parse_string(JSON.stringify(source[key]))
	return out


## RunData built from the fixtures. Null if the fixtures are broken.
static func run_data() -> RunData:
	return RunData.from_data(files_from_json(), catalog())
