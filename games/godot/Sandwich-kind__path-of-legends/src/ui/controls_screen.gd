class_name ControlsScreen
extends CanvasLayer
# ---------- «Управление» ----------
# Нарисованный Bluetooth-контроллер с подписями, что делает каждая кнопка
# (в бою — Дуэль и Арена, и в Истории), а ещё клавиатура и экранные кнопки.

signal back_pressed

var overlay := false          # открыт поверх игры (из паузы Истории)
var _vs := Vector2.ZERO
var _tab := "pad"
var _mode := "fight"
var _content: Control
var _tabs := {}
var _editing := false         # открыт список переназначения кнопок
var _wait_fn := ""            # функция, для которой ждём новую кнопку
var _wait_t := 0.0
var _wait_btn: Button
var _msg := ""
const WAIT := 5.0

const INK := Color(1.0, 0.95, 0.85)
const GOLD := Color(1.0, 0.85, 0.4)

# кнопка -> [в бою, в Истории, один контроллер на двоих]
const PAD := {
	"LT": ["Способность 3", "Способность 3", "Игрок 1: атака"],
	"LB": ["Способность 1", "Способность 1", "Игрок 1: перезарядка"],
	"RT": ["Ульта", "Ульта", "Игрок 2: атака"],
	"RB": ["Способность 2", "Способность 2", "Игрок 2: перезарядка"],
	"SEL": ["—", "Рюкзак", "—"],
	"STA": ["Пауза", "Меню (пауза)", "Пауза"],
	"DPAD": ["← → ходьба · ↑ прыжок · ↓ спрыгнуть", "← → ходьба · ↑ прыжок · ↓ спрыгнуть",
			"Игрок 1: ← спос. 1 · ↑ спос. 2 · → спос. 3 · ↓ ульта"],
	"LS": ["Ходьба · вверх — прыжок · вниз — спрыгнуть", "Ходьба · вниз — спрыгнуть",
			"Игрок 1: ходьба · вверх/нажать — прыжок · вниз — спрыгнуть"],
	"RS": ["Не используется", "Нажать — задания",
			"Игрок 2: ходьба · вверх/нажать — прыжок · вниз — спрыгнуть"],
	"Y": ["—", "Взаимодействие (сундук, дверь…)", "Игрок 2: способность 2"],
	"B": ["Перезарядка", "Дальний бой (лук, праща)", "Игрок 2: способность 3"],
	"A": ["Прыжок", "Прыжок", "Игрок 2: ульта"],
	"X": ["Стрельба / удар", "Удар ближнего боя", "Игрок 2: способность 1"],
}

func _ready() -> void:
	_vs = Config.screen(self)
	if overlay:
		var dim := ColorRect.new()
		dim.color = Color(0.05, 0.04, 0.05, 0.96)
		dim.size = _vs
		add_child(dim)
	else:
		StorySlots.backdrop(self, _vs)
		var shade := ColorRect.new()
		shade.color = Color(0.04, 0.03, 0.03, 0.55)
		shade.size = _vs
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
	var t := Label.new()
	t.text = "Управление"
	t.size = Vector2(_vs.x, 60)
	t.position = Vector2(0, 16)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", GOLD)
	t.add_theme_constant_override("outline_size", 10)
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.08))
	add_child(t)
	var back := Button.new()
	back.text = "Назад"
	back.position = Vector2(24, 20)
	back.size = Vector2(150, 54)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	var x := _vs.x / 2 - 330
	for tb in [["pad", "Геймпад"], ["keys", "Клавиатура"], ["touch", "Экранные кнопки"]]:
		var b := Button.new()
		b.text = tb[1]
		b.position = Vector2(x, 82)
		b.size = Vector2(212, 46)
		b.add_theme_font_size_override("font_size", 19)
		b.pressed.connect(func():
			_tab = tb[0]
			_refresh())
		add_child(b)
		_tabs[tb[0]] = b
		x += 224
	_content = Control.new()
	_content.size = _vs
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if _wait_fn != "":
		return
	if overlay and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_menu")):
		get_viewport().set_input_as_handled()
		back_pressed.emit()

