extends "res://tests/base_test.gd"
## The last good copy (SEC-02). Before a save replaces run.json or
## profile.json, the current file becomes <name>.bak when it holds a save that
## passed every check. Loading falls back to the .bak only when no valid temp
## file and no valid real file exist, and checks the .bak as strictly as the
## real file. Every file lives in a temp folder inside user://.

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


func _run_bak() -> String:
	return _run_path() + ".bak"


func _run_temp() -> String:
	return _run_path() + ".tmp"


func _profile_path() -> String:
	return _dir.path_join("profile.json")


func _profile_bak() -> String:
	return _profile_path() + ".bak"


func _profile_temp() -> String:
	return _profile_path() + ".tmp"


func _state(score: int) -> RunState:
	return F.run(F.with_cell(F.board_d(), Vector2i(0, 0), 5), score, PackedInt64Array(), 0, 0, 0, 1000)


func _text_of(score: int) -> String:
	return F.to_text(SaveCodec.run_to_data(_state(score)))


func _records(best_score: int) -> Records:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(best_score)
	records.best_tile = 11
	return records


func _profile_text(best_score: int) -> String:
	return F.to_text(SaveCodec.profile_to_data(Settings.new(), _records(best_score)))


## A fresh service on the same folder, as after the app restarts.
func _reopen() -> SaveService:
	_service = SaveService.new(_dir)
	return _service


func _loaded_score() -> int:
	var state: RunState = _service.load_run(_config)
	return -1 if state == null else state.score.to_int()


func _loaded_best_score() -> int:
	var records: Records = Records.new()
	_service.load_profile(Settings.new(), records)
	return records.best_score.to_int()


## Three ways a file renamed just before a power cut can come back.
@warning_ignore("integer_division")
func _damaged(good_text: String) -> Dictionary[String, PackedByteArray]:
	var nul: PackedByteArray = PackedByteArray()
	nul.resize(good_text.to_utf8_buffer().size())
	nul.fill(0)
	return {
		"empty": PackedByteArray(),
		"cut short": good_text.left(good_text.length() / 3).to_utf8_buffer(),
		"NUL filled": nul,
	}


## Run A then run B, saved by the service: run.json holds B, run.json.bak A.
func _save_two_runs() -> void:
	assert_true(_service.save_run(_state(111)), "run A saved")
	assert_true(_service.save_run(_state(222)), "run B saved")


func _save_two_profiles() -> void:
	assert_true(_service.save_profile(Settings.new(), _records(5000)), "profile A saved")
	assert_true(_service.save_profile(Settings.new(), _records(9000)), "profile B saved")


# Making the copy

func test_the_first_save_makes_no_bak() -> void:
	assert_true(_service.save_run(_state(111)), "run saved")
	assert_true(_service.save_profile(Settings.new(), _records(5000)), "profile saved")
	assert_false(FileAccess.file_exists(_run_bak()), "no run .bak")
	assert_false(FileAccess.file_exists(_profile_bak()), "no profile .bak")


func test_the_next_save_keeps_the_last_one_as_bak() -> void:
	_save_two_runs()
	_save_two_profiles()
	assert_eq(F.read_text(_run_path()), _text_of(222), "run.json is the newest")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "run.json.bak is the one before")
	assert_eq(F.read_text(_profile_path()), _profile_text(9000), "profile.json is the newest")
	assert_eq(F.read_text(_profile_bak()), _profile_text(5000), "profile.json.bak is the one before")
	assert_false(FileAccess.file_exists(_run_temp()), "no run temp left")
	assert_false(FileAccess.file_exists(_profile_temp()), "no profile temp left")


func test_queued_saves_keep_a_bak_too() -> void:
	assert_true(_service.queue_run(_state(111)), "A queued")
	_service.flush()
	assert_true(_service.queue_run(_state(222)), "B queued")
	_service.flush()
	assert_eq(F.read_text(_run_bak()), _text_of(111), "the .bak is A")
	assert_eq(F.read_text(_run_path()), _text_of(222), "run.json is B")


func test_a_file_loaded_as_valid_becomes_the_bak_after_a_restart() -> void:
	assert_true(_service.save_run(_state(111)), "A saved")
	assert_true(_service.save_profile(Settings.new(), _records(5000)), "profile A saved")
	_reopen()
	assert_eq(_loaded_score(), 111, "A loads")
	assert_eq(_loaded_best_score(), 5000, "profile A loads")
	assert_true(_service.save_run(_state(222)), "B saved")
	assert_true(_service.save_profile(Settings.new(), _records(9000)), "profile B saved")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "A is the run .bak")
	assert_eq(F.read_text(_profile_bak()), _profile_text(5000), "profile A is the .bak")


