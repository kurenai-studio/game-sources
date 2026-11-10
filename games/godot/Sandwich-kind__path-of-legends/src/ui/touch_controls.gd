class_name TouchControls
# Нижняя панель и экранные кнопки управления.

# Тёмная панель внизу экрана, на которой лежат кнопки (если в настройках
# выбрано «Полоса снизу»; иначе кнопки полупрозрачные прямо поверх игры)
static func build_panel(world: Node, split: bool) -> void:
	if not Config.can_touch() or not Config.touch_panel():
		return
	var vs := Config.screen(world)
	var layer := CanvasLayer.new()
	layer.layer = 4
	layer.add_to_group("touch_ui")
	layer.visible = Config.touch()
	world.add_child(layer)
	var panel := ColorRect.new()
	panel.color = Color(0.1, 0.09, 0.12)
	panel.position = Vector2(0, vs.y - Config.PANEL)
	panel.size = Vector2(vs.x, Config.PANEL)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(panel)
	if split:   # разделитель между половинами игроков
		var line := ColorRect.new()
		line.color = Color(1, 1, 1, 0.15)
		line.position = Vector2(vs.x / 2 - 1, vs.y - Config.PANEL + 8)
		line.size = Vector2(2, Config.PANEL - 16)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(line)

# Корень для кнопок: поверх игры — полупрозрачный
static func _root(world: Node, layer_n: int) -> Control:
	var layer := CanvasLayer.new()
	layer.layer = layer_n
	layer.add_to_group("touch_ui")
	layer.visible = Config.touch()
	world.add_child(layer)
	var root := Control.new()
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not Config.touch_panel():
		root.modulate.a = clampf(float(StorySettings.get_value("touch_alpha")) / 100.0, 0.2, 1.0)
	layer.add_child(root)
	return root

static func use_stick() -> bool:
	return String(StorySettings.get_value("touch_move")) == "stick"

# side: "left" — игрок 1 в дуэли, "right" — игрок 2, "solo" — одиночная игра.
# Возвращает кнопки, чтобы герой мог показывать на них перезарядку способностей.
# Без экранных кнопок (геймпад, клавиатура) — маленькие значки способностей
# с перезарядкой и подписью, какую кнопку нажать.
static func build(world: Node, prefix: String, side: String, p: Player = null) -> Dictionary:
	# значки перезарядки (для геймпада и клавиатуры) есть всегда, экранные кнопки — если можно касаться
	var ind := build_indicators(world, prefix, side, p)
	if not Config.can_touch():
		return ind
	var vs := Config.screen(world)
	var W := vs.x
	var BTN := Config.BTN
	var root := _root(world, 5)
	var yt := vs.y - Config.PANEL + 6.0       # верхний ряд
	var yb := yt + BTN + 6.0                  # нижний ряд
	var b := Vector2(BTN, BTN)
	var stick := use_stick()
	# [действие, x, y, подпись, размер] — координаты для левой половины
	var actions := [
			["a1", 300.0, yt, "1", b], ["a2", 368.0, yt, "2", b],
			["a3", 436.0, yt, "3", b], ["ult", 504.0, yt, "U", b],
			["reload", 300.0, yb, "R", b], ["shoot", 368.0, yb, "*", Vector2(BTN * 3 + 12, BTN)]]
	if stick:
		actions.append(["jump", 572.0, yb, "^", b])     # со стиком прыжок — ещё и отдельной кнопкой (рядом с атакой)
	if side == "right":
		for a in actions:
			a[1] = W - a[1] - a[4].x      # зеркально у центра
	elif side == "solo":
		for a in actions:
			a[1] = W - 10.0 - (a[1] - 300.0) - a[4].x   # зеркально у правого края
	# движение: крестовина-кнопки или виртуальный стик
	var moves := []
	var ui := {}
	if not stick:
		# крестовина: вверх — над, вниз — под кнопками влево/вправо.
		# На двоих она не должна залезать на половину соседа — тогда чуть меньше.
		var room := INF
		if side != "solo":
			room = W / 2.0 - 10.0 - 280.0
		var cell := dpad_cell(room)
		var cw := cell * 3.0 + DPAD_GAP * 2.0
		var x0 := 10.0 if side != "right" else W - 10.0 - cw      # игроку 2 — у правого края, без зеркала
		var top := vs.y - 8.0 - cw
		ui.merge(add_dpad(root, prefix, Vector2(x0, top), cell))
		# способности сдвигаются, чтобы не лечь на большую крестовину
		var shift := maxf(0.0, cw + 24.0 - 300.0)
		if shift > 0.0:
			for a in actions:
				a[1] += shift * (-1.0 if side == "right" else 1.0) if side != "solo" else 0.0
	else:
		var area := Rect2(0, yt - 150.0, 226.0, vs.y - yt + 150.0)
		if side == "right":
			area.position.x = W - area.size.x
		add_stick(root, prefix, area)
	# у легенд на кнопках нарисованы их способности и оружие (у тестовых — цифры)
	var icons := {}
	if p and p.kit:
		for i in 3:
			icons["a%d" % (i + 1)] = p.abilities[i]
		icons["ult"] = p.ult
		icons["shoot"] = AbilityIcons.WEAPONS.get(p.kit.hero, "")
	for a in moves + actions:
		var label: String = a[3]
		var icon_id: String = icons.get(a[0], "")
		if icon_id != "" and AbilityIcons.has(icon_id):
			label = "#" + icon_id
		ui[a[0]] = _make_button(root, prefix + "_" + a[0], Vector2(a[1], a[2]), label, a[4])
	ui["_ind"] = ind
	return ui

