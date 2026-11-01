# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Progress
extends RefCounted
## Stars, Twists won, first sights and unlock counters, saved in progress.json
## (docs/ARCHITECTURE.md 3.5, 5.5), with the unlock rules of RULES 16.

const FORMAT: int = 1
## Most entries in levels, twists and seen. Far above the 24 campaign levels and 40 ids.
const MAX_ENTRIES: int = 512
## Ceiling of every counter. Counters saturate here, so a save never holds a value its check refuses.
const COUNTER_MAX: int = 1000000000
## The five counters of RULES 14.6.
const COUNTERS: Array[StringName] = [&"best_run_wave", &"runs_won", &"runs_won_normal", &"dailies_finished", &"risky_wins"]
const ALL_STARS: int = 7

var levels: Dictionary[StringName, int] = {}           # level id to star bits 0 to 7, the union of every win
var twists: Array[StringName] = []                     # levels whose Twist was won
var seen: Array[StringName] = []                       # towers, creatures and levels whose card or hint already showed
var counters: Dictionary[StringName, int] = {}


func _init() -> void:
	for counter: StringName in COUNTERS:
		counters[counter] = 0


## Adds star bits to a level's record. Each star is kept for good (RULES 10.4).
func record_level(id: StringName, bits: int) -> void:
	if not DataCheck.is_id(id) or bits < 0 or bits > ALL_STARS:
		return
	if not levels.has(id) and levels.size() >= MAX_ENTRIES:
		return
	levels[id] = levels.get(id, 0) | bits


func record_twist(id: StringName) -> void:
	_add_id(twists, id)


func mark_seen(id: StringName) -> void:
	_add_id(seen, id)


## Adds to a counter, saturating at COUNTER_MAX. Unknown counters and negative amounts do nothing.
func bump(counter: StringName, amount: int) -> void:
	if not counters.has(counter) or amount <= 0:
		return
	var value: int = counters[counter]
	counters[counter] = COUNTER_MAX if amount >= COUNTER_MAX - value else value + amount


## Keeps the larger value, for best_run_wave.
func raise(counter: StringName, value: int) -> void:
	if not counters.has(counter):
		return
	counters[counter] = maxi(counters[counter], clampi(value, 0, COUNTER_MAX))


## Star marks over every recorded level.
func stars() -> int:
	var total: int = 0
	for id: StringName in levels:
		var bits: int = levels[id] & ALL_STARS
		total += (bits & 1) + ((bits >> 1) & 1) + ((bits >> 2) & 1)
	return total


## A level is cleared once it has been won: every win earns star 1.
func cleared(id: StringName) -> bool:
	return (levels.get(id, 0) & 1) != 0


## RULES 16: the first level of an open region is open; any other level opens when
## the level before it in its region is cleared.
func level_open(game: GameData, id: StringName) -> bool:
	if game == null:
		return false
	for index: int in game.campaign.size():
		var list: Array[StringName] = game.campaign[index]["levels"]
		var at: int = list.find(id)
		if at < 0:
			continue
		if not region_open(game, index):
			return false
		return at == 0 or cleared(list[at - 1])
	return false


## RULES 16: region 1 is open from the start. Each later region needs the last level
## of the region before it cleared and the star count in rules.json.
func region_open(game: GameData, index: int) -> bool:
	if game == null or game.catalog == null or index < 0 or index >= game.campaign.size():
		return false
	if index == 0:
		return true
	var needs: Array[int] = game.catalog.rules.region_stars
	if index >= needs.size():
		return false
	var before: Array[StringName] = game.campaign[index - 1]["levels"]
	if before.is_empty() or not cleared(before.back()):
		return false
	return stars() >= needs[index]


## The roguelite and the daily (RULES 16).
func runs_open(game: GameData) -> bool:
	if game == null or game.catalog == null:
		return false
	return stars() >= game.catalog.rules.run_stars


## The player's content tier for runs and the daily (RULES 14.9, contract 14.8): how many
## of run.json's tiers have their `level` cleared. It comes from the level records, which
## keep every star for good, so it only grows. 0 without run data.
func tier(game: GameData) -> int:
	if game == null or game.run == null:
		return 0
	var count: int = 0
	for item: Dictionary in game.run.tiers:
		if cleared(item["level"]):
			count += 1
	return count


## A level's Twist needs 3 stars on that level.
func twist_open(id: StringName) -> bool:
	return (levels.get(id, 0) & ALL_STARS) == ALL_STARS


## The counters plus "stars" and "twists_cleared", for the card pool (phase 7).
func unlock_counters() -> Dictionary:
	var out: Dictionary[StringName, int] = {}
	for counter: StringName in COUNTERS:
		out[counter] = counters[counter]
	out[&"stars"] = stars()
	out[&"twists_cleared"] = twists.size()
	return out


func to_data() -> Dictionary:
	var level_out: Dictionary = {}
	for id: StringName in levels:
		level_out[String(id)] = levels[id]
	var counter_out: Dictionary = {}
	for counter: StringName in COUNTERS:
		counter_out[String(counter)] = counters[counter]
	return {
		"format": FORMAT, "levels": level_out, "twists": _id_strings(twists),
		"seen": _id_strings(seen), "counters": counter_out,
	}


## Any bad field or entry falls back to its default. Unknown keys and counters are dropped.
## Unknown but well formed level ids are kept, so a later version's progress survives.
static func from_data(data: Variant) -> Progress:
	var progress: Progress = new()
	if typeof(data) != TYPE_DICTIONARY:
		return progress
	var top: Dictionary = data
	var level_value: Variant = top.get("levels", null)
	if typeof(level_value) == TYPE_DICTIONARY and (level_value as Dictionary).size() <= MAX_ENTRIES:
		var level_data: Dictionary = level_value
		for key: Variant in level_data:
			var bits: Variant = level_data[key]
			if DataCheck.is_id(key) and DataCheck.is_whole(bits) and int(bits) >= 0 and int(bits) <= ALL_STARS:
				progress.levels[StringName(String(key))] = int(bits)
	progress.twists = _read_ids(top.get("twists", null))
	progress.seen = _read_ids(top.get("seen", null))
	var counter_value: Variant = top.get("counters", null)
	if typeof(counter_value) == TYPE_DICTIONARY:
		var counter_data: Dictionary = counter_value
		for counter: StringName in COUNTERS:
			var value: Variant = counter_data.get(String(counter), null)
			if DataCheck.is_whole(value) and int(value) >= 0 and int(value) <= COUNTER_MAX:
				progress.counters[counter] = int(value)
	return progress


## An array of at most MAX_ENTRIES ids. Bad items and repeats are dropped; a bad array gives [].
static func _read_ids(value: Variant) -> Array[StringName]:
	var out: Array[StringName] = []
	if typeof(value) != TYPE_ARRAY or (value as Array).size() > MAX_ENTRIES:
		return out
	for item: Variant in value:
		if DataCheck.is_id(item):
			var id: StringName = StringName(String(item))
			if not out.has(id):
				out.append(id)
	return out


static func _id_strings(ids: Array[StringName]) -> Array:
	var out: Array = []
	for id: StringName in ids:
		out.append(String(id))
	return out


static func _add_id(list: Array[StringName], id: StringName) -> void:
	if DataCheck.is_id(id) and not list.has(id) and list.size() < MAX_ENTRIES:
		list.append(id)
