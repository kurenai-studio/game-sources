extends "res://tests/base_test.gd"
## SaveService with a temp folder (docs/ARCHITECTURE.md section 10, TH18), and
## the save and resume acceptance tests it can prove (GDD 19.12, 19.14). A new
## SaveService on the same folder stands in for reopening the app.

const F := preload("res://tests/save/save_fixtures.gd")

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


## The app reopened: a new service on the same folder.
func _reopened() -> SaveService:
	return SaveService.new(_dir)


# Run

func test_save_and_load_run() -> void:
	var state: RunState = F.control_run()
	assert_true(_service.save_run(state), "saved")
	assert_true(_service.has_run(), "a run is saved")
	var loaded: RunState = _reopened().load_run(_config)
	assert_true(loaded != null, "loads after a restart")
	assert_true(state.equals(loaded), "equals the saved run exactly")


func test_round_trip_values_at_the_ceiling() -> void:
	var board: PackedInt64Array = F.board_huge()
	var top: BigNum = F.pow2_plus(_config.max_score_bits, -1)
	var state: RunState = F.run(board, top, board, top, _config.max_exponent, CoreRules.free_earned(_config.max_exponent, _config), top)
	assert_true(_service.save_run(state), "saved")
	var size: int = F.read_bytes(_run_path()).size()
	assert_true(size > 3 * 19748 and size <= SaveService.MAX_BYTES, "about 60 KB, under the 256 KB cap (%d bytes)" % size)
	var loaded: RunState = _reopened().load_run(_config)
	assert_true(loaded != null and state.equals(loaded), "every value exact through the file")


func test_run_file_is_plain_json_in_the_documented_format() -> void:
	_service.save_run(F.control_run())
	assert_eq(DirAccess.get_files_at(_dir), PackedStringArray(["run.json"]), "only run.json, in the folder given")
	var data: Variant = JSON.parse_string(F.read_text(_run_path()))
	assert_eq(typeof(data), TYPE_DICTIONARY, "a JSON object")
	assert_eq((data as Dictionary).keys(), ["format", "columns", "rows", "cells", "score", "run_highest", "free_used", "best_at_start", "snapshot"], "exact keys")
	assert_eq((data as Dictionary)["format"], 2, "format 2")
	assert_eq(typeof((data as Dictionary)["score"]), TYPE_STRING, "score is a digit string")
	assert_eq(typeof((data as Dictionary)["best_at_start"]), TYPE_STRING, "best_at_start is a digit string")


func test_load_run_with_no_file_is_null() -> void:
	assert_false(_service.has_run(), "nothing saved")
	assert_true(_service.load_run(_config) == null, "no run")


func test_delete_run() -> void:
	_service.save_run(F.control_run())
	_service.delete_run()
	assert_false(_service.has_run(), "deleted")
	assert_true(_reopened().load_run(_config) == null, "nothing to resume")
	_service.delete_run()
	assert_false(_service.has_run(), "deleting twice is harmless")


func test_delete_run_keeps_the_profile() -> void:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(5000)
	_service.save_profile(Settings.new(), records)
	_service.save_run(F.control_run())
	_service.delete_run()
	assert_true(FileAccess.file_exists(_profile_path()), "profile kept")


func test_save_run_refuses_invalid_states_and_keeps_the_last_save() -> void:
	var good: RunState = F.control_run()
	assert_true(_service.save_run(good), "good run saved")
	var board: PackedInt64Array = F.board_d()
	var short_board: PackedInt64Array = board.duplicate()
	short_board.resize(39)
	var top: BigNum = BigNum.pow2(_config.max_score_bits)
	var bad: Dictionary = {
		"a score at the ceiling": F.run(board, top),
		"a cell past the ceiling": F.run(F.with_cell(board, Vector2i(1, 1), 65536), 0, PackedInt64Array(), 0, 65536),
		"an empty cell": F.run(F.with_cell(board, Vector2i(1, 1), 0), 0),
		"a negative value": F.run(F.with_cell(board, Vector2i(1, 1), -2), 0),
		"run highest below the board": F.run(board, 0, PackedInt64Array(), 0, 3),
		"39 cells": F.run(short_board, 0),
		"no cells": F.run(PackedInt64Array(), 0),
		"zero columns": RunState.create(board, BigNum.zero(), PackedInt64Array(), null, 0, 0, 0, BigNum.zero()),
		"negative columns": RunState.create(board, BigNum.zero(), PackedInt64Array(), null, 0, -5, 0, BigNum.zero()),
		"snapshot points 2": F.run(board, 10, board, 2),
		"a short snapshot": F.run(board, 10, short_board, 40),
		"snapshot points at the ceiling": F.run(board, 10, board, top),
		"a free booster used with none earned": F.run(board, 10, PackedInt64Array(), 0, 0, 1),
		"negative free boosters used": F.run(board, 10, PackedInt64Array(), 0, 0, -1),
		"an unknown starting Best Score": RunState.create(board, BigNum.from_int(10)),
		"a starting Best Score at the ceiling": F.run(board, 10, PackedInt64Array(), 0, 0, 0, top),
	}
	for label: String in bad:
		assert_false(_service.save_run(bad[label]), "refused: %s" % label)
	assert_false(_service.save_run(null), "refused: null")
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null and good.equals(loaded), "the last good save is still there")
	assert_false(FileAccess.file_exists(_run_path() + ".tmp"), "no temp file left")


