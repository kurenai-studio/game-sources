extends Node
## Deadline District: screens, menus, weapon bench shop, HUD and input (keyboard+mouse and twin-stick touch).

class Hud extends Control:
	var main
	func _draw() -> void:
		if main:
			main.draw_hud(self)

const WorldScript = preload("res://scripts/World.gd")
const ORANGE := Color(1.0, 0.62, 0.22)
const GOLD := Color(1.0, 0.84, 0.35)
const INK := Color(0.93, 0.93, 0.97)
const DIM := Color(0.62, 0.65, 0.75)

var world = null
var screen := "title"
var map_i := 0
var shop_tab := "weapons"
var ui_layer: CanvasLayer
var ui: Control
var hud_layer: CanvasLayer
var hud: Hud
var theme: Theme
var font: Font
var msgs: Array = []
var touch_mode := false
var touches := {}
var mouse_held := false
var touch_fire := false
var stick_move := Vector2.ZERO
var portrait := false
var shop_list: VBoxContainer
var shop_cash: Label
var record := false
var ghost_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	font = ThemeDB.fallback_font
	_make_theme()
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud = Hud.new()
	hud.main = self
	hud.set_anchors_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud_layer.add_child(hud)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 20
	add_child(ui_layer)
	ui = Control.new()
	ui.theme = theme
	ui.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_layer.add_child(ui)
	get_tree().root.size_changed.connect(_on_resize)
	_on_resize()
	_new_world(0, true)
	show_screen("title")

func _on_resize() -> void:
	var ws = get_window().size
	var p = ws.y > ws.x
	get_window().content_scale_size = Vector2i(540, 960) if p else Vector2i(960, 540)
	if p != portrait:
		portrait = p
		if is_inside_tree() and ui:
			show_screen.call_deferred(screen)

func vsize() -> Vector2:
	return hud.size if hud and hud.size.x > 0 else Vector2(get_viewport().get_visible_rect().size)

# ------------------------------------------------------------------ theme / widgets
func _sb(bg: Color, border: Color, bw := 2, rad := 8) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(rad)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _make_theme() -> void:
	theme = Theme.new()
	theme.set_stylebox("normal", "Button", _sb(Color(0.13, 0.14, 0.21, 0.96), ORANGE.darkened(0.25)))
	theme.set_stylebox("hover", "Button", _sb(Color(0.22, 0.2, 0.26, 0.98), ORANGE))
	theme.set_stylebox("focus", "Button", _sb(Color(0.22, 0.2, 0.26, 0.0), GOLD))
	theme.set_stylebox("pressed", "Button", _sb(ORANGE, GOLD))
	theme.set_stylebox("disabled", "Button", _sb(Color(0.1, 0.1, 0.13, 0.9), Color(0.3, 0.3, 0.35)))
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_pressed_color", "Button", Color(0.1, 0.06, 0.02))
	theme.set_color("font_disabled_color", "Button", Color(0.45, 0.45, 0.5))
	theme.set_font_size("font_size", "Button", 18)
	theme.set_font_size("font_size", "Label", 16)
	theme.set_color("font_color", "Label", INK)
	theme.set_stylebox("panel", "PanelContainer", _sb(Color(0.05, 0.06, 0.1, 0.94), ORANGE.darkened(0.3), 2, 12))

func _btn(text: String, cb: Callable, minw := 220.0) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(minw, 46)
	b.pressed.connect(func(): Sfx.play("click"); cb.call())
	return b

func _lbl(text: String, size := 16, col := INK, outline := 0) -> Label:
	var l = Label.new()
	l.text = text
	var ls = LabelSettings.new()
	ls.font_size = size
	ls.font_color = col
	if outline > 0:
		ls.outline_size = outline
		ls.outline_color = Color(0.05, 0.02, 0.0)
		ls.shadow_color = Color(0.8, 0.2, 0.05, 0.6)
		ls.shadow_offset = Vector2(0, 4)
		ls.shadow_size = 0
	l.label_settings = ls
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if text.length() > 36 else TextServer.AUTOWRAP_OFF
	return l

