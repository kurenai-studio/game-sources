# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Fixtures for the balance bots (task B6). Until the data of regions 5 to 8 lands (E5.1 to E8.1), the bots prove the new
## towers, creatures and map features on test data, not on the real files: the test-only catalog of the sim engineer
## (tests/sim/fixtures/creature_fixtures.gd, which holds the four expansion towers and the creatures it has so far) and
## fixture levels and a tiered run plan that this file builds from the real run files. Nothing here is in data/ and nothing
## is exported with the game. Every tool that takes `fixture=` calls `game()` and gets a GameData whose catalog is the test
## catalog, whose levels hold the fixture levels beside the real ones, and whose `run` holds content tiers.
##
## Fixture levels (ids the bots read as regions 5 to 8 by their number, `r5_fx1`):
##   r5_fx1  a fork: the west road runs through a tunnel, the east road has a gate socket. One entrance.
##   r6_fx1  a road that crosses itself on a bridge, with a socket beside the deck. Two entrances.
##   r7_fx1  a fork whose east road is an ice slide pointing south. One entrance.
##   r8_fx1  a road with two hollow stumps and a shortcut between them, and a socket below the second stump. One entrance.
##   r8_fx2  all four features on one map. Two entrances.
## Their waves bring every creature the catalog has, with a boss in the last wave. They are not tuned.

const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

const LEVEL_IDS: Array[StringName] = [&"r5_fx1", &"r6_fx1", &"r7_fx1", &"r8_fx1", &"r8_fx2"]

## The towers each region offers (RULES 12.6), as a level of that region would.
const REGION_TOWERS: Dictionary = {
	5: ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery", "bramble_cottage"],
	6: ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery", "bramble_cottage", "scarecrow"],
	7: ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery", "bramble_cottage", "scarecrow", "snow_fort"],
	8: ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery", "bramble_cottage", "scarecrow", "snow_fort", "moth_lantern"],
}

const GRIDS: Dictionary = {
	&"r5_fx1": [
		"...1...",
		"o..#..o",
		".#####.",
		".T.o.G.",
		".T...#.",
		".#.o.#.",
		".#####.",
		"..o#o..",
		"...#...",
		"..oBo..",
	],
	&"r6_fx1": [
		"...1...",
		".o.#G#o",
		"...#o#.",
		"2##X##.",
		"o..#o#o",
		"...#.#.",
		"####.#.",
		"#.o.o#o",
		"#....#.",
		"#.o.o#.",
		"#....#.",
		"#....#.",
		"#####B.",
	],
	&"r7_fx1": [
		"o..1..o",
		"o..#..o",
		".#####.",
		".G.o.v.",
		".#...v.",
		".#.o.#.",
		".#.o.#.",
		".#####.",
		"..oBo..",
	],
	&"r8_fx1": [
		"o..1..o",
		"o..#..o",
		".##P##.",
		".#.o.#.",
		".#o.o#.",
		".#...P.",
		".#.o.G.",
		".#####.",
		"..oBo..",
	],
	&"r8_fx2": [
		"o..1..o",
		"..oT..o",
		"...T...",
		"2##X##.",
		"...#.v.",
		".o.#ov.",
		"...P.#.",
		".o.#.#.",
		".o.#o#.",
		"...#.P.",
		"...#.G.",
		"...###.",
		"....B..",
	],
}

## Gates in hand, starting gold and wave strength of each fixture level.
const SETTINGS: Dictionary = {
	&"r5_fx1": {"gates": 1, "gold": 2200, "strength": 70},
	&"r6_fx1": {"gates": 1, "gold": 2400, "strength": 70},
	&"r7_fx1": {"gates": 1, "gold": 2400, "strength": 70},
	&"r8_fx1": {"gates": 1, "gold": 2600, "strength": 70},
	&"r8_fx2": {"gates": 1, "gold": 2800, "strength": 70},
}

## The tiers of RULES 14.9 and ARCHITECTURE 14.8: what a tier lists. Ids the catalog lacks are left out when the tiers are built.
const TIER_LISTS: Array = [
	{"level": "r5_l6", "towers": ["bramble_cottage"], "creatures": ["mossbud", "mistwisp"], "bosses": ["burrowbelly"], "grid": "T"},
	{"level": "r6_l6", "towers": ["scarecrow"], "creatures": ["gleamer", "sleepyhead"], "bosses": ["old_hayrick"], "grid": "X"},
	{"level": "r7_l6", "towers": ["snow_fort"], "creatures": ["snowroller", "yawner"], "bosses": ["snowsnore"], "grid": "^v<>"},
	{"level": "r8_l6", "towers": ["moth_lantern"], "creatures": ["blinker", "hootling"], "bosses": ["glimmertoad"], "grid": "PQ"},
]


