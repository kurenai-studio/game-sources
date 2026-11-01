extends "res://tests/test_case.gd"

const ACTIONS: Array[StringName] = [
	&"move_left", &"move_right", &"jump", &"interact", &"climb_up", &"climb_down", &"pause",
]


func test_actions_have_keyboard_and_gamepad() -> void:
	for action in ACTIONS:
		check(InputMap.has_action(action), "missing action %s" % action)
		if not InputMap.has_action(action):
			continue
		var events := InputMap.action_get_events(action)
		check(events.any(func(e: InputEvent) -> bool: return e is InputEventKey), "%s: no keyboard binding" % action)
		check(
			events.any(func(e: InputEvent) -> bool: return e is InputEventJoypadButton or e is InputEventJoypadMotion),
			"%s: no gamepad binding" % action,
		)
