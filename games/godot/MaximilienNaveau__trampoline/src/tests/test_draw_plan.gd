# Standalone checks for draw_plan.gd, runnable via:
#   godot4 --headless --path . --script tests/test_draw_plan.gd
extends SceneTree

var _failures := 0


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: ", message)
	else:
		print("FAIL: ", message)
		_failures += 1


func _initialize() -> void:
	_test_known_values()

	if _failures == 0:
		print("\nAll checks passed.")
	else:
		print("\n", _failures, " check(s) failed.")
	quit(1 if _failures > 0 else 0)


func _test_known_values() -> void:
	_check(DrawPlan.hand_size(1) == 9, "solo hands hold 9 tiles")
	_check(DrawPlan.hand_size(2) == 13, "2-player hands hold 13 tiles (the rules' first draw)")
	_check(DrawPlan.hand_size(3) == 12, "3-player hands hold 12 tiles")
	_check(DrawPlan.hand_size(4) == 11, "4-player hands hold 11 tiles")