## The test-only catalog: the real stats, the four expansion towers, and the creatures the sim engineer has so far.
static func catalog() -> Catalog:
	return Cx.catalog()


## The creature ids of the expansion that this catalog holds, in tier order.
static func new_creatures(cat: Catalog) -> Array[StringName]:
	var out: Array[StringName] = []
	for tier: Dictionary in TIER_LISTS:
		for list: String in ["creatures", "bosses"]:
			for id: String in tier[list]:
				if cat.has_enemy(StringName(id)):
					out.append(StringName(id))
	return out


## The expansion creatures the catalog lacks (regions 7 and 8 until the sim engineer's S10b lands).
static func missing_creatures(cat: Catalog) -> Array[StringName]:
	var out: Array[StringName] = []
	for tier: Dictionary in TIER_LISTS:
		for list: String in ["creatures", "bosses"]:
			for id: String in tier[list]:
				if not cat.has_enemy(StringName(id)):
					out.append(StringName(id))
	return out


# Fixture levels.

## A group, with the creature swapped for `fallback` when the catalog lacks it.
static func _group(cat: Catalog, enemy: String, fallback: String, count: int, entrance: int, at_ms: int, every_ms: int) -> Dictionary:
	var scaled: int = count if count == 1 else maxi(2, count * 6 / 10)
	return {"enemy": enemy if cat.has_enemy(StringName(enemy)) else fallback, "count": scaled, "entrance": entrance, "at_ms": at_ms, "every_ms": every_ms}


## Ten waves. The creatures of the expansion come in turn, a flying wave is in every fixture, and wave ten holds a boss.
static func _waves(cat: Catalog, entrances: int, strength: int, boss: String) -> Array:
	var e2: int = 2 if entrances > 1 else 1
	var s: int = strength
	var spec: Array = [
		[_group(cat, "scamp", "scamp", 8, 1, 0, 1000)],
		[_group(cat, "mossbud", "scamp", 6, 1, 0, 1200), _group(cat, "scamp", "scamp", 8, e2, 4000, 800)],
		[_group(cat, "pip", "pip", 24, 1, 0, 150), _group(cat, "flitter", "flitter", 6, e2, 3000, 500)],
		[_group(cat, "mistwisp", "skitter", 5, 1, 0, 1400), _group(cat, "skitter", "skitter", 10, e2, 3000, 600)],
		[_group(cat, "gleamer", "shellback", 4, 1, 0, 1600), _group(cat, "shellback", "shellback", 5, e2, 2000, 1400)],
		[_group(cat, "sleepyhead", "scamp", 6, 1, 0, 1200), _group(cat, "puffball", "puffball", 5, e2, 3000, 1500)],
		[_group(cat, "snowroller", "shellback", 4, 1, 0, 1800), _group(cat, "yawner", "mender", 3, 1, 800, 1800), _group(cat, "pip", "pip", 20, e2, 5000, 150)],
		[_group(cat, "hootling", "dusk_moth", 3, 1, 0, 1500), _group(cat, "blinker", "skitter", 6, e2, 2000, 900), _group(cat, "flitter", "flitter", 8, 1, 6000, 400)],
		[_group(cat, "gatecrasher", "gatecrasher", 3, 1, 0, 4000), _group(cat, "bubbler", "bubbler", 8, e2, 3000, 800), _group(cat, "scamp", "scamp", 12, 1, 6000, 700)],
		[_group(cat, boss, "grumblesack", 1, 1, 0, 1000), _group(cat, "scamp", "scamp", 10, e2, 4000, 800), _group(cat, "flitter", "flitter", 6, 1, 9000, 500)],
	]
	var waves: Array = []
	for k: int in spec.size():
		# The boss wave is weaker than the waves before it: a boss with 3000 health or more at full strength beats every build these
		# untuned fixtures allow, and the checks need some builds to win.
		waves.append({"strength": 50 if k == spec.size() - 1 else s + 4 * k, "groups": spec[k]})
	return waves


static func level_data(id: StringName, cat: Catalog) -> Dictionary:
	var grid: Array = GRIDS[id]
	var region: int = int(String(id)[1])
	var entrances: int = 2 if (grid.any(func(row: String) -> bool: return row.contains("2"))) else 1
	var setting: Dictionary = SETTINGS[id]
	var boss: String = ["burrowbelly", "old_hayrick", "snowsnore", "glimmertoad"][region - 5]
	return {
		"format": 1, "id": String(id), "name": "Fixture %s" % String(id), "grid": grid.duplicate(),
		"start_gold": int(setting["gold"]), "gates": int(setting["gates"]), "strength": int(setting["strength"]),
		"towers": (REGION_TOWERS[region] as Array).duplicate(), "star3": {"kind": "no_lives_lost"},
		"waves": _waves(cat, entrances, int(setting["strength"]), boss),
	}


