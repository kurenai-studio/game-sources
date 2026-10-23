extends SceneTree
## Runs every test file in this directory and exits with a failure code if any test fails.
## Run with: godot --headless --path . --script tests/run_tests.gd
##
## A test file is any test_*.gd here; its tests are the methods whose names start with test_.
## Each test gets a fresh instance and reports failures through check(). An error the engine
## reports while a test runs (a script error, a refused call) fails that test too, even if every
## check passed: the game would have hit the same error.

const TEST_DIRECTORY := "res://tests"


## Hears every error the engine reports, warnings aside.
class ErrorCounter extends Logger:
	var errors: Array[String] = []

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_WARNING:
			errors.append("%s:%d in %s: %s" % [file, line, function, rationale if not rationale.is_empty() else code])


func _init() -> void:
	var errors := ErrorCounter.new()
	OS.add_logger(errors)
	var failures := 0
	var count := 0
	for file_name in DirAccess.get_files_at(TEST_DIRECTORY):
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		var script := load(TEST_DIRECTORY.path_join(file_name)) as GDScript
		if script == null or not script.can_instantiate():
			# A test file that doesn't compile runs no tests; that's a failure, not a pass.
			count += 1
			failures += 1
			print("FAIL  %s: doesn't compile" % file_name)
			continue
		for method in script.get_script_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_"):
				continue
			count += 1
			var test: TestCase = script.new()
			var errors_before := errors.errors.size()
			test.call(method_name)
			for error in errors.errors.slice(errors_before):
				test.failures.append("the engine reported an error: " + error)
			if test.failures.is_empty():
				print("pass  %s: %s" % [file_name, method_name])
			else:
				failures += 1
				print("FAIL  %s: %s" % [file_name, method_name])
				for message in test.failures:
					print("      " + message)
	print("\n%d of %d tests passed." % [count - failures, count])
	quit(1 if failures > 0 or count == 0 else 0)
