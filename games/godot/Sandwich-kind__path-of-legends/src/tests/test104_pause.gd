extends SceneTree
# Пауза в Арене и Дуэли: открыть кнопкой «Меню» и Esc, настройки (кнопки перестраиваются),
# продолжить, начать матч заново, выйти в главное меню с подтверждением.
var main
var f := 0

func _initialize() -> void:
	Save.load_game()
	Config.SHOW_TOUCH_ON_PC = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func pause_node():
	if main.world == null:
		return null
	for c in main.world.get_children():
		if c is BattlePause:
			return c
	return null

func count_touch() -> int:
	var n := 0
	for g in ["touch_ui", "pad_ui"]:
		for x in get_nodes_in_group(g):
			if not x.is_queued_for_deletion():
				n += 1
	return n

func key(k: Key) -> void:
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := ev.duplicate()
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _process(_d: float) -> bool:
	f += 1
	match f:
		5:
			main.sel = [0, 0]
			main.start_arena(false, 1)
		200:
			print("arena: touch layers=", count_touch())
			main.hud.menu_pressed.emit()
		205:
			var pz = pause_node()
			print("menu button -> pause=", pz != null, " paused=", paused)
			pz._settings()
		215:
			var pz = pause_node()
			pz._sub.back_pressed.emit()
		225:
			print("after settings: touch layers=", count_touch(), " paused=", paused)
			pause_node().resume()
		230:
			print("resumed: paused=", paused, " pause node=", pause_node() != null)
		240:
			main._on_duel_ready("test_field", 3, 5, [0, 1], {})
		400:
			key(KEY_ESCAPE)
		405:
			print("duel esc -> pause=", pause_node() != null, " paused=", paused)
			pause_node()._restart()
		420:
			print("restart: mode=", main.mode, " paused=", paused, " round=", main.round_num)
			main.open_pause()
		425:
			var pz = pause_node()
			pz._confirm_exit()
		430:
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/pause_exit.png")
			pause_node()._exit()
		440:
			print("exit: mode=", main.mode, " paused=", paused)
			return true
	return false
