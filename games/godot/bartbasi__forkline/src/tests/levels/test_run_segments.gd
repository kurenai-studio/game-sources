# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The real run segments and wave packs in data/segments/ (docs/ARCHITECTURE.md 2.9, 2.12;
## RULES 14.2, 14.3, 14.9). Every file is listed, the files pass RunData.check, every stack of
## segments that fit, at every content tier, is a valid run map with a gate worth placing, a Bakery
## spot, tunnels that keep RULES 3.6 across the seams and a first gate that takes walkers out of them, every bottom segment keeps its last row
## scenery, features sit only in middle segments, bridges keep RULES 3.7, slides RULES 3.8 and stumps RULES 3.9 on every stack, a first
## gate closes the way into every stump, every choice of packs at
## every tier keeps the new creature rule and shows each tier creature as if new, and only boss waves set their own strength.

const SEGMENT_DIR: String = "res://data/segments/"
const RUN_PATH: String = "res://data/runs/run.json"
const CARDS_PATH: String = "res://data/cards/cards.json"
const INDEX_FILE: String = "index.json"
const PACKS_FILE: String = "packs.json"
## Size caps of 2.12.
const SEGMENT_CAP: int = 16 * 1024
const INDEX_CAP: int = 16 * 1024
const PACKS_CAP: int = 256 * 1024
const RUN_CAP: int = 16 * 1024
const CARDS_CAP: int = 256 * 1024
## RULES 12.5: aim for 80 or fewer creatures a wave, and 4 groups or fewer so the folded
## preview strip shows the whole wave.
const SPAWN_AIM: int = 80
const GROUPS_AIM: int = 4
## Seeds assembled into whole runs.
const SEEDS: int = 50
## RULES 14.2: the build spots a Bakery spot has among its eight neighbors.
const BAKERY_NEIGHBORS: int = 3
## RULES 14.3 and docs/ARCHITECTURE.md 2.4, 2.9: a boss wave's own strength.
const STRENGTH_MIN: int = 50
const STRENGTH_MAX: int = 1000
## RULES 12.5: at most 6 of each of these creatures in a pack wave, with any one risk card.
const CAPPED_CREATURES: Array[String] = ["mistwisp", "hootling"]
const CAPPED_MOST: int = 6
## RULES 14.3: each content tier adds packs with its creatures in every band from the first band where a
## pack can show them, plus two band 6 packs for its boss. A band 2 pack already shows its three new
## creatures, one a wave, so no wave is left to show a tier creature as if new: the packs of every tier
## start in band 3, the Mossbud and the Sleepyhead of band 2 included.
const TIER_FIRST_BAND: Dictionary = {1: 3, 2: 3, 3: 3, 4: 3}
## RULES 14.2: which feature each map character belongs to.
const FEATURE_KINDS: Dictionary = {"T": "tunnel", "X": "bridge", "^": "slide", "v": "slide", "<": "slide", ">": "slide", "P": "stump", "Q": "stump"}
## TUNING_R5.md 1.6: on a tunnel stack the best first gate adds at least this many steps outside tunnels.
const TUNNEL_DETOUR_MIN: int = 2
## RULES 14.2, TUNING_R5.md 1.6 for stumps: on a stump stack the best first gate adds at least this many steps in reach.
const STUMP_DETOUR_MIN: int = 2

const Rules: GDScript = preload("res://tests/levels/fixtures/map_rules.gd")

var catalog: Catalog = null
var files: Dictionary = {}
var data: RunData = null


func before_each() -> void:
	catalog = _catalog()
	files = _files()
	data = RunData.from_data(files, catalog)


static func _read(path: String, cap: int) -> Variant:
	var got: Dictionary = JsonFile.read(path, cap)
	if got["status"] != JsonFile.OK_STATUS:
		return null
	return got["data"]


static func _catalog() -> Catalog:
	var cap: int = 256 * 1024
	return Catalog.from_data(_read("res://data/stats/towers.json", cap), _read("res://data/stats/enemies.json", cap), _read("res://data/stats/rules.json", cap))


## The ids index.json lists, in its order. Empty when it has the wrong shape.
static func _listed() -> Array[String]:
	var out: Array[String] = []
	var index: Variant = _read(SEGMENT_DIR + INDEX_FILE, INDEX_CAP)
	if typeof(index) != TYPE_DICTIONARY or typeof((index as Dictionary).get("segments", null)) != TYPE_ARRAY:
		return out
	for id: Variant in (index as Dictionary)["segments"]:
		if DataCheck.is_id(id):
			out.append(String(id))
	return out


## The parsed files keyed by their path under data/, as GameData hands them to RunData (2.12).
static func _files() -> Dictionary:
	var out: Dictionary = {
		"runs/run.json": _read(RUN_PATH, RUN_CAP),
		"cards/cards.json": _read(CARDS_PATH, CARDS_CAP),
		"segments/index.json": _read(SEGMENT_DIR + INDEX_FILE, INDEX_CAP),
		"segments/packs.json": _read(SEGMENT_DIR + PACKS_FILE, PACKS_CAP),
	}
	for id: String in _listed():
		out["segments/%s.json" % id] = _read(SEGMENT_DIR + id + ".json", SEGMENT_CAP)
	return out