func _clear() -> void:
	for c in ui.get_children():
		c.queue_free()
	shop_list = null

func _centered() -> VBoxContainer:
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(cc)
	var v = VBoxContainer.new()
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_theme_constant_override("separation", 10)
	cc.add_child(v)
	return v

func _panel(minsize: Vector2) -> VBoxContainer:
	var cc = CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(cc)
	var dim = ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.move_child(cc, ui.get_child_count() - 1)
	ui.add_child(dim)
	ui.move_child(dim, ui.get_child_count() - 2)
	var pc = PanelContainer.new()
	pc.custom_minimum_size = minsize
	cc.add_child(pc)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	return v

# ------------------------------------------------------------------ world lifecycle
func _new_world(mi: int, demo: bool) -> void:
	if world:
		world.queue_free()
		remove_child(world)
	world = WorldScript.new()
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	add_child(world)
	move_child(world, 0)
	world.setup(mi, demo)
	world.message.connect(_on_msg)
	world.ended.connect(_on_ended)
	msgs.clear()

func start_game(mi: int) -> void:
	map_i = mi
	get_tree().paused = false
	_new_world(mi, false)
	world.mouse_aim = not touch_mode
	record = false
	Sfx.music("calm")
	show_screen("play")

func _on_msg(t: String, c: Color) -> void:
	msgs.append({"t": t, "c": c, "life": 3.5})
	if msgs.size() > 4:
		msgs.pop_front()

func _on_ended(won: bool) -> void:
	record = Data.record_run(map_i, world.wave if won else world.wave - (0 if world.state == "intermission" else 1) if false else world.wave, world.kills, won)
	await get_tree().create_timer(1.3).timeout
	show_screen("won" if won else "over")

# ------------------------------------------------------------------ screens
func show_screen(s: String) -> void:
	screen = s
	_clear()
	get_tree().paused = s in ["shop", "pause", "won"]
	match s:
		"title": _title()
		"maps": _maps()
		"how": _how()
		"play": pass
		"shop": _shop()
		"pause": _pause()
		"over": _over(false)
		"won": _over(true)

func _title() -> void:
	if world == null or not world.demo:
		_new_world(0, true)
	Sfx.music("title")
	var bg = ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05, 0.35)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(bg)
	var v = _centered()
	var big = 66 if portrait else 84
	var t1 = _lbl("DEADLINE", big, ORANGE, 10)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t1)
	var t2 = _lbl("D  I  S  T  R  I  C  T", 30 if portrait else 34, INK, 6)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(t2)
	var tag = _lbl("The whole city pulled an all-nighter. Now it wants your brains.\nSurvive 15 waves. Clock out alive.", 15, DIM)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tag.custom_minimum_size.x = 460 if portrait else 560
	v.add_child(tag)
	v.add_child(Control.new())
	var play = _btn("PLAY", func(): show_screen("maps"), 260)
	v.add_child(play)
	v.add_child(_btn("HOW TO PLAY", func(): show_screen("how"), 260))
	var snd = _btn("SOUND: " + ("ON" if Data.save.sound else "OFF"), func(): pass, 260)
	snd.pressed.connect(func(): _toggle_sound(); snd.text = "SOUND: " + ("ON" if Data.save.sound else "OFF"))
	v.add_child(snd)
	for b in v.get_children():
		if b is Button:
			b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var best = Data.save.best
	var st = _lbl("Best waves  ·  Plaza %d  ·  Overpass %d  ·  Mall %d   |   Total kills %d" % [best[0], best[1], best[2], Data.save.kills], 13, DIM)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	st.custom_minimum_size.x = 440 if portrait else 700
	v.add_child(st)
	play.grab_focus.call_deferred()

func _toggle_sound() -> void:
	Data.save.sound = not Data.save.sound
	Data.write_save()
	Sfx.refresh()

