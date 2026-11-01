extends "res://tests/base_test.gd"
## SEC-04 in the App. When the profile cannot be saved for the whole session
## (its file could not be opened at launch), the App logs that once, not on
## every move or settings change. A save that works again ends the row, so a
## later failure is logged again.

const U := preload("res://tests/ui/ui_fixtures.gd")
const WARNING: String = "App: the profile could not be saved"


## Counts the warnings that hold WARNING.
class Warnings extends Logger:
	var mutex: Mutex = Mutex.new()
	var count: int = 0

	func _log_error(_function: String, _file: String, _line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if not (code.contains(WARNING) or rationale.contains(WARNING)):
			return
		mutex.lock()
		count += 1
		mutex.unlock()


var _dir: String = ""
var _app: App = null
var _quits: Array[int] = []
var _warnings: Warnings = null


func before_each() -> void:
	_dir = U.make_temp_dir()
	_quits = []
	Motion.bind_tweens = false
	_warnings = Warnings.new()
	OS.add_logger(_warnings)


func after_each() -> void:
	OS.remove_logger(_warnings)
	U.stop_app(_app)
	U.remove_temp_dir(_dir)
	Motion.bind_tweens = true


func test_a_blocked_profile_is_logged_once() -> void:
	U.save_game(_dir, null, 500)
	_app = U.start_app(_dir, _quits)
	var profile_path: String = _dir.path_join(SaveService.PROFILE_FILE)
	var blocked: SaveService = SaveService.new(_dir)
	blocked.set_unopenable(profile_path, -1)
	blocked.load_profile(Settings.new(), Records.new())
	_app.save = blocked
	for i: int in 4:
		_app.settings.set_sound_on(i % 2 == 1)
	assert_eq(_warnings.count, 1, "four failed saves, one warning")
	blocked.set_unopenable(profile_path, 0)
	_app.save = SaveService.new(_dir)
	_app.settings.set_sound_on(false)
	assert_eq(_warnings.count, 1, "a save that works logs nothing")
	_app.save = blocked
	_app.settings.set_sound_on(true)
	assert_eq(_warnings.count, 2, "a failure after a save that worked is logged again")