## Every segment file name in the folder, without ".json". index.json and packs.json are left out.
static func _segment_files() -> Array[String]:
	var out: Array[String] = []
	for file_name: String in DirAccess.get_files_at(SEGMENT_DIR):
		if file_name.ends_with(".json") and file_name != INDEX_FILE and file_name != PACKS_FILE:
			out.append(file_name.trim_suffix(".json"))
	out.sort()
	return out


## Every stack MapAssembler can pick at `tier`: [top, middle, bottom] segment ids. The highest tier
## holds every stack of the tiers below it, so "every stack at every tier" is every stack at the top.
func _stacks(tier: int = -1) -> Array[Array]:
	var out: Array[Array] = []
	if data == null:
		return out
	var at: int = _top_tier() if tier < 0 else tier
	for top: Dictionary in data.segments_of(&"top", at):
		for middle: Dictionary in data.segments_under(top["id"], at):
			for bottom: Dictionary in data.segments_under(middle["id"], at):
				out.append([top["id"], middle["id"], bottom["id"]])
	return out


## The highest content tier run.json holds (docs/ARCHITECTURE.md 14.8).
func _top_tier() -> int:
	return 0 if data == null else data.tiers.size()


## The content tier of each creature and boss that a tier lists; anything else is tier 0 (RULES 14.9).
func _creature_tiers() -> Dictionary:
	var out: Dictionary = {}
	if data == null:
		return out
	for t: int in data.tiers.size():
		for key: String in ["creatures", "bosses"]:
			for id: Variant in (data.tiers[t] as Dictionary)[key]:
				out[String(id)] = t + 1
	return out


## One pack per band, the first of each, so a stack can be built into a level.
func _first_packs() -> Array[StringName]:
	var out: Array[StringName] = []
	for band: int in range(1, RunData.BANDS + 1):
		out.append(data.packs_of(band)[0]["id"])
	return out


func _build(stack: Array) -> LevelData:
	return MapAssembler.build(data, catalog, stack[0], stack[1], stack[2], _first_packs())


