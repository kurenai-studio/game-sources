# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunData
extends RefCounted
## The run plan, the segments, the wave packs and the cards, checked and held
## (docs/ARCHITECTURE.md 2.9 to 2.11). src/save/ reads the files and passes the parsed
## values in one Dictionary keyed by path under data/ (2.12). Read only.

## A run has 6 bands of 3 waves: 18 waves and 17 drafts (2.10). Fixed in code, not data.
const BANDS: int = 6
const FORMAT: int = 1
## Content tiers above tier 0 (docs/ARCHITECTURE.md 14.8).
const MAX_TIERS: int = 4
## The map feature characters a tier may list (14.2).
const TIER_FEATURES: String = "TX^v<>PQ"
const TIER_KEYS: PackedStringArray = ["level", "towers", "creatures", "bosses", "grid"]
const RUN_FILE: String = "runs/run.json"
const CARDS_FILE: String = "cards/cards.json"
const INDEX_FILE: String = "segments/index.json"
const PACKS_FILE: String = "segments/packs.json"
const SEGMENT_DIR: String = "segments/"
const RUN_KEYS: PackedStringArray = [
	"format", "strength_start", "strength_step", "start_gold", "gates", "towers", "rows",
	"spots", "sockets", "bands", "weights", "tiers",
]
const ROW_KINDS: PackedStringArray = ["top", "middle", "bottom"]
## The card kinds in draft order (3.4).
const WEIGHT_KINDS: PackedStringArray = ["tower", "perk", "gate", "economy", "risk"]

# The run plan (2.10).
var strength_start: int = 100
var strength_step: int = 10
var start_gold: int = 0
var gates: int = 0
var towers: Array[StringName] = []
var rows: Dictionary = {}                                # {"top": int, "middle": int, "bottom": int}
var spots_min: int = 0
var spots_max: int = 0
var sockets_min: int = 0
var sockets_max: int = 0
var bands: Array[Array] = []                             # six lists of StringName: the creatures each band adds
var weights: Dictionary[StringName, int] = {}            # card kind to draft weight
## The content tiers, tier 1 first (14.8): {"level": StringName, "towers", "creatures",
## "bosses": Array[StringName], "grid": String}. Empty until regions 5 to 8 have data.
var tiers: Array[Dictionary] = []

# The files. Segments, packs and cards keep the order of their files.
var segment_ids: Array[StringName] = []
var packs: Array[Dictionary] = []
var cards: Array[Dictionary] = []

var _segments: Dictionary[StringName, Dictionary] = {}
var _card_index: Dictionary[StringName, int] = {}
var _bosses: Array[StringName] = []
## What each tier lists, worked out when run.json is read: the tier of a tower, a creature or
## boss, and a map feature character. Anything not listed is tier 0.
var _tower_tiers: Dictionary[StringName, int] = {}
var _creature_tiers: Dictionary[StringName, int] = {}
var _feature_tiers: Dictionary[String, int] = {}


## Every problem in the parsed files; empty when valid. files holds "runs/run.json",
## "cards/cards.json", "segments/index.json", "segments/packs.json" and
## "segments/<id>.json" for each listed id (a missing one is left out and reported).
static func check(files: Dictionary, catalog: Catalog) -> PackedStringArray:
	var built: Array = _build(files, catalog)
	return built[1]


## Null when check() finds anything.
static func from_data(files: Dictionary, catalog: Catalog) -> RunData:
	var built: Array = _build(files, catalog)
	var problems: PackedStringArray = built[1]
	if not problems.is_empty():
		return null
	return built[0]


## {} when unknown, else {"id", "kind", "tower" (&"" for none), "name", "text", "once",
## "unlock" ({} or {"counter", "at"}), "effects", "tier"}.
func card(id: StringName) -> Dictionary:
	if not _card_index.has(id):
		return {}
	return cards[_card_index[id]].duplicate(true)


## Every card of that tier or below, in cards.json order. The daily uses all of them.
func card_ids(tier: int = 0) -> Array[StringName]:
	var out: Array[StringName] = []
	for item: Dictionary in cards:
		if int(item["tier"]) <= tier:
			out.append(item["id"])
	return out