func _lbl(t: String, pos: Vector2, size: int, c := INK, w := 0.0) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content.add_child(l)
	if w > 0.0:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.update_minimum_size()
		l.size = Vector2(w, 20)
	return l

func _refresh() -> void:
	for c in _content.get_children():
		c.queue_free()
	for k in _tabs:
		_tabs[k].modulate = Color(1.25, 1.15, 0.8) if k == _tab else Color(0.8, 0.8, 0.8)
	match _tab:
		"pad":
			_pad_page()
		"keys":
			_keys_page()
		"touch":
			_touch_page()

# ---------- Геймпад ----------
func _pad_page() -> void:
	var names := Pad.names()
	var st := ("Подключено: " + ", ".join(names)) if not names.is_empty() else \
			"Контроллер не подключён — включи его и подключи к телефону по Bluetooth"
	var sl := _lbl(st, Vector2(0, 136), 16, Color(0.6, 1.0, 0.6) if not names.is_empty() else Color(1, 0.8, 0.6))
	sl.size = Vector2(_vs.x, 24)
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# переключатель: бой или История
	var x := _vs.x / 2 - 375
	for m in [["fight", "Арена (один игрок)"], ["story", "История"], ["shared", "Двое игроков"]]:
		var b := Button.new()
		b.text = m[1]
		b.position = Vector2(x, 166)
		b.size = Vector2(240, 40)
		b.add_theme_font_size_override("font_size", 16)
		b.modulate = Color(1.25, 1.15, 0.8) if m[0] == _mode else Color(0.75, 0.75, 0.75)
		b.pressed.connect(func():
			_mode = m[0]
			_editing = false
			_refresh())
		_content.add_child(b)
		x += 260
	if _editing and _mode != "shared":
		_edit_page()
		return
	var c := Vector2(_vs.x / 2, 380)
	var k := 0.78
	var pts := _draw_pad(c, k)
	var texts := _texts()
	var left := ["LT", "LB", "SEL", "DPAD", "LS"]
	var right := ["RT", "RB", "STA", "Y", "B", "A", "X", "RS"]
	var lx := c.x - 270.0 * k - 40.0
	var rx := c.x + 270.0 * k + 40.0
	for i in left.size():
		var key: String = left[i]
		var y := 226.0 + i * 70.0
		_callout(Vector2(lx, y), pts[key], key, texts[key], true)
	for i in right.size():
		var key2: String = right[i]
		var y2 := 222.0 + i * 46.0
		_callout(Vector2(rx, y2), pts[key2], key2, texts[key2], false)
	var ft := "В меню: крестовина или левый стик — выбор, A — нажать, B — назад."
	if _mode == "shared":
		ft = "Двое: один контроллер делится пополам (левая часть — Игрок 1, правая — Игрок 2). С двумя контроллерами у каждого стандартная раскладка Арены."
	else:
		var eb := Button.new()
		eb.text = "Переназначить кнопки"
		eb.position = Vector2(_vs.x / 2 - 150, _vs.y - 84)
		eb.size = Vector2(300, 42)
		eb.add_theme_font_size_override("font_size", 18)
		eb.pressed.connect(func():
			_editing = true
			_msg = ""
			_refresh())
		_content.add_child(eb)
		ft = "Левый стик всегда отвечает за ходьбу (в Арене и Дуэли вверх — прыжок). Раскладки Арены и Истории настраиваются отдельно."
	var foot := _lbl(ft,
			Vector2(40, _vs.y - 40), 14, Color(1, 1, 1, 0.7))
	foot.size = Vector2(_vs.x - 80, 24)
	foot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Подписи на схеме: для двоих — постоянные, для одного игрока — из его раскладки
