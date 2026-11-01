# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/render/frames_checks.gd in a second Godot process, because drawing needs real
## frames and the test runner has none. Every region 1 level plays on a real Battle at both
## Fold5 sizes, so every _draw() in src/render/ runs and any script error fails here.


func test_map_view_draws_through_real_frames() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/render/frames_checks.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL") or line.contains("SCRIPT ERROR") or line.contains("ERROR:"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the frame checks")
