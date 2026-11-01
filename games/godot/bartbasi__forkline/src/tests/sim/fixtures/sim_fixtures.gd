# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Shared fixtures for tests/sim/: the real stat files, test maps and helpers.
## Test maps live here, not in data/levels/.

const STATS_DIR: String = "res://data/stats/"

## The contract's example fork (docs/ARCHITECTURE.md 2.4). Both branches are 13 steps,
## so with no gate the tie break sends walkers west. Sockets at [1, 3] and [5, 5].
const FORK_GRID: Array = [
	"...1...",
	"o..#..o",
	".#####.",
	".G.o.#.",
	".#...#.",
	".#.o.G.",
	".#...#.",
	".#.o.#.",
	".#####.",
	"..oBo..",
]

## A straight road down column 3: entrance [3, 0], base [3, 7], 7 steps.
const LINE_GRID: Array = [
	"...1...",
	"..o#o..",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...B...",
]

## Three branches between [3, 2] and [3, 8], each with a socket, and two entrances.
const TRIPLE_GRID: Array = [
	"1.....2",
	"#..o..#",
	"#######",
	"G..G..G",
	"#..#..#",
	"#.o#o.#",
	"#..#..#",
	"#######",
	"...#...",
	"...B...",
]

## A straight road down column 3 between two pairs of spot columns, so spots touch:
## for Bakery reach (RULES 5.8, 8.6). Spots in columns 1, 2, 4 and 5 of rows 1 and 2.
const CLUSTER_GRID: Array = [
	"...1...",
	".oo#oo.",
	".oo#oo.",
	"...#...",
	"...#...",
	"...#...",
	"...#...",
	"...B...",
]

## Two branches of equal length; the tie break sends walkers (and breakers) west. The
## west branch holds two sockets, [1, 4] and [1, 6], one after the other (RULES 7.7).
const TWO_SOCKET_GRID: Array = [
	"...1...",
	"...#...",
	".#####.",
	".#...#.",
	".G.o.#.",
	".#...#.",
	".G...#.",
	".#...#.",
	".#####.",
	"...B...",
]

## Entrance [0, 0]. The short road goes down column 0 through the socket [0, 1]; the
## long road goes east along row 0 and back along row 4. A walker on the long road
## near the entrance turns back when the socket opens (RULES 7.8).
const LOOP_GRID: Array = [
	"1######",
	"G.....#",
	"#.o...#",
	"#.....#",
	"#######",
	"...#...",
	"...#...",
	"...B...",
]

# Map features (docs/ARCHITECTURE.md 14.2, 14.3; RULES 3.5 to 3.9).

## A road that crosses itself at the bridge [3, 3]: it goes over the deck east, loops
## round and passes under it north to the base. 14 steps; as a plain junction it would be 4.
const BRIDGE_LOOP_GRID: Array = [
	"...B...",
	"...#...",
	"...#...",
	"1##X##.",
	"...#.#.",
	"...###.",
	".......",
	".......",
]

## Entrance 1 [3, 0] walks south over the bridge [3, 3] on its north-south road and round
## the long west loop, 20 steps, while the socket [4, 1] is closed. With it open the way
## back north is shorter (14 steps from the entrance). Entrance 2 [0, 3] crosses the
## bridge east to west and goes down column 5. Base [5, 12].
const BRIDGE_GATE_GRID: Array = [
	"...1...",
	"...#G#.",
	"...#.#.",
	"2##X##.",
	"...#.#.",
	"...#.#.",
	"####.#.",
	"#....#.",
	"#....#.",
	"#....#.",
	"#....#.",
	"#....#.",
	"#####B.",
]

## Two branches like the fork, but the east one is a slide pointing north, away from the
## base: walkers can never go down it. A gate on the west socket [1, 3] would seal.
const SLIDE_UP_GRID: Array = [
	"...1...",
	"...#...",
	".#####.",
	".G...^.",
	".#...^.",
	".#...#.",
	".#...#.",
	".#####.",
	"...B...",
]

## The same with the slide pointing south: the east branch is open one way, down.
const SLIDE_DOWN_GRID: Array = [
	"...1...",
	"...#...",
	".#####.",
	".G...v.",
	".#...v.",
	".#...#.",
	".#...#.",
	".#####.",
	"...B...",
]

## Twin stumps P at [3, 2] and [5, 5]. The twin step is the shortcut: 8 steps from the
## entrance, against 13 by either branch.
const STUMP_GRID: Array = [
	"...1...",
	"...#...",
	".##P##.",
	".#...#.",
	".#...#.",
	".#...P.",
	".#...#.",
	".#####.",
	"...B...",
]

## A straight road with a tunnel of three tiles, [3, 2] to [3, 4], and spots beside it.
const TUNNEL_GRID: Array = [
	"...1...",
	"..o#o..",
	"...T...",
	"..oT...",
	"...T...",
	"...#...",
	"..o#o..",
	"...B...",
]

## Every feature on one map. Entrance 1 [3, 0] goes through the tunnel [3, 1] and [3, 2],
## under the bridge [3, 3], and takes the twin step from [3, 6] to [5, 9]. Entrance 2
## [0, 3] crosses the bridge, rides the slide [5, 4] and [5, 5] down, and walks past
## [5, 9]. A gate on the socket [5, 10] sends entrance 2 through the stumps the other way.
const FEATURE_GRID: Array = [
	"...1...",
	"..oT...",
	"...T...",
	"2##X##.",
	"...#.v.",
	".o.#ov.",
	"...P.#.",
	"...#.#.",
	".o.#o#.",
	"...#.P.",
	"...#.G.",
	"...###.",
	"....B..",
]


