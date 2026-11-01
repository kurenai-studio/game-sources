extends "res://tests/base_test.gd"
## SEC-05. The save files are plain ASCII, so any byte of 0x80 or above is
## refused before the text is decoded: fast, and without the UTF-8 decoder's
## one error per bad byte. This holds for every file the service reads (temp,
## real and .bak, run and profile), and the service never writes such a byte.

const F := preload("res://tests/save/save_fixtures.gd")


## Every error and warning logged while it is attached.
class Collector extends Logger:
	var mutex: Mutex = Mutex.new()
	var errors: int = 0

	func _log_error(_function: String, _file: String, _line: int, _code: String, _rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == Logger.ERROR_TYPE_WARNING:
			return
		mutex.lock()
		errors += 1
		mutex.unlock()


var _dir: String = ""
var _service: SaveService = null
var _config: GameConfig = GameConfig.new()
var _log: Collector = null


func before_each() -> void:
	_dir = F.make_temp_dir()
	_service = SaveService.new(_dir)
	_config = GameConfig.new()
	_log = Collector.new()
	OS.add_logger(_log)


func after_each() -> void:
	OS.remove_logger(_log)
	_service = null
	F.remove_temp_dir(_dir)


func _run_path() -> String:
	return _dir.path_join("run.json")


func _profile_path() -> String:
	return _dir.path_join("profile.json")


func _state(score: int) -> RunState:
	return F.run(F.with_cell(F.board_d(), Vector2i(0, 0), 5), score, PackedInt64Array(), 0, 0, 0, 1000)


func _run_bytes(score: int) -> PackedByteArray:
	return F.to_text(SaveCodec.run_to_data(_state(score))).to_utf8_buffer()


func _profile_bytes(best_score: int) -> PackedByteArray:
	var records: Records = Records.new()
	records.best_score = BigNum.from_int(best_score)
	return F.to_text(SaveCodec.profile_to_data(Settings.new(), records)).to_utf8_buffer()


## bytes with its first tab (whitespace, so the JSON stays valid apart from
## the byte itself) replaced by high.
static func _with_high_byte(bytes: PackedByteArray, high: int) -> PackedByteArray:
	var copy: PackedByteArray = bytes.duplicate()
	copy[copy.find(9)] = high
	return copy


func _loaded_score() -> int:
	var state: RunState = _service.load_run(_config)
	return -1 if state == null else state.score.to_int()


func _loaded_best_score() -> int:
	var records: Records = Records.new()
	_service.load_profile(Settings.new(), records)
	return records.best_score.to_int()


func test_plain_ascii_check() -> void:
	assert_true(SaveService._is_plain_ascii(_run_bytes(5)), "a run file is plain ASCII")
	assert_true(SaveService._is_plain_ascii(_profile_bytes(5)), "a profile file is plain ASCII")
	for high: int in [0x80, 0xBF, 0xC3, 0xEF, 0xFF]:
		assert_false(SaveService._is_plain_ascii(_with_high_byte(_run_bytes(5), high)), "byte %d refused" % high)
	assert_false(SaveService._is_plain_ascii(PackedByteArray([0x7B, 0, 0x7D])), "NUL still refused")
	assert_true(SaveService._is_plain_ascii(PackedByteArray([0x7F])), "0x7F is ASCII")


func test_every_run_file_with_one_high_byte_is_refused() -> void:
	# Real file: refused and deleted, no run.
	F.write_bytes(_run_path(), _with_high_byte(_run_bytes(100), 0x80))
	assert_eq(_loaded_score(), -1, "real file refused")
	assert_false(FileAccess.file_exists(_run_path()), "and deleted")
	# Temp file: refused and deleted, the real file is used.
	F.write_bytes(_run_path(), _run_bytes(100))
	F.write_bytes(_run_path() + ".tmp", _with_high_byte(_run_bytes(200), 0xC3))
	assert_eq(_loaded_score(), 100, "temp refused, real file used")
	assert_false(FileAccess.file_exists(_run_path() + ".tmp"), "temp deleted")
	# .bak: refused and deleted.
	DirAccess.remove_absolute(_run_path())
	F.write_bytes(_run_path() + ".bak", _with_high_byte(_run_bytes(50), 0xFF))
	assert_eq(_loaded_score(), -1, ".bak refused")
	assert_false(FileAccess.file_exists(_run_path() + ".bak"), ".bak deleted")
	assert_eq(_log.errors, 0, "no error logged")


func test_every_profile_file_with_one_high_byte_is_refused() -> void:
	F.write_bytes(_profile_path(), _with_high_byte(_profile_bytes(100), 0x80))
	assert_eq(_loaded_best_score(), 0, "real file refused: defaults")
	F.write_bytes(_profile_path(), _profile_bytes(100))
	F.write_bytes(_profile_path() + ".tmp", _with_high_byte(_profile_bytes(200), 0xEF))
	assert_eq(_loaded_best_score(), 100, "temp refused, real file used")
	assert_false(FileAccess.file_exists(_profile_path() + ".tmp"), "temp deleted")
	DirAccess.remove_absolute(_profile_path())
	F.write_bytes(_profile_path() + ".bak", _with_high_byte(_profile_bytes(50), 0xFF))
	assert_eq(_loaded_best_score(), 0, ".bak refused: defaults")
	assert_false(FileAccess.file_exists(_profile_path() + ".bak"), ".bak deleted")
	assert_eq(_log.errors, 0, "no error logged")


func test_a_utf8_byte_order_mark_is_refused() -> void:
	var bom: PackedByteArray = PackedByteArray([0xEF, 0xBB, 0xBF])
	bom.append_array(_run_bytes(100))
	F.write_bytes(_run_path(), bom)
	assert_eq(_loaded_score(), -1, "the game never writes one")


func test_256_kb_of_high_bytes_is_refused_fast_and_quietly() -> void:
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(SaveService.MAX_BYTES)
	bytes.fill(0xFF)
	var random_bytes: PackedByteArray = PackedByteArray()
	random_bytes.resize(SaveService.MAX_BYTES)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	for index: int in random_bytes.size():
		random_bytes[index] = rng.randi_range(0x80, 0xFF)
	for suffix: String in ["", ".tmp", ".bak"]:
		F.write_bytes(_run_path() + suffix, bytes)
		F.write_bytes(_profile_path() + suffix, random_bytes)
	var start: int = Time.get_ticks_msec()
	assert_eq(_loaded_best_score(), 0, "profile defaults")
	assert_eq(_loaded_score(), -1, "no run")
	var spent: int = Time.get_ticks_msec() - start
	assert_true(spent < 300, "six 256 KB files refused in %d ms" % spent)
	assert_eq(_log.errors, 0, "no error logged")


func test_a_non_ascii_skin_id_is_never_written() -> void:
	var settings: Settings = Settings.new()
	settings.set_skin_id(StringName("g" + String.chr(0xFC) + "mdrop"))
	assert_false(_service.save_profile(settings, Records.new()), "save_profile refuses")
	assert_false(_service.queue_profile(settings, Records.new()), "queue_profile refuses")
	_service.flush()
	assert_false(FileAccess.file_exists(_profile_path()), "nothing written")
	assert_false(FileAccess.file_exists(_profile_path() + ".tmp"), "no temp file")