# Profile

func test_at_44_and_at_94_profile_persists_across_a_restart() -> void:
	var settings: Settings = Settings.new()
	settings.set_sound_on(false)
	settings.set_skin_id(&"nova")
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(123456)
	records.best_tile = 14
	assert_true(_service.save_profile(settings, records), "saved")
	var loaded_settings: Settings = Settings.new()
	var loaded_records: Records = Records.new()
	_reopened().load_profile(loaded_settings, loaded_records)
	assert_false(loaded_settings.sound_on, "sound off after reopening")
	assert_eq(loaded_settings.skin_id, &"nova", "chosen skin after reopening")
	assert_eq(F.text(loaded_records.best_score), "123456", "Best Score kept")
	assert_eq(loaded_records.best_tile, 14, "Best Tile kept")


func test_at_94_first_launch_has_sound_on_and_the_default_skin() -> void:
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	_service.load_profile(settings, records)
	assert_true(settings.sound_on, "sound on at first launch")
	assert_eq(settings.skin_id, &"gumdrop", "default skin")
	assert_eq(F.text(records.best_score), "0", "Best Score 0 before the first run")
	assert_eq(records.best_tile, 0, "Best Tile 0 before the first run")
	assert_false(FileAccess.file_exists(_profile_path()), "loading writes nothing")


func test_profile_with_a_bad_part_keeps_its_good_parts() -> void:
	F.write_text(_profile_path(), "{\"format\": 1, \"settings\": {\"sound_on\": false, \"skin\": \"NOPE\"}, \"records\": {\"best_score\": \"5000\", \"best_tile\": 65536}}")
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	_service.load_profile(settings, records)
	assert_false(settings.sound_on, "valid sound kept")
	assert_eq(settings.skin_id, &"gumdrop", "invalid skin uses the default")
	assert_eq(F.text(records.best_score), "5000", "valid Best Score kept")
	assert_eq(records.best_tile, 0, "invalid Best Tile uses the default")
	assert_true(FileAccess.file_exists(_profile_path()), "a broken profile is not deleted")


func test_save_profile_refuses_null() -> void:
	assert_false(_service.save_profile(null, Records.new()), "no settings")
	assert_false(_service.save_profile(Settings.new(), null), "no records")
	assert_false(FileAccess.file_exists(_profile_path()), "nothing written")


# The folder

func test_a_folder_outside_user_is_refused() -> void:
	# Each refused folder logs one programming error on purpose.
	for folder: String in ["res://", "user://../escape", "C:/sumup_save_test"]:
		var service: SaveService = SaveService.new(folder)
		assert_false(service.save_run(F.control_run()), "%s: no run saved" % folder)
		assert_false(service.save_profile(Settings.new(), Records.new()), "%s: no profile saved" % folder)
		assert_true(service.load_run(_config) == null, "%s: no run loaded" % folder)
		assert_false(service.has_run(), "%s: no run" % folder)
		service.delete_run()
		var settings: Settings = Settings.new()
		service.load_profile(settings, Records.new())
		assert_true(settings.sound_on, "%s: defaults" % folder)
	assert_false(FileAccess.file_exists("res://run.json"), "nothing written to res://")
	assert_false(DirAccess.dir_exists_absolute("C:/sumup_save_test"), "nothing written outside user://")