func _texts() -> Dictionary:
	var res := {}
	if _mode == "shared":
		for key in PAD:
			res[key] = PAD[key][2]
		return res
	var b := Pad.binds(_mode)
	var by_id := {}
	for fn in b:
		var nm := Pad.func_name(_mode, fn)
		by_id[b[fn]] = (by_id[b[fn]] + ", " + nm) if by_id.has(b[fn]) else nm
	var one := func(id: String) -> String: return String(by_id.get(id, "—"))
	for pair in [["LT", "a4+"], ["RT", "a5+"], ["LB", "b9"], ["RB", "b10"], ["SEL", "b4"], ["STA", "b6"],
			["Y", "b3"], ["B", "b1"], ["A", "b0"], ["X", "b2"]]:
		res[pair[0]] = one.call(pair[1])
	var dp := []
	for d in [["↑", "b11"], ["↓", "b12"], ["←", "b13"], ["→", "b14"]]:
		if by_id.has(d[1]):
			dp.append(d[0] + " " + String(by_id[d[1]]).to_lower())
	res["DPAD"] = " · ".join(dp) if not dp.is_empty() else "—"
	res["LS"] = ("Ходьба · вверх — прыжок · вниз — спрыгнуть" if _mode == "fight" else "Ходьба · вниз — спрыгнуть") \
			+ (" · нажать — " + String(by_id["b7"]).to_lower() if by_id.has("b7") else "")
	if _mode == "fight" and res.get("STA", "—") == "—":
		res["STA"] = "Пауза"
	var rs := []
	if by_id.has("b8"):
		rs.append("нажать — " + String(by_id["b8"]).to_lower())
	for d2 in [["←", "a2-"], ["→", "a2+"], ["↑", "a3-"], ["↓", "a3+"]]:
		if by_id.has(d2[1]):
			rs.append(d2[0] + " " + String(by_id[d2[1]]).to_lower())
	res["RS"] = " · ".join(rs) if not rs.is_empty() else "Не используется"
	return res

# ---------- Переназначение кнопок ----------
func _edit_page() -> void:
	var b := Pad.binds(_mode)
	var funcs: Array = Pad.FUNCS[_mode]
	var hint := _lbl("Нажми на функцию, затем нажми на контроллере новую кнопку (5 секунд). Если кнопка уже занята — функции поменяются кнопками.",
			Vector2(60, 216), 15, Color(0.75, 0.9, 1.0), _vs.x - 120)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var colw := minf(520.0, (_vs.x - 120) / 2.0)
	var rows := ceili(funcs.size() / 2.0)
	var rh := minf(48.0, (_vs.y - 380.0) / rows)
	for i in funcs.size():
		var fn: String = funcs[i][0]
		var col := i / rows
		var x := _vs.x / 2 - colw - 10 + col * (colw + 20)
		var y := 262.0 + (i % rows) * rh
		var nl := _lbl(String(funcs[i][1]), Vector2(x, y + 8), 18)
		nl.size = Vector2(colw * 0.48, 26)
		var bt := Button.new()
		bt.position = Vector2(x + colw * 0.5, y)
		bt.size = Vector2(colw * 0.5, rh - 6)
		bt.add_theme_font_size_override("font_size", 17)
		bt.text = Pad.id_name(String(b[fn]))
		bt.set_meta("fn", fn)
		bt.pressed.connect(_start_wait.bind(fn, bt))
		_content.add_child(bt)
		if fn == _wait_fn:
			_wait_btn = bt
	var ml := _lbl(_msg, Vector2(40, _vs.y - 130), 17, Color(1.0, 0.85, 0.45))
	ml.size = Vector2(_vs.x - 80, 26)
	ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var rb := Button.new()
	rb.text = "Сбросить"
	rb.position = Vector2(_vs.x / 2 - 260, _vs.y - 92)
	rb.size = Vector2(240, 46)
	rb.add_theme_font_size_override("font_size", 18)
	rb.pressed.connect(func():
		_wait_fn = ""
		Pad.reset(_mode)
		_msg = "Раскладка «%s» сброшена" % ("Арена" if _mode == "fight" else "История")
		_refresh())
	_content.add_child(rb)
	var db := Button.new()
	db.text = "Готово"
	db.position = Vector2(_vs.x / 2 + 20, _vs.y - 92)
	db.size = Vector2(240, 46)
	db.add_theme_font_size_override("font_size", 18)
	db.pressed.connect(func():
		_wait_fn = ""
		_editing = false
		_refresh())
	_content.add_child(db)

