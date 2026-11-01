extends "res://tests/base_test.gd"
## AT-169. Save ranges widen, and old saves load unchanged (GDD 19.17, 15.1,
## docs/ARCHITECTURE.md section 17). Plus the hostile edges of the new ranges:
## huge digit strings and exponents at and past the ceiling are refused
## quickly, and nothing freezes.
##
## Setup as AT-95: a valid profile (Best Score 5,000, Best Tile 512) and the
## control run file.

const F := preload("res://tests/save/save_fixtures.gd")

const PROFILE_TEXT: String = "{\"format\": 1, \"settings\": {\"sound_on\": true, \"skin\": \"gumdrop\"}, \"records\": {\"best_score\": \"5000\", \"best_tile\": 9}}"
const INT64_MAX: int = 9223372036854775807
## A refusal slower than this would be felt at launch. Measured on the dev
## machine: well under 200 ms for every case here.
const QUICK_MSEC: int = 1000

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()
var _profile_bytes: PackedByteArray = PackedByteArray()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()
	F.write_text(_profile_path(), PROFILE_TEXT)
	_profile_bytes = F.read_bytes(_profile_path())


func after_each() -> void:
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _profile_path() -> String:
	return _dir.path_join("profile.json")


func _control_data() -> Dictionary:
	return SaveCodec.run_to_data(F.control_run())


func _top() -> BigNum:
	return F.pow2_plus(_config.max_score_bits, -1)


func _ceiling() -> BigNum:
	return BigNum.pow2(_config.max_score_bits)


## Writes data as the run file and loads it with a fresh service, timed.
func _load_text(text: String, label: String) -> RunState:
	F.write_text(_run_path(), text)
	var start: int = Time.get_ticks_msec()
	var loaded: RunState = SaveService.new(_dir).load_run(_config)
	var spent: int = Time.get_ticks_msec() - start
	assert_true(spent < QUICK_MSEC, "%s: judged in %d ms" % [label, spent])
	return loaded


func _assert_loads(data: Dictionary, expected: RunState, label: String) -> void:
	var loaded: RunState = _load_text(F.to_text(data), label)
	assert_true(loaded != null, "%s: loads" % label)
	assert_true(loaded != null and expected.equals(loaded), "%s: equals what was saved, field by field" % label)
	_assert_profile_untouched(label)


func _assert_refused(text: String, label: String) -> void:
	assert_true(_load_text(text, label) == null, "%s: the run loader returns no run" % label)
	assert_false(_service.has_run(), "%s: the run is discarded" % label)
	_assert_profile_untouched(label)


func _assert_profile_untouched(label: String) -> void:
	assert_eq(F.read_bytes(_profile_path()), _profile_bytes, "%s: profile file untouched" % label)
	var records: Records = Records.new()
	SaveService.new(_dir).load_profile(Settings.new(), records)
	assert_eq(F.text(records.best_score), "5000", "%s: Best Score 5,000 kept" % label)
	assert_eq(records.best_tile, 9, "%s: Best Tile 512 kept" % label)


## Loads a profile with records changed and returns [records, problems].
func _load_profile_with(best_score: String, best_tile: int) -> Array:
	var data: Dictionary = JSON.parse_string(PROFILE_TEXT)
	(data["records"] as Dictionary)["best_score"] = best_score
	(data["records"] as Dictionary)["best_tile"] = best_tile
	var text: String = F.to_text(data)
	F.write_text(_profile_path(), text)
	var records: Records = Records.new()
	var start: int = Time.get_ticks_msec()
	SaveService.new(_dir).load_profile(Settings.new(), records)
	var spent: int = Time.get_ticks_msec() - start
	assert_true(spent < QUICK_MSEC, "profile judged in %d ms" % spent)
	return [records, SaveCodec.data_to_profile(JSON.parse_string(text), Settings.new(), Records.new())]


func test_at_169_a_a_cell_at_the_tile_ceiling() -> void:
	var expected: RunState = F.run(F.with_cell(F.board_d(), Vector2i(2, 0), 65535), 41286, F.board_d(), 96, 65535, 0, 38500)
	var data: Dictionary = _control_data()
	(data["cells"] as Array)[2] = 65535
	data["run_highest"] = 65535
	_assert_loads(data, expected, "(a) exponent 65535")


func test_at_169_b_a_cell_past_the_tile_ceiling() -> void:
	var data: Dictionary = _control_data()
	(data["cells"] as Array)[2] = 65536
	data["run_highest"] = 65536
	_assert_refused(F.to_text(data), "(b) exponent 65536")
	var snapshot: Dictionary = _control_data()
	((snapshot["snapshot"] as Dictionary)["cells"] as Array)[0] = 65536
	_assert_refused(F.to_text(snapshot), "(b) exponent 65536 in the snapshot")
	var highest: Dictionary = _control_data()
	highest["run_highest"] = 65536
	_assert_refused(F.to_text(highest), "(b) run highest 65536")


