class_name StoryInventory
extends CanvasLayer
# ---------- Рюкзак героя (игра на паузе) ----------
# Вкладки: Броня, Ближний бой, Дальний бой, Способности, Вещи, Особые,
# Характеристики. У вкладок с оружием и бронёй — фильтры по виду.
# Справа — герой во всём надетом: броня, оружие в руке, дальнее — за спиной.

var mode                     # StoryMode
var _tab := "armor"
var _filter := "all"
var _sel := ""               # выбранный предмет (индекс в рюкзаке как строка) или способность
var _sel_ability := ""
var _vs := Vector2.ZERO
var _content: Control
var _details: Control
var _preview: Control
var _tab_btns := {}
var _grid_rect := Rect2()
var _focus_key := ""         # какую кнопку выбрать геймпадом после перестройки

const TABS := [["armor", "Броня"], ["melee", "Ближний бой"], ["ranged", "Дальний бой"], ["abilities", "Способности"],
		["items", "Вещи"], ["special", "Особые"], ["stats", "Характеристики"]]
const BG := Color(0.10, 0.08, 0.07, 0.97)
const TRIM := Color(0.80, 0.60, 0.30)
const CELL := 68.0

func _ready() -> void:
	layer = 20
	_vs = Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.55)
	dim.size = _vs
	add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(14, 12)
	panel.size = _vs - Vector2(28, 24)
	panel.add_theme_stylebox_override("panel", StoryHud.box(BG, TRIM, 14, 3))
	add_child(panel)
	var title := _lbl(self, "Рюкзак", Vector2(34, 18), 28, Color(1.0, 0.85, 0.45))
	title.size = Vector2(200, 40)
	var close := Button.new()
	close.text = "Закрыть"
	close.size = Vector2(150, 46)
	close.position = Vector2(_vs.x - 180, 20)
	close.add_theme_font_size_override("font_size", 20)
	close.focus_mode = Control.FOCUS_ALL
	close.pressed.connect(queue_free)
	add_child(close)
	PadGlyph.attach(close, "B", -1)
	# вкладки
	var x := 200.0
	var tw := (_vs.x - 200.0 - 250.0) / TABS.size()
	for t in TABS:
		var b := Button.new()
		b.text = t[1]
		b.position = Vector2(x, 22)
		b.size = Vector2(tw - 6, 42)
		b.add_theme_font_size_override("font_size", 15 if t[0] != "stats" else 14)
	
		b.pressed.connect(_set_tab.bind(t[0]))
		b.set_meta("fk", "tab_" + String(t[0]))
		add_child(b)
		_tab_btns[t[0]] = b
		x += tw
	PadGlyph.attach(_tab_btns[TABS[0][0]], "LB", -1)
	PadGlyph.attach(_tab_btns[TABS[-1][0]], "RB", 1)
	_content = Control.new()
	_content.size = _vs
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE      # иначе слой перекрывал касания вкладок и «Закрыть»
	add_child(_content)
	_refresh()

var _trig := {}               # курки LT/RT: нажат ли сейчас (срабатывают один раз за нажатие)