static func _text(cells: Array[Vector2i]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for cell: Vector2i in cells:
		parts.append("%d,%d" % [cell.x, cell.y])
	return " ".join(parts)


# Files

func test_every_segment_file_is_listed_once_and_every_listed_file_exists() -> void:
	var listed: Array[String] = _listed()
	assert_true(listed.size() > 0, "index.json lists segments")
	var on_disk: Array[String] = _segment_files()
	for id: String in on_disk:
		assert_eq(listed.count(id), 1, "%s.json is listed exactly once in index.json" % id)
	for id: String in listed:
		assert_true(on_disk.has(id), "index.json lists %s, which has a file" % id)
	assert_true(FileAccess.file_exists(SEGMENT_DIR + PACKS_FILE), "packs.json exists")


func test_files_are_plain_ascii_with_lf_endings_and_under_their_caps() -> void:
	var paths: Dictionary = {SEGMENT_DIR + INDEX_FILE: INDEX_CAP, SEGMENT_DIR + PACKS_FILE: PACKS_CAP}
	for id: String in _segment_files():
		paths[SEGMENT_DIR + id + ".json"] = SEGMENT_CAP
	for path: String in paths:
		var bytes: PackedByteArray = FileAccess.get_file_as_bytes(path)
		assert_true(bytes.size() > 0, "%s is not empty" % path)
		assert_true(bytes.size() <= int(paths[path]), "%s is under its size cap" % path)
		var bad: int = 0
		for b: int in bytes:
			if b >= 0x80 or b == 0 or b == 13:
				bad += 1
		assert_eq(bad, 0, "%s: bytes outside plain ASCII, or a CR" % path)


func test_the_real_run_files_pass_run_data_check() -> void:
	var found: PackedStringArray = RunData.check(files, catalog)
	assert_eq(found, PackedStringArray(), "\n".join(found))
	assert_not_null(data, "RunData.from_data")


func test_game_data_loads_the_run_files() -> void:
	var game: GameData = GameData.load_from()
	assert_eq(game.problems, PackedStringArray(), "GameData problems")
	assert_not_null(game.run, "GameData.run")


func test_segment_ids_equal_their_file_names() -> void:
	for id: String in _listed():
		var raw: Variant = files.get("segments/%s.json" % id, null)
		assert_true(raw is Dictionary, "%s.json parses to an object" % id)
		if raw is Dictionary:
			assert_eq(str((raw as Dictionary).get("id", "")), id, "%s.json id" % id)


# Maps

## docs/ARCHITECTURE.md 2.4, 2.9 and RULES 14.2: a run map has 13 rows, so its bottom row,
## the last row of every bottom segment, is scenery only.
func test_every_bottom_segments_last_row_is_scenery() -> void:
	if data == null:
		fail("the run files do not load")
		return
	assert_eq(int(data.rows["top"]) + int(data.rows["middle"]) + int(data.rows["bottom"]), Sim.MAP_ROWS_MAX, "run maps have 13 rows")
	var bottoms: Array[Dictionary] = data.segments_of(&"bottom")
	assert_true(bottoms.size() >= 2, "more than one bottom segment, for variety")
	for bottom: Dictionary in bottoms:
		var grid: PackedStringArray = bottom["grid"]
		assert_eq(grid[grid.size() - 1], ".".repeat(Sim.MAP_COLUMNS), "%s: the last row is all scenery" % bottom["id"])


## Every segment shows up in some stack, so none is dead data.
func test_every_segment_is_used_in_some_stack() -> void:
	var used: Dictionary = {}
	for stack: Array in _stacks():
		for id: StringName in stack:
			used[id] = true
	for id: String in _listed():
		assert_true(used.has(StringName(id)), "%s is part of some stack" % id)


## 2.9: every stack MapAssembler can pick is a valid map within run.json's spots and sockets,
## and every entrance has an open route to the base with no gates placed.
func test_every_stack_is_a_valid_run_map() -> void:
	var stacks: Array[Array] = _stacks()
	assert_true(stacks.size() >= 20, "plenty of stacks for variety, got %d" % stacks.size())
	for stack: Array in stacks:
		var label: String = "%s / %s / %s" % stack
		var level: LevelData = _build(stack)
		assert_not_null(level, label)
		if level == null:
			continue
		assert_eq(level.rows, Sim.MAP_ROWS_MAX, "%s: 13 rows" % label)
		assert_eq(level.grid[level.rows - 1], ".".repeat(Sim.MAP_COLUMNS), "%s: the bottom row is scenery" % label)
		assert_true(level.spots.size() >= data.spots_min and level.spots.size() <= data.spots_max, "%s: %d spots" % [label, level.spots.size()])
		assert_true(level.sockets.size() >= data.sockets_min and level.sockets.size() <= data.sockets_max, "%s: %d sockets" % [label, level.sockets.size()])
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var dist: PackedInt32Array = map.distances(none)
		assert_false(map.seals(none), "%s: no gate seals nothing" % label)
		for i: int in level.entrances.size():
			var path: Array[Vector2i] = map.route(level.entrances[i], dist)
			assert_true(path.size() >= 2, "%s: entrance %d has an open route" % [label, i + 1])
			if path.size() >= 2:
				assert_eq(path[path.size() - 1], level.base, "%s: entrance %d reaches the base" % [label, i + 1])


## RULES 14.2: middle segments hold the forks. In every stack some single gate, placed where
## it seals nothing, changes where walkers go, so the run's first gate is a real choice.
func test_every_stack_has_a_gate_that_steers() -> void:
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var open_dist: PackedInt32Array = map.distances(none)
		var steers: int = 0
		for socket: Vector2i in level.sockets:
			var closed: Array[Vector2i] = [socket]
			if map.seals(closed):
				continue
			var dist: PackedInt32Array = map.distances(closed)
			for entrance: Vector2i in level.entrances:
				if _text(map.route(entrance, dist)) != _text(map.route(entrance, open_dist)):
					steers += 1
					break
		assert_true(steers >= 1, "%s / %s / %s: some gate changes a route" % stack)


## RULES 14.2 and docs/ARCHITECTURE.md 2.9: every stack has a Bakery spot, a build spot with at
## least 3 other build spots among its eight neighbors, so a Bakery there reaches 3 towers.
func test_every_stack_has_a_bakery_spot() -> void:
	var stacks: Array[Array] = _stacks()
	assert_true(stacks.size() > 0, "some stacks")
	for stack: Array in stacks:
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		var best: int = 0
		for spot: Vector2i in level.spots:
			var near: int = 0
			for other: Vector2i in level.spots:
				if other != spot and absi(other.x - spot.x) <= 1 and absi(other.y - spot.y) <= 1:
					near += 1
			best = maxi(best, near)
		assert_true(best >= BAKERY_NEIGHBORS, "%s / %s / %s: the best Bakery spot reaches %d spots, needs %d" % [stack[0], stack[1], stack[2], best, BAKERY_NEIGHBORS])


## Every assembled run builds at every tier, as the roguelite engineer's test also checks, and its
## waves reach only entrances the map has.
func test_runs_from_seeds_assemble() -> void:
	if data == null:
		fail("the run files do not load")
		return
	for tier: int in _top_tier() + 1:
		for run_seed: int in SEEDS:
			var level: LevelData = MapAssembler.assemble(run_seed, data, catalog, tier)
			assert_not_null(level, "tier %d seed %d" % [tier, run_seed])
			if level == null:
				continue
			assert_eq(level.waves.size(), RunData.BANDS * 3, "tier %d seed %d: 18 waves" % [tier, run_seed])


# Packs

## RULES 14.3 and docs/ARCHITECTURE.md 2.9: for every choice of one pack per band (band 6:
## every pack), reading waves 1 to 18 in order, a creature the run has not shown yet comes in
## the wave's first group, no group of that wave starts before it, and no wave brings two.
## The creatures shown so far are all that a later band depends on, so equal sets are walked once.
## Since A12 at every content tier (14.13): a creature of tiers 1 to 4 also counts as new in the first
## wave of each pack that has it (RULES 14.3), and no wave shows two creatures as new, counting both kinds.
func test_every_choice_of_packs_keeps_the_new_creature_rule() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var tiered: Dictionary = _creature_tiers()
	var walked: int = 0
	for tier: int in _top_tier() + 1:
		var states: Dictionary = {"": []}
		for band: int in range(1, RunData.BANDS + 1):
			var next: Dictionary = {}
			var packs: Array[Dictionary] = data.packs_of(band, &"", tier)
			assert_true(packs.size() >= 4, "tier %d band %d has at least 4 packs" % [tier, band])
			for key: String in states:
				var shown_before: Array = states[key]
				for pack: Dictionary in packs:
					walked += 1
					var shown: Array = shown_before.duplicate()
					var in_pack: Array = []
					var waves: Array = pack["waves"]
					for w: int in waves.size():
						var label: String = "tier %d: %s wave %d after [%s]" % [tier, pack["id"], w + 1, key]
						_check_new_creatures((waves[w] as Dictionary)["groups"], shown, label, tiered, in_pack)
					shown.sort()
					next[",".join(PackedStringArray(shown))] = shown
			states = next
	assert_true(walked > 0, "some packs were walked")


## Checks one wave against the creatures shown so far, then adds its creatures to them. `in_pack`
## holds the tier creatures this pack has shown already: a tier creature counts as new in the first
## wave of its pack that has it (RULES 14.3).
func _check_new_creatures(groups: Array, shown: Array, label: String, tiered: Dictionary, in_pack: Array) -> void:
	var fresh: Array[String] = []
	for raw: Variant in groups:
		var enemy: String = String((raw as Dictionary)["enemy"])
		var as_new: bool = not shown.has(enemy) or (tiered.has(enemy) and not in_pack.has(enemy))
		if as_new and not fresh.has(enemy):
			fresh.append(enemy)
	for raw: Variant in groups:
		var enemy: String = String((raw as Dictionary)["enemy"])
		if tiered.has(enemy) and not in_pack.has(enemy):
			in_pack.append(enemy)
	assert_true(fresh.size() <= 1, "%s: shows two creatures as new %s" % [label, fresh])
	if fresh.size() == 1:
		var first: Dictionary = groups[0]
		assert_eq(String(first["enemy"]), fresh[0], "%s: the new %s comes in the first group" % [label, fresh[0]])
		for raw: Variant in groups:
			assert_true(int((raw as Dictionary)["at_ms"]) >= int(first["at_ms"]), "%s: no group starts before the new %s" % [label, fresh[0]])
	for raw: Variant in groups:
		var enemy: String = String((raw as Dictionary)["enemy"])
		if not shown.has(enemy):
			shown.append(enemy)


## The simple way the rule is kept (2.9): every band's pack shows every tier 0 creature its band adds,
## so any pack can follow any other. A tier creature (14.9) is shown as if new in each pack that uses
## it instead, so a pack need not use it.
func test_every_pack_shows_every_creature_its_band_adds() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var tiered: Dictionary = _creature_tiers()
	for pack: Dictionary in data.packs:
		var band: int = pack["band"]
		var seen: Array[String] = []
		for wave: Variant in pack["waves"]:
			for group: Variant in (wave as Dictionary)["groups"]:
				seen.append(String((group as Dictionary)["enemy"]))
		for creature: StringName in data.bands[band - 1]:
			if tiered.has(String(creature)):
				continue
			assert_true(seen.has(String(creature)), "%s shows %s" % [pack["id"], creature])


## RULES 12.5 aims, for a readable screen and a whole folded preview.
func test_pack_waves_stay_readable() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var none: Array[Dictionary] = []
	for pack: Dictionary in data.packs:
		var waves: Array = pack["waves"]
		for w: int in waves.size():
			var groups: Array = (waves[w] as Dictionary)["groups"]
			var total: int = RunPacks.spawn_total(groups, catalog, none)
			assert_true(total <= SPAWN_AIM, "%s wave %d spawns %d, RULES 12.5 aims for %d or fewer" % [pack["id"], w + 1, total, SPAWN_AIM])
			assert_true(groups.size() <= GROUPS_AIM, "%s wave %d has %d groups" % [pack["id"], w + 1, groups.size()])


## RULES 14.3 and docs/ARCHITECTURE.md 2.9: a band 6 pack's third wave, the boss wave, sets its
## own strength, 50 to 1,000, and no other pack wave has one. Read from the file itself, so the
## check holds whatever shape RunData gives its packs.
func test_only_boss_waves_set_a_strength() -> void:
	var raw: Variant = files.get("segments/packs.json", null)
	if typeof(raw) != TYPE_DICTIONARY or typeof((raw as Dictionary).get("packs", null)) != TYPE_ARRAY:
		fail("packs.json does not parse to an object with packs")
		return
	var boss_waves: int = 0
	for pack: Variant in (raw as Dictionary)["packs"]:
		var item: Dictionary = pack
		var waves: Array = item["waves"]
		for w: int in waves.size():
			var wave: Dictionary = waves[w]
			var label: String = "%s wave %d" % [item["id"], w + 1]
			if int(item["band"]) == RunData.BANDS and w == waves.size() - 1:
				boss_waves += 1
				assert_true(wave.has("strength"), "%s, the boss wave, sets its strength" % label)
				var value: Variant = wave.get("strength", 0)
				assert_true(typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == floorf(float(value))), "%s: the strength is a whole number" % label)
				assert_true(int(value) >= STRENGTH_MIN and int(value) <= STRENGTH_MAX, "%s: strength %s is %d to %d" % [label, value, STRENGTH_MIN, STRENGTH_MAX])
			else:
				assert_false(wave.has("strength"), "%s sets no strength; only boss waves do" % label)
	assert_true(boss_waves >= 4, "the band 6 packs were found, got %d" % boss_waves)


