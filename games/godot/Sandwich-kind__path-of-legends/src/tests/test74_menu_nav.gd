extends SceneTree
# Геймпад в меню: крестовина переходит между любыми кнопками экрана,
# кнопки по умолчанию («Новая игра», «В бой», «Ещё раз»), экран итогов Арены.
var main
var f := 0
var seq := []
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func btn(i: int) -> void:
	for on in [true, false]:
		var e := InputEventJoypadButton.new()
		e.button_index = i
		e.pressed = on
		Input.parse_input_event(e)
func fo() -> String:
	var o := root.get_viewport().gui_get_focus_owner()
	return (o.text if o is Button and o.text != "" else str(o)) if o else "none"
func _process(_d: float) -> bool:
	f += 1
	match f:
		3: btn(JOY_BUTTON_DPAD_DOWN)
		5: seq.append(fo()); btn(JOY_BUTTON_DPAD_DOWN)
		7: seq.append(fo()); btn(JOY_BUTTON_DPAD_RIGHT)
		9: seq.append(fo()); btn(JOY_BUTTON_DPAD_DOWN)
		11: seq.append(fo()); btn(JOY_BUTTON_DPAD_DOWN)
		13: seq.append(fo()); btn(JOY_BUTTON_DPAD_RIGHT)
		15:
			seq.append(fo())
			print("main menu: ", seq)
			seq = []
			main._on_mode_chosen("arena")
		30:
			Pad.focus_first(main)
			seq.append(fo()); btn(JOY_BUTTON_DPAD_UP)
		32: seq.append(fo()); btn(JOY_BUTTON_DPAD_RIGHT)
		34: seq.append(fo()); btn(JOY_BUTTON_DPAD_DOWN)
		36: seq.append(fo()); btn(JOY_BUTTON_DPAD_RIGHT)
		38:
			seq.append(fo())
			print("arena setup: ", seq)
			seq = []
			btn(JOY_BUTTON_DPAD_DOWN)
		40:
			print("down from Вдвоём: ", fo())
			root.get_viewport().gui_release_focus()
			Pad.focus_first(main)
			print("before A: ", fo()); btn(JOY_BUTTON_A)        # «Новая игра» → выбор легенд
		100:
			Pad.focus_first(main)
			seq.append(fo()); btn(JOY_BUTTON_DPAD_UP)
		102: seq.append(fo()); btn(JOY_BUTTON_DPAD_RIGHT)
		104: seq.append(fo()); btn(JOY_BUTTON_DPAD_LEFT)
		106: seq.append(fo()); btn(JOY_BUTTON_DPAD_LEFT)
		108: seq.append(fo()); btn(JOY_BUTTON_DPAD_DOWN)
		110:
			seq.append(fo())
			print("legend picker: ", seq, "  screens: ", main.world.get_children().map(func(n): return n.get_class() if n.get_script() == null else n.get_script().get_global_name()))
			seq = []
			main.start_arena(false, 1)
		160:
			main._on_arena_finished(false, 0, 0)
		165:
			var arena_playing: bool
			for n in main.get_children():
				if n is Pad: arena_playing = n._playing()
			Pad.focus_first(main)
			seq.append(fo()); btn(JOY_BUTTON_DPAD_RIGHT)
			print("playing during result: ", arena_playing)
		167:
			seq.append(fo())
			print("arena result: ", seq)
			return true
	return false
