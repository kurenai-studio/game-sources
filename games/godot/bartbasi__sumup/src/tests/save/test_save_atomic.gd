extends "res://tests/base_test.gd"
## Atomic writes and recovery (docs/ARCHITECTURE.md section 10).
##
## A save writes <name>.tmp, checks it, then renames it over <name>. On
## Windows, Godot's rename deletes <name> before it moves <name>.tmp in, so a
## kill can leave any of these on disk: the old file; the old file plus a
## partial or complete temp file; only the complete temp file; the new file.
## These tests build each state by hand and check that loading always gives
## the newest complete save (QA6-07), never a broken or missing one.

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


func _run_temp() -> String:
	return _run_path() + ".tmp"


func _profile_path() -> String:
	return _dir.path_join("profile.json")


func _profile_temp() -> String:
	return _profile_path() + ".tmp"


## The old run A and the new run B, as the text a save writes.
func _old_run() -> RunState:
	return F.plain_run()


func _new_run() -> RunState:
	return F.control_run()


func _text_of(state: RunState) -> String:
	return F.to_text(SaveCodec.run_to_data(state))


@warning_ignore("integer_division")
func _half(text: String) -> String:
	return text.left(text.length() / 2)


func _profile_text(best_score: int) -> String:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(best_score)
	return F.to_text(SaveCodec.profile_to_data(Settings.new(), records))


func _loaded_best_score() -> int:
	var records: Records = Records.new()
	_service.load_profile(Settings.new(), records)
	return records.best_score.to_int()


# Normal saves

func test_a_save_leaves_only_the_real_files() -> void:
	assert_true(_service.save_run(_old_run()), "run saved")
	assert_true(_service.save_profile(Settings.new(), Records.new()), "profile saved")
	var files: PackedStringArray = DirAccess.get_files_at(_dir)
	files.sort()
	assert_eq(files, PackedStringArray(["profile.json", "run.json"]), "no temp files left")


func test_a_save_replaces_an_existing_file() -> void:
	_service.save_run(_old_run())
	assert_true(_service.save_run(_new_run()), "the second save works over the first")
	assert_true(_new_run().equals(_service.load_run(_config)), "the new run loads")
	assert_eq(F.read_text(_run_path()), _text_of(_new_run()), "the file holds exactly the new run")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file left")


func test_a_save_over_a_leftover_temp_file() -> void:
	_service.save_run(_old_run())
	F.write_text(_run_temp(), "garbage")
	assert_true(_service.save_run(_new_run()), "saved")
	assert_true(_new_run().equals(_service.load_run(_config)), "the new run loads")
	assert_false(FileAccess.file_exists(_run_temp()), "the leftover is gone")


# Every moment a kill can hit a save of B over A

func test_run_kill_at_every_step_leaves_the_old_or_the_new_save() -> void:
	var a: String = _text_of(_old_run())
	var b: String = _text_of(_new_run())
	# Each step: [real file text or null, temp file text or null, which run must load].
	var steps: Array = [
		["before the write", a, null, "old"],
		["part way through writing the temp file", a, _half(b), "old"],
		["temp file written, rename not started (QA6-07: the newest complete save wins)", a, b, "new"],
		["Windows: old file deleted, temp not yet moved", null, b, "new"],
		["after the rename", b, null, "new"],
	]
	for step: Array in steps:
		after_each()    # the runner made a folder already; start each step clean
		before_each()
		if step[1] != null:
			F.write_text(_run_path(), step[1])
		if step[2] != null:
			F.write_text(_run_temp(), step[2])
		var expected: RunState = _old_run() if step[3] == "old" else _new_run()
		var loaded: RunState = _service.load_run(_config)
		assert_true(loaded != null, "%s: a run loads" % step[0])
		assert_true(expected.equals(loaded), "%s: the %s run" % [step[0], step[3]])
		assert_false(FileAccess.file_exists(_run_temp()), "%s: no temp file after loading" % step[0])
		assert_true(expected.equals(SaveService.new(_dir).load_run(_config)), "%s: the same run after another restart" % step[0])


func test_profile_kill_at_every_step_leaves_the_old_or_the_new_save() -> void:
	var a: String = _profile_text(1000)
	var b: String = _profile_text(2000)
	var steps: Array = [
		["before the write", a, null, 1000],
		["part way through writing the temp file", a, _half(b), 1000],
		["temp file written, rename not started (QA6-07: the newest complete save wins)", a, b, 2000],
		["Windows: old file deleted, temp not yet moved", null, b, 2000],
		["after the rename", b, null, 2000],
	]
	for step: Array in steps:
		after_each()    # the runner made a folder already; start each step clean
		before_each()
		if step[1] != null:
			F.write_text(_profile_path(), step[1])
		if step[2] != null:
			F.write_text(_profile_temp(), step[2])
		assert_eq(_loaded_best_score(), step[3], "%s" % step[0])
		assert_false(FileAccess.file_exists(_profile_temp()), "%s: no temp file after loading" % step[0])
		assert_eq(_loaded_best_score(), step[3], "%s: the same after another restart" % step[0])


# Recovery paths one by one

func test_complete_temp_next_to_a_good_run_wins() -> void:
	# QA6-07. Every write rewrites the temp file before its rename, so a temp
	# file that passes every check is newer than the real file.
	F.write_text(_run_path(), _text_of(_old_run()))
	F.write_text(_run_temp(), _text_of(_new_run()))
	assert_true(_new_run().equals(_service.load_run(_config)), "the newer temp file wins")
	assert_false(FileAccess.file_exists(_run_temp()), "it is renamed into place")
	assert_eq(F.read_text(_run_path()), _text_of(_new_run()), "and replaces the old file")


