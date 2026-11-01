extends "res://tests/base_test.gd"
## The format 2 run file through SaveService (docs/ARCHITECTURE.md section 10,
## GDD 15.1, TH18): free boosters used (D-46) and the Best Score when the run
## began (QA6-03), format 1 files from older builds, and the save halves of
## AT-125, AT-138, AT-139 and AT-145. The session halves (what resume reports,
## the New best badge) belong to GameSession's tests.

const F := preload("res://tests/save/save_fixtures.gd")

## AT-95's profile: Best Score 5,000, Best Tile 512.
const PROFILE_TEXT: String = "{\"format\": 1, \"settings\": {\"sound_on\": true, \"skin\": \"gumdrop\"}, \"records\": {\"best_score\": \"5000\", \"best_tile\": 9}}"

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()


func after_each() -> void:
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _profile_path() -> String:
	return _dir.path_join("profile.json")


## Board D with a 131072 (exponent 17) on (2,0): run highest exponent 17, so 7
## stars and 2 free boosters earned.
func _late_board() -> PackedInt64Array:
	return F.with_cell(F.board_d(), Vector2i(2, 0), 17)


func _late_run(free_used: int) -> RunState:
	return F.run(_late_board(), 2400000, PackedInt64Array(), 0, 0, free_used, 2000000)


## The app reopened: a new service on the same folder.
func _reloaded() -> RunState:
	return SaveService.new(_dir).load_run(_config)


func _write_run(data: Dictionary) -> void:
	F.write_text(_run_path(), F.to_text(data))


## AT-95's checks for a refused run file: no run, discarded, nothing after a
## restart, the profile file untouched.
func _assert_refused_as_at_95(label: String) -> void:
	var profile_bytes: PackedByteArray = F.read_bytes(_profile_path())
	assert_true(_service.load_run(_config) == null, "%s: the run loader returns no run" % label)
	assert_false(_service.has_run(), "%s: the run is discarded" % label)
	assert_true(_reloaded() == null, "%s: nothing to continue after a restart" % label)
	assert_eq(F.read_bytes(_profile_path()), profile_bytes, "%s: profile file untouched" % label)
	var records: Records = Records.new()
	SaveService.new(_dir).load_profile(Settings.new(), records)
	assert_eq(F.text(records.best_score), "5000", "%s: Best Score kept" % label)
	assert_eq(records.best_tile, 9, "%s: Best Tile 512 kept" % label)


# The file

func test_a_run_is_written_as_format_2() -> void:
	assert_true(_service.save_run(_late_run(1)), "saved")
	var data: Dictionary = JSON.parse_string(F.read_text(_run_path()))
	assert_eq(data["format"], 2, "format 2")
	assert_eq(data["free_used"], 1, "free boosters used")
	assert_eq(data["best_at_start"], "2000000", "Best Score when the run began, as a digit string")
	assert_eq(data["run_highest"], 17, "run highest 131072 as exponent 17")


func test_a_format_1_file_loads_through_the_service() -> void:
	_write_run(F.format_1_data(F.control_run()))
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null, "a run saved before D-46 resumes")
	assert_true(F.as_format_1(F.control_run()).equals(loaded), "same board, score, snapshot and run highest tile")
	if loaded != null:
		assert_eq(loaded.free_used, 0, "no free booster used")
		assert_true(loaded.best_at_start == null, "the starting Best Score is unknown")
	assert_true(_service.has_run(), "and the file is kept")


func test_a_format_1_run_saved_again_keeps_its_meaning() -> void:
	# GDD 15.1: a run saved before the starting Best Score existed takes the
	# Best Score loaded with it. GameSession.resume does that; the next save
	# writes it, so the next load gives the same value.
	_write_run(F.format_1_data(F.control_run()))
	var format_1_bytes: PackedByteArray = F.read_bytes(_run_path())
	var loaded: RunState = _service.load_run(_config)
	assert_false(_service.save_run(loaded), "still unknown: refused, never written as a made up value")
	assert_eq(F.read_bytes(_run_path()), format_1_bytes, "so the format 1 file stays, and still means unknown")
	loaded.best_at_start = BigNum.from_int(50000)    # as GameSession.resume does with the loaded Best Score
	assert_true(_service.save_run(loaded), "once known, it saves")
	var data: Dictionary = JSON.parse_string(F.read_text(_run_path()))
	assert_eq(data["format"], 2, "as format 2")
	var again: RunState = _reloaded()
	assert_true(again != null and loaded.equals(again), "and loads back the same")
	assert_eq(F.text(again.best_at_start) if again != null else "", "50000", "with the loaded Best Score")
	assert_eq(again.free_used if again != null else -1, 0, "and 0 free boosters used")


func test_the_profile_stays_format_1() -> void:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(96520)
	records.best_tile = 12
	assert_true(_service.save_profile(Settings.new(), records), "saved")
	var data: Dictionary = JSON.parse_string(F.read_text(_profile_path()))
	assert_eq(data["format"], 1, "profile format 1")
	assert_eq(data.keys(), ["format", "settings", "records"], "profile keys unchanged")


# AT-125 (save half)

