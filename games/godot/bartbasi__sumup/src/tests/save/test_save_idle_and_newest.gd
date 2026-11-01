extends "res://tests/base_test.gd"
## SaveService.is_idle and set_hold (QA6-06, TH23, the save half of AT-146),
## and "the newest complete save wins" (QA6-07): a valid temp file wins on
## load, an invalid one is deleted, a failed rename is tried again before the
## next write and on flush, and a deleted run never comes back.
##
## Some cases hold a file open with a second FileAccess handle, as QA did. On
## Windows that makes Godot's rename and delete fail; on Android and other
## POSIX systems they still work. Every check here holds on both.

const F := preload("res://tests/save/save_fixtures.gd")

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()


func after_each() -> void:
	_service.set_hold(false)
	_service.flush()
	_service = null
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _run_temp() -> String:
	return _run_path() + ".tmp"


## A valid run whose score marks which save it was.
func _state(score: int) -> RunState:
	return F.run(F.board_d(), score)


func _text_of(score: int) -> String:
	return F.to_text(SaveCodec.run_to_data(_state(score)))


## The score of the run in run.json, read straight from the file without any
## service (so nothing is flushed, retried or renamed), or -1 for none.
func _score_in_run_file() -> int:
	var parsed: Variant = JSON.parse_string(F.read_text(_run_path()))
	var state: RunState = SaveCodec.data_to_run(parsed, _config)
	return state.score.to_int() if state != null else -1


## What a reopened app loads, or -1 for no run.
func _score_on_reload() -> int:
	var state: RunState = SaveService.new(_dir).load_run(_config)
	return state.score.to_int() if state != null else -1


func _on_windows() -> bool:
	return OS.get_name() == "Windows"


## Waits, without flushing, until the service is idle. False if it never got
## there within about two seconds.
func _wait_until_idle(service: SaveService) -> bool:
	for attempt: int in 400:
		if service.is_idle():
			return true
		OS.delay_msec(5)
	return service.is_idle()


# is_idle

func test_is_idle_with_nothing_queued() -> void:
	assert_true(_service.is_idle(), "a new service is idle")
	_service.save_run(_state(1))
	assert_true(_service.is_idle(), "a synchronous save leaves nothing queued")
	_service.flush()
	assert_true(_service.is_idle(), "after a flush")


func test_is_idle_turns_true_by_itself_once_the_write_lands() -> void:
	# The board polls is_idle once a frame; nobody flushes.
	assert_true(_service.queue_run(_state(7)), "queued")
	assert_true(_wait_until_idle(_service), "idle once the writer is done")
	assert_eq(_score_in_run_file(), 7, "and the run is on disk by then")
	assert_false(FileAccess.file_exists(_run_temp()), "with no temp file left")


func test_a_refused_save_is_idle() -> void:
	assert_false(_service.queue_run(F.run(F.board_d(), BigNum.pow2(GameConfig.new().max_score_bits))), "a state that would not load back is refused")
	assert_false(_service.queue_run(null), "and null")
	assert_true(_service.is_idle(), "nothing was queued, so the move can show")


func test_a_failed_write_is_idle_too() -> void:
	# A save that fails must not freeze the game (GDD 15.1).
	DirAccess.make_dir_absolute(_run_temp())    # the temp file cannot be written
	assert_true(_service.queue_run(_state(3)), "queued")
	assert_true(_wait_until_idle(_service), "idle once the write has failed (one push_warning)")
	assert_false(FileAccess.file_exists(_run_path()), "nothing written")
	DirAccess.remove_absolute(_run_temp())


# set_hold (TH23)

func test_at_146_held_writes_wait_and_is_idle_stays_false() -> void:
	assert_true(_service.save_run(_state(1)), "the run before the move")
	_service.set_hold(true)
	assert_false(_service.is_idle(), "false while held, even with nothing queued")
	assert_true(_service.queue_run(_state(2)), "the move's save is queued")
	OS.delay_msec(30)
	assert_false(_service.is_idle(), "still not idle: the board keeps the move hidden")
	assert_eq(_score_in_run_file(), 1, "nothing written while held")
	assert_false(FileAccess.file_exists(_run_temp()), "not even the temp file")
	_service.set_hold(false)
	assert_true(_wait_until_idle(_service), "released: the writer runs and the service turns idle")
	assert_eq(_score_in_run_file(), 2, "the move's save is on disk")


