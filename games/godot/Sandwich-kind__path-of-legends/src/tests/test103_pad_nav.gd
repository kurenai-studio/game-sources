extends SceneTree
# Навигация геймпадом: главное меню, магазин, пауза в бою.
# Шлём нажатия крестовины и печатаем, какая кнопка выбрана.
var main
var f := 0
var steps: Array = []
var si := 0
var wait := 0
var pending := ""

func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
	var scen := OS.get_environment("SCEN")
	if scen == "" or scen == "menu":
		steps = [["focus", "Арена"], ["L"], ["D"], ["D"], ["R"], ["U"], ["U"], ["U"], ["R"], ["D"], ["D"], ["L"], ["L"], ["U"]]
	elif scen == "shop":
		steps = [["mode", "shop"], ["wait", 20], ["U"], ["U"], ["D"], ["R"], ["A"], ["wait", 90], ["show"], ["U"], ["U"], ["R"], ["R"], ["D"], ["shot", "shop_pad"], ["A"], ["wait", 10], ["show"], ["shot", "shop_card"], ["R"], ["L"], ["B"], ["wait", 10], ["show"], ["B"], ["wait", 10], ["show"]]
	elif scen == "arena":
		steps = [["mode", "arena"], ["wait", 40], ["show"], ["U"], ["U"], ["R"], ["D"], ["D"], ["L"], ["R"], ["R"], ["R"], ["R"], ["U"], ["U"], ["U"]]
	elif scen == "inv":
		steps = [["mode", "inventory"], ["wait", 30], ["show"], ["D"], ["D"], ["D"], ["D"], ["D"], ["D"], ["D"], ["D"], ["D"], ["D"], ["R"], ["U"]]
	elif scen == "pause":
		steps = [["arena"], ["wait", 300], ["start"], ["wait", 10], ["show"], ["shot", "pause_menu"], ["D"], ["D"], ["D"], ["U"], ["A"], ["wait", 20], ["show"], ["shot", "pause_settings"], ["B"], ["wait", 10], ["show"], ["start"], ["wait", 10], ["paused?"]]

func dpad(btn: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.device = 0
	ev.button_index = btn as JoyButton
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)

func focus_name() -> String:
	var o := root.gui_get_focus_owner()
	if o == null:
		return "<нет>"
	var t := ""
	if o is Button:
		t = (o as Button).text
	if t == "":
		t = o.name
	return "%s @%s" % [t.replace("\n", " "), str(o.get_global_rect().position.round())]

func _process(_d: float) -> bool:
	f += 1
	if f < 10:
		return false
	if wait > 0:
		wait -= 1
		return false
	if pending != "":
		print(pending, " -> ", focus_name())
		pending = ""
	if si >= steps.size():
		print("DONE")
		return true
	var s: Array = steps[si]
	si += 1
	match s[0]:
		"focus":
			for b in Pad._candidates(main):
				if b is Button and b.text == s[1]:
					b.grab_focus()
			print("start: ", focus_name())
		"mode":
			main._on_mode_chosen(s[1])
		"arena":
			main.sel = [0, 0]
			main.start_arena(false, 1)
		"wait":
			wait = s[1]
		"show":
			print("   focus: ", focus_name(), "  paused=", paused)
		"shot":
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/%s.png" % s[1])
		"start":
			dpad(JOY_BUTTON_START)
		"paused?":
			print("paused=", paused)
		"A":
			dpad(JOY_BUTTON_A)
			pending = "A"
			wait = 2
		"B":
			dpad(JOY_BUTTON_B)
			pending = "B"
			wait = 2
		_:
			var m := {"L": JOY_BUTTON_DPAD_LEFT, "R": JOY_BUTTON_DPAD_RIGHT, "U": JOY_BUTTON_DPAD_UP, "D": JOY_BUTTON_DPAD_DOWN}
			dpad(m[s[0]])
			wait = 2
			pending = s[0]
	return false
