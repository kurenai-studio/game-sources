extends CanvasLayer
## The battle's interface: who is winning across the top, commands along
## the bottom, news in between. Reads the battle; acts only through the
## screen's command functions.

const K := UnitTypes.Kind
const S := Regiment.State

var screen
var _top: Control
var _bottom: HBoxContainer
var _bottom_bg: Panel
var _info: Label
var _hint: Label
var _toasts: VBoxContainer
var _overlay: Control
var _buttons := {}
var _portrait := false
var _menu_button: Button
var _menu: Control
var _leave: Button
var _restart: Button
## A retreat needs a second tap before this time (seconds since start).
var _leave_armed_until := 0.0
## Grand battles only: the whole field small, top right.
var _minimap: Control


func top_height(portrait: bool) -> float:
	return 64.0 if portrait else 58.0


func bottom_height(portrait: bool) -> float:
	return 132.0 if portrait else 84.0


func _ready() -> void:
	_overlay = DragOverlay.new()
	_overlay.screen = screen
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_top = TopBar.new()
	_top.screen = screen
	_top.mouse_filter = Control.MOUSE_FILTER_PASS
	_top.gui_input.connect(_take_press.bind(_top))
	add_child(_top)
	_bottom_bg = Panel.new()
	_bottom_bg.add_theme_stylebox_override("panel", _bar_style())
	_bottom_bg.mouse_filter = Control.MOUSE_FILTER_PASS
	_bottom_bg.gui_input.connect(_take_press.bind(_bottom_bg))
	add_child(_bottom_bg)
	_bottom = HBoxContainer.new()
	_bottom.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom.add_theme_constant_override("separation", 8)
	add_child(_bottom)
	_add_button("pause", "Pause", screen.toggle_pause)
	_add_button("speed", "1×", screen.toggle_speed)
	_add_button("all", "All", screen.select_all)
	_add_button("clear", "Clear", screen.clear_selection)
	_add_button("rally", "Rally", screen.use_ability.bind("rally"))
	_add_button("barrage", "Barrage", screen.use_ability.bind("barrage"))
	_add_button("march", "March", screen.use_ability.bind("march"))
	_add_button("fight", "Fight!", screen.begin_battle)
	_buttons.fight.custom_minimum_size.x = 150
	_buttons.fight.add_theme_color_override("font_color", Palette.DESK)
	var gold := _bar_style()
	gold.bg_color = Palette.BRASS
	gold.set_corner_radius_all(6)
	_buttons.fight.add_theme_stylebox_override("normal", gold)
	var gold_hover := gold.duplicate()
	gold_hover.bg_color = Palette.GOLD
	_buttons.fight.add_theme_stylebox_override("hover", gold_hover)
	_buttons.fight.add_theme_stylebox_override("pressed", gold_hover)
	_info = _label(15, Palette.INK)
	_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_info)
	_hint = _label(17, Palette.INK)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.add_theme_constant_override("outline_size", 6)
	_hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	add_child(_hint)
	if screen.grand:
		_minimap = preload("res://scripts/minimap.gd").new()
		_minimap.screen = screen
		add_child(_minimap)
	_toasts = VBoxContainer.new()
	_toasts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toasts.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_toasts)
	_menu_button = Button.new()
	_menu_button.text = "Menu"
	_menu_button.focus_mode = Control.FOCUS_NONE
	_menu_button.pressed.connect(screen.open_menu)
	add_child(_menu_button)
	_build_menu()


