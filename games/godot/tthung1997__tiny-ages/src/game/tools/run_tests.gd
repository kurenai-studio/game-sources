extends SceneTree
## Runs every test suite under res://tests/ headlessly and exits non-zero on any failure:
##   & $env:GODOT --headless --path game --script res://tools/run_tests.gd [-- <suite filter>]
## Suites extend McpTestSuite (the assertion base class from the Godot AI addon) and run with
## its McpTestRunner. They run headless only: the editor's test_run MCP tool cannot instantiate
## them, because that needs every class under test to be @tool and the sim deliberately is not.
## Filter by suite name or leave empty to run all.

const TESTS_DIR: String = "res://tests"


func _init() -> void:
	var filter: String = ""
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	if not user_args.is_empty():
		filter = user_args[0]
	var suites: Array = []
	for file_name: String in DirAccess.get_files_at(TESTS_DIR):
		if not (file_name.begins_with("test_") and file_name.ends_with(".gd")):
			continue
		var script: GDScript = load("%s/%s" % [TESTS_DIR, file_name]) as GDScript
		if script == null:
			push_error("Could not load %s" % file_name)
			quit(2)
			return
		suites.append(script.new())
	var runner: McpTestRunner = McpTestRunner.new()
	var results: Dictionary = runner.run_suites(suites, filter, "", {}, true)
	for entry: Dictionary in results.get("results", []):
		var status: String = "ok  "
		if entry.get("skipped", false):
			status = "skip"
		elif not entry.get("passed", false):
			status = "FAIL"
		print("%s %s.%s %s" % [
			status, entry.get("suite", "?"), entry.get("test", "?"), entry.get("message", ""),
		])
	print("%d passed, %d failed, %d skipped (%d ms)" % [
		results.get("passed", 0), results.get("failed", 0), results.get("skipped", 0),
		results.get("duration_ms", 0),
	])
	if OS.get_environment("SH_SLOW_TESTS") != "":
		_print_slowest(results.get("results", []), 15)
	quit(1 if results.get("failed", 0) > 0 or results.get("total", 0) == 0 else 0)


## Set SH_SLOW_TESTS=1 to list the slowest tests, to see where the time goes.
func _print_slowest(entries: Array, count: int) -> void:
	var sorted: Array = entries.duplicate()
	sorted.sort_custom(
		func(a: Dictionary, b: Dictionary) -> bool:
			return a.get("duration_ms", 0) > b.get("duration_ms", 0)
	)
	for entry: Dictionary in sorted.slice(0, count):
		print("slow %6d ms  %s.%s" % [
			entry.get("duration_ms", 0), entry.get("suite", "?"), entry.get("test", "?"),
		])
