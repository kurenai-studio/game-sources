extends "res://tests/base_test.gd"
## SaveService's queued writes (QA4-02): one write at a time on a worker
## thread, the newest data for a file wins, and every synchronous call waits
## for queued writes first, so nothing interleaves and reads see every save.

const F := preload("res://tests/save/save_fixtures.gd")

var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()


func after_each() -> void:
	_service.flush()
	_service = null
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


## A valid run whose score marks which save it was.
func _state(score: int) -> RunState:
	return F.run(F.board_d(), score)


## The run on disk, read with a separate service, so nothing waits for us.
func _on_disk() -> RunState:
	return SaveService.new(_dir).load_run(_config)


func test_a_queued_run_reaches_the_disk() -> void:
	assert_true(_service.queue_run(_state(10)), "queued")
	_service.flush()
	var loaded: RunState = _on_disk()
	assert_true(loaded != null and loaded.score.to_int() == 10, "on disk after flush")
	assert_false(FileAccess.file_exists(_run_path() + ".tmp"), "no temp file left")


func test_reads_wait_for_queued_writes() -> void:
	_service.queue_run(_state(20))
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null and loaded.score.to_int() == 20, "load_run sees the queued save")
	_service.queue_run(_state(21))
	assert_true(_service.has_run(), "has_run waits too")
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(777)
	_service.queue_profile(Settings.new(), records)
	var read: Records = Records.new()
	_service.load_profile(Settings.new(), read)
	assert_eq(F.text(read.best_score), "777", "load_profile sees the queued profile")


func test_the_newest_queued_data_wins() -> void:
	for score: int in range(1, 101):
		_service.queue_run(_state(score))
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 100, "the last of 100 quick saves is what stays")


func test_a_synchronous_save_lands_after_queued_ones() -> void:
	_service.queue_run(_state(1))
	assert_true(_service.save_run(_state(2)), "saved at once")
	assert_eq(_on_disk().score.to_int(), 2, "the synchronous save is on disk, after the queued one")
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 2, "and nothing older overwrites it later")


func test_a_queued_save_lands_after_a_synchronous_one() -> void:
	_service.save_run(_state(1))
	_service.queue_run(_state(2))
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 2, "the queued save is newer and wins")


func test_delete_run_after_a_queued_save_never_brings_it_back() -> void:
	_service.queue_run(_state(5))
	_service.delete_run()
	assert_false(FileAccess.file_exists(_run_path()), "deleted")
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "and still deleted once everything has run")
	assert_false(_service.has_run(), "no run")


func test_a_file_that_has_not_changed_is_not_written_again() -> void:
	_service.queue_run(_state(5))
	_service.flush()
	DirAccess.remove_absolute(_run_path())
	_service.queue_run(_state(5))
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "the same bytes again are skipped")
	_service.queue_run(_state(6))
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 6, "new bytes are written")
	_service.delete_run()
	_service.queue_run(_state(6))
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 6, "after a delete the same bytes are written again")


func test_queue_refuses_a_run_that_would_not_load_back() -> void:
	assert_false(_service.queue_run(F.run(F.board_d(), BigNum.pow2(GameConfig.new().max_score_bits))), "a score at the ceiling refused")
	assert_false(_service.queue_run(null), "null refused")
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "nothing written")


func test_a_failed_queued_write_keeps_the_last_good_save() -> void:
	assert_true(_service.save_run(_state(1)), "a good save")
	DirAccess.make_dir_absolute(_run_path() + ".tmp")    # the temp file cannot be written
	_service.queue_run(_state(2))
	_service.flush()    # reports the failure with one push_warning
	assert_eq(_on_disk().score.to_int(), 1, "the last good save stays")
	DirAccess.remove_absolute(_run_path() + ".tmp")
	_service.queue_run(_state(2))
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 2, "the same data is tried again once writing works")


func test_many_saves_and_reads_interleaved_stay_consistent() -> void:
	for step: int in range(1, 201):
		_service.queue_run(_state(step))
		if step % 2 == 0:
			var records: Records = Records.new()
			records.best_score = BigNum.from_int(step)
			_service.queue_profile(Settings.new(), records)
		if step % 7 == 0:
			var loaded: RunState = _service.load_run(_config)
			assert_true(loaded != null and loaded.score.to_int() == step, "step %d reads its own save" % step)
	_service.flush()
	assert_eq(_on_disk().score.to_int(), 200, "the last run")
	var read: Records = Records.new()
	SaveService.new(_dir).load_profile(Settings.new(), read)
	assert_eq(F.text(read.best_score), "200", "the last profile")
	assert_false(FileAccess.file_exists(_run_path() + ".tmp"), "no temp file left")


func test_flush_with_nothing_queued_is_harmless() -> void:
	_service.flush()
	_service.flush()
	assert_false(FileAccess.file_exists(_run_path()), "nothing written")


func test_a_service_dropped_with_writes_queued_still_writes_them() -> void:
	var service: SaveService = SaveService.new(_dir)
	service.queue_run(_state(42))
	service = null
	# The writer task holds the service until it has written everything. Watch
	# the files without touching them, then read.
	for attempt: int in 400:
		if FileAccess.file_exists(_run_path()) and not FileAccess.file_exists(_run_path() + ".tmp"):
			break
		OS.delay_msec(5)
	var loaded: RunState = _on_disk()
	assert_true(loaded != null and loaded.score.to_int() == 42, "the queued run lands")
