# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Shared helpers for tests/render/: the real stat files and region 1 levels, real Battle
## objects, and a simple fixed defense. Nothing here is the game's own code.

const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

const STATS_DIR: String = "res://data/stats/"
const LEVEL_DIR: String = "res://data/levels/"
const REGION_1: Array[String] = ["r1_l1", "r1_l2", "r1_l3", "r1_l4", "r1_l5", "r1_l6"]
## Logical window sizes of the Fold5 (1080 x 2400 base, canvas_items stretch, expand).
const COVER: Vector2i = Vector2i(1080, 2767)
const INNER: Vector2i = Vector2i(1998, 2400)


static func parse(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func catalog() -> Catalog:
	return Catalog.from_data(parse(STATS_DIR + "towers.json"), parse(STATS_DIR + "enemies.json"), parse(STATS_DIR + "rules.json"))


## A real level, with the starting gold raised so a defense can be bought.
static func level(id: String, stats: Catalog, gold: int = 6000) -> LevelData:
	var data: Dictionary = parse(LEVEL_DIR + id + ".json")
	data["start_gold"] = gold
	return LevelData.from_data(data, stats)


static func battle(id: String, gold: int = 6000) -> Battle:
	var stats: Catalog = catalog()
	return Battle.create(level(id, stats, gold), stats, false, [])


## Builds on every spot: Sling Posts and Pumpkin Catapults, in a mix of tiers and paths.
## Returns how many towers stand.
static func defend(b: Battle) -> int:
	var n: int = 0
	for i: int in b.level.spots.size():
		var cell: Vector2i = b.level.spots[i]
		var type: StringName = &"sling_post" if i % 2 == 0 else &"pumpkin_catapult"
		if b.place_tower(cell, type) != Battle.DONE:
			continue
		n += 1
		var step: int = i % 3
		if step >= 1:
			b.upgrade_tower(cell)
		if step >= 2:
			b.upgrade_tower(cell, (i / 3) % 2)
	return n


## Steps one tick and returns the events.
static func tick(b: Battle) -> Array[Dictionary]:
	b.step()
	return b.take_events()


## Runs whole waves without a view, until `wave` is the next to start.
static func fast_forward(b: Battle, wave: int) -> void:
	while b.waves_started < wave and b.phase != Battle.Phase.LOST and b.phase != Battle.Phase.WON:
		b.start_next_wave()
		var guard: int = 0
		while b.phase == Battle.Phase.WAVE and guard < 20000:
			b.step()
			guard += 1
	b.take_events()


## A long serpentine road like the sim's own benchmark, for a crowd of 200 creatures.
const SNAKE_GRID: Array = [
	"1######", "o..o..#", "#######", "#..o..o", "#######", "o..o..#",
	"#######", "#..o...", "#######", "......#", "......B",
]


## The busiest battle: two waves of 120 with a boss, seven towers on a 41 step road.
static func stress() -> Battle:
	var stats: Catalog = catalog()
	var waves: Array = [
		{"groups": [_group("pip", 60, 50), _group("scamp", 40, 100), _group("flitter", 20, 150)]},
		{"groups": [_group("grumblesack", 1, 1000), _group("scamp", 100, 50), _group("pip", 19, 100)]},
	]
	var data: Dictionary = {
		"format": 1, "id": "stress", "name": "Stress", "grid": SNAKE_GRID.duplicate(), "start_gold": 10000,
		"gates": 0, "strength": 1000, "towers": ["sling_post", "pumpkin_catapult"],
		"star3": {"kind": "no_lives_lost"}, "waves": waves,
	}
	var b: Battle = Battle.create(LevelData.from_data(data, stats), stats, false, [])
	defend(b)
	return b


static func _group(enemy: String, count: int, every_ms: int) -> Dictionary:
	return {"enemy": enemy, "count": count, "entrance": 1, "at_ms": 0, "every_ms": every_ms}


## A 7 x 11 map with a ring road: one entrance at the top, a fork that closes round the ring, three
## gate sockets (two on the sides, one on the bottom) and nine build spots. Flyers cross the
## ring in a straight line. Used by the tests of what phase 7 added.
const ARENA_GRID: Array = [
	"..1....", "..#.o..", ".o#.o..", ".#####.", ".#o.o#.", ".G...G.",
	".Go.o#.", ".###G#.", "...#...", ".o.#o..", "...B...",
]
const ARENA_SPOTS: Array[Vector2i] = [
	Vector2i(4, 1), Vector2i(1, 2), Vector2i(4, 2), Vector2i(2, 4), Vector2i(4, 4),
	Vector2i(2, 6), Vector2i(4, 6), Vector2i(1, 9), Vector2i(4, 9),
]
const ALL_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]
## Gate sockets of the arena: left side, right side, bottom right, and a second one on the left side
## (in series with the first, so both can be closed without sealing).
const ARENA_SOCKETS: Array[Vector2i] = [Vector2i(1, 5), Vector2i(5, 5), Vector2i(4, 7), Vector2i(1, 6)]


