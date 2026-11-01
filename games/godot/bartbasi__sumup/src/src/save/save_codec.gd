class_name SaveCodec extends RefCounted
## Turns the run and the profile into JSON shaped data and back
## (docs/ARCHITECTURE.md sections 10 and 17, GDD 15.1). Pure: no files.
## SaveService does the reading and writing.
##
## Godot's JSON parser returns every number as a float, which cannot hold a
## large integer exactly. So tiles are stored as exponents (2 is 1, 1024 is
## 10, 2^56 is 56) and scores and points as strings of decimal digits. Since
## 2026-10-21 neither has a 64 bit limit: exponents go up to max_exponent and
## digit strings up to the length of 2^max_score_bits, with the value below
## 2^max_score_bits (GDD D-37). The format itself did not change, so every
## earlier save loads unchanged and writes back byte for byte the same.
##
## Loading trusts nothing. The input is only ever plain JSON values
## (Dictionary, Array, String, float, bool, null), and nothing here turns data
## into objects or code. Every field is checked for type, exact keys and range.
## Numbers may arrive as float (from the JSON parser) or int (from code); both
## must be whole and in range. A digit string is refused by its length before
## any of it is converted, so a huge one costs nothing.
##
## Run files are written as format 2. A format 1 run file, from builds before
## D-46, still loads: it has exactly the format 1 keys, and loads with
## free_used 0 and best_at_start null (unknown). Anything else is invalid.
##
## A state whose best_at_start is null is never written. run_to_data encodes
## it as JSON null, which data_to_run refuses, so SaveService refuses the save
## and the last good file stays. In play this never happens: GameSession sets
## best_at_start when a run starts, and on resume turns null into the loaded
## Best Score (ARCHITECTURE.md section 5), so the next save writes that value.

const RUN_FORMAT: int = 2              # D-46 added free_used, QA6-03 best_at_start; format 1 run files still load
const PROFILE_FORMAT: int = 1

const _RUN_FORMAT_1: int = 1
const _RUN_KEYS: Array[String] = ["format", "columns", "rows", "cells", "score", "run_highest", "free_used", "best_at_start", "snapshot"]
const _RUN_KEYS_FORMAT_1: Array[String] = ["format", "columns", "rows", "cells", "score", "run_highest", "snapshot"]
const _SNAPSHOT_KEYS: Array[String] = ["cells", "points"]
const _PROFILE_KEYS: Array[String] = ["format", "settings", "records"]
const _SETTINGS_KEYS: Array[String] = ["sound_on", "skin"]
const _RECORDS_KEYS: Array[String] = ["best_score", "best_tile"]

const _MIN_SNAPSHOT_POINTS: int = 4        # the smallest chain, 2 + 2 (GDD 15.1)
const _SKIN_ID_MAX_LENGTH: int = 32
const _CHAR_A: int = 97
const _CHAR_Z: int = 122
const _CHAR_UNDERSCORE: int = 95
const _LOG10_2: float = 0.30102999566398120

## _max_digits worked out per max_score_bits, so it is computed once.
static var _digits_for_bits: Dictionary[int, int] = {}


## The run in the save format, always format 2. A state that breaks a rule (an
## empty cell, a negative score, free_used above what was earned,
## best_at_start null) still encodes, but data_to_run refuses the result, and
## SaveService checks that before it writes.
@warning_ignore("integer_division")
static func run_to_data(state: RunState) -> Dictionary:
	if state == null:
		return {}
	var rows: int = 0
	if state.columns > 0:
		rows = state.cells.size() / state.columns
	var snapshot: Variant = null
	if state.has_snapshot():
		snapshot = {
			"cells": _list_of(state.snapshot_cells),
			"points": _text_of(state.snapshot_points),
		}
	return {
		"format": RUN_FORMAT,
		"columns": state.columns,
		"rows": rows,
		"cells": _list_of(state.cells),
		"score": _text_of(state.score),
		"run_highest": state.run_highest,
		"free_used": state.free_used,
		"best_at_start": _text_of(state.best_at_start),
		"snapshot": snapshot,
	}