## Every assembled run's wave 18 takes its band 6 pack's boss wave strength, and waves 1 to 17
## rise by run.json's step, at every tier.
func test_runs_take_the_boss_wave_strength_from_their_pack() -> void:
	if data == null:
		fail("the run files do not load")
		return
	for tier: int in _top_tier() + 1:
		for run_seed: int in SEEDS:
			var plan: Dictionary = MapAssembler.plan(run_seed, data, tier)
			var level: LevelData = MapAssembler.assemble(run_seed, data, catalog, tier)
			if level == null or plan.is_empty():
				fail("tier %d seed %d does not assemble" % [tier, run_seed])
				continue
			var boss_pack: StringName = (plan["packs"] as Array)[RunData.BANDS - 1]
			var wanted: int = -1
			for pack: Dictionary in data.packs_of(RunData.BANDS, &"", tier):
				if pack["id"] == boss_pack:
					wanted = int(((pack["waves"] as Array)[2] as Dictionary).get("strength", -1))
			var last: int = level.waves.size() - 1
			assert_eq(level.waves[last].strength, wanted, "tier %d seed %d: wave 18 has %s's boss wave strength" % [tier, run_seed, boss_pack])
			for w: int in last:
				assert_eq(level.waves[w].strength, data.strength_start + data.strength_step * w, "tier %d seed %d wave %d strength" % [tier, run_seed, w + 1])