func test_a_file_never_checked_never_becomes_the_bak() -> void:
	# A fresh service has not loaded or written run.json, so it does not know
	# the file is good and keeps the old .bak.
	F.write_text(_run_path(), "{\"format\": 2, \"cells\": [1")
	F.write_text(_run_bak(), _text_of(111))
	assert_true(_service.save_run(_state(222)), "B saved")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "the old .bak stays")
	assert_eq(F.read_text(_run_path()), _text_of(222), "run.json is B")


func test_a_file_changed_on_disk_never_becomes_the_bak() -> void:
	_save_two_runs()
	F.write_text(_run_path(), "")
	assert_true(_service.save_run(_state(333)), "C saved")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "the damaged file did not replace the .bak")
	assert_eq(F.read_text(_run_path()), _text_of(333), "run.json is C")


# Loading from the copy

func test_a_damaged_run_loads_the_bak() -> void:
	for what: String in _damaged(_text_of(222)):
		_save_two_runs()
		F.write_bytes(_run_path(), _damaged(_text_of(222))[what])
		_reopen()
		assert_eq(_loaded_score(), 111, "%s run.json: the .bak loads" % what)
		_service.delete_run()


func test_a_damaged_profile_loads_the_bak() -> void:
	for what: String in _damaged(_profile_text(9000)):
		DirAccess.remove_absolute(_profile_path())
		DirAccess.remove_absolute(_profile_bak())
		_reopen()
		_save_two_profiles()
		F.write_bytes(_profile_path(), _damaged(_profile_text(9000))[what])
		_reopen()
		var settings: Settings = Settings.new()
		var records: Records = Records.new()
		_service.load_profile(settings, records)
		assert_eq(F.text(records.best_score), "5000", "%s profile.json: Best Score from the .bak" % what)
		assert_eq(records.best_tile, 11, "%s profile.json: Best Tile from the .bak" % what)


func test_a_missing_run_loads_the_bak() -> void:
	_save_two_runs()
	DirAccess.remove_absolute(_run_path())
	_reopen()
	assert_true(_service.has_run(), "the .bak counts as a saved run")
	assert_eq(_loaded_score(), 111, "the .bak loads")


func test_a_profile_with_one_bad_field_loads_the_bak() -> void:
	_save_two_profiles()
	var data: Dictionary = SaveCodec.profile_to_data(Settings.new(), _records(9000))
	(data["records"] as Dictionary)["best_tile"] = 65536
	F.write_text(_profile_path(), F.to_text(data))
	_reopen()
	var records: Records = Records.new()
	_service.load_profile(Settings.new(), records)
	assert_eq(F.text(records.best_score), "5000", "the whole .bak is used, not part of each")
	assert_eq(records.best_tile, 11, "Best Tile from the .bak")


func test_the_next_save_after_a_bak_load_keeps_the_bak() -> void:
	_save_two_runs()
	F.write_text(_run_path(), "")
	_reopen()
	assert_eq(_loaded_score(), 111, "the .bak loads")
	assert_true(_service.save_run(_state(333)), "C saved")
	assert_eq(_loaded_score(), 333, "C loads")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "the .bak is still A")


# A valid newer file always wins

func test_a_valid_run_wins_over_the_bak() -> void:
	_save_two_runs()
	_reopen()
	assert_eq(_loaded_score(), 222, "run.json wins")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "the .bak is left alone")


func test_a_valid_profile_wins_over_the_bak() -> void:
	_save_two_profiles()
	_reopen()
	assert_eq(_loaded_best_score(), 9000, "profile.json wins")


func test_a_valid_temp_wins_over_the_bak() -> void:
	# A kill between the two renames: run.json became the .bak, the temp file
	# holds the newer run and there is no run.json.
	F.write_text(_run_bak(), _text_of(111))
	F.write_text(_run_temp(), _text_of(222))
	assert_eq(_loaded_score(), 222, "the temp file wins")
	assert_eq(F.read_text(_run_path()), _text_of(222), "and is renamed into place")
	assert_eq(F.read_text(_run_bak()), _text_of(111), "the .bak is left alone")


func test_a_valid_temp_wins_over_a_damaged_run_and_the_bak() -> void:
	F.write_text(_run_path(), "")
	F.write_text(_run_bak(), _text_of(111))
	F.write_text(_run_temp(), _text_of(333))
	assert_eq(_loaded_score(), 333, "the temp file wins")