# Геймпад: LB/RB — вкладки, LT/RT — фильтры, Y — действие с выбранной вещью,
# B (или SEL / меню) — закрыть. Клавиатура: Q/E — вкладки, Z/C — фильтры.
func _unhandled_input(event: InputEvent) -> void:
	var step_tab := 0
	var step_filter := 0
	if event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_LEFT_SHOULDER:
				step_tab = -1
			JOY_BUTTON_RIGHT_SHOULDER:
				step_tab = 1
			JOY_BUTTON_Y:
				get_viewport().set_input_as_handled()
				_action()
				return
	elif event is InputEventJoypadMotion and event.axis in [JOY_AXIS_TRIGGER_LEFT, JOY_AXIS_TRIGGER_RIGHT]:
		var on: bool = event.axis_value > 0.6
		if on and not _trig.get(event.axis, false):
			step_filter = -1 if event.axis == JOY_AXIS_TRIGGER_LEFT else 1
		_trig[event.axis] = event.axis_value > 0.3
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_Q:
				step_tab = -1
			KEY_E:
				step_tab = 1
			KEY_Z:
				step_filter = -1
			KEY_C:
				step_filter = 1
	if step_tab != 0:
		get_viewport().set_input_as_handled()
		var i := 0
		for k in TABS.size():
			if TABS[k][0] == _tab:
				i = k
		i = posmod(i + step_tab, TABS.size())
		_focus_key = ""
		_set_tab(TABS[i][0])
		return
	if step_filter != 0:
		get_viewport().set_input_as_handled()
		var f := _filters()
		if f.is_empty():
			return
		var j := 0
		for k in f.size():
			if f[k][0] == _filter:
				j = k
		_filter = f[posmod(j + step_filter, f.size())][0]
		_sel = ""
		_focus_key = ""
		_refresh()
		return
	if event.is_action_pressed("p1_inv") or event.is_action_pressed("p1_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close.call_deferred()

# Главное действие с выбранным (Y): надеть / снять / выпить / прочитать
func _action() -> void:
	for n in _details.get_children():
		if n is Button and n.has_meta("main") and not n.is_queued_for_deletion():
			n.emit_signal("pressed")
			return

func _set_tab(t: String) -> void:
	_tab = t
	_filter = "all"
	_sel = ""
	_sel_ability = ""
	_refresh()

func _lbl(parent: Node, t: String, pos: Vector2, size: int, c := Color(1, 0.95, 0.85)) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _btn(parent: Node, t: String, pos: Vector2, size: Vector2, fs := 16) -> Button:
	var b := Button.new()
	b.text = t
	b.position = pos
	b.size = size
	b.add_theme_font_size_override("font_size", fs)

	parent.add_child(b)
	return b

# ---------- Перестроить всё ----------
func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()
	for k in _tab_btns:
		_tab_btns[k].modulate = Color(1.25, 1.15, 0.8) if k == _tab else Color(0.8, 0.8, 0.8)
	var right_w := 250.0
	var det_w := 290.0
	var gx := 36.0
	var gy := 124.0
	_grid_rect = Rect2(gx, gy, _vs.x - gx - right_w - det_w - 60.0, _vs.y - gy - 30.0)
	_build_preview(Rect2(_vs.x - right_w - 30.0, 76.0, right_w, _vs.y - 106.0))
	_details = Panel.new()
	_details.position = Vector2(_grid_rect.end.x + 12.0, 76.0)
	_details.size = Vector2(det_w, _vs.y - 106.0)
	_details.add_theme_stylebox_override("panel", StoryHud.box(Color(0.16, 0.12, 0.09, 0.9), TRIM.darkened(0.3), 10, 2))
	_content.add_child(_details)
	match _tab:
		"abilities":
			_build_abilities()
		"stats":
			_build_stats()
		_:
			_build_filters()
			_build_grid()
	_build_details()
	_restore_focus.call_deferred()

# Геймпад: после перестройки снова выбрать ту же кнопку,
# а если её нет — первую вещь в сетке (или первую кнопку вкладки)
func _restore_focus() -> void:
	if not (Pad.connected() or PadGlyph.force):
		return
	var first: BaseButton = null
	var first_cell: BaseButton = null
	var stack: Array = [_content]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n.is_queued_for_deletion():
			continue
		for c in n.get_children():
			stack.append(c)
		if n is BaseButton:
			var k: String = n.get_meta("fk", "")
			if _focus_key != "" and k == _focus_key:
				n.grab_focus()
				return
			if first == null and k != "" and not k.begins_with("f_"):
				first = n
			if first_cell == null and (k.begins_with("c_") or k.begins_with("slot_")):
				first_cell = n
	var pick := first_cell if first_cell else first
	if pick:
		pick.grab_focus()

# Перерисовать только описание (геймпад листает вещи — фокус не сбивается)
func _refresh_details() -> void:
	for c in _details.get_children():
		c.queue_free()
	_build_details()

func _remember(b: BaseButton, key: String) -> void:
	b.set_meta("fk", key)
	b.pressed.connect(func(): _focus_key = key)

# ---------- Фильтры ----------
func _filters() -> Array:
	match _tab:
		"armor":
			var f := [["all", "Все"]]
			for s in Items.ARMOR_SLOTS:
				f.append([s, Items.SLOT_NAME[s]])
			return f
		"melee":
			var f2 := [["all", "Все"]]
			for s in Items.MELEE_SUBS:
				f2.append([s, Items.SUB_NAME[s]])
			return f2
		"ranged":
			var f3 := [["all", "Все"]]
			for s in Items.RANGED_SUBS:
				f3.append([s, Items.SUB_NAME[s]])
			f3.append(["ammo", "Снаряды"])
			return f3
		"items":
			return [["all", "Все"], ["potion", "Зелья"], ["scroll", "Свитки"]]
	return []

func _build_filters() -> void:
	var f := _filters()
	if f.is_empty():
		return
	var x := _grid_rect.position.x + 46.0
	var w := minf(110.0, (_grid_rect.size.x - 92.0) / f.size() - 4.0)
	var first_b: Button = null
	var last_b: Button = null
	for it in f:
		var b := _btn(_content, it[1], Vector2(x, 78), Vector2(w, 36), 13)
		b.modulate = Color(1.25, 1.15, 0.8) if it[0] == _filter else Color(0.75, 0.75, 0.75)
		_remember(b, "f_" + String(it[0]))
		b.pressed.connect(func():
			_filter = it[0]
			_sel = ""
			_refresh())
		x += w + 4.0
		if first_b == null:
			first_b = b
		last_b = b
	PadGlyph.attach(first_b, "LT", -1)
	PadGlyph.attach(last_b, "RT", 1)

func _passes(id: String) -> bool:
	if Items.tab_of(id) != _tab:
		return false
	if _filter == "all":
		return true
	var d := Items.get_def(id)
	match _tab:
		"armor":
			return d.get("slot", "") == _filter
		"melee":
			return d.get("sub", "") == _filter
		"ranged":
			if _filter == "ammo":
				return d.get("kind", "") == "ammo"
			return d.get("sub", "") == _filter
		"items":
			return d.get("kind", "") == _filter
	return true

# ---------- Сетка предметов ----------
func _build_grid() -> void:
	var inv: Array = mode.data["inventory"]
	var cols := maxi(1, int((_grid_rect.size.x + 6) / (CELL + 6)))
	var n := 0
	for i in inv.size():
		var id: String = inv[i]["id"]
		if not _passes(id):
			continue
		var pos := _grid_rect.position + Vector2((n % cols) * (CELL + 6), (n / cols) * (CELL + 6))
		_cell(pos, id, int(inv[i]["n"]), str(i))
		n += 1
	if n == 0:
		var l := _lbl(_content, "Пусто", _grid_rect.position + Vector2(0, 20), 20, Color(1, 1, 1, 0.4))
		l.size = Vector2(_grid_rect.size.x, 40)

func _cell(pos: Vector2, id: String, n: int, key: String) -> void:
	var d := Items.get_def(id)
	var rc: Color = Items.RARITY.get(d.get("rarity", "common"), Color.WHITE)
	var b := Button.new()
	b.position = pos
	b.size = Vector2(CELL, CELL)

	var sel := key == _sel
	for st in ["normal", "hover", "pressed"]:
		var sb := StoryHud.box(Color(0.22, 0.17, 0.12) if not sel else Color(0.38, 0.30, 0.16), rc if not sel else Color(1, 0.9, 0.5), 8, 2 if not sel else 3)
		if st == "hover":
			sb.bg_color = sb.bg_color.lightened(0.08)
		b.add_theme_stylebox_override(st, sb)
	_remember(b, "c_" + key)
	b.pressed.connect(func():
		_sel = key
		_refresh())
	b.focus_entered.connect(func():
		# геймпад: вещь под рамкой сразу показывается в описании
		_focus_key = "c_" + key
		if _sel != key and (Pad.connected() or PadGlyph.force):
			_sel = key
			_refresh_details())
	_content.add_child(b)
	var ic := AbilityIcons.make(id, CELL * 0.72)
	if ic:
		ic.position = Vector2(CELL / 2, CELL / 2)
		b.add_child(ic)
	if n > 1:
		var l := _lbl(b, str(n), Vector2(4, CELL - 22), 15)
		l.size = Vector2(CELL - 8, 20)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	if mode.is_equipped(id):
		var e := _lbl(b, "Надето", Vector2(2, 1), 11, Color(0.6, 1.0, 0.55))
		e.size = Vector2(CELL - 4, 14)

func _selected_id() -> String:
	if _sel == "":
		return ""
	var i := int(_sel)
	var inv: Array = mode.data["inventory"]
	return String(inv[i]["id"]) if i < inv.size() else ""

# ---------- Описание выбранного ----------
func _build_details() -> void:
	var w := _details.size.x
	if _tab == "abilities":
		_ability_details(w)
		return
	if _tab == "stats":
		_details.visible = false
		return
	var id := _selected_id()
	if id == "":
		var l := _lbl(_details, "Выбери вещь,\nчтобы увидеть описание", Vector2(14, 16), 17, Color(1, 1, 1, 0.5))
		l.size = Vector2(w - 28, 60)
		return
	var d := Items.get_def(id)
	var rar: String = d.get("rarity", "common")
	var ic := AbilityIcons.make(id, 64)
	ic.position = Vector2(46, 50)
	_details.add_child(ic)
	var nm := _lbl(_details, Items.item_name(id), Vector2(86, 18), 19, Items.RARITY[rar])
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.update_minimum_size()
	nm.size = Vector2(w - 96, 50)
	var kind_s := _kind_text(d)
	_lbl(_details, kind_s + " · " + Items.RARITY_NAME[rar], Vector2(86, 66), 13, Color(1, 1, 1, 0.6))
	var y := 100.0
	var lines := []
	if d.has("dmg"):
		var sub: String = d["sub"]
		var stat := "melee" if d["kind"] == "melee" else "ranged"
		var real := int(round(float(d["dmg"]) * StoryStats.dmg_mult(mode.data, sub, stat)))
		lines.append(["Урон: %d  (с навыком — %d)" % [int(d["dmg"]), real], Color(1.0, 0.8, 0.5)])
		lines.append(["Ударов в секунду: %.1f" % (1.0 / float(d["cd"])), Color(1, 1, 1, 0.85)])
		lines.append(["Навык «%s»: ур. %d" % [StoryStats.SKILL_NAME.get(sub, sub), StoryStats.skill_lvl(mode.data, sub)], Color(0.6, 0.9, 1.0)])
		if d.has("ammo"):
			lines.append(["Снаряды: %s (%d)" % [Items.item_name(d["ammo"]), mode.count(d["ammo"])], Color(1, 1, 1, 0.85)])
	var st: Dictionary = d.get("stats", {})
	for k in st:
		var v = st[k]
		var txt := ("+%d%%" % int(round(float(v) * 100))) if k == "crit" else ("+%d" % int(v))
		lines.append([txt + " " + Items.STAT_NAME.get(k, k), Color(0.6, 1.0, 0.55)])
	if d.has("heal"):
		lines.append(["Лечит %d здоровья" % int(d["heal"]), Color(0.6, 1.0, 0.55)])
	if d.has("mana") and d.get("kind", "") == "potion":
		lines.append(["Восстанавливает %d маны" % int(d["mana"]), Color(0.5, 0.7, 1.0)])
	if d.has("teach"):
		var ab := StoryAbilities.get_def(d["teach"])
		lines.append(["Учит: " + String(ab["name"]), Color(0.85, 0.6, 1.0)])
		if d["teach"] in mode.data["learned"]:
			lines.append(["(уже изучено)", Color(1, 1, 1, 0.5)])
	for ln in lines:
		var l2 := _lbl(_details, ln[0], Vector2(16, y), 15, ln[1])
		l2.size = Vector2(w - 32, 22)
		y += 22.0
	var desc := _lbl(_details, String(d.get("desc", "")), Vector2(16, y + 8), 14, Color(0.95, 0.88, 0.72))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.update_minimum_size()
	desc.size = Vector2(w - 32, 90)
	# кнопки
	var by := _details.size.y - 64.0
	var k2: String = d.get("kind", "")
	if k2 in ["armor", "melee", "ranged"]:
		if mode.is_equipped(id):
			var b := _btn(_details, "Снять", Vector2(16, by), Vector2(w - 32, 48), 19)
			_main_btn(b)
			b.pressed.connect(func():
				mode.unequip(StoryMode.equip_slot(id))
				_refresh())
		else:
			var b2 := _btn(_details, "Надеть", Vector2(16, by), Vector2(w - 32, 48), 19)
			_main_btn(b2)
			b2.pressed.connect(func():
				mode.equip(id)
				_refresh())
	elif k2 in ["potion", "scroll"]:
		var b3 := _btn(_details, "Выпить" if k2 == "potion" else "Прочитать", Vector2(16, by), Vector2(w - 32, 48), 19)
		_main_btn(b3)
		b3.pressed.connect(func():
			var msg: String = mode.use_item(id)
			if msg != "":
				mode.hud.toast(msg)
			_sel = ""
			_refresh())

func _main_btn(b: Button) -> void:
	b.set_meta("main", true)
	PadGlyph.attach(b, "Y", 0)

func _kind_text(d: Dictionary) -> String:
	match String(d.get("kind", "")):
		"armor":
			return Items.SLOT_NAME.get(d.get("slot", ""), "Броня")
		"melee", "ranged":
			return Items.SUB_NAME.get(d.get("sub", ""), "Оружие")
		"ammo":
			return "Снаряды"
		"scroll":
			return "Свиток"
		"potion":
			return "Зелье"
		"key":
			return "Ключевой предмет"
	return ""

# ---------- Способности ----------
func _build_abilities() -> void:
	var x0 := _grid_rect.position.x
	_lbl(_content, "Ячейки способностей (одна способность — только в одной ячейке):", Vector2(x0, 80), 15, Color(1, 1, 1, 0.7))
	var keys := ["Q", "E", "C", "X"] if not Config.touch() else ["1", "2", "3", "Ульта"]
	for c in 4:
		var ab: String = String(mode.data["ult"]) if c == 3 else String(mode.data["slots"][c])
		var pos := Vector2(x0 + c * 112.0, 108.0)
		var b := Button.new()
		b.position = pos
		b.size = Vector2(96, 96)
	
		var col := Color(1.0, 0.78, 0.25) if c == 3 else TRIM
		for st in ["normal", "hover", "pressed"]:
			b.add_theme_stylebox_override(st, StoryHud.box(Color(0.2, 0.15, 0.1), col if ab != _sel_ability or ab == "" else Color(1, 1, 0.6), 10, 3))
		_remember(b, "slot_%d" % c)
		b.pressed.connect(_on_slot.bind(c))
		_content.add_child(b)
		if ab != "":
			var ic := AbilityIcons.make(String(StoryAbilities.get_def(ab)["icon"]), 66)
			ic.position = Vector2(48, 46)
			b.add_child(ic)
		var kl := _lbl(_content, ("Ульта" if c == 3 else "Ячейка %d" % (c + 1)) + "  [" + keys[c] + "]", pos + Vector2(0, 98), 13, Color(1, 1, 1, 0.6))
		kl.size = Vector2(110, 18)
	_lbl(_content, "Изученные способности:", Vector2(x0, 236), 17, Color(1.0, 0.85, 0.5))
	var learned: Array = mode.data["learned"]
	if learned.is_empty():
		var e := _lbl(_content, "Пока ничего. Способности учатся из свитков (вкладка «Вещи»).", Vector2(x0, 266), 16, Color(1, 1, 1, 0.45))
		e.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		e.update_minimum_size()
		e.size = Vector2(_grid_rect.size.x, 50)
		return
	for i in learned.size():
		var ab2: String = learned[i]
		var d := StoryAbilities.get_def(ab2)
		var pos2 := Vector2(x0 + (i % 2) * (_grid_rect.size.x / 2.0), 266.0 + (i / 2) * 78.0)
		var card := Button.new()
		card.position = pos2
		card.size = Vector2(_grid_rect.size.x / 2.0 - 8.0, 70)
		card.focus_mode = Control.FOCUS_ALL
		var sel := ab2 == _sel_ability
		for st in ["normal", "hover", "pressed"]:
			card.add_theme_stylebox_override(st, StoryHud.box(Color(0.22, 0.17, 0.12) if not sel else Color(0.38, 0.30, 0.16),
					Color(1.0, 0.78, 0.25) if d.get("ult", false) else TRIM.darkened(0.2), 8, 2))
		_remember(card, "ab_" + ab2)
		card.pressed.connect(func():
			_sel_ability = ab2
			_refresh())
		_content.add_child(card)
		var ic2 := AbilityIcons.make(String(d["icon"]), 52)
		ic2.position = Vector2(36, 35)
		card.add_child(ic2)
		_lbl(card, String(d["name"]), Vector2(70, 8), 17, Color(1.0, 0.9, 0.6))
		var sub := "Сверхспособность" if d.get("ult", false) else "Мана %d · перезарядка %.0f с" % [int(d["mana"]), float(d["cd"])]
		_lbl(card, sub, Vector2(70, 36), 13, Color(1, 1, 1, 0.65))

func _on_slot(c: int) -> void:
	if _sel_ability != "":
		var is_ult: bool = StoryAbilities.get_def(_sel_ability).get("ult", false)
		if is_ult != (c == 3):
			mode.hud.toast("Сверхспособность — только в ячейку ульты" if is_ult else "В ячейку ульты — только сверхспособность")
			return
		mode.assign_ability(_sel_ability, c)
	else:
		_sel_ability = String(mode.data["ult"]) if c == 3 else String(mode.data["slots"][c])
	_refresh()

func _ability_details(w: float) -> void:
	if _sel_ability == "":
		var l := _lbl(_details, "Выбери способность,\nа потом нажми на ячейку,\nкуда её поставить", Vector2(14, 16), 17, Color(1, 1, 1, 0.5))
		l.size = Vector2(w - 28, 90)
		return
	var d := StoryAbilities.get_def(_sel_ability)
	var ic := AbilityIcons.make(String(d["icon"]), 64)
	ic.position = Vector2(46, 50)
	_details.add_child(ic)
	var nm := _lbl(_details, String(d["name"]), Vector2(86, 22), 20, Color(1.0, 0.85, 0.45))
	nm.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	nm.update_minimum_size()
	nm.size = Vector2(w - 96, 50)
	var desc := _lbl(_details, String(d["desc"]), Vector2(16, 100), 15, Color(0.95, 0.88, 0.72))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.update_minimum_size()
	desc.size = Vector2(w - 32, 160)
	var by := _details.size.y - 64.0
	var cell := -1
	if String(mode.data["ult"]) == _sel_ability:
		cell = 3
	else:
		cell = (mode.data["slots"] as Array).find(_sel_ability)
	if cell >= 0:
		var b := _btn(_details, "Убрать из ячейки", Vector2(16, by), Vector2(w - 32, 48), 18)
		_main_btn(b)
		b.pressed.connect(func():
			mode.clear_ability(cell)
			_refresh())
	else:
		var hint := _lbl(_details, "Нажми на ячейку слева сверху, чтобы поставить", Vector2(16, by - 10), 14, Color(0.6, 0.9, 1.0))
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		hint.update_minimum_size()
		hint.size = Vector2(w - 32, 50)

# ---------- Характеристики ----------
func _build_stats() -> void:
	var d: Dictionary = mode.data
	var s := StoryStats.derive(d)
	var x0 := _grid_rect.position.x
	var colw := (_grid_rect.size.x + 290.0) / 2.0
	var y := 82.0
	_lbl(_content, "%s — уровень %d" % [d["name"], int(d["level"])], Vector2(x0, y), 22, Color(1.0, 0.85, 0.45))
	y += 34.0
	_bar_row(Vector2(x0, y), colw - 20.0, "Опыт", float(d["xp"]), float(StoryStats.level_next(int(d["level"]))), Color(1.0, 0.78, 0.25))
	y += 40.0
	var rows := [["Здоровье", "%d / %d" % [mode.hero.hp, int(s["hp"])]], ["Мана", "%d / %d" % [int(mode.kit.mana), int(s["mana"])]],
			["Сила удара", str(int(s["melee"]))], ["Меткость", str(int(s["ranged"]))], ["Интеллект", str(int(s["int"]))],
			["Броня", "%d  (−%d%% урона)" % [int(s["armor"]), int(round((1.0 - StoryStats.reduce(float(s["armor"]))) * 100))]],
			["Защита от магии", "%d  (−%d%% урона)" % [int(s["mres"]), int(round((1.0 - StoryStats.reduce(float(s["mres"]))) * 100))]],
			["Шанс крита", "%d%%" % int(round(float(s["crit"]) * 100))]]
	for r in rows:
		_lbl(_content, r[0], Vector2(x0, y), 17, Color(1, 1, 1, 0.75))
		var v := _lbl(_content, r[1], Vector2(x0 + 180, y), 17, Color(1.0, 0.95, 0.8))
		v.size = Vector2(colw - 200, 24)
		y += 30.0
	var hint := _lbl(_content, "Уровень героя растёт от опыта за победы: с ним растут здоровье и мана.\nНавыки растут от использования: бей мечом — растёт «Мечи» и урон мечей.",
			Vector2(x0, y + 8), 13, Color(0.7, 0.85, 1.0))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.update_minimum_size()
	hint.size = Vector2(colw - 20, 60)
	# навыки
	var x1 := x0 + colw
	var y2 := 82.0
	_lbl(_content, "Навыки", Vector2(x1, y2), 22, Color(1.0, 0.85, 0.45))
	y2 += 34.0
	var rowh := minf(32.0, (_vs.y - 150.0) / StoryStats.SKILLS.size())
	for k in StoryStats.SKILLS:
		var sk: Dictionary = d["skills"].get(k, {"lvl": 1, "xp": 0})
		var nm := _lbl(_content, "%s  %d" % [StoryStats.SKILL_NAME[k], int(sk["lvl"])], Vector2(x1, y2), 15, Color(1, 1, 1, 0.85))
		nm.size = Vector2(180, 22)
		_bar_row(Vector2(x1 + 180, y2 + 4), colw - 220.0, "", float(sk["xp"]), float(StoryStats.skill_next(int(sk["lvl"]))), Color(0.45, 0.75, 1.0), 12.0)
		y2 += rowh

func _bar_row(pos: Vector2, w: float, label: String, v: float, mx: float, c: Color, h := 22.0) -> void:
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.5)
	bg.position = pos
	bg.size = Vector2(w, h)
	_content.add_child(bg)
	var f := ColorRect.new()
	f.color = c
	f.position = pos + Vector2(2, 2)
	f.size = Vector2((w - 4) * clampf(v / maxf(mx, 1.0), 0.0, 1.0), h - 4)
	_content.add_child(f)
	if label != "":
		var l := _lbl(_content, "%s: %d / %d" % [label, int(v), int(mx)], pos + Vector2(0, -1), 14)
		l.size = Vector2(w, h)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# ---------- Герой во весь рост ----------