## RULES 14.3: the boss comes alone at the start of the third wave of its pack, and each boss
## has more than one pack so its runs differ. A boss of a content tier has its packs at that tier
## (docs/ARCHITECTURE.md 14.13: 2 band 6 packs for each boss whose tier's level is in campaign.json).
func test_each_boss_has_two_packs_and_leads_its_wave() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var tiered: Dictionary = _creature_tiers()
	var campaign: PackedStringArray = _campaign_levels()
	for t: int in data.tiers.size():
		var level: String = String((data.tiers[t] as Dictionary)["level"])
		assert_true(campaign.has(level), "tier %d's level %s is in campaign.json" % [t + 1, level])
	for boss: StringName in catalog.enemy_ids():
		var type: EnemyType = catalog.enemy(boss)
		if not type.boss:
			continue
		var packs: Array[Dictionary] = data.packs_of(RunData.BANDS, boss, int(tiered.get(String(boss), 0)))
		assert_true(packs.size() >= 2, "%s has at least 2 band 6 packs" % boss)
		for pack: Dictionary in packs:
			var groups: Array = ((pack["waves"] as Array)[2] as Dictionary)["groups"]
			assert_eq(StringName(String((groups[0] as Dictionary)["enemy"])), boss, "%s: the boss leads wave 3" % pack["id"])


## Level ids of campaign.json, in play order.
static func _campaign_levels() -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var raw: Variant = _read("res://data/levels/campaign.json", 16 * 1024)
	if typeof(raw) != TYPE_DICTIONARY or typeof((raw as Dictionary).get("regions", null)) != TYPE_ARRAY:
		return out
	for region: Variant in (raw as Dictionary)["regions"]:
		if typeof(region) == TYPE_DICTIONARY and typeof((region as Dictionary).get("levels", null)) == TYPE_ARRAY:
			for id: Variant in (region as Dictionary)["levels"]:
				out.append(str(id))
	return out


# Map features (RULES 3.5, 3.6, 14.2)

