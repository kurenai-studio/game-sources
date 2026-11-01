# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Runs tests/ui/real_tree_hud_steady.gd in a second Godot process, because layout needs a
## running scene tree and the test runner has none. Whatever the call button says (ready,
## calling, last wave out, and every other label), the HUD keeps its size and the map keeps
## its size and place, at the Fold5 cover and inner sizes (QA 2026-10-29 L1). Every label also
## takes a font size of 40 or more and fits the button (QA 2026-10-30 L1).
##
## The child gets a 600 s watchdog of its own; the process wait here is not timed, so a busy
## machine only makes the test slow, never wrong.


func test_the_call_button_never_changes_the_hud_or_moves_the_map() -> void:
	var output: Array = []
	var args: PackedStringArray = [
		"--headless", "--path", ProjectSettings.globalize_path("res://"),
		"--script", "res://tests/ui/real_tree_hud_steady.gd",
	]
	var code: int = OS.execute(OS.get_executable_path(), args, output, true)
	var text: String = "\n".join(PackedStringArray(output))
	for line: String in text.split("\n"):
		if line.begins_with("FAIL"):
			fail(line)
	assert_true(text.contains("checks, 0 failed"), "the checks did not finish cleanly: %s" % text.right(600))
	assert_eq(code, 0, "exit code of the HUD checks")
