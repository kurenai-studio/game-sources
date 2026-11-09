extends SceneTree
## Minimal headless test runner with no external dependencies.
## Usage: godot --headless -s res://tests/run_tests.gd
## Exit code is 1 when any test fails, so CI can gate on it.

const TEST_DIR := "res://tests/unit"

var _passed := 0
var _failed := 0


func _initialize() -> void:
	# Never touch the player's own save files.
	GameSettings.path = "user://test_run_settings.cfg"
	Progress.path = "user://test_run_progress.cfg"
	var files := DirAccess.get_files_at(TEST_DIR)
	if files.is_empty():
		push_error("No test files found in %s" % TEST_DIR)
		quit(1)
		return
	for file in files:
		if file.begins_with("test_") and file.ends_with(".gd"):
			_run_suite(TEST_DIR.path_join(file))
	print("\n%d passed, %d failed" % [_passed, _failed])
	for file in [GameSettings.path, Progress.path]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(file))
	quit(1 if _failed > 0 else 0)


func _run_suite(path: String) -> void:
	var script := load(path) as GDScript
	# A script with parse errors still loads but cannot be instantiated;
	# count it as a failure instead of silently running zero tests.
	if script == null or not script.can_instantiate():
		print("  FAIL %s (could not load: parse error?)" % path.get_file())
		_failed += 1
		return
	for method in script.get_script_method_list():
		var method_name: String = method.name
		if not method_name.begins_with("test_"):
			continue
		var suite: TestCase = script.new()
		suite.call(method_name)
		if suite.failures.is_empty():
			_passed += 1
			print("  PASS %s::%s" % [path.get_file(), method_name])
		else:
			_failed += 1
			print("  FAIL %s::%s\n       %s" % [path.get_file(), method_name, "\n       ".join(suite.failures)])