## RULES 14.2 and docs/ARCHITECTURE.md 14.13: features only in middle segments, never in their top or
## bottom row, and at most one feature a segment: one tunnel run, one bridge, one slide run or one pair
## of stumps.
func test_features_only_in_the_middle_rows_of_middle_segments() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var with_features: int = 0
	for id: String in _listed():
		var segment: Dictionary = data.segment(StringName(id))
		var grid: PackedStringArray = segment["grid"]
		var cells: Array[Vector2i] = []
		var kinds: Dictionary = {}
		var chars: Dictionary = {}
		for r: int in grid.size():
			for c: int in grid[r].length():
				var ch: String = grid[r][c]
				if FEATURE_KINDS.has(ch):
					cells.append(Vector2i(c, r))
					kinds[FEATURE_KINDS[ch]] = true
					chars[ch] = true
					assert_true(r > 0 and r < grid.size() - 1, "%s: the feature at %s is in a middle row" % [id, Vector2i(c, r)])
		if cells.is_empty():
			continue
		with_features += 1
		assert_eq(segment["kind"], &"middle", "%s: only middle segments hold features" % id)
		assert_eq(kinds.size(), 1, "%s holds one kind of feature, got %s" % [id, kinds.keys()])
		if kinds.has("tunnel") or kinds.has("slide"):
			assert_true(_connected(cells), "%s: its tunnel or slide is one run" % id)
		if kinds.has("bridge"):
			assert_eq(cells.size(), 1, "%s holds one bridge" % id)
		if kinds.has("stump"):
			assert_eq(chars.size(), 1, "%s holds one pair of stumps" % id)
	assert_true(with_features >= 2, "some middle segments hold features, so the rule is exercised")


## True when the cells are joined north, south, east or west into one group.
static func _connected(cells: Array[Vector2i]) -> bool:
	var reached: Array[Vector2i] = [cells[0]]
	var todo: Array[Vector2i] = [cells[0]]
	while not todo.is_empty():
		var cell: Vector2i = todo.pop_back()
		for side: Vector2i in Rules.SIDES:
			var next: Vector2i = cell + side
			if cells.has(next) and not reached.has(next):
				reached.append(next)
				todo.append(next)
	return reached.size() == cells.size()


## RULES 3.6 and 14.2 on every stack at every tier: tunnels are straight runs of 1 to 4 tiles with no fork
## or bend, at most 6 tiles a map, never next to a socket (across the seams between segments too), and at
## most a quarter of any entrance's shortest route with no gates.
func test_every_stack_keeps_the_tunnel_rules() -> void:
	var tunnelled: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		if not Rules.tunnel_tiles(level).is_empty():
			tunnelled += 1
		var found: PackedStringArray = Rules.tunnel_problems(level)
		assert_eq(found, PackedStringArray(), "%s / %s / %s: %s" % [stack[0], stack[1], stack[2], "; ".join(found)])
	assert_true(tunnelled >= 1, "some stack has a tunnel, so the rules are exercised")


## RULES 14.2 and TUNING_R5.md 1.6: on every stack with a tunnel, walkers with no gates take a tunnel, and some
## placement of the run's first gate that seals nothing takes them out of it onto a longer road: the entrance
## with the fewest steps outside tunnels gains at least TUNNEL_DETOUR_MIN of them.
func test_every_tunnel_stack_has_a_gate_that_adds_road_in_reach() -> void:
	var tunnelled: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		var tiles: Array[Vector2i] = Rules.tunnel_tiles(level)
		if tiles.is_empty():
			continue
		tunnelled += 1
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var open_dist: PackedInt32Array = map.distances(none)
		var walked: bool = false
		for entrance: Vector2i in level.entrances:
			for cell: Vector2i in map.route(entrance, open_dist):
				walked = walked or tiles.has(cell)
		assert_true(walked, "%s / %s / %s: with no gates some walkers take a tunnel" % stack)
		var open_reach: int = _least_in_reach(level, map, open_dist, tiles)
		var best: int = open_reach
		for socket: Vector2i in level.sockets:
			var closed: Array[Vector2i] = [socket]
			if not map.seals(closed):
				best = maxi(best, _least_in_reach(level, map, map.distances(closed), tiles))
		assert_true(best - open_reach >= TUNNEL_DETOUR_MIN, "%s / %s / %s: the best gate adds %d steps in reach, needs %d" % [stack[0], stack[1], stack[2], best - open_reach, TUNNEL_DETOUR_MIN])
	assert_true(tunnelled >= 1, "some stack has a tunnel, so the rule is exercised")


## The fewest steps outside tunnels on any entrance's route over `dist`.
static func _least_in_reach(level: LevelData, map: RoadMap, dist: PackedInt32Array, tiles: Array[Vector2i]) -> int:
	var least: int = -1
	for entrance: Vector2i in level.entrances:
		var route: Array[Vector2i] = map.route(entrance, dist)
		var reach: int = route.size() - 1
		for cell: Vector2i in route:
			if tiles.has(cell):
				reach -= 1
		least = reach if least < 0 else mini(least, reach)
	return least


## RULES 14.9: a tier 0 run never meets a feature, so the run maps of regions 1 to 4 stay as they were.
func test_tier_zero_stacks_hold_no_features() -> void:
	for stack: Array in _stacks(0):
		var level: LevelData = _build(stack)
		if level == null:
			continue
		assert_eq(Rules.feature_chars(level.grid), "", "%s / %s / %s is a tier 0 stack" % stack)