func _build_preview(r: Rect2) -> void:
	_preview = Panel.new()
	_preview.position = r.position
	_preview.size = r.size
	_preview.add_theme_stylebox_override("panel", StoryHud.box(Color(0.20, 0.24, 0.20, 0.9), TRIM.darkened(0.3), 10, 2))
	_content.add_child(_preview)
	var floor_y := r.size.y - 150.0
	var holder := Node2D.new()
	var k := 3.6
	holder.scale = Vector2(k, k)
	holder.position = Vector2(r.size.x / 2, floor_y - Player.SIZE.y * k / 2)
	_preview.add_child(holder)
	var rig := BotRig.new()
	rig.kind = "story"
	rig.size = Player.SIZE
	rig.puppet_facing = 1
	rig.custom_spec = StoryLook.spec(mode.data["look"], mode.data["equipped"])
	holder.add_child(rig)
	var ground := ColorRect.new()
	ground.color = Color(0, 0, 0, 0.25)
	ground.position = Vector2(30, floor_y)
	ground.size = Vector2(r.size.x - 60, 6)
	_preview.add_child(ground)
	# что надето — коротко
	var eq: Dictionary = mode.data["equipped"]
	var y := floor_y + 14.0
	for pair in [["melee", "В руке"], ["ranged", "За спиной"]]:
		var id: String = eq.get(pair[0], "")
		var t := _lbl(_preview, pair[1] + ": " + (Items.item_name(id) if id != "" else ("кулаки" if pair[0] == "melee" else "—")), Vector2(14, y), 14, Color(1, 1, 1, 0.8))
		t.size = Vector2(r.size.x - 28, 20)
		y += 22.0
	var s := StoryStats.derive(mode.data)
	var t2 := _lbl(_preview, "Броня %d · Маг. защита %d" % [int(s["armor"]), int(s["mres"])], Vector2(14, y + 4), 14, Color(0.7, 0.9, 1.0))
	t2.size = Vector2(r.size.x - 28, 20)
	var slots_txt := []
	for sl in Items.ARMOR_SLOTS:
		if eq.has(sl):
			slots_txt.append(Items.SLOT_NAME[sl])
	var t3 := _lbl(_preview, "Надето: " + (", ".join(slots_txt) if not slots_txt.is_empty() else "ничего"), Vector2(14, y + 28), 12, Color(1, 1, 1, 0.55))
	t3.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t3.update_minimum_size()
	t3.size = Vector2(r.size.x - 28, 40)

# Закрыть (отложенно — чтобы не удалять окно посреди обработки нажатия)
func _close() -> void:
	if not is_queued_for_deletion():
		queue_free()