# ---------- Крестовина ----------
const DPAD_CELL := 74.0        # кнопка крестовины при размере 100%
const DPAD_GAP := 5.0

# Размер одной кнопки крестовины с учётом настройки «Размер крестовины» (60–160%)
# room — сколько места есть по ширине (на двоих — половина экрана минус способности)
static func dpad_cell(room := INF) -> float:
	var k := clampf(float(StorySettings.get_value("dpad_size")) / 100.0, 0.6, 1.6)
	var cell := DPAD_CELL * k
	if room < INF:
		cell = minf(cell, (room - DPAD_GAP * 2.0) / 3.0)
	return maxf(cell, 48.0)

# Крестовина «плюсом»: вверх (прыжок), влево, вправо, вниз. В углах — невидимые
# двойные зоны: вверх-влево нажимает прыжок и влево сразу (удобно прыгать на бегу).
static func add_dpad(root: Control, prefix: String, top_left: Vector2, cell: float) -> Dictionary:
	var c := cell
	var st := c + DPAD_GAP
	var sz := Vector2(c, c)
	var ui := {}
	# подложка-крест, чтобы было видно, где крестовина целиком
	var plus := Polygon2D.new()
	var a0 := top_left
	plus.polygon = PackedVector2Array([a0 + Vector2(st, 0), a0 + Vector2(st + c, 0), a0 + Vector2(st + c, st),
			a0 + Vector2(st * 2 + c, st), a0 + Vector2(st * 2 + c, st + c), a0 + Vector2(st + c, st + c),
			a0 + Vector2(st + c, st * 2 + c), a0 + Vector2(st, st * 2 + c), a0 + Vector2(st, st + c),
			a0 + Vector2(0, st + c), a0 + Vector2(0, st), a0 + Vector2(st, st)])
	plus.color = Color(0, 0, 0, 0.18)
	root.add_child(plus)
	for m in [["jump", Vector2(st, 0), "^"], ["left", Vector2(0, st), "<"],
			["right", Vector2(st * 2, st), ">"], ["down", Vector2(st, st * 2), "v"]]:
		ui[m[0]] = _make_button(root, prefix + "_" + m[0], top_left + m[1], m[2], sz)
	# углы: две кнопки на одном месте — касание нажимает обе
	for corner in [[Vector2(0, 0), ["jump", "left"]], [Vector2(st * 2, 0), ["jump", "right"]],
			[Vector2(0, st * 2), ["down", "left"]], [Vector2(st * 2, st * 2), ["down", "right"]]]:
		for act in corner[1]:
			var tb := TouchScreenButton.new()
			var rs := RectangleShape2D.new()
			rs.size = sz
			tb.shape = rs
			tb.action = prefix + "_" + act
			tb.passby_press = true
			tb.position = top_left + corner[0] + sz / 2.0
			root.add_child(tb)
			var vis: Panel = ui[act]["bg"]
			tb.pressed.connect(func(): vis.modulate = Color(1.6, 1.6, 1.6))
			tb.released.connect(func(): vis.modulate = Color.WHITE)
	return ui

static func add_stick(parent: Node, prefix: String, area: Rect2) -> VirtualStick:
	var st := VirtualStick.new()
	st.prefix = prefix
	st.area = area
	parent.add_child(st)
	return st