func _maps() -> void:
	var v = _panel(Vector2(minf(vsize().x - 32, 880), 0))
	var h = _lbl("CHOOSE YOUR DISTRICT", 30, ORANGE, 6)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var box = VBoxContainer.new() if portrait else HBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	v.add_child(box)
	for i in 3:
		var mi = Data.MAP_INFO[i]
		var card = VBoxContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size = Vector2(0 if portrait else 250, 0)
		var dc = [Color(0.5, 0.9, 0.5), Color(1.0, 0.7, 0.3), Color(1.0, 0.35, 0.35)][i]
		card.add_child(_lbl(mi.name.to_upper(), 20, GOLD))
		card.add_child(_lbl(mi.diff + "  ·  zombie HP x%.2f" % mi.hp, 14, dc))
		var d = _lbl(mi.desc, 14, DIM)
		d.custom_minimum_size = Vector2(220, 0)
		card.add_child(d)
		card.add_child(_lbl("Best: wave %d" % int(Data.save.best[i]), 14, INK))
		var b = _btn("DEPLOY", func(): start_game(i), 200)
		card.add_child(b)
		if i == 0:
			b.grab_focus.call_deferred()
		box.add_child(card)
	var back = _btn("BACK", func(): show_screen("title"), 160)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)

func _how() -> void:
	var v = _panel(Vector2(minf(vsize().x - 32, 820), minf(vsize().y - 40, 520)))
	var h = _lbl("HOW TO PLAY", 28, ORANGE, 6)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var c = VBoxContainer.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(c)
	var txt = "Survive 15 waves of zombies. Every 5th wave a BOSS clocks in. Kill zombies for cash, then spend it between waves at the WEAPON BENCH.\n\n"
	txt += "KEYBOARD + MOUSE\nWASD / arrows  move   ·   mouse  aim   ·   hold left click  fire\nR reload  ·  1-0 / Q / wheel  switch weapon  ·  Space or Shift  dash\nB build barricade ($60)  ·  T build turret ($300)\nE open bench (between waves, when close)  ·  G / Enter  start next wave\nEsc / P  pause  ·  M  mute\n\n"
	txt += "TOUCH (twin-stick)\nLeft thumb: move stick  ·  Right thumb: aim + fire stick\nButtons: reload, swap, dash, barricade, turret, bench, ready, pause\n\n"
	txt += "DEFENSES\nBarricades block zombies (you can vault your own). Turrets auto-fire. Zombies chew through both, so keep building.\n\nTHE HORDE\n"
	for k in Data.ZOMBIES:
		txt += "%s (wave %d+): %s\n" % [Data.ZOMBIES[k].name, Data.ZOMBIES[k].from, Data.ZOMBIES[k].info]
	txt += "Bosses: The Middle Manager (wave 5), The Auditor (10), Crunch Titan (15)."
	var l = _lbl(txt, 14, INK)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.add_child(l)
	var back = _btn("BACK", func(): show_screen("title"), 160)
	back.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(back)
	back.grab_focus.call_deferred()

func _pause() -> void:
	var v = _panel(Vector2(320, 0))
	var h = _lbl("PAUSED", 30, ORANGE, 6)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var r = _btn("RESUME", func(): show_screen("play"))
	v.add_child(r)
	var snd = _btn("SOUND: " + ("ON" if Data.save.sound else "OFF"), func(): pass)
	snd.pressed.connect(func(): _toggle_sound(); snd.text = "SOUND: " + ("ON" if Data.save.sound else "OFF"))
	v.add_child(snd)
	v.add_child(_btn("RESTART MAP", func(): start_game(map_i)))
	v.add_child(_btn("QUIT TO TITLE", func(): get_tree().paused = false; _new_world(0, true); show_screen("title")))
	r.grab_focus.call_deferred()

func _over(won: bool) -> void:
	var v = _panel(Vector2(minf(vsize().x - 32, 460), 0))
	var h = _lbl("DISTRICT CLEARED!" if won else "YOU GOT CLOCKED OUT", 30, Color(0.5, 1.0, 0.6) if won else Color(1.0, 0.4, 0.35), 6)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var s = "%s  ·  reached wave %d\nKills %d   ·   Score %d" % [Data.MAP_INFO[map_i].name, world.wave, world.kills, world.score]
	if record:
		s += "\nNEW BEST WAVE!"
	var l = _lbl(s, 17, INK)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	var first: Button
	if won:
		first = _btn("KEEP GOING (ENDLESS)", func(): world.continue_endless(); Sfx.music("calm"); show_screen("play"))
		v.add_child(first)
	else:
		first = _btn("TRY AGAIN", func(): start_game(map_i))
		v.add_child(first)
	v.add_child(_btn("CHOOSE MAP", func(): get_tree().paused = false; _new_world(0, true); show_screen("maps")))
	v.add_child(_btn("TITLE", func(): get_tree().paused = false; _new_world(0, true); show_screen("title")))
	first.grab_focus.call_deferred()