func test_at_169_c_the_largest_score() -> void:
	var expected: RunState = F.run(F.with_cell(F.board_d(), Vector2i(2, 0), 10), _top(), F.board_d(), 96, 11, 0, 38500)
	var data: Dictionary = _control_data()
	data["score"] = _top().to_decimal()
	assert_eq((data["score"] as String).length(), 19748, "19,748 digits")
	_assert_loads(data, expected, "(c) score 2^65600 minus 1")


func test_at_169_d_a_score_at_the_ceiling() -> void:
	var data: Dictionary = _control_data()
	data["score"] = _ceiling().to_decimal()
	_assert_refused(F.to_text(data), "(d) score 2^65600")


func test_at_169_e_a_score_of_19749_digits() -> void:
	var data: Dictionary = _control_data()
	data["score"] = "1" + "0".repeat(19748)
	_assert_refused(F.to_text(data), "(e) 19,749 digits")


func test_at_169_f_the_largest_snapshot_points() -> void:
	var expected: RunState = F.run(F.with_cell(F.board_d(), Vector2i(2, 0), 10), 41286, F.board_d(), _top(), 11, 0, 38500)
	var data: Dictionary = _control_data()
	(data["snapshot"] as Dictionary)["points"] = _top().to_decimal()
	_assert_loads(data, expected, "(f) points 2^65600 minus 1")


func test_at_169_g_the_largest_records() -> void:
	var loaded: Array = _load_profile_with(_top().to_decimal(), 65535)
	var records: Records = loaded[0]
	assert_eq((loaded[1] as PackedStringArray).size(), 0, "(g) a fully valid profile")
	assert_true(records.best_score.equals(_top()), "(g) Best Score 2^65600 minus 1 exactly")
	assert_eq(records.best_tile, 65535, "(g) Best Tile 2^65535")


func test_at_169_h_a_best_score_at_the_ceiling() -> void:
	var loaded: Array = _load_profile_with(_ceiling().to_decimal(), 9)
	var records: Records = loaded[0]
	assert_eq((loaded[1] as PackedStringArray).size(), 1, "(h) one bad part")
	assert_eq(F.text(records.best_score), "0", "(h) Best Score falls back to 0, as a broken profile part does")
	assert_eq(records.best_tile, 9, "(h) Best Tile kept")
	var long_score: Array = _load_profile_with("9".repeat(19749), 9)
	assert_eq(F.text((long_score[0] as Records).best_score), "0", "(h) 19,749 digits fall back too")


func test_at_169_i_a_best_tile_past_the_ceiling() -> void:
	var loaded: Array = _load_profile_with("5000", 65536)
	var records: Records = loaded[0]
	assert_eq((loaded[1] as PackedStringArray).size(), 1, "(i) one bad part")
	assert_eq(records.best_tile, 0, "(i) Best Tile falls back to 0")
	assert_eq(F.text(records.best_score), "5000", "(i) Best Score kept")


## A run file as the 2026-10-20 build wrote it, by hand: tabs, keys in this
## order, cells up to exponent 62 and a score at the old limit. Two touching
## 2^62 tiles on (0,7) and (1,7).
func _old_build_run_text() -> String:
	var cells: Array[String] = []
	for index: int in 40:
		var cell: Vector2i = Vector2i(index % 5, index / 5)
		if cell == Vector2i(0, 7) or cell == Vector2i(1, 7):
			cells.append("\t\t62")
		else:
			cells.append("\t\t%d" % F.board_d()[index])
	return "{\n\t\"format\": 2,\n\t\"columns\": 5,\n\t\"rows\": 8,\n\t\"cells\": [\n" + ",\n".join(cells) \
		+ "\n\t],\n\t\"score\": \"9223372036854775807\",\n\t\"run_highest\": 62,\n\t\"free_used\": 17,\n\t\"best_at_start\": \"9000000000000000000\",\n\t\"snapshot\": null\n}"


const OLD_PROFILE_TEXT: String = "{\n\t\"format\": 1,\n\t\"settings\": {\n\t\t\"sound_on\": false,\n\t\t\"skin\": \"nova\"\n\t},\n\t\"records\": {\n\t\t\"best_score\": \"9223372036854775807\",\n\t\t\"best_tile\": 62\n\t}\n}"