# ---------- Значки способностей без экранных кнопок ----------
# keys — подписи под значками (какую кнопку нажать); по умолчанию — из раскладки
static func build_indicators(world: Node, prefix: String, side: String, p: Player, keys := {}) -> Dictionary:
	if p == null:
		return {}
	var vs := Config.screen(world)
	var layer := CanvasLayer.new()
	layer.layer = 5
	layer.add_to_group("pad_ui")
	layer.visible = not Config.touch()
	world.add_child(layer)
	var S := 54.0
	var names := ["a1", "a2", "a3", "ult"]
	if keys.is_empty():
		keys = key_names(prefix, "fight")
	var ui := {}
	for i in names.size():
		var a: String = names[i]
		var ab: String = p.ult if a == "ult" else p.abilities[i]
		var x := 14.0 + i * (S + 10.0)
		if side != "left":
			x = vs.x - 14.0 - (names.size() - i) * (S + 10.0)
		var pos := Vector2(x, vs.y - S - 34.0)
		var icon := ""
		if ab != "":
			icon = StoryAbilities.get_def(ab).get("icon", ab) if p.kit and p.kit.hero == "story" else ab
		var d := _make_indicator(layer, pos, Vector2(S, S), icon if AbilityIcons.has(icon) else "")
		var kl := Label.new()
		kl.text = String(keys.get(a, ""))
		kl.position = pos + Vector2(-8, S + 2)
		kl.size = Vector2(S + 16, 20)
		kl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		kl.add_theme_font_size_override("font_size", 13)
		kl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.6))
		kl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(kl)
		if ab == "":
			d["bg"].modulate = Color(1, 1, 1, 0.35)
		ui[a] = d
	return ui

# Подписи кнопок способностей: геймпад (из раскладки) или клавиатура
static func key_names(prefix: String, profile: String) -> Dictionary:
	if Pad.connected():
		var b := Pad.binds(profile) if prefix == "p1" and Pad.layout in ["fight", "story"] else Pad.DEFAULTS["fight"]
		if Pad.layout == "shared":
			var sp: Dictionary = Pad.SPLIT_P1 if prefix == "p1" else Pad.SPLIT_P2
			return {"a1": Pad.id_name(sp["a1"][0]), "a2": Pad.id_name(sp["a2"][0]), "a3": Pad.id_name(sp["a3"][0]),
					"ult": Pad.id_name(sp["ult"][0])}
		return {"a1": Pad.id_name(b["a1"]), "a2": Pad.id_name(b["a2"]), "a3": Pad.id_name(b["a3"]), "ult": Pad.id_name(b["ult"])}
	if prefix == "p2":
		return {"a1": "Num1", "a2": "Num2", "a3": "Num3", "ult": "Num0"}
	return {"a1": "Q", "a2": "E", "a3": "C", "ult": "X"}

static func _make_indicator(parent: Node, pos: Vector2, size: Vector2, icon_id: String) -> Dictionary:
	var vis := Panel.new()
	var st := _style(Color(1, 1, 1, 0.18))
	vis.add_theme_stylebox_override("panel", st)
	vis.size = size
	vis.position = pos
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(vis)
	var fill := ColorRect.new()
	fill.color = Color(1, 1, 1, 0.22)
	fill.size = size - Vector2(8, 8)
	fill.position = pos + Vector2(4, 4)
	fill.visible = false
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(fill)
	var icon: Node2D = null
	if icon_id != "":
		icon = AbilityIcons.make(icon_id, size.x * 0.78)
		icon.position = pos + size / 2
		parent.add_child(icon)
	return {"bg": vis, "fill": fill, "style": st, "icon": icon, "num": _num_label(parent, pos, size)}

const MOVE_W := 88.0
const READY := Color(1, 1, 1, 0.32)
const READY_ULT := Color(1.0, 0.78, 0.2, 0.75)
const NOT_READY := Color(1, 1, 1, 0.08)

static func _style(c: Color) -> StyleBoxTexture:
	var st := UiArt.touch_box()
	st.modulate_color = Color(c.r, c.g, c.b, minf(1.0, 0.55 + c.a * 1.4))
	return st

static func _make_button(layer: Node, action: String, pos: Vector2, text: String,
		size: Vector2) -> Dictionary:
	var vis := Panel.new()
	var st := _style(Color(1, 1, 1, 0.18))
	vis.add_theme_stylebox_override("panel", st)
	vis.size = size
	vis.position = pos
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(vis)

	var fill := ColorRect.new()          # полоска готовности способности
	fill.color = Color(1, 1, 1, 0.16)
	fill.size = size - Vector2(8, 8)
	fill.position = pos + Vector2(4, 4)
	fill.visible = false
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fill)

	var icon: Node2D = null
	if text.begins_with("#"):
		icon = AbilityIcons.make(text.substr(1), minf(size.x, size.y) * 0.78)
	else:
		icon = _icon(text, size)
	if icon:
		icon.position = pos + size / 2
		layer.add_child(icon)
	else:
		var lbl := Label.new()
		lbl.text = text
		lbl.size = size
		lbl.position = pos
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lbl.add_theme_font_size_override("font_size", 30)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(lbl)

	var btn := TouchScreenButton.new()
	var rs := RectangleShape2D.new()
	rs.size = size
	btn.shape = rs
	btn.action = action
	btn.passby_press = true
	btn.position = pos + size / 2
	layer.add_child(btn)
	# нажатая кнопка подсвечивается
	btn.pressed.connect(func(): vis.modulate = Color(1.6, 1.6, 1.6))
	btn.released.connect(func(): vis.modulate = Color.WHITE)
	return {"bg": vis, "fill": fill, "style": st, "icon": icon, "num": _num_label(layer, pos, size)}