## The menu over a dimmed battle: Resume, Restart (quick battles), Leave.
func _build_menu() -> void:
	_menu = Control.new()
	_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.visible = false
	add_child(_menu)
	var shade := ColorRect.new()
	shade.color = Color(Palette.DESK, 0.7)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_menu.add_child(shade)
	var centre := CenterContainer.new()
	centre.set_anchors_preset(Control.PRESET_FULL_RECT)
	_menu.add_child(centre)
	var col := VBoxContainer.new()
	col.custom_minimum_size.x = 300
	col.add_theme_constant_override("separation", 12)
	centre.add_child(col)
	var title := _label(30, Palette.INK)
	title.text = "Paused"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var name := _label(16, Palette.INK_DIM)
	name.text = screen.title
	name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(name)
	for entry in [["Resume", screen.close_menu], ["Restart", screen.restart], ["", _on_leave]]:
		var b := Button.new()
		b.text = entry[0]
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size.y = 52
		b.pressed.connect(entry[1])
		col.add_child(b)
		if entry[0] == "Restart":
			_restart = b
		elif entry[0] == "":
			_leave = b


func _on_leave() -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if screen.leaving_costs() and now > _leave_armed_until:
		_leave_armed_until = now + 3.0
		return
	screen.leave()


func _add_button(key: String, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(78, 50)
	b.pressed.connect(action)
	_bottom.add_child(b)
	_buttons[key] = b


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _bar_style() -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(Palette.DESK, 0.92)
	sb.border_color = Color(Palette.BRASS, 0.5)
	return sb


func layout(vp: Vector2, portrait: bool) -> void:
	_portrait = portrait
	var top := top_height(portrait)
	var bottom := bottom_height(portrait)
	_top.position = Vector2.ZERO
	_top.size = Vector2(vp.x, top)
	_overlay.position = Vector2.ZERO
	_overlay.size = vp
	_bottom_bg.position = Vector2(0, vp.y - bottom)
	_bottom_bg.size = Vector2(vp.x, bottom)
	var row_h := 54.0
	_bottom.position = Vector2(8, vp.y - row_h - 12.0)
	_bottom.size = Vector2(vp.x - 16, row_h)
	for b in _bottom.get_children():
		b.custom_minimum_size.x = 0 if portrait else 78
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if portrait else Control.SIZE_SHRINK_CENTER
	_info.position = Vector2(8, vp.y - bottom + 6.0)
	_info.size = Vector2(vp.x - 16, 22)
	_hint.position = Vector2(8, top + 8.0)
	_hint.size = Vector2(vp.x - 16, 52)
	_toasts.position = Vector2(vp.x * 0.5 - 220, top + 40.0)
	_toasts.size = Vector2(440, 200)
	if _minimap != null:
		var field: Vector2 = screen.battle.terrain.size
		var w := 150.0 if portrait else 230.0
		_minimap.size = Vector2(w, w * field.y / field.x)
		_minimap.position = Vector2(vp.x - w - 8.0, top + 8.0)
		_hint.size.x = vp.x - w - 32.0
	_menu_button.position = Vector2(6, 6)
	_menu_button.size = Vector2(TopBar.INSET - 14.0, top - 12.0)


func _process(_delta: float) -> void:
	var b: Battle = screen.battle
	_menu.visible = screen.menu_open
	if _menu.visible:
		_restart.visible = screen.quick
		var armed := Time.get_ticks_msec() / 1000.0 <= _leave_armed_until
		_leave.text = "Tap again to retreat" if armed else screen.leave_label()
	var deploying := b.phase == "deploy"
	_buttons.fight.visible = deploying
	for key in ["pause", "speed", "rally", "barrage", "march"]:
		_buttons[key].visible = not deploying
	_buttons.pause.text = "Resume" if screen.paused else "Pause"
	_buttons.speed.text = "%d×" % int(screen.speed)
	_buttons.clear.visible = not screen.selected.is_empty()
	for name in ["rally", "barrage", "march"]:
		var btn: Button = _buttons[name]
		btn.visible = not deploying and name in b.abilities
		var cd: float = b.cooldowns[name]
		var label: String = {"rally": "Rally", "barrage": "Barrage", "march": "March"}[name]
		btn.text = label if cd <= 0.0 else "%s %d" % [label, ceili(cd)]
		btn.disabled = cd > 0.0 or (name == "rally" and b.general_of(0) == null)
	_buttons.barrage.modulate = Palette.GOLD if screen.targeting == "barrage" else Color.WHITE
	_info.text = _selection_text(b)
	if deploying:
		_hint.text = "Drag your regiments to set the line. Tap Fight when ready."
	elif screen.targeting == "barrage":
		_hint.text = "Tap the field to aim the barrage."
	elif screen.pinned:
		_hint.text = "Tap where to go next."
	elif screen.paused and screen.grand and b.time < 1.0:
		_hint.text = "Drag the field to look around; pinch or scroll to zoom. Double-tap a brigade for its division. Resume when ready."
	elif screen.paused:
		_hint.text = "Paused. Orders still work."
	elif b.time < 10.0 and screen.goal != "":
		_hint.text = screen.goal
	elif screen.grand and not screen.selected.is_empty() and screen.delegated.is_empty() and b.time < 400.0:
		_hint.text = "Tap a flag to send them to take and hold it on their own."
	elif b.time < 12.0 and screen.selected.is_empty():
		_hint.text = "Tap a banner to select. Tap the field to move, drag an arrow to stand and face, tap an enemy to attack."
	else:
		_hint.text = ""
	_top.queue_redraw()
	_overlay.queue_redraw()


func _selection_text(b: Battle) -> String:
	var regs: Array[Regiment] = []
	for id in screen.selected:
		var r := b.get_regiment(id)
		if r != null:
			regs.append(r)
	if regs.is_empty():
		return ""
	if regs.size() > 1:
		var men := 0
		for r in regs:
			men += r.men()
		var division := regs[0].formation
		if division != "" and regs.all(func(r): return r.formation == division):
			return "%s · %d brigades · %d men" % [division, regs.size(), men]
		return "%d %s · %d men" % [regs.size(), "brigades" if screen.grand else "regiments", men]
	var r := regs[0]
	var stars := " " + "★".repeat(r.stars) if r.stars > 0 else ""
	if r.name != "":
		var own: String = screen.objective_name(r)
		var command := " · taking %s" % own if own != "" else ""
		return "%s%s · %s · %d of %d men · %s · %s%s" % [r.name, stars, r.formation, r.men(), r.men_max, _morale_word(r), _stamina_word(r), command]
	return "%s%s · %d of %d men · %s · %s" % [UnitTypes.label(r.kind), stars, r.men(), r.men_max, _morale_word(r), _stamina_word(r)]


func _stamina_word(r: Regiment) -> String:
	if r.stamina > 0.7:
		return "fresh"
	if r.stamina > 0.35:
		return "tiring"
	return "spent"


func _morale_word(r: Regiment) -> String:
	if r.state == S.ROUTING:
		return "routing"
	var m := r.morale / r.morale_max
	if m > 0.66:
		return "steady"
	if m > 0.33:
		return "shaken"
	return "wavering"


## A bar takes a press on it, so a tap on the resolve bars or the clock is
## not a tap on the field; a drag that only passes over a bar, or ends on
## it, still reaches the field.
func _take_press(event: InputEvent, bar: Control) -> void:
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		bar.accept_event()


func ping(at: Vector2, team: int) -> void:
	if _minimap != null:
		_minimap.ping(at, team)


func toast(text: String, team: int, hold := 1.6) -> void:
	var l := _label(17, Palette.TEAM_LIGHT[team])
	l.text = text
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_constant_override("outline_size", 6)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	_toasts.add_child(l)
	while _toasts.get_child_count() > 3:
		_toasts.get_child(0).free()
	var tw := l.create_tween()
	tw.tween_interval(hold)
	tw.tween_property(l, "modulate:a", 0.0, 0.6)
	tw.tween_callback(l.queue_free)


## Resolve bars, the three flags, and the clock.
class TopBar extends Control:
	## Room on the left for the Menu button.
	const INSET := 84.0
	var screen

	func _draw() -> void:
		var b: Battle = screen.battle
		var font := ThemeDB.fallback_font
		var w := size.x
		draw_rect(Rect2(Vector2.ZERO, size), Color(Palette.DESK, 0.92))
		draw_line(Vector2(0, size.y), Vector2(w, size.y), Color(Palette.BRASS, 0.5), 1.0)
		var centre_w := 150.0
		var bar_w := clampf((w - centre_w) * 0.5 - 14.0 - INSET, 60.0, 420.0)
		var y := size.y * 0.5 + 6.0
		_bar(Rect2(INSET, y, bar_w, 12.0), b.resolve[0] / 100.0, 0, false)
		_bar(Rect2(w - 14.0 - bar_w, y, bar_w, 12.0), b.resolve[1] / 100.0, 1, true)
		draw_string(font, Vector2(INSET, y - 7.0), "YOUR RESOLVE  %d" % ceili(b.resolve[0]), HORIZONTAL_ALIGNMENT_LEFT, bar_w, 13, Palette.INK_DIM)
		draw_string(font, Vector2(w - 14.0 - bar_w, y - 7.0), "ENEMY  %d" % ceili(b.resolve[1]), HORIZONTAL_ALIGNMENT_RIGHT, bar_w, 13, Palette.INK_DIM)
		var cx := w * 0.5
		for i in b.flags.size():
			var f: Dictionary = b.flags[i]
			var c := Vector2(cx + (i - (b.flags.size() - 1) * 0.5) * 30.0, 20.0)
			var owner: int = f.owner
			var color: Color = Palette.NEUTRAL if owner < 0 else Palette.TEAM[owner]
			draw_circle(c, 9.0, color)
			draw_arc(c, 9.0, 0, TAU, 20, Color.WHITE, 1.5, true)
			var prog: float = f.progress
			if absf(prog) > 0.01 and absf(prog) < 1.0:
				var pc: Color = Palette.TEAM_LIGHT[0] if prog > 0.0 else Palette.TEAM_LIGHT[1]
				draw_arc(c, 12.5, -PI * 0.5, -PI * 0.5 + TAU * absf(prog), 20, pc, 2.5, true)
		var t := int(b.time)
		var clock := "%d:%02d" % [t / 60, t % 60]
		var warn := b.time > Battle.DUSK_TIME
		if screen.clock.is_valid():
			# A historical day: the hour, and when night ends it.
			clock = "%s   dusk %s" % [screen.clock.call(b.time), screen.clock.call(b.deadline)]
			warn = b.deadline - b.time < 60.0
		elif b.phase == "deploy":
			clock = screen.title
		elif b.deadline > 0.0:
			var left := maxi(0, ceili(b.deadline - b.time))
			clock = "%d:%02d left" % [left / 60, left % 60]
			warn = left <= 30
		elif warn:
			clock += "  dusk"
		draw_string(font, Vector2(cx - 100.0, size.y - 8.0), clock, HORIZONTAL_ALIGNMENT_CENTER, 200.0, 14, Palette.BRASS if warn else Palette.INK)

	func _bar(rect: Rect2, value: float, team: int, from_right: bool) -> void:
		draw_rect(rect, Palette.DESK_RAISED)
		var fill := rect
		fill.size.x = rect.size.x * clampf(value, 0.0, 1.0)
		if from_right:
			fill.position.x = rect.end.x - fill.size.x
		draw_rect(fill, Palette.TEAM[team])
		draw_rect(rect, Color(1, 1, 1, 0.25), false, 1.0)


## The box being dragged out for selection.
class DragOverlay extends Control:
	var screen

	func _draw() -> void:
		var d: Dictionary = screen.drag
		if d.is_empty() or d.mode != "box":
			return
		var rect := Rect2(d.start_screen, Vector2.ZERO).expand(d.now_screen)
		draw_rect(rect, Color(Palette.GOLD, 0.12))
		draw_rect(rect, Palette.GOLD, false, 1.5)