static func parse(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(path))


static func stats_files() -> Array:
	return [parse(STATS_DIR + "towers.json"), parse(STATS_DIR + "enemies.json"), parse(STATS_DIR + "rules.json")]


static func catalog() -> Catalog:
	var files: Array = stats_files()
	return Catalog.from_data(files[0], files[1], files[2])


## A catalog from the real files with one tower's stat block changed: tiers 0 and 1,
## then specs 0 and 1, as index 0 to 3.
static func catalog_with_tower(id: String, index: int, changes: Dictionary) -> Catalog:
	var files: Array = stats_files()
	for item: Dictionary in files[0]["towers"]:
		if item["id"] == id:
			var block: Dictionary = item["tiers"][index] if index < 2 else item["specs"][index - 2]
			block.merge(changes, true)
	return Catalog.from_data(files[0], files[1], files[2])


## A catalog from the real files with one creature's fields changed.
static func catalog_with_enemy(id: String, changes: Dictionary) -> Catalog:
	var files: Array = stats_files()
	for item: Dictionary in files[1]["enemies"]:
		if item["id"] == id:
			item.merge(changes, true)
	return Catalog.from_data(files[0], files[1], files[2])


static func group(enemy: String, count: int, at_ms: int = 0, every_ms: int = 1000, entrance: int = 1) -> Dictionary:
	return {"enemy": enemy, "count": count, "entrance": entrance, "at_ms": at_ms, "every_ms": every_ms}


## A valid level dictionary. Pass changes to override top level keys.
static func level_data(grid: Array, waves: Array, changes: Dictionary = {}) -> Dictionary:
	var data: Dictionary = {
		"format": 1, "id": "test_map", "name": "Test Map", "grid": grid.duplicate(),
		"start_gold": 1000, "gates": 0, "strength": 100,
		"towers": ["sling_post", "pumpkin_catapult"],
		"star3": {"kind": "no_lives_lost"},
		"waves": waves.duplicate(true),
	}
	data.merge(changes, true)
	return data


static func level(grid: Array, waves: Array, changes: Dictionary = {}, stats: Catalog = null) -> LevelData:
	var cat: Catalog = stats if stats != null else catalog()
	return LevelData.from_data(level_data(grid, waves, changes), cat)


static func battle(grid: Array, waves: Array, changes: Dictionary = {}, stats: Catalog = null, relaxed: bool = false) -> Battle:
	var cat: Catalog = stats if stats != null else catalog()
	var lvl: LevelData = LevelData.from_data(level_data(grid, waves, changes), cat)
	return Battle.create(lvl, cat, relaxed, [])


## Steps until the phase changes or the tick limit. Returns ticks run.
static func run_wave(b: Battle, limit: int = 20000) -> int:
	var ran: int = 0
	while b.phase == Battle.Phase.WAVE and ran < limit:
		b.step()
		ran += 1
	return ran


## Steps n ticks.
static func steps(b: Battle, n: int) -> void:
	for i: int in n:
		b.step()


static func events_of(events: Array[Dictionary], kind: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for event: Dictionary in events:
		if event["kind"] == kind:
			out.append(event)
	return out


static func snapshot(b: Battle) -> String:
	return JSON.stringify(b.to_data())


## A copy through JSON text, as a save file would give it.
static func restored(b: Battle) -> Battle:
	return Battle.from_data(JSON.parse_string(JSON.stringify(b.to_data())), b.catalog)


## The [tick, event] pairs of a run of n ticks (or until the phase leaves WAVE).
static func log_ticks(b: Battle, n: int) -> Array:
	var out: Array = []
	for i: int in n:
		if b.phase != Battle.Phase.WAVE:
			break
		var at: int = b.tick
		b.step()
		for event: Dictionary in b.take_events():
			out.append([at, event])
	return out


## The entries of a log with this event kind.
static func of_kind(log: Array, kind: StringName) -> Array:
	var out: Array = []
	for entry: Array in log:
		if entry[1]["kind"] == kind:
			out.append(entry)
	return out


## The ticks of a log's entries.
static func ticks(entries: Array) -> Array[int]:
	var out: Array[int] = []
	for entry: Array in entries:
		out.append(entry[0])
	return out


## The stat block of a tower tier (spec -1) or path, from a catalog.
static func stats(cat: Catalog, tower: StringName, tier: int, spec: int = -1) -> TowerStats:
	return cat.tower(tower).stats(tier, spec)


## Each gain field (contract 2.8), as [use, effect], with the field set to "VALUE".
const GAINS: Array = [
	["card", {"type": "add_gold", "amount": "VALUE", "per_wave": 10}],
	["card", {"type": "add_gold", "amount": 100, "per_wave": "VALUE"}],
	["card", {"type": "add_lives", "amount": "VALUE"}],
	["risk", {"type": "reward_gold", "amount": "VALUE"}],
	["card", {"type": "interest", "pct": 10, "max": "VALUE"}],
]


static func gain_effect(item: Array, value: int) -> Dictionary:
	var effect: Dictionary = (item[1] as Dictionary).duplicate()
	for key: String in effect.keys():
		if effect[key] is String and effect[key] == "VALUE":
			effect[key] = value
	return effect


