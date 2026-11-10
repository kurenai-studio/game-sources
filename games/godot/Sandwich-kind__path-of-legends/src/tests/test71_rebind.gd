extends SceneTree
# Переназначение кнопок геймпада: новая кнопка, обмен с занятой, отмена через 5 секунд.
var main
var f := 0
var cs: ControlsScreen
var shots := ""
func _initialize() -> void:
	shots = OS.get_environment("SHOTS")
	Pad.reset("fight")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func btn(i: int, on: bool) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = i
	e.pressed = on
	Input.parse_input_event(e)
func held(a: String) -> bool:
	return Input.is_action_pressed(a)
func _process(_d: float) -> bool:
	f += 1
	match f:
		3:
			main._on_mode_chosen("controls")
		5:
			for n in main.world.get_children():
				if n is ControlsScreen: cs = n
			cs._editing = true
			cs._refresh()
		8:
			cs._start_wait("jump", null)
		30:
			btn(JOY_BUTTON_Y, true)
		31:
			btn(JOY_BUTTON_Y, false)
			print("jump -> ", Pad.binds("fight")["jump"], "  msg: ", cs._msg)
			cs._start_wait("reload", null)
		50:
			btn(JOY_BUTTON_Y, true)
		51:
			print("Y presses: p1_reload=", held("p1_reload"), " p1_jump=", held("p1_jump"))
			btn(JOY_BUTTON_Y, false)
			var b := Pad.binds("fight")
			print("swap: reload=", b["reload"], " jump=", b["jump"], "  msg: ", cs._msg)
		52:
			var on := []
			for e in InputMap.action_get_events("p1_jump"):
				if e is InputEventJoypadButton: on.append(e.button_index)
			print("p1_jump buttons in InputMap: ", on)
			cs._start_wait("a1", null)
		70:
			if shots != "": root.get_viewport().get_texture().get_image().save_png(shots + "/rebind.png")
		400:
			print("after timeout: a1=", Pad.binds("fight")["a1"], " waiting=", cs._wait_fn, "  msg: ", cs._msg)
			print("story untouched: jump=", Pad.binds("story")["jump"])
			btn(JOY_BUTTON_B, true)
		401:
			btn(JOY_BUTTON_B, false)
		404:
			print("B leaves edit list: editing=", cs._editing, " screen alive=", is_instance_valid(cs))
			if shots != "": root.get_viewport().get_texture().get_image().save_png(shots + "/rebind_diagram.png")
			Pad.reset("fight")
			return true
	return false