func test_held_writes_keep_only_the_newest_data() -> void:
	_service.set_hold(true)
	for score: int in [10, 11, 12]:
		_service.queue_run(_state(score))
	_service.set_hold(false)
	_service.flush()
	assert_true(_service.is_idle(), "idle after the flush")
	assert_eq(_score_in_run_file(), 12, "the newest held save wins")


func test_flush_while_held_still_writes_so_it_never_waits_forever() -> void:
	_service.set_hold(true)
	_service.queue_run(_state(4))
	_service.flush()
	assert_eq(_score_in_run_file(), 4, "flush writes what is held")
	assert_false(_service.is_idle(), "the hold still keeps is_idle false")
	_service.set_hold(false)
	assert_true(_service.is_idle(), "until it is released")


func test_a_held_write_never_lands_after_a_delete() -> void:
	_service.set_hold(true)
	_service.queue_run(_state(5))
	_service.delete_run()
	_service.set_hold(false)
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "deleted, and still deleted after the release")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file either")
	assert_true(_service.load_run(_config) == null, "nothing to resume")


func test_a_held_write_never_lands_after_a_newer_save() -> void:
	_service.set_hold(true)
	_service.queue_run(_state(6))
	assert_true(_service.save_run(_state(7)), "a synchronous save while held")
	_service.set_hold(false)
	_service.flush()
	assert_eq(_score_in_run_file(), 7, "the newer save stays")


func test_releasing_with_nothing_queued_is_harmless() -> void:
	_service.set_hold(true)
	_service.set_hold(false)
	assert_true(_service.is_idle(), "idle")
	assert_false(FileAccess.file_exists(_run_path()), "nothing written")


# QA6-07: the newest complete save wins

func test_qa6_07_reproduction_save_while_a_reader_holds_the_file() -> void:
	# QA's steps: save 111; while another handle has run.json open for
	# reading, save 222; close the handle; load.
	assert_true(_service.save_run(_state(111)), "first save")
	var reader: FileAccess = FileAccess.open(_run_path(), FileAccess.READ)
	assert_not_null(reader, "a reader holds run.json open")
	var saved: bool = _service.save_run(_state(222))
	if _on_windows():
		assert_false(saved, "Windows: the rename fails while the file is open")
		assert_eq(F.read_text(_run_temp()), _text_of(222), "Windows: the new run waits in the temp file")
	if reader != null:
		reader.close()
	assert_eq(_score_on_reload(), 222, "the load gives 222, the newest save")
	assert_eq(F.read_text(_run_path()), _text_of(222), "run.json now holds it")
	assert_false(FileAccess.file_exists(_run_temp()), "and the temp file is gone")


func test_qa6_07_reproduction_through_the_queued_writer() -> void:
	# The way QA first met it: the game's writer thread saving while another
	# program reads run.json.
	assert_true(_service.save_run(_state(111)), "first save")
	var reader: FileAccess = FileAccess.open(_run_path(), FileAccess.READ)
	assert_true(_service.queue_run(_state(222)), "the move's save is queued")
	assert_true(_wait_until_idle(_service), "idle once the writer is done, even if its rename failed")
	if reader != null:
		reader.close()
	assert_eq(_score_on_reload(), 222, "the load gives 222, the newest save")
	assert_false(FileAccess.file_exists(_run_temp()), "and the temp file is in place")


func test_qa6_07_a_failed_rename_is_retried_on_flush() -> void:
	assert_true(_service.save_run(_state(111)), "first save")
	var reader: FileAccess = FileAccess.open(_run_path(), FileAccess.READ)
	_service.save_run(_state(222))
	reader.close()
	_service.flush()
	assert_eq(_score_in_run_file(), 222, "the flush moved the new run into place")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file left")


func test_a_failed_rename_is_retried_on_flush() -> void:
	# The same on every system: nothing can be renamed over a folder.
	DirAccess.make_dir_absolute(_run_path())
	assert_false(_service.save_run(_state(222)), "the rename fails")
	assert_eq(F.read_text(_run_temp()), _text_of(222), "the new run is kept in the temp file")
	_service.flush()
	assert_true(DirAccess.dir_exists_absolute(_run_path()), "still blocked, nothing changes")
	DirAccess.remove_absolute(_run_path())
	_service.flush()
	assert_eq(_score_in_run_file(), 222, "unblocked: the flush renames it into place")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file left")


func test_a_failed_rename_is_retried_on_the_next_write() -> void:
	DirAccess.make_dir_absolute(_run_path())
	assert_false(_service.save_run(_state(222)), "the rename fails")
	DirAccess.remove_absolute(_run_path())
	# The next write is of the other file, on the writer thread, and nobody
	# flushes: the writer retries the run's rename first.
	assert_true(_service.queue_profile(Settings.new(), Records.new()), "the profile is queued")
	assert_true(_wait_until_idle(_service), "written")
	assert_eq(_score_in_run_file(), 222, "the run's rename was retried")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file left")
	assert_true(FileAccess.file_exists(_dir.path_join("profile.json")), "and the profile is saved")