func test_a_valid_profile_temp_wins_over_the_bak() -> void:
	F.write_text(_profile_bak(), _profile_text(5000))
	F.write_text(_profile_temp(), _profile_text(9000))
	assert_eq(_loaded_best_score(), 9000, "the temp file wins")
	assert_eq(F.read_text(_profile_path()), _profile_text(9000), "and is renamed into place")


func test_a_damaged_temp_does_not_hide_the_bak() -> void:
	F.write_text(_run_bak(), _text_of(111))
	F.write_text(_run_temp(), _text_of(222).left(20))
	assert_eq(_loaded_score(), 111, "the .bak loads")
	assert_false(FileAccess.file_exists(_run_temp()), "the broken temp is deleted")


# A damaged copy is refused

## .bak contents that must be refused, each with a damaged run.json.
func _bad_run_baks() -> Dictionary[String, PackedByteArray]:
	var bad: Dictionary[String, PackedByteArray] = _damaged(_text_of(111))
	bad["over 256 KB"] = F.padded(_text_of(111), SaveService.MAX_BYTES + 1).to_utf8_buffer()
	bad["nested too deep"] = ("[".repeat(40) + "]".repeat(40)).to_utf8_buffer()
	var negative: Dictionary = SaveCodec.run_to_data(_state(111))
	negative["score"] = "-5"
	bad["negative score"] = F.to_text(negative).to_utf8_buffer()
	var not_power: Dictionary = SaveCodec.run_to_data(_state(111))
	(not_power["cells"] as Array)[0] = 1.5
	bad["a tile not a power of two"] = F.to_text(not_power).to_utf8_buffer()
	var wide: Dictionary = SaveCodec.run_to_data(_state(111))
	wide["columns"] = 6
	bad["wrong board size"] = F.to_text(wide).to_utf8_buffer()
	bad["not an object"] = "[1, 2, 3]".to_utf8_buffer()
	bad["a string"] = "\"run\"".to_utf8_buffer()
	return bad


func test_a_damaged_run_bak_is_refused() -> void:
	var bad: Dictionary[String, PackedByteArray] = _bad_run_baks()
	for what: String in bad:
		F.write_text(_run_path(), "")
		F.write_bytes(_run_bak(), bad[what])
		_reopen()
		assert_null(_service.load_run(_config), "%s .bak: no run" % what)
		assert_false(FileAccess.file_exists(_run_bak()), "%s .bak: deleted" % what)
		assert_false(_service.has_run(), "%s .bak: nothing left" % what)


func test_a_damaged_profile_bak_is_refused() -> void:
	var bad: Dictionary[String, PackedByteArray] = _damaged(_profile_text(5000))
	bad["over 256 KB"] = F.padded(_profile_text(5000), SaveService.MAX_BYTES + 1).to_utf8_buffer()
	bad["nested too deep"] = ("[".repeat(40) + "]".repeat(40)).to_utf8_buffer()
	var negative: Dictionary = SaveCodec.profile_to_data(Settings.new(), _records(5000))
	(negative["records"] as Dictionary)["best_score"] = "-1"
	bad["negative Best Score"] = F.to_text(negative).to_utf8_buffer()
	var high: Dictionary = SaveCodec.profile_to_data(Settings.new(), _records(5000))
	(high["records"] as Dictionary)["best_tile"] = 65536
	bad["Best Tile out of range"] = F.to_text(high).to_utf8_buffer()
	for what: String in bad:
		F.write_text(_profile_path(), "")
		F.write_bytes(_profile_bak(), bad[what])
		_reopen()
		var settings: Settings = Settings.new()
		var records: Records = Records.new()
		_service.load_profile(settings, records)
		assert_eq(F.text(records.best_score), "0", "%s .bak: default Best Score" % what)
		assert_eq(records.best_tile, 0, "%s .bak: default Best Tile" % what)
		assert_true(settings.sound_on, "%s .bak: default sound" % what)
		assert_false(FileAccess.file_exists(_profile_bak()), "%s .bak: deleted" % what)


func test_a_damaged_profile_with_part_valid_keeps_that_part_when_the_bak_is_bad() -> void:
	var data: Dictionary = SaveCodec.profile_to_data(Settings.new(), _records(9000))
	(data["records"] as Dictionary)["best_tile"] = 65536
	F.write_text(_profile_path(), F.to_text(data))
	F.write_text(_profile_bak(), "")
	var records: Records = Records.new()
	_service.load_profile(Settings.new(), records)
	assert_eq(F.text(records.best_score), "9000", "the valid part of profile.json is kept, as before")
	assert_eq(records.best_tile, 0, "the bad part is the default")