func _start_wait(fn: String, bt: Button) -> void:
	_wait_fn = fn
	_wait_t = WAIT
	_wait_btn = bt
	_msg = "Нажми новую кнопку для «%s»..." % Pad.func_name(_mode, fn)
	_refresh_keep(fn)

func _process(delta: float) -> void:
	if _wait_fn == "":
		return
	_wait_t -= delta
	if _wait_t <= 0.0:
		_msg = "Время вышло — «%s» осталась на прежней кнопке" % Pad.func_name(_mode, _wait_fn)
		_wait_fn = ""
		_refresh()
		return
	if is_instance_valid(_wait_btn):
		_wait_btn.text = "Нажми кнопку... %d" % ceili(_wait_t)
		_wait_btn.modulate = Color(1.3, 1.2, 0.7) if int(_wait_t * 4) % 2 == 0 else Color.WHITE

# Пока ждём кнопку — перехватываем всё, что пришло с контроллера
func _input(event: InputEvent) -> void:
	if _wait_fn == "":
		# B в списке переназначения — вернуться к схеме, а не выйти из экрана
		if _editing and event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_editing = false
			_refresh()
		return
	if not (event is InputEventJoypadButton or event is InputEventJoypadMotion):
		return
	get_viewport().set_input_as_handled()
	if _wait_t > WAIT - 0.2:
		return                                   # то же нажатие, которым выбрали функцию
	var id := Pad.id_of(event)
	if id == "":
		if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_LEFT_X, JOY_AXIS_LEFT_Y] and absf(event.axis_value) > 0.6:
			_msg = "Левый стик занят ходьбой — выбери другую кнопку"
		return
	var fn := _wait_fn
	_wait_fn = ""
	var other := Pad.set_bind(_mode, fn, id)
	if other != "":
		_msg = "«%s» и «%s» поменялись кнопками" % [Pad.func_name(_mode, fn), Pad.func_name(_mode, other)]
	else:
		_msg = "«%s» — теперь %s" % [Pad.func_name(_mode, fn), Pad.id_name(id)]
	_refresh_keep(fn)

# Перестроить и вернуть выбор геймпада на ту же строку
func _refresh_keep(fn: String) -> void:
	_refresh()
	await get_tree().process_frame
	for c in _content.get_children():
		if c is Button and c.get_meta("fn", "") == fn and not c.is_queued_for_deletion():
			c.grab_focus()

func _callout(at: Vector2, anchor: Vector2, key: String, text: String, left_side: bool) -> void:
	var name := {"DPAD": "Крестовина", "LS": "Левый стик", "RS": "Правый стик"}.get(key, key) as String
	var w := 230.0
	var pos := at - Vector2(w, 0) if left_side else at
	var kl := _lbl(name, pos, 15, GOLD)
	kl.size = Vector2(w, 20)
	var tl := _lbl(text, pos + Vector2(0, 19), 14, INK if text != "—" else Color(1, 1, 1, 0.4), w)
	if left_side:
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var line := Line2D.new()
	var start := at + Vector2(6 if left_side else -6, 12)
	line.points = PackedVector2Array([start, Vector2(lerpf(start.x, anchor.x, 0.35), start.y), anchor])
	line.width = 2.0
	line.default_color = Color(1.0, 0.85, 0.4, 0.55)
	_content.add_child(line)
	var dot := Polygon2D.new()
	dot.polygon = Util.circle(4.0, 10)
	dot.color = GOLD
	dot.position = anchor
	_content.add_child(dot)

