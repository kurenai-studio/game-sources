extends SceneTree
# Геймпад: действия от кнопок/стиков, фокус в меню, «Назад» кнопкой B, экран «Управление».
var main
var f := 0
var shots := ""

func _initialize() -> void:
	shots = OS.get_environment("SHOTS")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func btn(i: int, on: bool, dev := 0) -> void:
	var e := InputEventJoypadButton.new()
	e.button_index = i
	e.pressed = on
	e.device = dev
	Input.parse_input_event(e)

func axis(a: int, v: float, dev := 0) -> void:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	e.device = dev
	Input.parse_input_event(e)

func snap(n: String) -> void:
	if shots != "":
		root.get_viewport().get_texture().get_image().save_png(shots + "/" + n + ".png")

func _process(_d: float) -> bool:
	f += 1
	match f:
		5:
			btn(JOY_BUTTON_A, true)
		6:
			print("p1_jump=", Input.is_action_pressed("p1_jump"), " ui_accept=", Input.is_action_pressed("ui_accept"))
			btn(JOY_BUTTON_A, false)
			axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)
			axis(JOY_AXIS_LEFT_X, -0.8)
			btn(JOY_BUTTON_LEFT_SHOULDER, true, 1)
		7:
			print("p1_ult=", Input.is_action_pressed("p1_ult"), " p1 axis=", Input.get_axis("p1_left", "p1_right"),
					" p2_a1=", Input.is_action_pressed("p2_a1"), " p1_a1=", Input.is_action_pressed("p1_a1"))
			axis(JOY_AXIS_TRIGGER_RIGHT, 0.0)
			axis(JOY_AXIS_LEFT_X, 0.0)
			btn(JOY_BUTTON_LEFT_SHOULDER, false, 1)
			# фокус в главном меню по крестовине
			btn(JOY_BUTTON_DPAD_DOWN, true)
		8:
			btn(JOY_BUTTON_DPAD_DOWN, false)
		10:
			var fo := root.get_viewport().gui_get_focus_owner()
			print("menu focus=", fo.text if fo else "none")
			main._on_mode_chosen("controls")
		14:
			snap("pad_controls")
			for n in main.world.get_children():
				if n is ControlsScreen:
					n._mode = "story"
					n._refresh()
		16:
			snap("pad_controls_story")
			for n in main.world.get_children():
				if n is ControlsScreen:
					n._mode = "shared"
					n._refresh()
		18:
			snap("pad_controls_shared")
			for n in main.world.get_children():
				if n is ControlsScreen:
					n._tab = "keys"
					n._refresh()
		22:
			snap("pad_keys")
			btn(JOY_BUTTON_B, true)
		23:
			btn(JOY_BUTTON_B, false)
		26:
			print("after B: mode=", main.mode)
			var d := StorySave.new_game("Тест", StoryLook.default_look())
			main.start_story(2, d)
		32:
			btn(JOY_BUTTON_BACK, true)        # SEL — рюкзак
		33:
			btn(JOY_BUTTON_BACK, false)
		36:
			print("paused=", paused)
			btn(JOY_BUTTON_RIGHT_SHOULDER, true)   # RB — следующая вкладка
		37:
			btn(JOY_BUTTON_RIGHT_SHOULDER, false)
		40:
			for n in main.world.get_children():
				if n is StoryInventory: print("tab=", n._tab)
			btn(JOY_BUTTON_B, true)
		41:
			btn(JOY_BUTTON_B, false)
		44:
			print("paused after B=", paused)
			btn(JOY_BUTTON_START, true)
		45:
			btn(JOY_BUTTON_START, false)
		50:
			snap("pad_pause")
			print("pause open=", paused)
			btn(JOY_BUTTON_B, true)
		51:
			btn(JOY_BUTTON_B, false)
		54:
			print("paused after B=", paused)
			StorySave.delete_slot(2)
			return true
	return false