## RULES 3.7 and 14.2 on every stack at every tier: each bridge has four road neighbors, there are at most 3
## with a plain road tile between two, and each lies on the shortest route of some placement of the run's
## starting gates, so it always matters.
func test_every_stack_keeps_the_bridge_rules() -> void:
	var bridged: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		if not Rules.bridge_tiles(level).is_empty():
			bridged += 1
		var found: PackedStringArray = Rules.bridge_problems(level)
		assert_eq(found, PackedStringArray(), "%s / %s / %s: %s" % [stack[0], stack[1], stack[2], "; ".join(found)])
		var off: Array[Vector2i] = Rules.bridges_off_every_route(level, data.gates)
		assert_true(off.is_empty(), "%s / %s / %s: the bridges %s lie on no route" % [stack[0], stack[1], stack[2], off])
	assert_true(bridged >= 1, "some stack has a bridge, so the rules are exercised")


## RULES 3.8 and 14.2 on every stack at every tier: slides are straight runs of 2 or more tiles with every arrow
## along the run, each arrow points at road, no slide is a dead end with no gates, and each slide tile lies on the
## shortest route of some placement of the run's starting gates, so it always matters.
func test_every_stack_keeps_the_slide_rules() -> void:
	var slid: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		if not Rules.slide_tiles(level).is_empty():
			slid += 1
		var found: PackedStringArray = Rules.slide_problems(level)
		assert_eq(found, PackedStringArray(), "%s / %s / %s: %s" % [stack[0], stack[1], stack[2], "; ".join(found)])
		var off: Array[Vector2i] = Rules.slides_off_every_route(level, data.gates)
		assert_true(off.is_empty(), "%s / %s / %s: the slides %s lie on no route" % [stack[0], stack[1], stack[2], off])
	assert_true(slid >= 1, "some stack has a slide, so the rules are exercised")


## RULES 14.2: a slide can make a gate placement seal that looks open, so on every stack with a slide some
## placement of the run's first gate that seals nothing makes a detour: some entrance's route gets longer.
func test_every_slide_stack_has_a_gate_that_makes_a_detour() -> void:
	var slid: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		if Rules.slide_tiles(level).is_empty():
			continue
		slid += 1
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var open_dist: PackedInt32Array = map.distances(none)
		var detour: bool = false
		for socket: Vector2i in level.sockets:
			var closed: Array[Vector2i] = [socket]
			if map.seals(closed):
				continue
			var dist: PackedInt32Array = map.distances(closed)
			for entrance: Vector2i in level.entrances:
				if map.route(entrance, dist).size() > map.route(entrance, open_dist).size():
					detour = true
		assert_true(detour, "%s / %s / %s: some gate makes a detour" % stack)
	assert_true(slid >= 1, "some stack has a slide, so the rule is exercised")


## RULES 3.9 and 14.2 on every stack at every tier: stumps come in one pair a segment with twins apart, and each pair's
## twin step lies on the shortest route of some placement of the run's starting gates, so it always matters.
func test_every_stack_keeps_the_stump_rules() -> void:
	var stumped: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		if not Rules.stump_tiles(level).is_empty():
			stumped += 1
		var found: PackedStringArray = Rules.stump_problems(level)
		assert_eq(found, PackedStringArray(), "%s / %s / %s: %s" % [stack[0], stack[1], stack[2], "; ".join(found)])
		var off: Array[Vector2i] = Rules.stump_pairs_off_every_route(level, data.gates)
		assert_true(off.is_empty(), "%s / %s / %s: the stump pairs at %s lie on no route" % [stack[0], stack[1], stack[2], off])
	assert_true(stumped >= 1, "some stack has stumps, so the rules are exercised")


## RULES 3.9 and 14.2, and TUNING_R5.md 1.6 as for tunnels: on every stack with stumps the twin step is the shortcut
## that walkers take with no gates, and some placement of the run's first gate that seals nothing closes the way into it
## and sends them the long way: the entrance with the fewest steps in reach gains at least STUMP_DETOUR_MIN of them. A
## walker is out of reach for its whole twin step, so a twin step counts as a step out of reach.
func test_every_stump_stack_has_a_gate_that_closes_the_way_in() -> void:
	var stumped: int = 0
	for stack: Array in _stacks():
		var level: LevelData = _build(stack)
		if level == null:
			fail("%s / %s / %s does not build" % stack)
			continue
		if Rules.stump_tiles(level).is_empty():
			continue
		stumped += 1
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var open_dist: PackedInt32Array = map.distances(none)
		var stepped: bool = false
		for entrance: Vector2i in level.entrances:
			stepped = stepped or Rules.twin_steps(map.route(entrance, open_dist)) >= 1
		assert_true(stepped, "%s / %s / %s: with no gates some walkers take a twin step" % stack)
		var open_reach: int = _least_off_stumps(level, map, open_dist)
		var best: int = open_reach
		for socket: Vector2i in level.sockets:
			var closed: Array[Vector2i] = [socket]
			if not map.seals(closed):
				best = maxi(best, _least_off_stumps(level, map, map.distances(closed)))
		assert_true(best - open_reach >= STUMP_DETOUR_MIN, "%s / %s / %s: the best gate adds %d steps in reach, needs %d" % [stack[0], stack[1], stack[2], best - open_reach, STUMP_DETOUR_MIN])
	assert_true(stumped >= 1, "some stack has stumps, so the rule is exercised")