## TH18. The run in data, or null when anything about it is invalid. Follows
## GDD 15.1 exactly: format 2 with exactly its keys, or format 1 with exactly
## the format 1 keys; the board size of config; every exponent from 1 to
## config.max_exponent; a score of 0 or more and below 2^max_score_bits; a run
## highest tile at least the highest exponent on the board and on the snapshot
## board; a snapshot that is null or a full board plus points of 4 or more
## (and below the ceiling). Format 2 also needs free_used, a whole number from
## 0 up to CoreRules.free_earned(run_highest), and best_at_start, a digit
## string under the same ceiling (not checked against the records). Format 1
## loads with free_used 0 and best_at_start null.
static func data_to_run(data: Variant, config: GameConfig) -> RunState:
	if config == null or config.columns < 1 or config.rows < 1 or config.max_exponent < 1 or config.max_score_bits < 1:
		return null
	if typeof(data) != TYPE_DICTIONARY:
		return null
	var run: Dictionary = data
	if not run.has("format"):
		return null
	var format: int = _read_whole(run["format"], _RUN_FORMAT_1, RUN_FORMAT)
	if format == RUN_FORMAT:
		if not _has_exact_keys(run, _RUN_KEYS):
			return null
	elif format == _RUN_FORMAT_1:
		if not _has_exact_keys(run, _RUN_KEYS_FORMAT_1):
			return null
	else:
		return null
	if _read_whole(run["columns"], config.columns, config.columns) < 0:
		return null
	if _read_whole(run["rows"], config.rows, config.rows) < 0:
		return null
	var cells: PackedInt64Array = _read_board(run["cells"], config.cell_count(), config.max_exponent)
	if cells.is_empty():
		return null
	var score: BigNum = _read_number(run["score"], config.max_score_bits)
	if score == null:
		return null
	var run_highest: int = _read_whole(run["run_highest"], 1, config.max_exponent)
	if run_highest < 0:
		return null
	var snapshot_cells: PackedInt64Array = PackedInt64Array()
	var snapshot_points: BigNum = null
	var snapshot_data: Variant = run["snapshot"]
	if typeof(snapshot_data) != TYPE_NIL:
		if typeof(snapshot_data) != TYPE_DICTIONARY:
			return null
		var snapshot: Dictionary = snapshot_data
		if not _has_exact_keys(snapshot, _SNAPSHOT_KEYS):
			return null
		snapshot_cells = _read_board(snapshot["cells"], config.cell_count(), config.max_exponent)
		if snapshot_cells.is_empty():
			return null
		snapshot_points = _read_number(snapshot["points"], config.max_score_bits)
		if snapshot_points == null or snapshot_points.compare(BigNum.from_int(_MIN_SNAPSHOT_POINTS)) < 0:
			return null
	if run_highest < CoreRules.highest(cells) or run_highest < CoreRules.highest(snapshot_cells):
		return null
	var free_used: int = 0
	var best_at_start: BigNum = null
	if format == RUN_FORMAT:
		free_used = _read_whole(run["free_used"], 0, CoreRules.free_earned(run_highest, config))
		if free_used < 0:
			return null
		best_at_start = _read_number(run["best_at_start"], config.max_score_bits)
		if best_at_start == null:
			return null
	return RunState.create(cells, score, snapshot_cells, snapshot_points, run_highest, config.columns, free_used, best_at_start)


## The profile in the save format. best_tile is 0 for no tile yet, else an
## exponent.
static func profile_to_data(settings: Settings, records: Records) -> Dictionary:
	var source_settings: Settings = settings if settings != null else Settings.new()
	var source_records: Records = records if records != null else Records.new()
	return {
		"format": PROFILE_FORMAT,
		"settings": {
			"sound_on": source_settings.sound_on,
			"skin": String(source_settings.skin_id),
		},
		"records": {
			"best_score": _text_of(source_records.best_score),
			"best_tile": source_records.best_tile,
		},
	}


## Applies every valid part of a profile and returns the problems found
## (empty when the profile is fully valid).
##
## The data must be an object with format 1 (PROFILE_FORMAT), or nothing is
## applied. After that each of the four fields (settings.sound_on,
## settings.skin, records.best_score, records.best_tile) is checked on its own:
## a valid one is applied, a missing or invalid one leaves the value the
## object already holds (the default for a fresh object). Keys outside the
## format are reported and never read. Settings change through their setters,
## so their signals fire only for values that really change. The ceiling is
## GameConfig's: best_tile 0 to max_exponent, best_score below
## 2^max_score_bits.
static func data_to_profile(data: Variant, settings: Settings, records: Records) -> PackedStringArray:
	var limits: GameConfig = GameConfig.new()
	var problems: PackedStringArray = PackedStringArray()
	if typeof(data) != TYPE_DICTIONARY:
		problems.append("profile is not an object")
		return problems
	var profile: Dictionary = data
	if not profile.has("format") or _read_whole(profile["format"], PROFILE_FORMAT, PROFILE_FORMAT) < 0:
		problems.append("profile format is not %d" % PROFILE_FORMAT)
		return problems
	_report_unknown_keys(profile, _PROFILE_KEYS, "profile", problems)
	var settings_data: Dictionary = _read_part(profile, "settings", _SETTINGS_KEYS, problems)
	var records_data: Dictionary = _read_part(profile, "records", _RECORDS_KEYS, problems)

	if settings_data.has("sound_on") and typeof(settings_data["sound_on"]) == TYPE_BOOL:
		if settings != null:
			settings.set_sound_on(settings_data["sound_on"])
	else:
		problems.append("settings.sound_on is missing or invalid")

	var skin: String = ""
	if settings_data.has("skin"):
		skin = _read_skin_id(settings_data["skin"])
	if not skin.is_empty():
		if settings != null:
			settings.set_skin_id(StringName(skin))
	else:
		problems.append("settings.skin is missing or invalid")

	var best_score: BigNum = null
	if records_data.has("best_score"):
		best_score = _read_number(records_data["best_score"], limits.max_score_bits)
	if best_score != null:
		if records != null:
			records.best_score = best_score
	else:
		problems.append("records.best_score is missing or invalid")

	var best_tile: int = -1
	if records_data.has("best_tile"):
		best_tile = _read_whole(records_data["best_tile"], 0, limits.max_exponent)
	if best_tile >= 0:
		if records != null:
			records.best_tile = best_tile
	else:
		problems.append("records.best_tile is missing or invalid")
	return problems


