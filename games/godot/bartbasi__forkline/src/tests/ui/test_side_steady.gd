# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/ui/real_tree_side_steady.gd in a second Godot process, because layout needs a
## running scene tree and the test runner has none. Opening the build, tower, creature, draft
## or wave preview panel in the landscape side column keeps the map's scale and position and
## the column's width, at the Fold5 inner size and in a narrow landscape window (step U6b).


func test_every_side_panel_leaves_the_map_alone_inner_and_narrow() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/real_tree_side_steady.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the side column checks")