# ------------------------------------------------------------------ weapon bench
func open_shop() -> void:
	if world and world.can_shop() and screen == "play":
		Sfx.play("buy")
		show_screen("shop")

func _shop() -> void:
	var vs = vsize()
	var v = _panel(Vector2(minf(vs.x - 24, 800), minf(vs.y - 30, 500)))
	var top = HBoxContainer.new()
	v.add_child(top)
	var h = _lbl("WEAPON BENCH", 24, ORANGE, 5)
	h.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(h)
	shop_cash = _lbl("$%d" % world.cash, 24, GOLD)
	top.add_child(shop_cash)
	var tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	v.add_child(tabs)
	for t in [["weapons", "WEAPONS"], ["defense", "DEFENSE"], ["perks", "PERKS"]]:
		var b = _btn(t[1], func(): shop_tab = t[0]; show_screen("shop"), 0)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if shop_tab == t[0]:
			b.add_theme_stylebox_override("normal", _sb(ORANGE.darkened(0.4), GOLD))
		tabs.add_child(b)
	var sc = ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	shop_list = VBoxContainer.new()
	shop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	shop_list.add_theme_constant_override("separation", 6)
	sc.add_child(shop_list)
	_fill_shop()
	var bot = HBoxContainer.new()
	bot.add_theme_constant_override("separation", 8)
	v.add_child(bot)
	var close = _btn("BACK TO WORK [E]", func(): show_screen("play"), 0)
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(close)
	var rd = _btn("START WAVE %d [G]" % (world.wave + 1), func(): show_screen("play"); world.ready_up(), 0)
	rd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bot.add_child(rd)
	close.grab_focus.call_deferred()

func _row(title: String, desc: String, actions: Array) -> void:
	var r = HBoxContainer.new()
	r.add_theme_constant_override("separation", 6)
	var info = VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	info.add_child(_lbl(title, 16, GOLD))
	var d = _lbl(desc, 12, DIM)
	info.add_child(d)
	r.add_child(info)
	for a in actions:
		var b = _btn(a[0], a[1], 96 if portrait else 120)
		b.custom_minimum_size.y = 40
		b.add_theme_font_size_override("font_size", 14)
		b.disabled = a[2]
		r.add_child(b)
	shop_list.add_child(r)
	var sep = ColorRect.new()
	sep.color = Color(1, 1, 1, 0.06)
	sep.custom_minimum_size.y = 1
	shop_list.add_child(sep)

func _buy(cost: int, fn: Callable) -> void:
	if world.cash < cost:
		Sfx.play("deny")
		return
	world.cash -= cost
	fn.call()
	Sfx.play("buy")
	show_screen("shop")

