extends SceneTree
# Один контроллер на двоих: левая половина — Игрок 1, правая — Игрок 2.
var main
var f := 0
var checks := [
	["btn", JOY_BUTTON_DPAD_LEFT, "p1_a1"], ["btn", JOY_BUTTON_DPAD_DOWN, "p1_ult"], ["btn", JOY_BUTTON_LEFT_SHOULDER, "p1_reload"],
	["btn", JOY_BUTTON_LEFT_STICK, "p1_jump"], ["axis", JOY_AXIS_TRIGGER_LEFT, "p1_shoot"], ["axis", JOY_AXIS_LEFT_X, "p1_right"],
	["axisn", JOY_AXIS_LEFT_Y, "p1_jump"],
	["btn", JOY_BUTTON_X, "p2_a1"], ["btn", JOY_BUTTON_A, "p2_ult"], ["btn", JOY_BUTTON_RIGHT_SHOULDER, "p2_reload"],
	["btn", JOY_BUTTON_RIGHT_STICK, "p2_jump"], ["axis", JOY_AXIS_TRIGGER_RIGHT, "p2_shoot"], ["axisn", JOY_AXIS_RIGHT_X, "p2_left"],
	["axis", JOY_AXIS_RIGHT_Y, "p2_down"]]
var i := 0
var bad := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func send(c: Array, on: bool) -> void:
	if c[0] == "btn":
		var e := InputEventJoypadButton.new()
		e.button_index = c[1]
		e.pressed = on
		Input.parse_input_event(e)
	else:
		var m := InputEventJoypadMotion.new()
		m.axis = c[1]
		m.axis_value = (0.0 if not on else (-1.0 if c[0] == "axisn" else 1.0))
		Input.parse_input_event(m)
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		for n in main.get_children():
			if n is Pad: n.set_process(false)      # без настоящего контроллера раскладку включаем вручную
		Pad.apply_layout("shared")
	if f >= 5 and f % 2 == 1:
		if i >= checks.size():
			print("shared layout ok: ", bad == 0)
			Pad.apply_layout("fight")
			return true
		send(checks[i], true)
	elif f >= 5:
		var c: Array = checks[i]
		var hit := []
		for a in InputMap.get_actions():
			if (String(a).begins_with("p1_") or String(a).begins_with("p2_")) and Input.is_action_pressed(a):
				hit.append(a)
		var ok: bool = c[2] in hit and hit.size() == 1
		if not ok:
			bad += 1
			print("FAIL ", c, " -> ", hit)
		send(c, false)
		i += 1
	return false