## The four towers of the expansion, and every tower with them. data/stats/ has none of the new
## content until E5.1, so the expansion's fixtures play on the sim's test catalog (docs/ARCHITECTURE.md
## 14.4): tests/sim/fixtures/creature_fixtures.gd.
const EXPANSION_TOWER_IDS: Array = ["bramble_cottage", "scarecrow", "snow_fort", "moth_lantern"]
const EXPANSION_ENEMY_IDS: Array = ["mossbud", "mistwisp", "gleamer", "sleepyhead", "snowroller", "yawner", "blinker", "hootling"]
const EXPANSION_BOSS_IDS: Array = ["burrowbelly", "old_hayrick", "snowsnore", "glimmertoad"]

## A long serpentine road, 7 x 10, with 24 build spots: room for every look of the new towers at once.
const GALLERY_GRID: Array = [
	"1######", "oooooo#", "#######", "#oooooo", "#######", "oooooo#", "#######", "#oooooo", "#######", "......B",
]


## The arena (or `grid`) played on the sim's expansion catalog, with every tower on offer unless
## `towers` names the ones to offer. Lives are 1000 and gold plentiful.
static func expansion(waves: Array, strength: int = 100, grid: Array = ARENA_GRID, gates: int = 2, towers: Array = []) -> Battle:
	var stats: Catalog = Cx.catalog()
	var list: Array = []
	for groups: Array in waves:
		list.append({"groups": groups})
	var all: Array = ALL_TOWERS.duplicate()
	all.append_array(EXPANSION_TOWER_IDS)
	if not towers.is_empty():
		all = towers.duplicate()
	var data: Dictionary = {
		"format": 1, "id": "expansion", "name": "Expansion", "grid": grid.duplicate(), "start_gold": 50000,
		"gates": gates, "strength": strength, "towers": all,
		"star3": {"kind": "no_lives_lost"}, "waves": list,
	}
	var twist: Array[Dictionary] = [{"type": "set_lives", "lives": 1000}]
	return Battle.create(LevelData.from_data(data, stats), stats, false, twist)


## The busiest wave the new cast makes: two waves of 120 on the serpentine road, every new creature
## and flitters for the lanterns, against a defense of every new tower and old ones, with the strength
## up so they live long enough to be drawn crowded. Bosses are left out (the stress map has them).
static func expansion_crowd() -> Battle:
	var groups: Array = []
	for id: String in ["mossbud", "sleepyhead", "snowroller", "blinker", "yawner"]:
		groups.append(group(id, 20, 150))
	groups.append(group("hootling", 6, 300))
	groups.append(group("mistwisp", 6, 300))
	groups.append(group("flitter", 8, 200))
	var b: Battle = expansion([groups, groups], 1000, SNAKE_GRID, 0)
	var order: Array = [
		["bramble_cottage", 3, 0], ["snow_fort", 3, 1], ["moth_lantern", 3, 1], ["scarecrow", 3, 1],
		["sling_post", 3, 0], ["pumpkin_catapult", 2, -1], ["longbow_loft", 3, 1], ["firework_tower", 3, 0],
		["bramble_cottage", 2, -1], ["snow_fort", 2, -1], ["moth_lantern", 2, -1], ["bakery", 2, -1],
	]
	for i: int in mini(b.level.spots.size(), order.size()):
		var o: Array = order[i]
		build(b, b.level.spots[i], StringName(o[0]), o[1], o[2])
	return b


