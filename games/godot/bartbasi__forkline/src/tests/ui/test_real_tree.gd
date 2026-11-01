# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/ui/real_tree_checks.gd in a second Godot process, because layout
## and touch need a running scene tree and the test runner has none. It covers
## touch sizes at both Fold5 sizes, real taps (the coffee button's deadzone and
## its one hand-off per tap), the About first screenful and the App's screens.


func test_layout_and_touch_checks_pass_in_a_real_scene_tree() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/real_tree_checks.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the real tree checks")
