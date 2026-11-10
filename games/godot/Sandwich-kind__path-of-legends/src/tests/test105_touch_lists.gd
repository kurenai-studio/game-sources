extends SceneTree
# Бестиарий и Книга легенд: листать пальцем, коротким касанием выбирать; геймпад — список едет за выбором.
var main
var f := 0
var bs
var inv

func _initialize() -> void:
	Save.load_game()
	Save.see_all()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func mouse(at: Vector2, kind: String) -> void:
	var w := root.get_final_transform() * at
	if kind == "move":
		var m := InputEventMouseMotion.new()
		m.position = w
		m.global_position = w
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		Input.parse_input_event(m)
		return
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.position = w
	b.global_position = w
	b.pressed = kind == "down"
	Input.parse_input_event(b)

func dpad(btn: int) -> void:
	var ev := InputEventJoypadButton.new()
	ev.button_index = btn as JoyButton
	ev.pressed = true
	Input.parse_input_event(ev)
	var e2 := ev.duplicate()
	e2.pressed = false
	Input.parse_input_event(e2)

func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null

func _process(_d: float) -> bool:
	f += 1
	match f:
		5: main._on_mode_chosen("bestiary")
		12:
			bs = find(BestiaryScreen)
			bs._tab_btns[4].pressed.emit()          # «Самоцветы» — 14 противников
		20:
			var r: Rect2 = bs._scroll.get_global_rect()
			print("bestiary: cards=", bs._cards.size(), " scroll max=", bs._scroll.get_v_scroll_bar().max_value, " page=", bs._scroll.get_v_scroll_bar().page)
			mouse(r.get_center() + Vector2(0, 120), "down")
		22: mouse(bs._scroll.get_global_rect().get_center() + Vector2(0, 60), "move")
		24: mouse(bs._scroll.get_global_rect().get_center() + Vector2(0, -40), "move")
		26: mouse(bs._scroll.get_global_rect().get_center() + Vector2(0, -160), "move")
		28:
			mouse(bs._scroll.get_global_rect().get_center() + Vector2(0, -160), "up")
		50:
			print("after drag: scroll=", bs._scroll.scroll_vertical, " sel=", bs._sel, " (выбор не должен измениться от листания)")
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/best_scrolled.png")
			# коснуться карточки 13 (последний ряд)
			var c: Button = bs._cards[12]
			mouse(c.get_global_rect().get_center(), "down")
		52: mouse(bs._cards[12].get_global_rect().get_center(), "up")
		56:
			print("tap card 13: sel=", bs._sel)
			bs._scroll.scroll_vertical = 0
			bs._cards[0].grab_focus()
		60: dpad(JOY_BUTTON_DPAD_DOWN)
		64: dpad(JOY_BUTTON_DPAD_DOWN)
		68: dpad(JOY_BUTTON_DPAD_DOWN)
		74:
			var fo := root.gui_get_focus_owner()
			print("pad down x3: focus card=", bs._cards.find(fo), " scroll=", bs._scroll.scroll_vertical)
			main._on_mode_chosen("inventory")
		84:
			inv = find(InventoryScreen)
			var r2: Rect2 = inv._lsc.get_global_rect()
			mouse(r2.get_center() + Vector2(-40, 150), "down")
		86: mouse(inv._lsc.get_global_rect().get_center() + Vector2(-40, 100), "move")
		88: mouse(inv._lsc.get_global_rect().get_center() + Vector2(-40, 0), "move")
		90: mouse(inv._lsc.get_global_rect().get_center() + Vector2(-40, -120), "move")
		92: mouse(inv._lsc.get_global_rect().get_center() + Vector2(-40, -120), "up")
		110:
			print("inventory drag: scroll=", inv._lsc.scroll_vertical, " hero=", inv._hero, " (не должен смениться)")
			var tap: Vector2 = inv._lsc.get_global_rect().get_center() + Vector2(-40, 100)
			mouse(tap, "down")
		112:
			mouse(inv._lsc.get_global_rect().get_center() + Vector2(-40, 100), "up")
		120:
			print("inventory tap: hero=", Characters.LIST[inv._hero]["name"], " scroll kept=", inv._lsc.scroll_vertical)
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/inv_scrolled.png")
			return true
	return false
