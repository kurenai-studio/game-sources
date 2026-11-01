extends "res://tests/base_test.gd"
## AT-95. A broken saved run is discarded (GDD 19.12, TH18).
##
## Setup: a valid profile with "best_score": "5000" and "best_tile": 9 (Best
## Score 5,000, Best Tile 512) and a valid run file. The control loads that run
## file unchanged. Each fault test replaces the run file with a copy that has
## exactly one fault, then checks:
## - the run loader returns no run, and nothing crashes;
## - the run is discarded, so a restart has nothing to continue, and the next
##   game is a new run that saves and loads;
## - the profile file is untouched and still gives Best Score 5,000 and Best
##   Tile 512.

const F := preload("res://tests/save/save_fixtures.gd")

const PROFILE_TEXT: String = "{\"format\": 1, \"settings\": {\"sound_on\": true, \"skin\": \"gumdrop\"}, \"records\": {\"best_score\": \"5000\", \"best_tile\": 9}}"

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()
var _profile_bytes: PackedByteArray = PackedByteArray()
var _control_text: String = ""


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()
	F.write_text(_profile_path(), PROFILE_TEXT)
	_profile_bytes = F.read_bytes(_profile_path())
	_service.save_run(F.control_run())
	_control_text = F.read_text(_run_path())


func after_each() -> void:
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _profile_path() -> String:
	return _dir.path_join("profile.json")


## The control run file as data with ints, ready to receive one fault.
func _control_data() -> Dictionary:
	return SaveCodec.run_to_data(F.control_run())


func _assert_profile_untouched(label: String) -> void:
	assert_eq(F.read_bytes(_profile_path()), _profile_bytes, "%s: profile file untouched" % label)
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	SaveService.new(_dir).load_profile(settings, records)
	assert_eq(F.text(records.best_score), "5000", "%s: Best Score 5,000 kept" % label)
	assert_eq(records.best_tile, 9, "%s: Best Tile 512 kept" % label)


## Writes text as the run file and checks every AT-95 expectation.
func _assert_refused(text: String, label: String) -> void:
	F.write_text(_run_path(), text)
	assert_true(_service.has_run(), "%s: the faulty file is in place" % label)
	assert_true(_service.load_run(_config) == null, "%s: the run loader returns no run" % label)
	assert_false(_service.has_run(), "%s: the run is discarded" % label)
	assert_true(SaveService.new(_dir).load_run(_config) == null, "%s: nothing to continue after a restart" % label)
	_assert_profile_untouched(label)
	# The next game is a new run.
	var records: Records = Records.new()
	SaveService.new(_dir).load_profile(Settings.new(), records)
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(95)
	var fresh: RunState = RunRules.new_run(rng, records, _config)
	fresh.best_at_start = records.best_score    # as GameSession.start_new_run does
	assert_true(_service.save_run(fresh), "%s: the new run saves" % label)
	var loaded: RunState = SaveService.new(_dir).load_run(_config)
	assert_true(loaded != null and fresh.equals(loaded), "%s: and resumes" % label)
	assert_eq(F.text(loaded.score) if loaded != null else "", "0", "%s: with score 0" % label)
	assert_eq(F.text(records.best_score), "5000", "%s: Best Score still 5,000" % label)


func test_at_95_control_loads_and_equals_the_saved_run() -> void:
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null, "the control loads")
	assert_true(F.control_run().equals(loaded), "and equals the saved run exactly")
	assert_true(_service.has_run(), "and is kept")
	_assert_profile_untouched("control")


func test_at_95_a_39_cells() -> void:
	var data: Dictionary = _control_data()
	(data["cells"] as Array).resize(39)
	_assert_refused(F.to_text(data), "(a) 39 exponents")


func test_at_95_b_exponent_1_5() -> void:
	var data: Dictionary = _control_data()
	(data["cells"] as Array)[5] = 1.5
	_assert_refused(F.to_text(data), "(b) exponent 1.5")


func test_at_95_c_exponent_0() -> void:
	var data: Dictionary = _control_data()
	(data["cells"] as Array)[5] = 0
	_assert_refused(F.to_text(data), "(c) exponent 0")


func test_at_95_d_exponent_65536() -> void:
	# Changed on 2026-10-21: it was 63, which is now a valid tile (AT-169).
	var data: Dictionary = _control_data()
	(data["cells"] as Array)[5] = 65536
	_assert_refused(F.to_text(data), "(d) exponent 65536")


func test_at_95_e_score_minus_1() -> void:
	var data: Dictionary = _control_data()
	data["score"] = "-1"
	_assert_refused(F.to_text(data), "(e) score -1")


func test_at_95_f_score_12a() -> void:
	var data: Dictionary = _control_data()
	data["score"] = "12a"
	_assert_refused(F.to_text(data), "(f) score 12a")


func test_at_95_g_score_007() -> void:
	var data: Dictionary = _control_data()
	data["score"] = "007"
	_assert_refused(F.to_text(data), "(g) score 007")


func test_at_95_h_run_highest_below_a_1024_on_the_board() -> void:
	var data: Dictionary = _control_data()
	assert_true((data["cells"] as Array).has(10), "the cells include exponent 10, a 1024")
	data["run_highest"] = 9
	_assert_refused(F.to_text(data), "(h) run_highest 9")


func test_at_95_i_snapshot_points_2() -> void:
	var data: Dictionary = _control_data()
	var snapshot_cells: Array = (data["snapshot"] as Dictionary)["cells"]
	assert_eq(snapshot_cells.size(), 40, "the snapshot has 40 valid exponents")
	data["snapshot"] = {"cells": snapshot_cells, "points": "2"}
	_assert_refused(F.to_text(data), "(i) snapshot points 2")


func test_at_95_j_columns_6() -> void:
	var data: Dictionary = _control_data()
	data["columns"] = 6
	_assert_refused(F.to_text(data), "(j) columns 6")


func test_at_95_k_larger_than_the_size_cap() -> void:
	# The control file padded with trailing spaces: valid JSON, valid content,
	# but one byte over the cap, which rose from 64 KB to 256 KB on 2026-10-21
	# (ARCHITECTURE.md section 17).
	assert_eq(SaveService.MAX_BYTES, 256 * 1024, "the cap is 256 KB")
	var text: String = F.padded(_control_text, SaveService.MAX_BYTES + 1)
	assert_eq(text.to_utf8_buffer().size(), 256 * 1024 + 1, "one byte over 256 KB")
	_assert_refused(text, "(k) over 256 KB")



@warning_ignore("integer_division")
func test_at_95_l_cut_off_part_way_through() -> void:
	var text: String = _control_text.left(_control_text.length() / 2)
	assert_ne(JSON.new().parse(text), OK, "the cut text is malformed JSON")
	_assert_refused(text, "(l) cut off")