func test_at_125_b_a_loaded_run_has_its_stars_and_free_boosters() -> void:
	_write_run(SaveCodec.run_to_data(_late_run(1)))
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null, "the run loads")
	if loaded == null:
		return
	assert_eq(loaded.run_highest, 17, "run highest tile 131072")
	assert_eq(loaded.free_used, 1, "1 free booster used")
	assert_eq(CoreRules.stars(loaded.run_highest, _config), 7, "7 stars")
	assert_eq(CoreRules.free_held(loaded, _config), 1, "1 free booster held")
	assert_true(_late_run(1).equals(loaded), "the load changes nothing: no star or free booster is earned by loading")


# AT-138 (save half)

func test_at_138_stars_and_free_boosters_survive_a_restart() -> void:
	var state: RunState = _late_run(1)
	assert_true(_service.save_run(state), "saved")
	var loaded: RunState = _reloaded()
	assert_true(loaded != null and state.equals(loaded), "the loaded state equals the saved one")
	if loaded != null:
		assert_eq(CoreRules.stars(loaded.run_highest, _config), 7, "7 stars")
		assert_eq(CoreRules.free_held(loaded, _config), 1, "1 free booster held")
	var queued: RunState = _late_run(2)
	assert_true(_service.queue_run(queued), "a queued save too")
	_service.flush()
	var loaded_queued: RunState = _reloaded()
	assert_true(loaded_queued != null and queued.equals(loaded_queued), "the queued state loads the same")


# AT-139

func _at_139_data(free_used: Variant) -> Dictionary:
	var data: Dictionary = SaveCodec.run_to_data(_late_run(0))
	data["free_used"] = free_used
	return data


func _at_139_setup() -> void:
	F.write_text(_profile_path(), PROFILE_TEXT)


func test_at_139_a_0_used_loads_with_2_held() -> void:
	_at_139_setup()
	_write_run(_at_139_data(0))
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null, "loads")
	if loaded != null:
		assert_eq(CoreRules.free_held(loaded, _config), 2, "2 free boosters held")


func test_at_139_b_2_used_loads_with_0_held() -> void:
	_at_139_setup()
	_write_run(_at_139_data(2))
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null, "loads")
	if loaded != null:
		assert_eq(CoreRules.free_held(loaded, _config), 0, "0 free boosters held")


func test_at_139_c_3_used_is_refused() -> void:
	_at_139_setup()
	_write_run(_at_139_data(3))
	_assert_refused_as_at_95("(c) 3 used, 2 earned")


func test_at_139_d_minus_1_used_is_refused() -> void:
	_at_139_setup()
	_write_run(_at_139_data(-1))
	_assert_refused_as_at_95("(d) minus 1")


func test_at_139_e_1_5_used_is_refused() -> void:
	_at_139_setup()
	_write_run(_at_139_data(1.5))
	_assert_refused_as_at_95("(e) 1.5")


func test_at_139_f_the_text_1_is_refused() -> void:
	_at_139_setup()
	_write_run(_at_139_data("1"))
	_assert_refused_as_at_95("(f) the text \"1\"")


func test_at_139_g_no_entry_at_all_loads_as_0_used() -> void:
	# A file with no free boosters used entry is one saved before D-46: a
	# format 1 file (ARCHITECTURE.md section 10). A format 2 file missing only
	# that entry is not a file any build wrote, and is refused.
	_at_139_setup()
	_write_run(F.format_1_data(_late_run(0)))
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null, "loads")
	if loaded != null:
		assert_eq(loaded.free_used, 0, "as 0 used")
		assert_eq(CoreRules.free_held(loaded, _config), 2, "so 2 free boosters held")
	var missing: Dictionary = _at_139_data(0)
	missing.erase("free_used")
	_write_run(missing)
	_assert_refused_as_at_95("format 2 without free_used")


# AT-145 (save half)

## Board D1024, score 5,000, no snapshot, with a profile Best Score of 5,000.
func _at_145_run(best_at_start: int) -> RunState:
	return F.run(F.with_cell(F.board_d(), Vector2i(2, 0), 10), 5000, PackedInt64Array(), 0, 0, 0, best_at_start)


func _at_145_loaded(data: Dictionary) -> RunState:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(5000)
	_service.save_profile(Settings.new(), records)
	_write_run(data)
	return _service.load_run(_config)


func test_at_145_a_the_run_began_at_4000() -> void:
	var loaded: RunState = _at_145_loaded(SaveCodec.run_to_data(_at_145_run(4000)))
	assert_true(loaded != null and F.text(loaded.best_at_start) == "4000", "Best Score when the run began: 4,000, so the run raised the record")


func test_at_145_b_the_run_began_at_5000() -> void:
	var loaded: RunState = _at_145_loaded(SaveCodec.run_to_data(_at_145_run(5000)))
	assert_true(loaded != null and F.text(loaded.best_at_start) == "5000", "5,000: the run only equalled the record")


func test_at_145_c_no_starting_best_score_in_the_file() -> void:
	var loaded: RunState = _at_145_loaded(F.format_1_data(_at_145_run(4000)))
	assert_true(loaded != null and loaded.best_at_start == null, "unknown, so resume uses the loaded Best Score (the old behaviour)")