func _fill_shop() -> void:
	var w = world
	match shop_tab:
		"weapons":
			for i in Data.WEAPONS.size():
				var wd = Data.WEAPONS[i]
				var id: String = wd.id
				var key = str((i + 1) % 10)
				if not w.owned.has(id):
					_row("[%s] %s" % [key, wd.name], wd.desc, [["BUY $%d" % wd.cost, func(): _buy(wd.cost, func(): w.give_weapon(id)), w.cash < wd.cost]])
				else:
					var t = w.tier(id)
					var acts = []
					if t < 3:
						var uc = Data.upgrade_cost(wd, t)
						acts.append(["LV%d $%d" % [t + 2, uc], func(): _buy(uc, func(): w.owned[id] = t + 1; w.refill(id)), w.cash < uc])
					else:
						acts.append(["MAX LV", func(): pass, true])
					if wd.res >= 0 and wd.mag > 0:
						var a = w.ammo[id]
						var full = a[1] >= w.stat_res(id) and a[0] >= w.stat_mag(id)
						var ac = Data.ammo_cost(wd)
						acts.append(["AMMO $%d" % ac, func(): _buy(ac, func(): w.refill(id)), full or w.cash < ac])
					var am = "inf" if wd.res < 0 else "%d+%d" % [w.ammo[id][0], w.ammo[id][1]]
					if wd.mag == 0:
						am = "melee"
					_row("[%s] %s  LV%d" % [key, wd.name, t + 1], "DMG %d · ammo %s · %s" % [int(w.stat_dmg(id)), am, wd.desc], acts)
		"defense":
			_row("Medkit", "Patch up to full health (%d/%d)." % [int(w.hp), int(w.mhp)], [["HEAL $%d" % Data.MEDKIT_COST, func(): _buy(Data.MEDKIT_COST, func(): w.hp = w.mhp), w.hp >= w.mhp or w.cash < Data.MEDKIT_COST]])
			var rc = 0
			for b in w.bars:
				rc += int((b.mhp - b.hp) * 0.25)
			for t in w.turrets:
				rc += int((t.mhp - t.hp) * 0.6)
			_row("Repair defenses", "Fix every barricade and turret (%d barricades, %d turrets)." % [w.bars.size(), w.turrets.size()], [["REPAIR $%d" % rc, func(): _buy(rc, func(): _repair()), rc <= 0 or w.cash < rc]])
			_row("Barricade  ($%d)" % Data.BARRICADE_COST, "Press B (or the touch BAR button) to drop one where you aim. Blocks zombies; you can vault it.", [])
			_row("Auto-turret  ($%d)" % Data.TURRET_COST, "Press T (or the touch TUR button). Fires at the nearest zombie. Max 6.", [])
		"perks":
			for pk in Data.PERKS:
				var pid: String = pk.id
				if w.perks.has(pid):
					_row(pk.name, pk.desc, [["OWNED", func(): pass, true]])
				else:
					_row(pk.name, pk.desc, [["$%d" % pk.cost, func(): _buy(pk.cost, func(): w.apply_perk(pid)), w.cash < pk.cost]])

func _repair() -> void:
	for b in world.bars:
		b.hp = b.mhp
	for t in world.turrets:
		t.hp = t.mhp

# ------------------------------------------------------------------ input
func _process(delta: float) -> void:
	for k in range(msgs.size() - 1, -1, -1):
		msgs[k].life -= delta
		if msgs[k].life <= 0.0:
			msgs.remove_at(k)
	ghost_t -= delta
	if screen == "play" and world and not world.demo:
		var mv = Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): mv.x -= 1
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): mv.x += 1
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): mv.y -= 1
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): mv.y += 1
		world.in_move = mv.normalized() if mv != Vector2.ZERO else stick_move
		world.in_fire = mouse_held or touch_fire
	hud.queue_redraw()

func _unhandled_input(ev: InputEvent) -> void:
	if ev is InputEventKey and ev.pressed and not ev.echo:
		_key(ev.physical_keycode)
	if screen != "play" or world == null or world.demo:
		return
	if ev is InputEventMouseMotion and ev.device != -1:
		if touch_mode and ev.relative.length() > 2.0:
			touch_mode = false
		world.mouse_aim = not touch_mode
	elif ev is InputEventMouseButton and ev.device != -1 and not touch_mode:
		if ev.button_index == MOUSE_BUTTON_LEFT:
			mouse_held = ev.pressed
		elif ev.button_index == MOUSE_BUTTON_RIGHT and ev.pressed:
			world.dash()
		elif ev.button_index == MOUSE_BUTTON_WHEEL_UP and ev.pressed:
			world.cycle(-1)
		elif ev.button_index == MOUSE_BUTTON_WHEEL_DOWN and ev.pressed:
			world.cycle(1)

