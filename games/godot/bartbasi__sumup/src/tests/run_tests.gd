extends SceneTree
## Headless test runner for SumUp. No addons.
##
## Run from the repo root:
##     godot --headless --path . --script res://tests/run_tests.gd
##
## Finds every tests/**/test_*.gd file, runs each method whose name starts
## with "test_" on a fresh instance, and prints a summary. Exits with code 0
## when every test passes and 1 otherwise. A script error raised while a test
## runs (a null access, for example) counts as a failure for that test.

const TESTS_ROOT: String = "res://tests"
const BaseTest: GDScript = preload("res://tests/base_test.gd")


## Collects script errors raised while a test runs. Godot can log from any
## thread, so access goes through a mutex.
class ErrorCatcher extends Logger:
	var _mutex: Mutex = Mutex.new()
	var _errors: PackedStringArray = PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != Logger.ERROR_TYPE_SCRIPT:
			return
		var text: String = rationale if not rationale.is_empty() else code
		_mutex.lock()
		_errors.append("script error in %s() at %s:%d: %s" % [function, file, line, text])
		_mutex.unlock()

	## Returns the errors logged since the last call and clears the list.
	func take() -> PackedStringArray:
		_mutex.lock()
		var result: PackedStringArray = _errors
		_errors = PackedStringArray()
		_mutex.unlock()
		return result


var _catcher: ErrorCatcher = ErrorCatcher.new()


func _initialize() -> void:
	OS.add_logger(_catcher)
	var exit_code: int = _run_all()
	OS.remove_logger(_catcher)
	quit(exit_code)


func _run_all() -> int:
	print("SumUp tests, Godot %s" % Engine.get_version_info().string)
	var files: PackedStringArray = PackedStringArray()
	_collect_test_files(TESTS_ROOT, files)
	files.sort()
	# `-- --only=core,save` runs only those areas (folders under tests/).
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--only="):
			var areas: PackedStringArray = argument.trim_prefix("--only=").split(",", false)
			var kept: PackedStringArray = PackedStringArray()
			for path: String in files:
				for area: String in areas:
					if path.begins_with(TESTS_ROOT.path_join(area) + "/"):
						kept.append(path)
						break
			files = kept
	var total: int = 0
	var failed: int = 0
	for path: String in files:
		var result: Vector2i = _run_file(path)
		total += result.x
		failed += result.y
	print("Ran %d tests in %d files: %d passed, %d failed." % [total, files.size(), total - failed, failed])
	return 1 if failed > 0 else 0


func _collect_test_files(dir_path: String, out: PackedStringArray) -> void:
	for sub_dir: String in DirAccess.get_directories_at(dir_path):
		_collect_test_files(dir_path.path_join(sub_dir), out)
	for file_name: String in DirAccess.get_files_at(dir_path):
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			out.append(dir_path.path_join(file_name))


## Runs every test method in one file. Returns (tests run, tests failed).
func _run_file(path: String) -> Vector2i:
	var script: GDScript = load(path) as GDScript
	if script == null or not script.can_instantiate():
		_print_failure(path, "(load)", PackedStringArray(["could not load the script; see the parse error above"]))
		return Vector2i(1, 1)
	var probe: Variant = script.new()
	if not (probe is BaseTest):
		_print_failure(path, "(load)", PackedStringArray(["test files must extend res://tests/base_test.gd"]))
		return Vector2i(1, 1)
	var names: PackedStringArray = _test_method_names(script)
	var failed: int = 0
	for method_name: String in names:
		var problems: PackedStringArray = _run_test(script, method_name)
		if not problems.is_empty():
			failed += 1
			_print_failure(path, method_name, problems)
	print("%s %s (%d tests)" % ["ok  " if failed == 0 else "FAIL", path, names.size()])
	return Vector2i(names.size(), failed)


func _test_method_names(script: GDScript) -> PackedStringArray:
	var names: PackedStringArray = PackedStringArray()
	for method: Dictionary in script.get_script_method_list():
		var method_name: String = method["name"]
		if method_name.begins_with("test_") and not names.has(method_name):
			names.append(method_name)
	return names


func _run_test(script: GDScript, method_name: String) -> PackedStringArray:
	var test: BaseTest = script.new()
	_catcher.take()
	test.before_each()
	test.call(method_name)
	test.after_each()
	var problems: PackedStringArray = test.failures.duplicate()
	problems.append_array(_catcher.take())
	return problems


func _print_failure(path: String, method_name: String, problems: PackedStringArray) -> void:
	print("FAIL %s :: %s" % [path, method_name])
	for problem: String in problems:
		print("       %s" % problem)