func _poly(pts: PackedVector2Array, c: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = c
	_content.add_child(p)

func _circle(pos: Vector2, r: float, c: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = Util.circle(r, 24)
	p.color = c
	p.position = pos
	_content.add_child(p)

func _rrect(r: Rect2, rad: float, c: Color) -> void:
	var pts := PackedVector2Array()
	var corners := [[r.end.x - rad, r.position.y + rad, -PI / 2], [r.end.x - rad, r.end.y - rad, 0.0],
			[r.position.x + rad, r.end.y - rad, PI / 2], [r.position.x + rad, r.position.y + rad, PI]]
	for cc in corners:
		for i in 7:
			var a: float = cc[2] + PI / 2 * i / 6.0
			pts.append(Vector2(cc[0], cc[1]) + Vector2(cos(a), sin(a)) * rad)
	_poly(pts, c)

func _letter(t: String, pos: Vector2, size: int, c := Color.WHITE) -> void:
	var l := _lbl(t, pos - Vector2(30, size * 0.7), size, c)
	l.size = Vector2(60, size * 1.4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

# Сам контроллер; возвращает точки кнопок для подписей
func _draw_pad(c: Vector2, k: float) -> Dictionary:
	var body := Color(0.20, 0.20, 0.23)
	var edge := Color(0.10, 0.10, 0.12)
	var btn := Color(0.32, 0.32, 0.36)
	# курки и бамперы (сзади)
	for s in [-1, 1]:
		_rrect(Rect2(c + Vector2(s * 205 - 50, -150) * k, Vector2(100, 50) * k), 16 * k, edge)
		_rrect(Rect2(c + Vector2(s * 205 - 48, -148) * k, Vector2(96, 46) * k), 14 * k, btn.darkened(0.15))
		_rrect(Rect2(c + Vector2(s * 190 - 62, -118) * k, Vector2(124, 34) * k), 12 * k, edge)
		_rrect(Rect2(c + Vector2(s * 190 - 60, -116) * k, Vector2(120, 30) * k), 10 * k, btn)
	# корпус: середина и две рукояти
	for g in [[edge, 6.0], [body, 0.0]]:
		_rrect(Rect2(c + Vector2(-210 - g[1], -100 - g[1]) * k, Vector2(420 + g[1] * 2, 170 + g[1] * 2) * k), 50 * k, g[0])
		for s in [-1, 1]:
			_circle(c + Vector2(s * 190, 40) * k, (100 + g[1]) * k, g[0])
	_rrect(Rect2(c + Vector2(-206, -96) * k, Vector2(412, 18) * k), 9 * k, body.lightened(0.08))      # блик сверху
	# крестовина
	var dp := c + Vector2(-190, -10) * k
	for d in [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]:
		_rrect(Rect2(dp + d * 30 * k - Vector2(17, 17) * k, Vector2(34, 34) * k), 7 * k, btn.lightened(0.1))
	_letter("↑", dp + Vector2(0, -30) * k, 18)
	_letter("↓", dp + Vector2(0, 30) * k, 18)
	_letter("←", dp + Vector2(-30, 0) * k, 18)
	_letter("→", dp + Vector2(30, 0) * k, 18)
	# кнопки справа
	var fp := c + Vector2(190, -10) * k
	var face := {"Y": [Vector2(0, -38), Color(0.95, 0.8, 0.2)], "B": [Vector2(38, 0), Color(0.9, 0.3, 0.25)],
			"A": [Vector2(0, 38), Color(0.35, 0.8, 0.35)], "X": [Vector2(-38, 0), Color(0.3, 0.55, 0.95)]}
	var res := {}
	for key in face:
		var p: Vector2 = fp + face[key][0] * k
		_circle(p, 21 * k, edge)
		_circle(p, 19 * k, btn.lightened(0.05))
		_letter(key, p, 18, face[key][1])
		res[key] = p + Vector2(20, 6) * k            # подпись цепляется за край кнопки, не закрывая букву
	# стики
	for s in [-1, 1]:
		var sp := c + Vector2(s * 85, 70) * k
		_circle(sp, 40 * k, edge)
		_circle(sp, 34 * k, Color(0.14, 0.14, 0.16))
		_circle(sp + Vector2(0, -3) * k, 26 * k, btn)
		res["LS" if s < 0 else "RS"] = sp + Vector2(s * 26, 26) * k
	# SEL и STA
	for s in [-1, 1]:
		var p2 := c + Vector2(s * 48, -40) * k
		_rrect(Rect2(p2 - Vector2(24, 10) * k, Vector2(48, 20) * k), 10 * k, btn.lightened(0.1))
		_letter("SEL" if s < 0 else "STA", p2 + Vector2(0, 22) * k, 12, Color(1, 1, 1, 0.7))
		res["SEL" if s < 0 else "STA"] = p2 + Vector2(0, -10) * k
	_letter("LT", c + Vector2(-205, -125) * k, 14, Color(1, 1, 1, 0.8))
	_letter("RT", c + Vector2(205, -125) * k, 14, Color(1, 1, 1, 0.8))
	_letter("LB", c + Vector2(-190, -101) * k, 13, Color(1, 1, 1, 0.8))
	_letter("RB", c + Vector2(190, -101) * k, 13, Color(1, 1, 1, 0.8))
	res["LT"] = c + Vector2(-205, -140) * k
	res["RT"] = c + Vector2(205, -140) * k
	res["LB"] = c + Vector2(-240, -101) * k
	res["RB"] = c + Vector2(240, -101) * k
	res["DPAD"] = dp + Vector2(-47, 0) * k
	return res

# ---------- Клавиатура ----------
func _keys_page() -> void:
	var cols := [
		["Игрок 1 (и История)", [["A / D", "Ходьба"], ["W", "Прыжок"], ["S", "Спрыгнуть вниз"], ["F", "Стрельба / удар"],
				["R", "Перезарядка"], ["Q / E / C", "Способности 1–3"], ["X", "Ульта"]]],
		["Только в Истории", [["G", "Дальний бой"], ["T", "Взаимодействие"], ["I", "Рюкзак"], ["J", "Задания"],
				["Esc", "Меню (пауза)"], ["Q / E в рюкзаке", "Соседняя вкладка"]]],
		["Игрок 2 (Дуэль)", [["← / →", "Ходьба"], ["↑", "Прыжок"], ["↓", "Спрыгнуть вниз"], ["Enter", "Стрельба"],
				["Num +", "Перезарядка"], ["Num 1 / 2 / 3", "Способности"], ["Num 0", "Ульта"]]],
	]
	var cw := (_vs.x - 80) / 3.0
	for i in cols.size():
		var x := 40 + i * cw
		_lbl(cols[i][0], Vector2(x, 150), 22, GOLD)
		var y := 192.0
		for row in cols[i][1]:
			_lbl(row[0], Vector2(x, y), 18, Color(0.7, 0.9, 1.0))
			_lbl(row[1], Vector2(x + 150, y), 18)
			y += 38.0
	var f := _lbl("F11 (или Alt+Enter) — полный экран.", Vector2(40, _vs.y - 50), 15, Color(1, 1, 1, 0.6))
	f.size = Vector2(_vs.x - 80, 24)

# ---------- Экранные кнопки ----------
func _touch_page() -> void:
	var t := _lbl("На телефоне без контроллера управление — кнопками на экране:\n\n" +
			"• Слева — движение: виртуальный стик (веди пальцем: влево/вправо — ходьба, вверх — прыжок, вниз — спрыгнуть) или крестовина (вверх — прыжок, вниз — спрыгнуть; в углах можно нажать две стрелки сразу). Вид и размер крестовины — в «Настройках».\n" +
			"• Справа — стрельба или удар, способности 1–3, ульта (и отдельный прыжок при стике). Пока способность перезаряжается, кнопка заполняется и на ней видно, сколько секунд осталось.\n" +
			"• В Истории ещё: дальний бой, «Взаимодействие» (светится рядом с сундуком, дверью, табличкой), а сверху — «Рюкзак», «Задания», «Меню».\n\n" +
			"Кнопки полупрозрачные и лежат прямо на экране; в «Настройках» можно вернуть полосу снизу и выбрать, насколько кнопки видны. " +
			"Когда подключён контроллер, экранные кнопки прячутся, а перезарядка способностей показывается значками в углу.",
			Vector2(80, 160), 19, INK, _vs.x - 160)
	t.size = Vector2(_vs.x - 160, 400)