func _key(k: int) -> void:
	match screen:
		"play":
			match k:
				KEY_ESCAPE, KEY_P: show_screen("pause")
				KEY_R: world.reload()
				KEY_Q: world.cycle(1)
				KEY_SPACE, KEY_SHIFT: world.dash()
				KEY_B: world.place("bar"); ghost_t = 2.0
				KEY_T: world.place("tur"); ghost_t = 2.0
				KEY_E: open_shop()
				KEY_G, KEY_ENTER, KEY_KP_ENTER: world.ready_up()
				KEY_M: _toggle_sound()
				_:
					if k >= KEY_0 and k <= KEY_9:
						world.switch_to((k - KEY_1) if k != KEY_0 else 9)
		"shop":
			if k in [KEY_E, KEY_ESCAPE]:
				show_screen("play")
			elif k == KEY_G:
				show_screen("play")
				world.ready_up()
		"pause":
			if k in [KEY_ESCAPE, KEY_P]:
				show_screen("play")
		"how", "maps":
			if k == KEY_ESCAPE:
				show_screen("title")

func _input(ev: InputEvent) -> void:
	if ev is InputEventScreenTouch:
		touch_mode = true
		if world:
			world.mouse_aim = false
		mouse_held = false
		if screen != "play" or world == null or world.demo:
			return
		var vs = vsize()
		if ev.pressed:
			var b = _button_at(ev.position)
			if b != "":
				touches[ev.index] = {"role": "btn"}
				_press(b)
				get_viewport().set_input_as_handled()
				return
			var role = "move" if ev.position.x < vs.x * 0.5 else "aim"
			touches[ev.index] = {"role": role, "o": ev.position, "p": ev.position}
			if role == "aim":
				touch_fire = true
		else:
			var t = touches.get(ev.index)
			if t:
				if t.role == "move":
					stick_move = Vector2.ZERO
				elif t.role == "aim":
					touch_fire = false
				touches.erase(ev.index)
		get_viewport().set_input_as_handled()
	elif ev is InputEventScreenDrag:
		var t = touches.get(ev.index)
		if t == null or t.role == "btn":
			return
		t.p = ev.position
		var d = t.p - t.o
		if d.length() > 70.0:
			t.o = t.p - d.normalized() * 70.0
			d = t.p - t.o
		if t.role == "move":
			stick_move = d / 70.0 if d.length() > 6.0 else Vector2.ZERO
		elif d.length() > 10.0:
			world.aim = d.angle()
		get_viewport().set_input_as_handled()

func _buttons() -> Array:
	var vs = vsize()
	var r = 30.0
	var arr = [
		["pause", Vector2(vs.x - 34, 34), 22.0, "II"],
		["reload", Vector2(vs.x - 50, vs.y - 250), r, "RLD"],
		["swap", Vector2(vs.x - 120, vs.y - 285), r, "SWAP"],
		["dash", Vector2(vs.x - 195, vs.y - 300), r, "DASH"],
		["bar", Vector2(50, vs.y - 250), r, "BAR"],
		["tur", Vector2(120, vs.y - 285), r, "TUR"],
	]
	if world and world.state == "intermission":
		if world.can_shop():
			arr.append(["bench", Vector2(vs.x * 0.5 - 70, vs.y - 120), 34.0, "BENCH"])
		arr.append(["ready", Vector2(vs.x * 0.5 + 70, vs.y - 120), 34.0, "READY"])
	return arr

func _button_at(p: Vector2) -> String:
	for b in _buttons():
		if p.distance_to(b[1]) < b[2] + 8.0:
			return b[0]
	return ""

func _press(b: String) -> void:
	match b:
		"pause": show_screen("pause")
		"reload": world.reload()
		"swap": world.cycle(1)
		"dash": world.dash()
		"bar": world.place("bar"); ghost_t = 2.0
		"tur": world.place("tur"); ghost_t = 2.0
		"bench": open_shop()
		"ready": world.ready_up()

# ------------------------------------------------------------------ HUD
func _txt(c: Control, p: Vector2, s: String, size: int, col: Color, align := HORIZONTAL_ALIGNMENT_LEFT, w := -1.0) -> void:
	c.draw_string_outline(font, p, s, align, w, size, 4, Color(0, 0, 0, 0.85 * col.a))
	c.draw_string(font, p, s, align, w, size, col)

