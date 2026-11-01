# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/ui/real_tree_u4.gd in a second Godot process, because layout needs a running
## scene tree and the test runner has none. It covers the ten tower build panel and the
## panels of the new towers at both Fold5 sizes (docs/ARCHITECTURE.md 14.11).


func test_ten_tower_build_panel_and_new_tower_panels_at_both_fold5_sizes() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/real_tree_u4.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the U4 real tree checks")
