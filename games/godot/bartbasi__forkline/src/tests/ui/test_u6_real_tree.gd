# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/ui/real_tree_u6.gd in a second Godot process, because layout and touch need a
## running scene tree and the test runner has none. It covers a finger sliding over every
## scrolling list (a drag scrolls and presses nothing, a tap presses, a slow drag is a tap),
## and the Restart and music buttons at both Fold5 sizes.


func test_lists_scroll_under_a_finger_and_the_new_buttons_fit_at_both_fold5_sizes() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/real_tree_u6.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the U6 real tree checks")