func draw_hud(c: Control) -> void:
	if world == null or world.demo or not (screen in ["play", "shop", "pause", "over", "won"]):
		return
	var w = world
	var vs = c.size
	# health
	var hf = clampf(w.hp / w.mhp, 0.0, 1.0)
	c.draw_rect(Rect2(14, 14, 224, 20), Color(0, 0, 0, 0.65))
	c.draw_rect(Rect2(16, 16, 220 * hf, 16), Color(0.9, 0.25, 0.25).lerp(Color(0.35, 0.9, 0.45), hf))
	_txt(c, Vector2(22, 30), "HP %d / %d" % [int(w.hp), int(w.mhp)], 14, INK)
	_txt(c, Vector2(16, 60), "$%d" % w.cash, 22, GOLD)
	_txt(c, Vector2(16, 82), "KILLS %d" % w.kills, 13, DIM)
	# wave status
	var cx = vs.x * 0.5
	var top = 26.0 if not portrait else 110.0
	if w.state == "intermission":
		var s = "WAVE %d IN %ds" % [w.wave + 1, int(ceil(w.inter_t))]
		_txt(c, Vector2(cx - 200, top), s, 20, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 400)
		_txt(c, Vector2(cx - 220, top + 20), ("tap READY" if touch_mode else "[G] start now") + "  ·  " + ("gear up at the bench" if not w.can_shop() else ("tap BENCH" if touch_mode else "[E] open bench")), 13, DIM, HORIZONTAL_ALIGNMENT_CENTER, 440)
	elif w.state == "wave":
		var left = w.zs.size()
		for q in w.queue:
			left += 4 if q == "crawlers" else 1
		_txt(c, Vector2(cx - 200, top), "WAVE %d  ·  %d LEFT" % [w.wave, left], 20, INK, HORIZONTAL_ALIGNMENT_CENTER, 400)
	if w.boss:
		var bw = minf(420.0, vs.x - 40)
		var bf = clampf(w.boss.hp / w.boss.mhp, 0.0, 1.0)
		var by = top + 16
		c.draw_rect(Rect2(cx - bw / 2 - 2, by - 2, bw + 4, 14), Color(0, 0, 0, 0.7))
		c.draw_rect(Rect2(cx - bw / 2, by, bw * bf, 10), Color(0.9, 0.25, 0.3))
		_txt(c, Vector2(cx - 200, by + 28), w.boss.name, 14, Color(1, 0.6, 0.55), HORIZONTAL_ALIGNMENT_CENTER, 400)
	# messages
	var my = top + (66 if w.boss else 48)
	for m in msgs:
		var a = clampf(m.life, 0.0, 1.0)
		_txt(c, Vector2(cx - 300, my), m.t, 15, Color(m.c.r, m.c.g, m.c.b, a), HORIZONTAL_ALIGNMENT_CENTER, 600)
		my += 20
	if w.announce_t > 0.0:
		var a = clampf(w.announce_t, 0.0, 1.0)
		var sc = 1.0 + maxf(0.0, w.announce_t - 2.2) * 2.0
		_txt(c, Vector2(cx - 400, vs.y * 0.36), w.announce, int(44 * sc), Color(ORANGE.r, ORANGE.g, ORANGE.b, a), HORIZONTAL_ALIGNMENT_CENTER, 800)
	# weapon panel
	var wd = w.wdef()
	var id = wd.id
	var py = vs.y - (24 if not touch_mode else 70)
	var a = w.ammo[id]
	var astr = "MELEE" if wd.mag == 0 else ("%d / INF" % a[0] if a[1] < 0 else "%d / %d" % [a[0], a[1]])
	_txt(c, Vector2(vs.x - 330, py - 26), "%s  LV%d" % [wd.name.to_upper(), w.tier(id) + 1], 16, GOLD, HORIZONTAL_ALIGNMENT_RIGHT, 314)
	_txt(c, Vector2(vs.x - 330, py), astr, 24 if wd.mag > 0 and a[0] > 0 else 24, INK if wd.mag == 0 or a[0] > 0 else Color(1, 0.4, 0.35), HORIZONTAL_ALIGNMENT_RIGHT, 314)
	if w.reload_t > 0.0:
		c.draw_rect(Rect2(vs.x - 156, py + 6, 140, 5), Color(0, 0, 0, 0.6))
		c.draw_rect(Rect2(vs.x - 156, py + 6, 140 * (1.0 - w.reload_t / w.reload_max), 5), GOLD)
	if not touch_mode or not portrait:
		var sx = 16.0
		for i in w.order.size():
			var sel = i == w.cur
			var rr = Rect2(sx, vs.y - (40 if not touch_mode else 60) - 10, 28, 28)
			c.draw_rect(rr, Color(1, 0.62, 0.22, 0.85) if sel else Color(0, 0, 0, 0.55))
			_txt(c, rr.position + Vector2(0, 20), str((Data.WEAPONS.find(Data.weapon(w.order[i])) + 1) % 10), 14, INK if not sel else Color(0.1, 0.05, 0), HORIZONTAL_ALIGNMENT_CENTER, 28)
			sx += 32
		_txt(c, Vector2(16, vs.y - (58 if not touch_mode else 78) - 10), "B barricade $%d · T turret $%d" % [Data.BARRICADE_COST, Data.TURRET_COST] if not touch_mode else "", 12, DIM)
	# bench pointer
	var ct = w.get_viewport().get_canvas_transform()
	if w.state == "intermission":
		var bs = ct * w.m.bench
		if not Rect2(Vector2.ZERO, vs).grow(-30).has_point(bs):
			var ctr = vs * 0.5
			var dirv = (bs - ctr).normalized()
			var ep = ctr + dirv * minf((vs.x * 0.5 - 40) / maxf(absf(dirv.x), 0.01), (vs.y * 0.5 - 40) / maxf(absf(dirv.y), 0.01))
			var pts = PackedVector2Array([ep + dirv * 16, ep + dirv.rotated(2.4) * 12, ep + dirv.rotated(-2.4) * 12])
			c.draw_colored_polygon(pts, GOLD)
			_txt(c, ep - dirv * 26 + Vector2(-40, 5), "BENCH", 12, GOLD, HORIZONTAL_ALIGNMENT_CENTER, 80)
	# build ghost
	if (w.state == "intermission" or ghost_t > 0.0) and w.alive:
		var gt = w.build_target()
		var ok = w.build_ok(gt)
		var sp = ct * gt
		var s = 36.0 * ct.get_scale().x
		c.draw_rect(Rect2(sp - Vector2(s, s) * 0.5, Vector2(s, s)), Color(0.4, 1.0, 0.5, 0.35) if ok else Color(1.0, 0.3, 0.3, 0.3), false, 2.0)
	# touch controls
	if touch_mode:
		for t in touches.values():
			if t.role == "btn":
				continue
			c.draw_circle(t.o, 70, Color(1, 1, 1, 0.08))
			c.draw_arc(t.o, 70, 0, TAU, 32, Color(1, 1, 1, 0.25), 2)
			c.draw_circle(t.p, 28, Color(1, 0.62, 0.22, 0.45) if t.role == "aim" else Color(1, 1, 1, 0.3))
		if touches.is_empty():
			_txt(c, Vector2(20, vs.y - 30), "MOVE", 13, Color(1, 1, 1, 0.35))
			_txt(c, Vector2(vs.x - 220, vs.y - 30), "AIM + FIRE", 13, Color(1, 1, 1, 0.35), HORIZONTAL_ALIGNMENT_RIGHT, 200)
		for b in _buttons():
			var bc = Color(1, 0.62, 0.22, 0.5) if b[0] in ["bench", "ready"] else Color(0.1, 0.1, 0.15, 0.55)
			c.draw_circle(b[1], b[2], bc)
			c.draw_arc(b[1], b[2], 0, TAU, 28, Color(1, 1, 1, 0.45), 2)
			_txt(c, b[1] + Vector2(-b[2], 5), b[3], 12, INK, HORIZONTAL_ALIGNMENT_CENTER, b[2] * 2)
