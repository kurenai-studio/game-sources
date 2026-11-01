# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/ui/real_tree_build_map.gd in a second Godot process, because layout needs a
## running scene tree and the test runner has none. Opening the build panel with 8, 9 and 10
## towers keeps the map's scale and position in the landscape layout, and every card stays
## inside the screen and at least 48 dp (step U6b).


func test_build_panel_with_eight_nine_and_ten_towers_leaves_the_map_alone() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/real_tree_build_map.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the build panel and map checks")