# Сколько секунд осталось до готовности — крупно посередине
static func _num_label(parent: Node, pos: Vector2, size: Vector2) -> Label:
	var n := Label.new()
	n.position = pos
	n.size = size
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	n.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	n.add_theme_font_size_override("font_size", int(size.y * 0.42))
	n.add_theme_constant_override("outline_size", 6)
	n.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.visible = false
	parent.add_child(n)
	return n

# Значки: стрелки, прыжок, прицел. Для остальных — надпись.
static func _icon(text: String, size: Vector2) -> Node2D:
	var c := Color(1, 1, 1, 0.9)
	var n := Node2D.new()
	var p := Polygon2D.new()
	p.color = c
	var k := minf(size.x, size.y) * 0.22
	match text:
		"<":
			p.polygon = PackedVector2Array([Vector2(-k * 1.2, 0), Vector2(k, -k * 1.3), Vector2(k, k * 1.3)])
		">":
			p.polygon = PackedVector2Array([Vector2(k * 1.2, 0), Vector2(-k, -k * 1.3), Vector2(-k, k * 1.3)])
		"^":
			p.polygon = PackedVector2Array([Vector2(0, -k * 1.1), Vector2(k * 1.3, k * 0.8), Vector2(-k * 1.3, k * 0.8)])
		"v":
			p.polygon = PackedVector2Array([Vector2(0, k * 1.1), Vector2(k * 1.3, -k * 0.8), Vector2(-k * 1.3, -k * 0.8)])
		"*":
			var ring := Line2D.new()
			var pts := Util.circle(k * 1.1, 20)
			pts.append(pts[0])
			ring.points = pts
			ring.width = 4.0
			ring.default_color = c
			n.add_child(ring)
			p.polygon = Util.circle(k * 0.35, 10)
			for v in [Vector2(1, 0), Vector2(-1, 0), Vector2(0, 1), Vector2(0, -1)]:
				var l := Line2D.new()
				l.points = PackedVector2Array([v * k * 0.6, v * k * 1.5])
				l.width = 4.0
				l.default_color = c
				n.add_child(l)
		_:
			return null
	n.add_child(p)
	return n

# Показывает готовность способности: заполняется снизу, готовая — подсвечена
static func set_state(b: Dictionary, ratio: float, is_ult: bool, left := -1.0) -> void:
	if b.has("num") and b["num"]:
		var nl: Label = b["num"]
		nl.visible = left > 0.0 and ratio < 1.0
		if nl.visible:
			nl.text = ("%.1f" % left) if left < 1.0 else str(ceili(left))
	var bg: Panel = b["bg"]
	var fill: ColorRect = b["fill"]
	var st: StyleBoxTexture = b["style"]
	var ready := ratio >= 1.0
	var c := (READY_ULT if is_ult else READY) if ready else NOT_READY
	st.modulate_color = Color(c.r, c.g, c.b, minf(1.0, 0.55 + c.a * 1.4))
	if b.has("icon") and b["icon"]:
		b["icon"].modulate = Color(1, 1, 1, 1.0 if ready else 0.45)   # значок тускнеет, пока перезаряжается
	fill.visible = not ready
	var inner := bg.size - Vector2(8, 8)
	fill.size = Vector2(inner.x, inner.y * clampf(ratio, 0.0, 1.0))
	fill.position = bg.position + Vector2(4, 4 + inner.y - fill.size.y)

# Действия и клавиши (клавиатура — для игры на компьютере)
static func add_actions() -> void:
	_add("p1", {"left": KEY_A, "right": KEY_D, "jump": KEY_W, "down": KEY_S, "shoot": KEY_F,
			"a1": KEY_Q, "a2": KEY_E, "a3": KEY_C, "ult": KEY_X, "reload": KEY_R})
	_add("p2", {"left": KEY_LEFT, "right": KEY_RIGHT, "jump": KEY_UP, "down": KEY_DOWN, "shoot": KEY_ENTER,
			"a1": KEY_KP_1, "a2": KEY_KP_2, "a3": KEY_KP_3, "ult": KEY_KP_0, "reload": KEY_KP_ADD})

static func _add(prefix: String, keys: Dictionary) -> void:
	for a in keys:
		var action_name: String = prefix + "_" + a
		if InputMap.has_action(action_name):
			continue
		InputMap.add_action(action_name)
		var ev := InputEventKey.new()
		ev.physical_keycode = keys[a]
		InputMap.action_add_event(action_name, ev)
