extends Node
## Registers input actions in code so all keyboard and gamepad bindings
## live in one readable place instead of verbose project.godot entries.

const DEADZONE := 0.25


func _enter_tree() -> void:
	_add_action(&"move_left", [KEY_A, KEY_LEFT], [JOY_BUTTON_DPAD_LEFT], JOY_AXIS_LEFT_X, -1.0)
	_add_action(&"move_right", [KEY_D, KEY_RIGHT], [JOY_BUTTON_DPAD_RIGHT], JOY_AXIS_LEFT_X, 1.0)
	_add_action(&"move_up", [KEY_W, KEY_UP], [JOY_BUTTON_DPAD_UP], JOY_AXIS_LEFT_Y, -1.0)
	_add_action(&"move_down", [KEY_S, KEY_DOWN], [JOY_BUTTON_DPAD_DOWN], JOY_AXIS_LEFT_Y, 1.0)
	_add_action(&"shift_form", [KEY_SPACE, KEY_SHIFT], [JOY_BUTTON_A, JOY_BUTTON_RIGHT_SHOULDER])
	_add_action(&"restart", [KEY_R], [])
	_add_action(&"pause", [KEY_ESCAPE, KEY_P], [JOY_BUTTON_START])
	_add_action(&"mute", [KEY_M], [])


func _add_action(action: StringName, keys: Array[int], buttons: Array[int], axis: int = -1, axis_direction: float = 0.0) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action, DEADZONE)
	for key in keys:
		var key_event := InputEventKey.new()
		key_event.physical_keycode = key
		InputMap.action_add_event(action, key_event)
	for button in buttons:
		var button_event := InputEventJoypadButton.new()
		button_event.button_index = button
		InputMap.action_add_event(action, button_event)
	if axis >= 0:
		var motion_event := InputEventJoypadMotion.new()
		motion_event.axis = axis
		motion_event.axis_value = axis_direction
		InputMap.action_add_event(action, motion_event)