## A fixture level against `cat`, or null with the problems printed (a bug in the fixture).
static func level(id: StringName, cat: Catalog) -> LevelData:
	var data: Dictionary = JSON.parse_string(JSON.stringify(level_data(id, cat)))
	var made: LevelData = LevelData.from_data(data, cat)
	if made == null:
		printerr("fixture level %s is refused: %s" % [id, ", ".join(LevelData.check(data, cat))])
	return made


# A tiered run plan.

## Reads one bundled run file, parsed. {} when it cannot be read.
static func _read(relative: String, cap: int) -> Variant:
	var got: Dictionary = JsonFile.read("res://data".path_join(relative), cap)
	if got["status"] != JsonFile.OK_STATUS:
		return {}
	return got["data"]


## The real run files with the content of the tiers added: tower cards and perks, one middle segment for each tier's map
## feature, packs for the tier creatures, and a band 6 pack for each boss the real packs do not have. The creatures a tier
## lists are the ones the catalog holds. Returns the files, ready for RunData.from_data.
static func run_files(cat: Catalog) -> Dictionary:
	var files: Dictionary = {}
	files[GameData.RUN_FILE] = _read(GameData.RUN_FILE, GameData.RUN_CAP)
	files[GameData.CARDS_FILE] = _read(GameData.CARDS_FILE, GameData.CARDS_CAP)
	files[GameData.INDEX_FILE] = _read(GameData.INDEX_FILE, GameData.INDEX_CAP)
	files[GameData.PACKS_FILE] = _read(GameData.PACKS_FILE, GameData.PACKS_CAP)
	for id: Variant in files[GameData.INDEX_FILE]["segments"]:
		var path: String = "%s/%s.json" % [GameData.SEGMENT_DIR, id]
		files[path] = _read(path, GameData.SEGMENT_CAP)
	_add_tiers(files, cat)
	_add_cards(files)
	_add_segments(files)
	_add_packs(files, cat)
	return files


static func _add_tiers(files: Dictionary, cat: Catalog) -> void:
	var tiers: Array = []
	for item: Dictionary in TIER_LISTS:
		var entry: Dictionary = {"level": item["level"], "towers": item["towers"].duplicate(), "grid": item["grid"], "creatures": [], "bosses": []}
		for list: String in ["creatures", "bosses"]:
			for id: String in item[list]:
				if cat.has_enemy(StringName(id)):
					(entry[list] as Array).append(id)
		tiers.append(entry)
	files[GameData.RUN_FILE]["tiers"] = tiers


static func _add_cards(files: Dictionary) -> void:
	var cards: Array = files[GameData.CARDS_FILE]["cards"]
	var made: Array = [
		["bramble_cottage", "Bramble Cottage", "thorn_tips", "Thorn Tips", "Bramble Cottages deal 2 more damage.", "damage", 2],
		["scarecrow", "Scarecrow", "big_hat", "Big Hat", "Scarecrows reach further.", "reach", 50],
		["snow_fort", "Snow Fort", "packed_snow", "Packed Snow", "Snow Forts deal 4 more damage.", "damage", 4],
		["moth_lantern", "Moth Lantern", "bright_wick", "Bright Wick", "Moth Lanterns reach further.", "reach", 50],
	]
	for item: Array in made:
		cards.append({"id": "tower_" + item[0], "kind": "tower", "tower": item[0], "name": item[1],
			"text": "You can build %ss for the rest of the run." % item[1], "once": true, "unlock": {},
			"effects": [{"type": "add_tower", "tower": item[0]}]})
		cards.append({"id": item[2], "kind": "perk", "tower": item[0], "name": item[3], "text": item[4], "once": true, "unlock": {},
			"effects": [{"type": "tower_add", "tower": item[0], "stat": item[5], "amount": item[6]}]})