## The base cards plus every card whose counter has reached its `at`, in cards.json
## order. counters is Progress.unlock_counters(): counter names (StringName or String)
## to whole numbers. A counter that is missing, or not a number, counts as 0. Cards above
## the tier are left out (14.8).
func pool(counters: Dictionary, tier: int = 0) -> Array[StringName]:
	var values: Dictionary[String, int] = {}
	for key: Variant in counters.keys():
		var value: Variant = counters[key]
		if (typeof(key) == TYPE_STRING or typeof(key) == TYPE_STRING_NAME) and typeof(value) == TYPE_INT:
			values[String(key)] = value
	var out: Array[StringName] = []
	for item: Dictionary in cards:
		if int(item["tier"]) > tier:
			continue
		var unlock: Dictionary = item["unlock"]
		if unlock.is_empty() or values.get(unlock["counter"], 0) >= int(unlock["at"]):
			out.append(item["id"])
	return out


## {} when unknown, else {"id", "kind", "grid", "top_ports", "bottom_ports", "spots", "sockets",
## "tier"}.
func segment(id: StringName) -> Dictionary:
	if not _segments.has(id):
		return {}
	return _segments[id].duplicate(true)


## The segments of one kind (&"top", &"middle" or &"bottom") of that tier or below, in
## index order.
func segments_of(kind: StringName, tier: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in segment_ids:
		if _segments[id]["kind"] == kind and int(_segments[id]["tier"]) <= tier:
			out.append(_segments[id].duplicate(true))
	return out


## The middle segments that fit under a segment (their top ports equal its bottom ports),
## or the bottom segments that fit under a middle one, of that tier or below. In index order.
func segments_under(upper_id: StringName, tier: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not _segments.has(upper_id):
		return out
	var upper: Dictionary = _segments[upper_id]
	var wanted: StringName = &"middle" if upper["kind"] == &"top" else &"bottom"
	if upper["kind"] == &"bottom":
		return out
	for id: StringName in segment_ids:
		var lower: Dictionary = _segments[id]
		if lower["kind"] == wanted and int(lower["tier"]) <= tier and RunSegments.fits(upper, lower):
			out.append(lower.duplicate(true))
	return out


## The packs of one band of that tier or below, in packs.json order. For band 6, boss limits
## them to the packs naming that boss (&"" for all).
func packs_of(band: int, boss: StringName = &"", tier: int = 0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for pack: Dictionary in packs:
		if pack["band"] == band and int(pack["tier"]) <= tier and (boss == &"" or pack["boss"] == boss):
			out.append(pack.duplicate(true))
	return out


## The bosses that have a band 6 pack of that tier or below, in enemies.json order.
func boss_ids(tier: int = 0) -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _bosses:
		for pack: Dictionary in packs:
			if pack["band"] == BANDS and pack["boss"] == id and int(pack["tier"]) <= tier:
				out.append(id)
				break
	return out


## [RunData, PackedStringArray of problems].
static func _build(files: Dictionary, catalog: Catalog) -> Array:
	var data: RunData = new()
	var problems: PackedStringArray = PackedStringArray()
	if catalog == null or catalog.rules == null:
		problems.append("run: needs a valid catalog")
		return [data, problems]
	data._read_all(files, catalog, problems)
	return [data, problems]


func _read_all(files: Dictionary, catalog: Catalog, problems: PackedStringArray) -> void:
	var plan_ok: bool = false
	if not files.has(RUN_FILE):
		problems.append("run.json: is missing")
	else:
		var chk: DataCheck = DataCheck.new("run.json")
		_read_plan(files[RUN_FILE], catalog, chk)
		problems.append_array(chk.problems)
		plan_ok = chk.ok()
	var start_towers: Array[StringName] = []
	if plan_ok:
		start_towers = towers
	else:
		# Without a usable run.json nothing is known about tiers: everything is tier 0.
		_tower_tiers.clear()
		_creature_tiers.clear()
		_feature_tiers.clear()
		tiers.clear()
	if not files.has(CARDS_FILE):
		problems.append("cards.json: is missing")
	else:
		cards = RunCards.read(files[CARDS_FILE], catalog, start_towers, problems, _tower_tiers, _creature_tiers)
		for i: int in cards.size():
			_card_index[cards[i]["id"]] = i
	var risks: Array = []
	for item: Dictionary in cards:
		if item["kind"] == &"risk":
			risks.append({"id": item["id"], "effects": item["effects"]})
	var listed: Array[StringName] = []
	if not files.has(INDEX_FILE):
		problems.append("index.json: is missing")
	else:
		listed = RunSegments.read_index(files[INDEX_FILE], problems)
	_read_segments(files, listed, rows if plan_ok else {}, problems)
	if not files.has(PACKS_FILE):
		problems.append("packs.json: is missing")
	else:
		var band_lists: Array = bands if plan_ok else []
		packs = RunPacks.read(files[PACKS_FILE], catalog, band_lists, risks, problems, _creature_tiers)
		for id: StringName in catalog.enemy_ids():
			for pack: Dictionary in packs:
				if pack["band"] == BANDS and pack["boss"] == id:
					_bosses.append(id)
					break
	_check_file_keys(files, listed, problems)


func _read_segments(files: Dictionary, listed: Array[StringName], row_counts: Dictionary, problems: PackedStringArray) -> void:
	var found: Array[Dictionary] = []
	for id: StringName in listed:
		var path: String = "%s%s.json" % [SEGMENT_DIR, id]
		if not files.has(path):
			problems.append("%s.json: is missing" % id)
			continue
		var segment_data: Dictionary = RunSegments.read_segment(files[path], id, row_counts, problems, _feature_tiers)
		if not segment_data.is_empty():
			found.append(segment_data)
	if not listed.is_empty() and found.size() == listed.size():
		_check_coverage(found, problems)
		for segment_data: Dictionary in found:
			_segments[segment_data["id"]] = segment_data
			segment_ids.append(segment_data["id"])


## The coverage of 2.9 at every tier from 0 to the tier count, over the segments of that tier
## and below. A problem already named at a lower tier is not named again.
func _check_coverage(found: Array[Dictionary], problems: PackedStringArray) -> void:
	var named: PackedStringArray = PackedStringArray()
	for tier: int in tiers.size() + 1:
		var subset: Array[Dictionary] = []
		for segment_data: Dictionary in found:
			if int(segment_data["tier"]) <= tier:
				subset.append(segment_data)
		var found_here: PackedStringArray = PackedStringArray()
		RunSegments.check_coverage(subset, found_here)
		for line: String in found_here:
			if not named.has(line):
				named.append(line)
				problems.append(line if tier == 0 else "tier %d: %s" % [tier, line])


## An entry the contract does not name is a problem (the index is the only list of segments).
func _check_file_keys(files: Dictionary, listed: Array[StringName], problems: PackedStringArray) -> void:
	var known: PackedStringArray = [RUN_FILE, CARDS_FILE, INDEX_FILE, PACKS_FILE]
	for id: StringName in listed:
		known.append("%s%s.json" % [SEGMENT_DIR, id])
	for key: Variant in files.keys():
		if typeof(key) != TYPE_STRING or not known.has(key):
			problems.append("files: unexpected entry %s" % str(key).left(40).c_escape())


func _read_plan(raw: Variant, catalog: Catalog, chk: DataCheck) -> void:
	if not chk.object(raw, "", RUN_KEYS):
		return
	var top: Dictionary = raw
	chk.integer(top, "format", "", FORMAT, FORMAT)
	strength_start = chk.integer(top, "strength_start", "", 50, 1000, 1, 100)
	strength_step = chk.integer(top, "strength_step", "", 0, 100)
	# Waves 1 to 17 rise by the step. Wave 18 takes its pack's own strength (2.9).
	if strength_start + strength_step * (BANDS * 3 - 2) > 1000:
		chk.fail("strength_step", "wave %d's strength must be at most 1000" % (BANDS * 3 - 1))
	start_gold = chk.integer(top, "start_gold", "", 0, 100000, 10)
	gates = chk.integer(top, "gates", "", 0, catalog.rules.max_gates)
	var tower_list: Array = chk.array(top, "towers", "", 1, 6)
	for i: int in tower_list.size():
		var id: StringName = chk.ident_value(tower_list[i], "towers[%d]" % i)
		if id == &"":
			continue
		if not catalog.has_tower(id):
			chk.fail("towers[%d]" % i, "names no tower")
		elif towers.has(id):
			chk.fail("towers[%d]" % i, "repeats %s" % id)
		else:
			towers.append(id)
	_read_rows(top.get("rows", null), chk)
	var spot_range: Vector2i = _read_range(top.get("spots", null), "spots", 1, LevelData.MAX_SPOTS, chk)
	spots_min = spot_range.x
	spots_max = spot_range.y
	var socket_range: Vector2i = _read_range(top.get("sockets", null), "sockets", 0, LevelData.MAX_SOCKETS, chk)
	sockets_min = socket_range.x
	sockets_max = socket_range.y
	_read_bands(top.get("bands", null), catalog, chk)
	_read_weights(top.get("weights", null), chk)
	_read_tiers(top.get("tiers", null), catalog, chk)


func _read_rows(raw: Variant, chk: DataCheck) -> void:
	if not chk.object(raw, "rows", ROW_KINDS):
		return
	var item: Dictionary = raw
	var sum: int = 0
	for kind: String in ROW_KINDS:
		var count: int = chk.integer(item, kind, "rows", 1, 11, 1, 1)
		rows[kind] = count
		sum += count
	if sum < Sim.MAP_ROWS_MIN or sum > Sim.MAP_ROWS_MAX:
		chk.fail("rows", "must add up to %d to %d rows" % [Sim.MAP_ROWS_MIN, Sim.MAP_ROWS_MAX])


## [lo, hi] with lo_floor <= lo <= hi <= hi_ceiling.
func _read_range(raw: Variant, path: String, lo_floor: int, hi_ceiling: int, chk: DataCheck) -> Vector2i:
	var pair: Vector2i = chk.pair(raw, path, lo_floor, hi_ceiling)
	if pair.x >= lo_floor and pair.y >= lo_floor and pair.x > pair.y:
		chk.fail(path, "the low end must not be above the high end")
	return pair


func _read_bands(raw: Variant, catalog: Catalog, chk: DataCheck) -> void:
	var lists: Array = chk.array_value(raw, "bands", BANDS, BANDS)
	var seen: Array[StringName] = []
	for b: int in lists.size():
		var path: String = "bands[%d]" % b
		var creatures: Array = chk.array_value(lists[b], path, 0, 64)
		var band: Array[StringName] = []
		for i: int in creatures.size():
			var id: StringName = chk.ident_value(creatures[i], "%s[%d]" % [path, i])
			if id == &"":
				continue
			var type: EnemyType = catalog.enemy(id)
			if type == null:
				chk.fail("%s[%d]" % [path, i], "names no creature")
			elif type.boss or id == &"puff":
				chk.fail("%s[%d]" % [path, i], "%s cannot be listed in a band" % id)
			elif seen.has(id):
				chk.fail("%s[%d]" % [path, i], "%s is in more than one band" % id)
			else:
				seen.append(id)
				band.append(id)
		bands.append(band)


func _read_weights(raw: Variant, chk: DataCheck) -> void:
	if not chk.object(raw, "weights", WEIGHT_KINDS):
		return
	var item: Dictionary = raw
	var sum: int = 0
	for kind: String in WEIGHT_KINDS:
		var weight: int = chk.integer(item, kind, "weights", 0, 1000)
		weights[StringName(kind)] = weight
		sum += weight
	if sum <= 0:
		chk.fail("weights", "at least one weight must be above 0")
	if weights.get(&"economy", 0) <= 0:
		chk.fail("weights.economy", "must be above 0, so a draft is never empty")


## run.json `tiers` (14.8): 0 to 4 entries, tier 1 first. Each tower, creature, boss and map
## feature character is listed in at most one tier.
func _read_tiers(raw: Variant, catalog: Catalog, chk: DataCheck) -> void:
	var list: Array = chk.array_value(raw, "tiers", 0, MAX_TIERS)
	var seen_towers: Array[StringName] = []
	var seen_creatures: Array[StringName] = []
	var seen_bosses: Array[StringName] = []
	var seen_chars: String = ""
	for t: int in list.size():
		var path: String = "tiers[%d]" % t
		if not chk.object(list[t], path, TIER_KEYS):
			continue
		var item: Dictionary = list[t]
		var level: StringName = chk.ident(item, "level", path)
		var tower_ids: Array[StringName] = []
		var tower_list: Array = chk.array(item, "towers", path, 0, 10)
		for i: int in tower_list.size():
			var id: StringName = chk.ident_value(tower_list[i], "%s.towers[%d]" % [path, i])
			if id == &"":
				continue
			if not catalog.has_tower(id):
				chk.fail("%s.towers[%d]" % [path, i], "names no tower")
			elif towers.has(id):
				chk.fail("%s.towers[%d]" % [path, i], "%s is a tower the run starts with" % id)
			elif seen_towers.has(id):
				chk.fail("%s.towers[%d]" % [path, i], "%s is in more than one tier" % id)
			else:
				seen_towers.append(id)
				tower_ids.append(id)
				_tower_tiers[id] = t + 1
		var creature_ids: Array[StringName] = []
		var creature_list: Array = chk.array(item, "creatures", path, 0, 64)
		for i: int in creature_list.size():
			var id: StringName = chk.ident_value(creature_list[i], "%s.creatures[%d]" % [path, i])
			if id == &"":
				continue
			var type: EnemyType = catalog.enemy(id)
			if type == null:
				chk.fail("%s.creatures[%d]" % [path, i], "names no creature")
			elif type.boss or id == &"puff":
				chk.fail("%s.creatures[%d]" % [path, i], "%s cannot be listed as a creature" % id)
			elif seen_creatures.has(id):
				chk.fail("%s.creatures[%d]" % [path, i], "%s is in more than one tier" % id)
			else:
				seen_creatures.append(id)
				creature_ids.append(id)
				_creature_tiers[id] = t + 1
		var boss_ids_here: Array[StringName] = []
		var boss_list: Array = chk.array(item, "bosses", path, 0, 8)
		for i: int in boss_list.size():
			var id: StringName = chk.ident_value(boss_list[i], "%s.bosses[%d]" % [path, i])
			if id == &"":
				continue
			var type: EnemyType = catalog.enemy(id)
			if type == null or not type.boss:
				chk.fail("%s.bosses[%d]" % [path, i], "names no boss")
			elif seen_bosses.has(id):
				chk.fail("%s.bosses[%d]" % [path, i], "%s is in more than one tier" % id)
			else:
				seen_bosses.append(id)
				boss_ids_here.append(id)
				_creature_tiers[id] = t + 1
		var features: String = ""
		var grid_value: Variant = item.get("grid", null)
		if not DataCheck.is_string(grid_value) or String(grid_value).length() > TIER_FEATURES.length():
			chk.fail("%s.grid" % path, "must be 0 to %d characters of %s" % [TIER_FEATURES.length(), TIER_FEATURES])
		else:
			for ch: String in String(grid_value):
				if TIER_FEATURES.find(ch) < 0:
					chk.fail("%s.grid" % path, "has %s, which is not a map feature" % ch.c_escape())
				elif seen_chars.contains(ch):
					chk.fail("%s.grid" % path, "%s is in more than one tier, or repeated" % ch)
				else:
					seen_chars += ch
					features += ch
					_feature_tiers[ch] = t + 1
		tiers.append({
			"level": level, "towers": tower_ids, "creatures": creature_ids,
			"bosses": boss_ids_here, "grid": features,
		})