func test_a_retry_only_moves_the_bytes_that_were_written() -> void:
	DirAccess.make_dir_absolute(_run_path())
	assert_false(_service.save_run(_state(222)), "the rename fails")
	F.write_text(_run_temp(), "garbage")    # something else changed the temp file
	DirAccess.remove_absolute(_run_path())
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "the changed temp file is not moved into place")
	assert_true(_service.load_run(_config) == null, "the load judges it: broken, so no run")
	assert_false(FileAccess.file_exists(_run_temp()), "and deletes it")


func test_a_held_temp_file_during_the_rename() -> void:
	# On Windows a temp file held open makes the rename delete run.json and
	# then fail, so the temp file is the only copy. It must win.
	assert_true(_service.save_run(_state(111)), "first save")
	F.write_text(_run_temp(), "")
	var reader: FileAccess = FileAccess.open(_run_temp(), FileAccess.READ)
	_service.save_run(_state(222))
	if reader != null:
		reader.close()
	assert_eq(_score_on_reload(), 222, "the newest save loads")
	assert_false(FileAccess.file_exists(_run_temp()), "and is in place")


func test_a_valid_temp_wins_even_when_its_rename_fails_on_load() -> void:
	F.write_text(_run_temp(), _text_of(222))
	DirAccess.make_dir_absolute(_run_path())
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null and loaded.score.to_int() == 222, "the temp run is used")
	assert_true(FileAccess.file_exists(_run_temp()), "and kept while it cannot move")
	DirAccess.remove_absolute(_run_path())
	_service.flush()
	assert_eq(_score_in_run_file(), 222, "the flush finishes the move")


func test_an_invalid_temp_is_deleted_and_the_real_file_used() -> void:
	var cases: Dictionary = {
		"garbage": "garbage",
		"cut off": _text_of(222).left(40),
		"a negative score": _text_of(222).replace("\"222\"", "\"-1\""),
		"a free booster never earned": _text_of(222).replace("\"free_used\": 0", "\"free_used\": 1"),
		"an unknown key": _text_of(222).replace("\"format\": 2", "\"format\": 2, \"x\": 1"),
		"empty": "",
	}
	for label: String in cases:
		after_each()    # each case in a clean folder
		before_each()
		assert_true(_service.save_run(_state(111)), "%s: a good save" % label)
		F.write_text(_run_temp(), cases[label])
		assert_eq(_score_on_reload(), 111, "%s: the real file is used" % label)
		assert_false(FileAccess.file_exists(_run_temp()), "%s: the invalid temp file is deleted" % label)
		assert_eq(F.read_text(_run_path()), _text_of(111), "%s: the real file is unchanged" % label)


# A deleted run never comes back

func test_delete_run_drops_a_failed_rename() -> void:
	DirAccess.make_dir_absolute(_run_path())
	assert_false(_service.save_run(_state(222)), "the rename fails, the run waits in the temp file")
	DirAccess.remove_absolute(_run_path())
	_service.delete_run()
	assert_false(FileAccess.file_exists(_run_temp()), "the temp file is deleted with the run")
	_service.flush()
	_service.queue_profile(Settings.new(), Records.new())
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "no later flush or write brings it back")
	assert_true(_service.load_run(_config) == null, "nothing to resume")


func test_delete_run_while_a_reader_holds_the_temp_file() -> void:
	assert_true(_service.save_run(_state(111)), "a saved run")
	F.write_text(_run_temp(), _text_of(222))    # a newer save still in its temp file
	var reader: FileAccess = FileAccess.open(_run_temp(), FileAccess.READ)
	_service.delete_run()
	if reader != null:
		reader.close()
	assert_true(_service.load_run(_config) == null, "the newer temp file cannot bring the run back")
	assert_false(_service.has_run(), "and nothing is left once loaded")


func test_delete_run_while_a_reader_holds_the_run_file() -> void:
	assert_true(_service.save_run(_state(111)), "a saved run")
	var reader: FileAccess = FileAccess.open(_run_path(), FileAccess.READ)
	_service.delete_run()
	if reader != null:
		reader.close()
	assert_true(_service.load_run(_config) == null, "the ended run does not come back")
	assert_false(_service.has_run(), "and nothing is left once loaded")