## The fewest steps in reach on any entrance's route over `dist`: its steps less its twin steps.
static func _least_off_stumps(level: LevelData, map: RoadMap, dist: PackedInt32Array) -> int:
	var least: int = -1
	for entrance: Vector2i in level.entrances:
		var route: Array[Vector2i] = map.route(entrance, dist)
		var reach: int = route.size() - 1 - Rules.twin_steps(route)
		least = reach if least < 0 else mini(least, reach)
	return least


# Packs by tier (RULES 14.3, 14.9)

## RULES 14.3: every pack shows each tier 1 to 4 creature it uses as if it were new: in the first group
## of the first wave of the pack that has it, with no group of that wave starting before it, and at most
## one such creature a wave. Bosses count, since a tier lists them too.
func test_every_pack_shows_its_tier_creatures_as_if_new() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var tiered: Dictionary = _creature_tiers()
	var checked: int = 0
	for pack: Dictionary in data.packs:
		var met: Array[String] = []
		var waves: Array = pack["waves"]
		for w: int in waves.size():
			var groups: Array = (waves[w] as Dictionary)["groups"]
			var first_here: Array[String] = []
			for raw: Variant in groups:
				var enemy: String = String((raw as Dictionary)["enemy"])
				if tiered.has(enemy) and not met.has(enemy) and not first_here.has(enemy):
					first_here.append(enemy)
			assert_true(first_here.size() <= 1, "%s wave %d shows two tier creatures as new %s" % [pack["id"], w + 1, first_here])
			if first_here.is_empty():
				continue
			checked += 1
			var first: Dictionary = groups[0]
			assert_eq(String(first["enemy"]), first_here[0], "%s wave %d: %s comes in the first group" % [pack["id"], w + 1, first_here[0]])
			for raw: Variant in groups:
				assert_true(int((raw as Dictionary)["at_ms"]) >= int(first["at_ms"]), "%s wave %d: no group starts before %s" % [pack["id"], w + 1, first_here[0]])
			met.append_array(first_here)
	assert_true(checked >= 1, "some pack uses a tier creature, so the rule is exercised")


## RULES 14.3: each content tier adds packs that use its creatures in every band from the first band
## where a pack can show them (TIER_FIRST_BAND) to band 5, and each of its creatures is in some pack.
func test_each_tier_adds_packs_in_its_bands() -> void:
	if data == null:
		fail("the run files do not load")
		return
	for t: int in data.tiers.size():
		var tier: int = t + 1
		assert_true(TIER_FIRST_BAND.has(tier), "tier %d has a planned first band" % tier)
		var used: Dictionary = {}
		for band: int in range(1, RunData.BANDS + 1):
			var count: int = 0
			for pack: Dictionary in data.packs_of(band, &"", tier):
				if int(pack["tier"]) != tier:
					continue
				count += 1
				for wave: Variant in pack["waves"]:
					for group: Variant in (wave as Dictionary)["groups"]:
						used[String((group as Dictionary)["enemy"])] = true
			if band >= int(TIER_FIRST_BAND.get(tier, 1)) and band < RunData.BANDS:
				assert_true(count >= 1, "tier %d has a pack in band %d" % [tier, band])
		for creature: Variant in (data.tiers[t] as Dictionary)["creatures"]:
			assert_true(used.has(String(creature)), "tier %d's %s is in some pack" % [tier, creature])


## RULES 12.5: at most 6 Mistwisps and 6 Hootlings in a pack wave, counted as the 120 bound counts them:
## with no risk card and with each risk card in turn (the boss wave never gets one), boss summons not counted.
func test_at_most_6_mistwisps_and_hootlings_a_pack_wave() -> void:
	if data == null:
		fail("the run files do not load")
		return
	var risks: Array[Array] = [[]]
	for id: StringName in data.card_ids(_top_tier()):
		var card: Dictionary = data.card(id)
		if card["kind"] == &"risk":
			risks.append(card["effects"])
	var checked: int = 0
	for pack: Dictionary in data.packs:
		var waves: Array = pack["waves"]
		for w: int in waves.size():
			var boss_wave: bool = int(pack["band"]) == RunData.BANDS and w == waves.size() - 1
			var groups: Array = (waves[w] as Dictionary)["groups"]
			for effects_raw: Array in risks:
				if boss_wave and not effects_raw.is_empty():
					continue
				var effects: Array[Dictionary] = []
				effects.assign(effects_raw)
				for capped: String in CAPPED_CREATURES:
					var total: int = 0
					for raw: Variant in groups:
						var group: Dictionary = raw
						if String(group["enemy"]) == capped:
							checked += 1
							total += Modifiers.group_count(effects, int(group["count"]), false, false)
					for effect: Dictionary in effects:
						if effect["type"] == "add_group" and String(effect["enemy"]) == capped:
							total += int(effect["count"])
					assert_true(total <= CAPPED_MOST, "%s wave %d brings %d %s with %s, at most %d" % [pack["id"], w + 1, total, capped, effects, CAPPED_MOST])
	assert_true(checked >= 1, "some pack brings Mistwisps, so the cap is exercised")
