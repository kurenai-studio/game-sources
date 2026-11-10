extends SceneTree
# Экранная крестовина: вид в Арене (один, вдвоём) и в Дуэли; у игрока 2 «влево» — слева;
# угол крестовины нажимает две кнопки сразу.
var main
var f := 0
var step := 0
var shots := "/tmp/claude-0/st/"

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	StorySettings.load_all()
	StorySettings._cache["touch_move"] = "dpad"
	StorySettings._cache["touch_panel"] = OS.get_environment("PANEL") == "1"
	StorySettings._cache["dpad_size"] = int(OS.get_environment("SIZE")) if OS.get_environment("SIZE") != "" else 100
	Config.SHOW_TOUCH_ON_PC = true
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func shot(n: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	if img:
		img.save_png(shots + n + ".png")

func find_btn(action: String) -> TouchScreenButton:
	for b in _all(main.world):
		if b is TouchScreenButton and b.action == action:
			return b
	return null

func _all(n: Node) -> Array:
	var res: Array = [n]
	for c in n.get_children():
		res += _all(c)
	return res

func touch(at: Vector2, down: bool, idx := 0) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.position = root.get_final_transform() * at
	ev.pressed = down
	Input.parse_input_event(ev)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 11]
		main.start_arena(true, 1)
	if f == 300:
		shot("touch_coop_%s" % OS.get_environment("SIZE"))
		# игрок 2: где кнопки «влево» и «вправо»
		var l := find_btn("p2_left")
		var r := find_btn("p2_right")
		var u := find_btn("p2_jump")
		print("p2 left x=", l.position.x if l else -1.0, " right x=", r.position.x if r else -1.0, " jump y=", u.position.y if u else -1.0, " left y=", l.position.y if l else -1.0)
		var l1 := find_btn("p1_left")
		var r1 := find_btn("p1_right")
		print("p1 left x=", l1.position.x if l1 else -1.0, " right x=", r1.position.x if r1 else -1.0)
		if l:
			touch(l.position, true)
	if f == 302:
		print("touch on p2 '<': p2_left=", Input.is_action_pressed("p2_left"), " p2_right=", Input.is_action_pressed("p2_right"))
		touch(find_btn("p2_left").position, false)
	if f == 304:
		# угол вверх-влево у игрока 2
		var l := find_btn("p2_left")
		var u := find_btn("p2_jump")
		touch(Vector2(l.position.x, u.position.y), true, 1)
	if f == 306:
		print("corner up-left p2: jump=", Input.is_action_pressed("p2_jump"), " left=", Input.is_action_pressed("p2_left"))
		var l := find_btn("p2_left")
		var u := find_btn("p2_jump")
		touch(Vector2(l.position.x, u.position.y), false, 1)
	if f == 310:
		main.show_menu()
		main.sel = [0, 0]
		main.start_arena(false, 1)
	if f == 600:
		shot("touch_solo_%s" % OS.get_environment("SIZE"))
		main.show_menu()
		main._on_duel_ready("test_field", 3, 99, [0, 11], {})
	if f == 700:
		shot("touch_duel_%s" % OS.get_environment("SIZE"))
		return true
	return false