# Deleting

func test_delete_run_leaves_no_bak() -> void:
	_save_two_runs()
	assert_true(FileAccess.file_exists(_run_bak()), "a .bak exists")
	_service.delete_run()
	assert_false(FileAccess.file_exists(_run_path()), "no run.json")
	assert_false(FileAccess.file_exists(_run_bak()), "no run.json.bak")
	assert_false(FileAccess.file_exists(_run_temp()), "no temp")
	assert_false(_service.has_run(), "no run")
	_reopen()
	assert_null(_service.load_run(_config), "the ended run never comes back")


func test_after_delete_run_the_next_run_starts_without_a_bak() -> void:
	_save_two_runs()
	_service.delete_run()
	assert_true(_service.save_run(_state(5)), "the next run's first save")
	assert_false(FileAccess.file_exists(_run_bak()), "no .bak from the ended run")
	F.write_text(_run_path(), "")
	_reopen()
	assert_null(_service.load_run(_config), "a damaged first save never brings the ended run back")


func test_delete_run_leaves_the_profile_bak() -> void:
	_save_two_profiles()
	_save_two_runs()
	_service.delete_run()
	assert_eq(F.read_text(_profile_bak()), _profile_text(5000), "the profile .bak stays")


# AT-154 (SPL-01, GDD 15.1 LG1 to LG3): a damaged run file with a valid last
# good copy continues that copy.

## Run A, score 19,000 with an Undo snapshot.
func _at_154_a() -> RunState:
	return F.run(F.with_cell(F.board_d(), Vector2i(0, 0), 5), 19000, F.board_d(), 40, 0, 0, 18000)


## Run B, one chain later: score 20,000.
func _at_154_b() -> RunState:
	return F.run(F.with_cell(F.board_d(), Vector2i(0, 0), 6), 20000, F.with_cell(F.board_d(), Vector2i(0, 0), 5), 1000, 0, 0, 18000)


## The setup: a profile with Best Score 20,000, run A then run B saved, then
## run.json cut off part way. No temp file.
@warning_ignore("integer_division")
func _at_154_setup() -> PackedByteArray:
	assert_true(_service.save_profile(Settings.new(), _records(20000)), "the profile")
	assert_true(_service.save_run(_at_154_a()), "run A saved")
	assert_true(_service.save_run(_at_154_b()), "run B saved")
	var b_text: String = F.read_text(_run_path())
	F.write_text(_run_path(), b_text.left(b_text.length() / 2))
	assert_false(FileAccess.file_exists(_run_temp()), "no temp file")
	return F.read_bytes(_profile_path())


func test_at_154_a_a_damaged_run_continues_the_last_good_copy() -> void:
	var profile: PackedByteArray = _at_154_setup()
	_reopen()
	var loaded: RunState = _service.load_run(_config)
	assert_not_null(loaded, "a run loads")
	assert_true(loaded != null and loaded.equals(_at_154_a()), "run A, equal in every field")
	assert_eq(F.text(loaded.best_at_start) if loaded != null else "", "18000", "its starting Best Score too")
	assert_false(FileAccess.file_exists(_run_path()), "the damaged run.json is deleted")
	assert_eq(_loaded_best_score(), 20000, "the profile is untouched: Best Score 20,000")
	assert_eq(F.read_bytes(_profile_path()), profile, "byte for byte")


@warning_ignore("integer_division")
func test_at_154_b_a_damaged_last_good_copy_too_means_no_run() -> void:
	var profile: PackedByteArray = _at_154_setup()
	var a_text: String = F.read_text(_run_bak())
	F.write_text(_run_bak(), a_text.left(a_text.length() / 2))
	_reopen()
	assert_null(_service.load_run(_config), "no run")
	assert_false(FileAccess.file_exists(_run_path()), "the damaged run.json is deleted")
	assert_false(FileAccess.file_exists(_run_bak()), "the damaged last good copy is deleted")
	assert_false(_service.has_run(), "nothing left")
	assert_eq(F.read_bytes(_profile_path()), profile, "the profile is untouched")
	assert_eq(_loaded_best_score(), 20000, "Best Score 20,000")


func test_at_154_c_a_valid_temp_holding_b_wins() -> void:
	_at_154_setup()
	F.write_text(_run_temp(), F.to_text(SaveCodec.run_to_data(_at_154_b())))
	_reopen()
	var loaded: RunState = _service.load_run(_config)
	assert_true(loaded != null and loaded.equals(_at_154_b()), "run B: the temp wins")
