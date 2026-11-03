extends RefCounted


static func read(device: int, deadzone: float) -> Vector2:
	if device < 0:
		return Vector2.ZERO
	var left := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_LEFT_X),
		Input.get_joy_axis(device, JOY_AXIS_LEFT_Y)
	)
	var right := Vector2(
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y)
	)
	var active := left if left.length() >= right.length() else right
	if active.length() < deadzone:
		return Vector2.ZERO
	return active.limit_length(1.0)