func test_saving_creates_a_missing_folder() -> void:
	var nested: String = _dir.path_join("a/b")
	var service: SaveService = SaveService.new(nested)
	assert_true(service.save_run(F.control_run()), "saved into a new folder")
	assert_true(service.load_run(_config) != null, "and loads")


# Save and resume acceptance tests

func test_at_55_offer_board_survives_a_restart() -> void:
	# Board D1024 has no valid move, so GameSession.resume opens the offer
	# again once it has this exact board and score back.
	var snapshot: PackedInt64Array = F.with_cell(F.board_d(), Vector2i(1, 7), 3)    # has a valid move
	var state: RunState = F.run(F.with_cell(F.board_d(), Vector2i(2, 0), 10), 5000, snapshot, 40)
	assert_false(CoreRules.has_valid_move(state.cells, state.score, _config), "no valid move before closing")
	_service.save_run(state)
	var loaded: RunState = _reopened().load_run(_config)
	assert_true(loaded != null and state.equals(loaded), "same board, score and snapshot")
	assert_false(CoreRules.has_valid_move(loaded.cells, loaded.score, _config), "still no valid move, so the offer opens again")


func test_at_65_and_at_93_only_the_run_itself_is_saved() -> void:
	# Targeting, a Swap selection and a drag live in GameSession and the board,
	# never in RunState, and the file has exactly the GDD 15.1 fields.
	var state: RunState = F.plain_run()
	_service.save_run(state)
	var data: Dictionary = JSON.parse_string(F.read_text(_run_path()))
	assert_eq(data.size(), 9, "nine fields, none for targeting or a drag")
	var loaded: RunState = _reopened().load_run(_config)
	assert_true(state.equals(loaded), "board and score as before")


func test_at_83_undo_snapshot_survives_a_restart() -> void:
	# AT-76 right after its chain: the 512 is on the snapshot board, so the
	# run highest tile is at least 512.
	var state: RunState = F.run(F.board_d(), 1032, F.with_cell(F.board_d(), Vector2i(2, 0), 9), 32, 9)
	assert_true(_service.save_run(state), "saved")
	var loaded: RunState = _reopened().load_run(_config)
	assert_true(loaded != null and loaded.has_snapshot(), "Undo still has its snapshot")
	assert_eq(loaded.snapshot_cells, state.snapshot_cells, "same snapshot board")
	assert_eq(F.text(loaded.snapshot_points), "32", "same snapshot points")
	assert_eq(loaded.cells, state.cells, "same board, so the same Undo cost")
	assert_eq(F.text(loaded.score), "1032", "same score")


func test_at_91_resume_after_the_app_is_killed() -> void:
	var state: RunState = F.control_run()
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(50000)
	records.best_tile = 11
	_service.save_run(state)
	_service.save_profile(settings, records)
	var reopened: SaveService = _reopened()
	var loaded_records: Records = Records.new()
	reopened.load_profile(Settings.new(), loaded_records)
	var loaded: RunState = reopened.load_run(_config)
	assert_true(loaded != null, "the run resumes")
	assert_eq(loaded.cells, state.cells, "same board")
	assert_true(loaded.score.equals(state.score), "same score")
	assert_eq(loaded.run_highest, 11, "same run highest tile")
	assert_eq(loaded.snapshot_cells, state.snapshot_cells, "Undo snapshot board")
	assert_true(loaded.snapshot_points.equals(state.snapshot_points), "Undo snapshot points")
	assert_eq(F.text(loaded_records.best_score), "50000", "same Best Score")
	assert_eq(loaded_records.best_tile, 11, "same Best Tile")


func test_at_92_a_chain_is_saved_as_soon_as_it_resolves() -> void:
	# The App saves on save_requested, which GameSession emits before any
	# animation. Here the save follows the commit directly, and a restart
	# finds the chain's result and points.
	var state: RunState = F.run(F.with_cell(F.board_d(), Vector2i(0, 0), 3), 1000)
	var records: Records = Records.new()
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(7)
	var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1)]
	var result: MoveResult = RunRules.commit_chain(state, records, chain, rng, _config)
	assert_true(result.accepted, "the chain commits")
	assert_true(_service.save_run(state), "saved at once")
	var loaded: RunState = _reopened().load_run(_config)
	assert_true(loaded != null and state.equals(loaded), "the resolved move is what resumes")
	assert_eq(F.text(loaded.score), "1016", "the chain's 16 points are there")

	assert_true(loaded.has_snapshot(), "with its Undo snapshot")