func test_at_169_j_old_build_files_load_unchanged_and_play_on() -> void:
	var run_text: String = _old_build_run_text()
	F.write_text(_run_path(), run_text)
	F.write_text(_profile_path(), OLD_PROFILE_TEXT)
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	_service.load_profile(settings, records)
	var state: RunState = _service.load_run(_config)
	assert_true(state != null, "(j) the old run loads")
	if state == null:
		return
	assert_eq(F.text(state.score), str(INT64_MAX), "(j) score 2^63 minus 1")
	assert_eq(state.run_highest, 62, "(j) run highest 2^62")
	assert_eq(state.free_used, 17, "(j) 17 free boosters used")
	assert_eq(F.text(state.best_at_start), "9000000000000000000", "(j) Best Score when the run began")
	assert_false(state.has_snapshot(), "(j) no snapshot")
	assert_eq(F.text(records.best_score), str(INT64_MAX), "(j) Best Score 2^63 minus 1")
	assert_eq(records.best_tile, 62, "(j) Best Tile 2^62")
	assert_false(settings.sound_on, "(j) sound off")
	assert_eq(settings.skin_id, &"nova", "(j) Nova")
	# Nothing changed, so saving writes the same bytes back.
	assert_true(_service.save_run(state), "(j) saves again")
	assert_true(_service.save_profile(settings, records), "(j) the profile saves again")
	assert_eq(F.read_text(_run_path()), run_text, "(j) run.json byte for byte the same")
	assert_eq(F.read_text(_profile_path()), OLD_PROFILE_TEXT, "(j) profile.json byte for byte the same")
	# Its chain whose points pass the old limit now commits.
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(169)
	assert_true(CoreRules.has_valid_move(state.cells, state.score, _config), "(j) a valid move")
	var result: MoveResult = RunRules.commit_chain(state, records, [Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i], rng, _config)
	assert_true(result.accepted, "(j) the 2^62 pair commits")
	assert_eq(F.text(state.score), "18446744073709551615", "(j) 2^63 minus 1 plus 2^63, exactly")
	assert_true(_service.save_run(state), "(j) and saves")
	var again: RunState = SaveService.new(_dir).load_run(_config)
	assert_true(again != null and state.equals(again), "(j) and reloads the same")


func test_format_1_files_load_with_an_unknown_starting_best_score() -> void:
	var data: Dictionary = F.format_1_data(F.control_run())
	var loaded: RunState = _load_text(F.to_text(data), "format 1")
	assert_true(loaded != null and F.as_format_1(F.control_run()).equals(loaded), "loads")
	assert_true(loaded != null and loaded.best_at_start == null, "best_at_start absent is null")
	var json_null: Dictionary = _control_data()
	json_null["best_at_start"] = null
	_assert_refused(F.to_text(json_null), "format 2 with best_at_start null")


# Hostile edges of the new ranges, each judged quickly

func test_huge_digit_strings_are_refused_quickly() -> void:
	var cases: Dictionary = {
		"19,749 ones": "1".repeat(19749),
		"19,748 nines": "9".repeat(19748),
		"2^65600": _ceiling().to_decimal(),
		"2^65600 plus 1": _ceiling().add(BigNum.from_int(1)).to_decimal(),
		"60,000 nines": "9".repeat(60000),
		"250,000 digits": "1".repeat(250000),
	}
	for label: String in cases:
		for field: String in ["score", "best_at_start", "points"]:
			var data: Dictionary = _control_data()
			if field == "points":
				(data["snapshot"] as Dictionary)["points"] = cases[label]
			else:
				data[field] = cases[label]
			_assert_refused(F.to_text(data), "%s as %s" % [label, field])


func test_three_fields_at_the_ceiling_in_one_file() -> void:
	var data: Dictionary = _control_data()
	var digits: String = _ceiling().to_decimal()
	data["score"] = digits
	data["best_at_start"] = digits
	(data["snapshot"] as Dictionary)["points"] = digits
	_assert_refused(F.to_text(data), "every number at 2^65600")
	var top: String = _top().to_decimal()
	var valid: Dictionary = _control_data()
	valid["score"] = top
	valid["best_at_start"] = top
	(valid["snapshot"] as Dictionary)["points"] = top
	var text: String = F.to_text(valid)
	assert_true(text.length() > 3 * 19748 and text.length() < SaveService.MAX_BYTES, "about 60 KB, under the cap")
	assert_true(_load_text(text, "every number at 2^65600 minus 1") != null, "the largest valid file loads")


func test_exponents_at_and_past_the_ceiling() -> void:
	for value: Variant in [65536, 65537, 100000, 1 << 31, 1 << 40, INT64_MAX, 1e18, 1e300]:
		var data: Dictionary = _control_data()
		(data["cells"] as Array)[7] = value
		_assert_refused(F.to_text(data), "cell exponent %s" % str(value))
		var highest: Dictionary = _control_data()
		highest["run_highest"] = value
		_assert_refused(F.to_text(highest), "run highest %s" % str(value))
	var every_cell: Dictionary = _control_data()
	var cells: Array = every_cell["cells"]
	for index: int in cells.size():
		cells[index] = 65535
	every_cell["run_highest"] = 65535
	assert_true(_load_text(F.to_text(every_cell), "40 cells of 2^65535") != null, "a full board at the ceiling loads")


func test_a_file_of_256_kb_is_the_cap() -> void:
	var text: String = F.to_text(_control_data())
	var at_cap: String = F.padded(text, SaveService.MAX_BYTES)
	assert_eq(at_cap.length(), 262144, "exactly 256 KB")
	assert_true(_load_text(at_cap, "256 KB") != null, "256 KB loads")
	_assert_refused(F.padded(text, SaveService.MAX_BYTES + 1), "256 KB plus 1 byte")
	var digits: Dictionary = _control_data()
	digits["score"] = F.RAW
	var filler: String = "\"" + "9".repeat(SaveService.MAX_BYTES - text.length()) + "\""
	var full: String = F.raw_text(digits, filler)
	assert_true(full.length() <= SaveService.MAX_BYTES, "a score filling the whole cap")
	_assert_refused(full, "a 256 KB score")