## A wave group for the arena: `count` of `enemy`, one every `every_ms`, from `at_ms`.
static func group(enemy: String, count: int, every_ms: int = 400, at_ms: int = 0) -> Dictionary:
	return {"enemy": enemy, "count": count, "entrance": 1, "at_ms": at_ms, "every_ms": every_ms}


## The arena with these waves (each an array of groups). Lives are 1000, so only a test that
## wants it ends in a loss. `effects` are a Twist's.
static func arena(waves: Array, strength: int = 100, gates: int = 2, effects: Array = []) -> Battle:
	var stats: Catalog = catalog()
	var list: Array = []
	for groups: Array in waves:
		list.append({"groups": groups})
	var data: Dictionary = {
		"format": 1, "id": "arena", "name": "Arena", "grid": ARENA_GRID.duplicate(), "start_gold": 20000,
		"gates": gates, "strength": strength, "towers": ALL_TOWERS.duplicate(),
		"star3": {"kind": "no_lives_lost"}, "waves": list,
	}
	var twist: Array[Dictionary] = [{"type": "set_lives", "lives": 1000}]
	for effect: Dictionary in effects:
		twist.append(effect)
	return Battle.create(LevelData.from_data(data, stats), stats, false, twist)


## Builds `type` on `cell` and takes it to `tier`; at tier 3 `spec` picks the path. True when it worked.
static func build(b: Battle, cell: Vector2i, type: StringName, tier: int = 1, spec: int = -1) -> bool:
	if b.place_tower(cell, type) != Battle.DONE:
		return false
	for t: int in range(2, tier + 1):
		if b.upgrade_tower(cell, spec if t == 3 else -1) != Battle.DONE:
			return false
	return true


## The real run data files, read the way src/save/ passes them (2.12). Null if a file is bad.
static func run_data(stats: Catalog) -> RunData:
	var files: Dictionary = {}
	for key: String in ["runs/run.json", "cards/cards.json", "segments/index.json", "segments/packs.json"]:
		files[key] = JsonFile.read("res://data/" + key, 1048576)["data"]
	for id: Variant in (files["segments/index.json"] as Dictionary)["segments"]:
		files["segments/%s.json" % id] = JsonFile.read("res://data/segments/%s.json" % id, 262144)["data"]
	return RunData.from_data(files, stats)


## Every run map the assembler can make from the real segments: each top, a middle that fits
## under it, a bottom that fits under that. Every tower is allowed and gold is plentiful, so a
## test can fill the map. The wave packs are the first of each band.
static func run_levels(stats: Catalog) -> Array[LevelData]:
	var out: Array[LevelData] = []
	var data: RunData = run_data(stats)
	if data == null:
		return out
	var packs: Array[StringName] = []
	for band: int in range(1, RunData.BANDS + 1):
		var boss: StringName = data.boss_ids()[0] if band == RunData.BANDS else &""
		packs.append(data.packs_of(band, boss)[0]["id"])
	for top: Dictionary in data.segments_of(&"top"):
		for middle: Dictionary in data.segments_under(top["id"]):
			for bottom: Dictionary in data.segments_under(middle["id"]):
				var level: LevelData = MapAssembler.build(data, stats, top["id"], middle["id"], bottom["id"], packs)
				if level != null:
					level.start_gold = 100000
					level.towers = ALL_TOWER_IDS.duplicate()
					out.append(level)
	return out


const ALL_TOWER_IDS: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"lullaby_bell", &"longbow_loft", &"firework_tower", &"bakery"]


## A real level, as a Battle with plenty of gold.
static func level_battle(level: LevelData, stats: Catalog) -> Battle:
	return Battle.create(level, stats, false, [])


## Builds a tower on every spot, all at tier 3 (the tallest looks), cycling over the six
## towers and both paths. `shift` moves where the cycle starts. Returns how many stand.
static func fill(b: Battle, shift: int = 0) -> int:
	var n: int = 0
	for i: int in b.level.spots.size():
		var type: StringName = ALL_TOWER_IDS[(i + shift) % ALL_TOWER_IDS.size()]
		if build(b, b.level.spots[i], type, 3, ((i + shift) / ALL_TOWER_IDS.size() + i) % 2):
			n += 1
	return n
