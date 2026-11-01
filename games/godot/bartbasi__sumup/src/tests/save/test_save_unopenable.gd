extends "res://tests/base_test.gd"
## SEC-04. A run.json or profile.json, or its temp file, that exists but
## cannot be opened (on Windows, another program holding it with no sharing,
## or briefly right after a process ends) is not judged: no older file is
## used, and no file is written, renamed or deleted while that service lives.
## The next load that can open the file reads it. Opening is tried again for
## a short while first.
## Godot opens files with read sharing, so a test cannot hold one shut;
## SaveService.set_unopenable stands in for the other program.

const F := preload("res://tests/save/save_fixtures.gd")

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()


func after_each() -> void:
	_service = null
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _profile_path() -> String:
	return _dir.path_join("profile.json")


func _state(score: int) -> RunState:
	return F.run(F.with_cell(F.board_d(), Vector2i(0, 0), 5), score, PackedInt64Array(), 0, 0, 0, 1000)


func _records(best_score: int) -> Records:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(best_score)
	records.best_tile = 11
	return records


## A fresh service on the same folder, as after the app restarts.
func _reopen() -> SaveService:
	_service = SaveService.new(_dir)
	return _service


## Every file in the folder with its bytes.
func _snapshot() -> Dictionary:
	var files: Dictionary = {}
	for file_name: String in DirAccess.get_files_at(_dir):
		files[file_name] = F.read_bytes(_dir.path_join(file_name))
	return files


## run.json at 200 and run.json.bak at 100.
func _two_runs() -> void:
	assert_true(_service.save_run(_state(100)), "first run save")
	assert_true(_service.save_run(_state(200)), "second run save")
	assert_true(FileAccess.file_exists(_run_path() + ".bak"), "the .bak is there")


## profile.json at 2000 and profile.json.bak at 1000.
func _two_profiles() -> void:
	assert_true(_service.save_profile(Settings.new(), _records(1000)), "first profile save")
	assert_true(_service.save_profile(Settings.new(), _records(2000)), "second profile save")
	assert_true(FileAccess.file_exists(_profile_path() + ".bak"), "the .bak is there")


func _loaded_score(service: SaveService) -> int:
	var state: RunState = service.load_run(_config)
	return -1 if state == null else state.score.to_int()


func test_unopenable_run_does_not_use_the_bak_and_touches_no_file() -> void:
	_two_runs()
	var before: Dictionary = _snapshot()
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path(), -1)
	assert_null(service.load_run(_config), "no run this launch, not the older .bak")
	assert_false(service.save_run(_state(300)), "save_run refuses to write over it")
	assert_false(service.queue_run(_state(301)), "queue_run refuses too")
	service.delete_run()
	service.flush()
	assert_eq(_snapshot(), before, "every run file is exactly as it was")
	service.set_unopenable(_run_path(), 0)
	assert_eq(_loaded_score(_reopen()), 200, "the next launch reads run.json")


func test_same_service_reads_run_once_it_opens_again() -> void:
	_two_runs()
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path(), -1)
	assert_null(service.load_run(_config), "held: no run")
	service.set_unopenable(_run_path(), 0)
	assert_eq(_loaded_score(service), 200, "a later load reads run.json")
	assert_true(service.save_run(_state(300)), "and saving works again")
	assert_eq(_loaded_score(_reopen()), 300, "the new save loads")


func test_run_briefly_unopenable_is_read_after_a_retry() -> void:
	_two_runs()
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path(), 2)
	assert_eq(_loaded_score(service), 200, "the third try opens run.json")
	assert_true(service.save_run(_state(300)), "saving is not blocked")
	assert_eq(_loaded_score(_reopen()), 300, "the new save loads")


func test_valid_temp_still_wins_over_an_unopenable_run() -> void:
	_two_runs()
	F.write_text(_run_path() + ".tmp", F.to_text(SaveCodec.run_to_data(_state(300))))
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path(), -1)
	assert_eq(_loaded_score(service), 300, "the newest save, the temp file, wins as before")