## Middle segments with one feature each, cut from real middle segments, so ports, spots and sockets are the real ones and
## every stack still fits run.json's ranges: mid_split with a tunnel, mid_ring with a bridge (the road crosses at [3, 1]),
## mid_split with an ice slide down the west road, and mid_split with two stumps, one at the top of the road and one at the bottom of its west branch, so the twin step is a real shortcut.
static func _add_segments(files: Dictionary) -> void:
	var made: Array = [
		["mid_split", "mid_tunnel", [[1, 4, "T"]]],
		["mid_ring", "mid_bridge", [[3, 1, "X"]]],
		["mid_split", "mid_slide", [[1, 3, "v"], [1, 4, "v"]]],
		["mid_split", "mid_stump", [[3, 0, "P"], [1, 4, "P"]]],
	]
	var index: Array = files[GameData.INDEX_FILE]["segments"]
	for item: Array in made:
		var grid: Array = (files["%s/%s.json" % [GameData.SEGMENT_DIR, item[0]]]["grid"] as Array).duplicate()
		for edit: Array in item[2]:
			var row: String = grid[int(edit[1])]
			grid[int(edit[1])] = row.substr(0, int(edit[0])) + String(edit[2]) + row.substr(int(edit[0]) + 1)
		files["%s/%s.json" % [GameData.SEGMENT_DIR, item[1]]] = {"format": 1, "id": item[1], "kind": "middle", "grid": grid}
		index.append(item[1])


## Packs: one for each tier creature the catalog holds (the real pack of a band with one group's creature swapped, in band 2,
## 3, 3 and 4 for the first four, then bands 4 and 5), and a band 6 pack for each boss the real packs lack.
static func _add_packs(files: Dictionary, cat: Catalog) -> void:
	var packs: Array = files[GameData.PACKS_FILE]["packs"]
	var real: Array = packs.duplicate(true)
	var creatures: Array[String] = []
	var bosses: Array[String] = []
	for tier: Dictionary in files[GameData.RUN_FILE]["tiers"]:
		creatures.append_array(tier["creatures"])
		bosses.append_array(tier["bosses"])
	var bands: Array[int] = [2, 3, 3, 4, 4, 5, 5, 2]
	for i: int in creatures.size():
		var band: int = bands[i % bands.size()]
		var source: Dictionary = {}
		for pack: Dictionary in real:
			if int(pack["band"]) == band:
				source = pack
				break
		var copy: Dictionary = source.duplicate(true)
		copy["id"] = "fx_%s" % creatures[i]
		var groups: Array = copy["waves"][1]["groups"]
		(groups[0] as Dictionary)["enemy"] = creatures[i]
		packs.append(copy)
	for boss: String in bosses:
		for pack: Dictionary in real:
			if int(pack["band"]) == 6:
				var copy2: Dictionary = pack.duplicate(true)
				copy2["id"] = "fx_%s" % boss
				copy2["boss"] = boss
				for group: Dictionary in copy2["waves"][2]["groups"]:
					if cat.enemy(StringName(group["enemy"])).boss:
						group["enemy"] = boss
				packs.append(copy2)
				break
	# A boss in the catalog that no tier lists still needs a band 6 pack (RunPacks.check).
	for id: StringName in cat.enemy_ids():
		if cat.enemy(id).boss and not bosses.has(String(id)) and not _has_boss_pack(packs, String(id)):
			for pack: Dictionary in real:
				if int(pack["band"]) == 6:
					var copy3: Dictionary = pack.duplicate(true)
					copy3["id"] = "fx_%s" % id
					copy3["boss"] = String(id)
					for group: Dictionary in copy3["waves"][2]["groups"]:
						if cat.enemy(StringName(group["enemy"])).boss:
							group["enemy"] = String(id)
					packs.append(copy3)
					break


static func _has_boss_pack(packs: Array, boss: String) -> bool:
	for pack: Dictionary in packs:
		if int(pack["band"]) == 6 and String(pack["boss"]) == boss:
			return true
	return false


## RunData for the test catalog with the tiers, or null (the problems are printed).
static func run_data(cat: Catalog) -> RunData:
	var files: Dictionary = JSON.parse_string(JSON.stringify(run_files(cat)))
	var made: RunData = RunData.from_data(files, cat)
	if made == null:
		printerr("fixture run data is refused: %s" % ", ".join(RunData.check(files, cat)))
	return made


## The bundled game with the test catalog, the fixture levels added, and the tiered run data. Null with a message when a fixture
## is refused (a bug in the fixtures, or a change in the sim that they do not know).
static func game() -> GameData:
	var base: GameData = GameData.load_from("res://data")
	if not base.problems.is_empty():
		printerr("data problems: %s" % ", ".join(base.problems))
		return null
	var cat: Catalog = catalog()
	if cat == null:
		printerr("the test catalog is refused")
		return null
	base.catalog = cat
	for id: StringName in LEVEL_IDS:
		var made: LevelData = level(id, cat)
		if made == null:
			return null
		base.levels[id] = made
	var run: RunData = run_data(cat)
	if run == null:
		return null
	base.run = run
	return base