## The most decimal digits a number below 2^bits can have: the digit count of
## 2^bits, floor(bits * log10(2)) + 1 (65600 bits give 19,748). bits * log10(2)
## is never a whole number for bits above 0, and the float error at these
## sizes is far below the distance to one, so the floor is exact.
## tests/save checks it against BigNum.pow2(bits).to_decimal().
static func _max_digits(bits: int) -> int:
	if bits < 1:
		return 1
	if not _digits_for_bits.has(bits):
		_digits_for_bits[bits] = int(floor(float(bits) * _LOG10_2)) + 1
	return _digits_for_bits[bits]


## The exponents of a board as a JSON list, unchanged.
static func _list_of(values: PackedInt64Array) -> Array:
	var list: Array = []
	for value: int in values:
		list.append(value)
	return list


## A BigNum as its digit string, or null (which never loads back) for none.
static func _text_of(value: BigNum) -> Variant:
	if value == null:
		return null
	return value.to_decimal()


## A whole number from low to high (low is 0 or more), or -1 when value is not
## one. Accepts an int, or a finite float with no fraction. Rejects everything
## else, including bool, NaN, infinity and strings.
static func _read_whole(value: Variant, low: int, high: int) -> int:
	match typeof(value):
		TYPE_INT:
			var whole: int = value
			if whole >= low and whole <= high:
				return whole
		TYPE_FLOAT:
			var number: float = value
			if is_finite(number) and number == floorf(number) and number >= float(low) and number <= float(high):
				return int(number)
	return -1


## A board of exactly count exponents from 1 to max_exponent, or an empty
## array when the data is not one.
static func _read_board(value: Variant, count: int, max_exponent: int) -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	if typeof(value) != TYPE_ARRAY:
		return cells
	var list: Array = value
	if list.size() != count:
		return cells
	for item: Variant in list:
		var exponent: int = _read_whole(item, 1, max_exponent)
		if exponent < 0:
			return PackedInt64Array()
		cells.append(exponent)
	return cells


## A string of ASCII digits with no leading zero (unless it is "0"), at most
## _max_digits(bits) long, whose value is below 2^bits, or null when value is
## not one. BigNum.parse refuses a string that is too long before reading it,
## and refuses signs, spaces, exponents and non ASCII digits.
static func _read_number(value: Variant, bits: int) -> BigNum:
	if typeof(value) != TYPE_STRING:
		return null
	var number: BigNum = BigNum.parse(value, _max_digits(bits))
	if number == null or number.bit_length() > bits:
		return null
	return number


## A skin id of 1 to 32 characters from a to z and underscore, or "" when
## value is not one.
static func _read_skin_id(value: Variant) -> String:
	if typeof(value) != TYPE_STRING:
		return ""
	var text: String = value
	if text.is_empty() or text.length() > _SKIN_ID_MAX_LENGTH:
		return ""
	for index: int in text.length():
		var code: int = text.unicode_at(index)
		if not ((code >= _CHAR_A and code <= _CHAR_Z) or code == _CHAR_UNDERSCORE):
			return ""
	return text


## True when every key is a String from keys and every one of keys is there.
static func _has_exact_keys(data: Dictionary, keys: Array[String]) -> bool:
	if data.size() != keys.size():
		return false
	for key: Variant in data:
		if typeof(key) != TYPE_STRING or not keys.has(key):
			return false
	return true


## The object under key in profile, or an empty one (after noting the
## problem) when it is missing or not an object. Unknown keys inside it are
## reported too.
static func _read_part(profile: Dictionary, key: String, keys: Array[String], problems: PackedStringArray) -> Dictionary:
	if not profile.has(key) or typeof(profile[key]) != TYPE_DICTIONARY:
		problems.append("%s is missing or not an object" % key)
		return {}
	var part: Dictionary = profile[key]
	_report_unknown_keys(part, keys, key, problems)
	return part


static func _report_unknown_keys(data: Dictionary, keys: Array[String], where: String, problems: PackedStringArray) -> void:
	for key: Variant in data:
		if typeof(key) != TYPE_STRING or not keys.has(key):
			problems.append("%s has an unknown key" % where)
			return