func test_unopenable_profile_does_not_use_the_bak_and_is_not_saved_over() -> void:
	_two_profiles()
	var before: Dictionary = _snapshot()
	var service: SaveService = _reopen()
	service.set_unopenable(_profile_path(), -1)
	var settings: Settings = Settings.new()
	var records: Records = Records.new()
	service.load_profile(settings, records)
	assert_eq(F.text(records.best_score), "0", "the older .bak is not used; values in memory stay")
	assert_eq(records.best_tile, 0, "Best Tile stays too")
	assert_false(service.save_profile(settings, records), "save_profile refuses to write over it")
	assert_false(service.queue_profile(settings, records), "queue_profile refuses too")
	service.flush()
	assert_eq(_snapshot(), before, "every profile file is exactly as it was, no temp file")
	service.set_unopenable(_profile_path(), 0)
	var later: Records = Records.new()
	_reopen().load_profile(Settings.new(), later)
	assert_eq(F.text(later.best_score), "2000", "the next launch reads profile.json")


func test_profile_briefly_unopenable_is_read_after_a_retry() -> void:
	_two_profiles()
	var service: SaveService = _reopen()
	service.set_unopenable(_profile_path(), 4)
	var records: Records = Records.new()
	service.load_profile(Settings.new(), records)
	assert_eq(F.text(records.best_score), "2000", "the last of five tries opens profile.json")
	assert_true(service.save_profile(Settings.new(), _records(3000)), "saving is not blocked")


func test_run_unopenable_on_every_try_gives_up_quickly() -> void:
	_two_runs()
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path(), 5)
	var start: int = Time.get_ticks_msec()
	assert_null(service.load_run(_config), "five failed tries: no run")
	assert_true(Time.get_ticks_msec() - start < 1000, "well under a second")


func test_unopenable_run_temp_blocks_like_the_real_file() -> void:
	# The temp file may be the newest save, so neither run.json nor the .bak
	# may be used in its place.
	_two_runs()
	F.write_text(_run_path() + ".tmp", F.to_text(SaveCodec.run_to_data(_state(300))))
	var before: Dictionary = _snapshot()
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path() + ".tmp", -1)
	assert_null(service.load_run(_config), "no run this launch, not the older run.json")
	assert_false(service.save_run(_state(400)), "save_run refuses")
	assert_false(service.queue_run(_state(401)), "queue_run refuses")
	service.delete_run()
	service.flush()
	assert_eq(_snapshot(), before, "every run file is exactly as it was")
	service.set_unopenable(_run_path() + ".tmp", 0)
	assert_eq(_loaded_score(service), 300, "the next load reads the temp file")


func test_unopenable_profile_temp_blocks_like_the_real_file() -> void:
	_two_profiles()
	F.write_text(_profile_path() + ".tmp", F.to_text(SaveCodec.profile_to_data(Settings.new(), _records(3000))))
	var before: Dictionary = _snapshot()
	var service: SaveService = _reopen()
	service.set_unopenable(_profile_path() + ".tmp", -1)
	var records: Records = Records.new()
	service.load_profile(Settings.new(), records)
	assert_eq(F.text(records.best_score), "0", "neither profile.json nor the .bak is used")
	assert_false(service.save_profile(Settings.new(), records), "save_profile refuses")
	assert_false(service.queue_profile(Settings.new(), records), "queue_profile refuses")
	service.flush()
	assert_eq(_snapshot(), before, "every profile file is exactly as it was")
	service.set_unopenable(_profile_path() + ".tmp", 0)
	var later: Records = Records.new()
	_reopen().load_profile(Settings.new(), later)
	assert_eq(F.text(later.best_score), "3000", "the next launch reads the temp file")


func test_unopenable_bak_alone_is_left_alone() -> void:
	_two_runs()
	DirAccess.remove_absolute(_run_path())
	var before: Dictionary = _snapshot()
	var service: SaveService = _reopen()
	service.set_unopenable(_run_path() + ".bak", -1)
	assert_null(service.load_run(_config), "no run")
	assert_eq(_snapshot(), before, "the .bak is kept")
	assert_true(service.save_run(_state(300)), "with no real file to protect, saving works")