func test_broken_temp_next_to_a_good_run_is_removed() -> void:
	F.write_text(_run_path(), _text_of(_old_run()))
	F.write_text(_run_temp(), _half(_text_of(_new_run())))
	assert_true(_old_run().equals(_service.load_run(_config)), "the real file is used")
	assert_false(FileAccess.file_exists(_run_temp()), "the broken temp file is removed")
	assert_eq(F.read_text(_run_path()), _text_of(_old_run()), "the real file is unchanged")


func test_temp_with_no_real_run_is_recovered_and_renamed_into_place() -> void:
	F.write_text(_run_temp(), _text_of(_new_run()))
	assert_true(_service.has_run(), "a recoverable run counts as saved")
	assert_true(_new_run().equals(_service.load_run(_config)), "recovered")
	assert_false(FileAccess.file_exists(_run_temp()), "the temp file is gone")
	assert_eq(F.read_text(_run_path()), _text_of(_new_run()), "and is now the real file")


func test_broken_temp_with_no_real_run_is_discarded() -> void:
	F.write_text(_run_temp(), _half(_text_of(_new_run())))
	assert_true(_service.load_run(_config) == null, "no run")
	assert_false(_service.has_run(), "the broken temp file is discarded")


func test_good_temp_next_to_a_broken_run_is_used() -> void:
	F.write_text(_run_path(), _half(_text_of(_old_run())))
	F.write_text(_run_temp(), _text_of(_new_run()))
	assert_true(_new_run().equals(_service.load_run(_config)), "the temp file is used")
	assert_eq(F.read_text(_run_path()), _text_of(_new_run()), "and replaces the broken file")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file left")


func test_delete_run_removes_the_temp_file_too() -> void:
	F.write_text(_run_path(), _text_of(_old_run()))
	F.write_text(_run_temp(), _text_of(_new_run()))
	_service.delete_run()
	assert_false(FileAccess.file_exists(_run_path()), "real file gone")
	assert_false(FileAccess.file_exists(_run_temp()), "temp file gone, so an ended run cannot come back")
	assert_true(_service.load_run(_config) == null, "nothing to resume")
	F.write_text(_run_temp(), _text_of(_new_run()))
	_service.delete_run()
	assert_false(_service.has_run(), "a lone temp file is deleted too")


func test_failed_write_keeps_the_old_save() -> void:
	_service.save_run(_old_run())
	DirAccess.make_dir_absolute(_run_temp())    # the temp file cannot be created
	assert_false(_service.save_run(_new_run()), "the save reports failure")
	assert_true(_old_run().equals(_service.load_run(_config)), "the old run still loads")


func test_failed_rename_keeps_the_new_run_in_the_temp_file() -> void:
	DirAccess.make_dir_absolute(_run_path())    # nothing can be renamed over a folder
	assert_false(_service.save_run(_new_run()), "the save reports failure")
	assert_true(FileAccess.file_exists(_run_temp()), "the checked temp file is kept")
	assert_true(_new_run().equals(_service.load_run(_config)), "and the next load finds the new run")


func test_profile_temp_with_no_real_file_is_recovered() -> void:
	F.write_text(_profile_temp(), _profile_text(2000))
	assert_eq(_loaded_best_score(), 2000, "recovered")
	assert_true(FileAccess.file_exists(_profile_path()), "renamed into place")
	assert_false(FileAccess.file_exists(_profile_temp()), "no temp file left")


func test_profile_complete_temp_next_to_a_good_file_wins() -> void:
	F.write_text(_profile_path(), _profile_text(1000))
	F.write_text(_profile_temp(), _profile_text(2000))
	assert_eq(_loaded_best_score(), 2000, "the newer temp file wins (QA6-07)")
	assert_false(FileAccess.file_exists(_profile_temp()), "it is renamed into place")
	assert_eq(F.read_text(_profile_path()), _profile_text(2000), "and replaces the old file")


func test_profile_temp_with_a_bad_part_next_to_a_good_file_is_removed() -> void:
	# A temp file is only ever written whole and valid, so one with a bad part
	# is not a save of ours: it is deleted, and the real file is used.
	F.write_text(_profile_path(), _profile_text(1000))
	F.write_text(_profile_temp(), _profile_text(2000).replace("\"gumdrop\"", "\"NOPE\""))
	assert_eq(_loaded_best_score(), 1000, "the real file is used")
	assert_false(FileAccess.file_exists(_profile_temp()), "the temp file is removed")
	F.write_text(_profile_temp(), _half(_profile_text(2000)))
	assert_eq(_loaded_best_score(), 1000, "a broken temp file: the real file is used")
	assert_false(FileAccess.file_exists(_profile_temp()), "and the temp file is removed")


func test_profile_good_temp_next_to_a_broken_file_is_used() -> void:
	F.write_text(_profile_path(), "{\"format\": 1, \"rec")
	F.write_text(_profile_temp(), _profile_text(2000))
	assert_eq(_loaded_best_score(), 2000, "the temp file is used")
	assert_false(FileAccess.file_exists(_profile_temp()), "and renamed into place")


func test_profile_broken_temp_alone_gives_defaults() -> void:
	F.write_text(_profile_temp(), _half(_profile_text(2000)))
	assert_eq(_loaded_best_score(), 0, "defaults")
