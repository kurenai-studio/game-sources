class_name LegendPicker
extends Control
# Выбор легенд: каменные колонны, на них стоят герои. Стрелки переключают героя.
# count = 1 (Арена в одиночку) или 2 (Дуэль, Арена вдвоём).

signal go_pressed
signal back_pressed

var count := 2
var sel := [0, 1]
var titles := ["Игрок 1", "Игрок 2"]
var colors := [Config.OUTLINE_P1, Config.OUTLINE_P2]
var outlines := true
var go_text := "В БОЙ!"
var style := "columns"        # "columns" — каменные колонны, "lift" — подъёмники в подвале Колизея
var _slots: Array = []
var _cols: Array = []
var _go: Button

func _ready() -> void:
	var vs := Config.screen(self)
	size = vs
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if style == "lift":
		var img := PixelArt.basement()
		var k := maxf(vs.x / img.get_width(), vs.y / img.get_height())
		var bg := PixelArt.make_sprite(img, k)
		bg.position = (vs - Vector2(img.get_size()) * k) / 2
		add_child(bg)
	var xs := [vs.x / 2] if count == 1 else [vs.x * 0.27, vs.x * 0.73]
	for i in count:
		_build_column(i, xs[i], vs)
	var go := MainMenu.make_button(self, go_text, Vector2(vs.x / 2 - 150, vs.y - 105), Vector2(300, 84), 40)
	go.pressed.connect(func():
		if not go.disabled:
			go_pressed.emit())
	_go = go
	go.set_meta("pad_default", true)
	var back := MainMenu.make_button(self, "Назад", Vector2(20, 20), Vector2(130, 55), 26)
	back.pressed.connect(func(): back_pressed.emit())
	_refresh()

func _build_column(slot: int, cx: float, vs: Vector2) -> void:
	var col := Control.new()
	col.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(col)
	_cols.append(col)
	var top := vs.y - 270.0
	if style == "lift":
		_build_lift(col, cx, vs)
		_add_labels(col, slot, cx, top)
		return
	# луч света сверху
	var cone := Polygon2D.new()
	cone.polygon = PackedVector2Array([Vector2(cx - 30, 0), Vector2(cx + 30, 0),
			Vector2(cx + 150, top), Vector2(cx - 150, top)])
	cone.color = Color(1.0, 0.95, 0.75, 0.08)
	col.add_child(cone)
	# каменная колонна: капитель, ствол с кладкой, база
	var stone := Color(0.62, 0.60, 0.58)
	_rect(col, Vector2(cx - 95, top), Vector2(190, 26), stone.lightened(0.12))
	_rect(col, Vector2(cx - 75, top + 26), Vector2(150, vs.y - top - 60), stone)
	for k in 9:
		_rect(col, Vector2(cx - 75, top + 50 + k * 26), Vector2(150, 3), stone.darkened(0.2))
		var off := 0.0 if k % 2 == 0 else 37.0
		for j in 3:
			if off + j * 75 < 147.0:
				_rect(col, Vector2(cx - 75 + off + j * 75, top + 26 + k * 26), Vector2(3, 24), stone.darkened(0.18))
	for fx in [-50.0, -10.0, 30.0]:
		_rect(col, Vector2(cx + fx, top + 26), Vector2(6, vs.y - top - 60), stone.darkened(0.08))
	_rect(col, Vector2(cx - 100, vs.y - 34), Vector2(200, 34), stone.darkened(0.1))
	_add_labels(col, slot, cx, top)

func _add_labels(col: Control, slot: int, cx: float, top: float) -> void:
	# надписи и стрелки
	var t := Label.new()
	t.text = titles[slot]
	t.size = Vector2(300, 36)
	t.position = Vector2(cx - 150, 80)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 24)
	t.add_theme_color_override("font_color", colors[slot] if outlines else Color(1.0, 0.85, 0.5))
	col.add_child(t)
	var name_lbl := Label.new()
	name_lbl.size = Vector2(360, 44)
	name_lbl.position = Vector2(cx - 180, 112)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 32)
	col.add_child(name_lbl)
	var left := MainMenu.make_button(col, "<", Vector2(cx - 190, top - 110), Vector2(64, 84), 38)
	left.pressed.connect(_change.bind(slot, -1))
	var right := MainMenu.make_button(col, ">", Vector2(cx + 126, top - 110), Vector2(64, 84), 38)
	right.pressed.connect(_change.bind(slot, 1))
	var holder := Control.new()
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(holder)
	# кнопка «МЕГА» под героем — только если усиление куплено в Лавке
	var mega := Button.new()
	mega.text = "МЕГА"
	mega.position = Vector2(cx - 80, top + 34)
	mega.size = Vector2(160, 56)
	mega.add_theme_font_size_override("font_size", 28)
	mega.pressed.connect(_toggle_mega.bind(slot))
	mega.visible = false
	col.add_child(mega)
	_slots.append({"name": name_lbl, "holder": holder, "cx": cx, "top": top, "mega": mega})

# Деревянный подъёмник: площадка на канатах, уходящих к люку в потолке
func _build_lift(col: Control, cx: float, vs: Vector2) -> void:
	var top := vs.y - 270.0
	var wood := Color(0.52, 0.34, 0.18)
	for side in [-1.0, 1.0]:
		_rect(col, Vector2(cx + side * 90 - 2, -10), Vector2(4, top + 10), Color(0.7, 0.6, 0.4))   # канаты
	_rect(col, Vector2(cx - 105, top), Vector2(210, 18), wood)
	_rect(col, Vector2(cx - 105, top), Vector2(210, 3), wood.lightened(0.2))
	for k in 6:
		_rect(col, Vector2(cx - 100 + k * 35, top + 2), Vector2(2, 16), wood.darkened(0.3))
	_rect(col, Vector2(cx - 95, top + 18), Vector2(190, 10), wood.darkened(0.25))
	for side in [-1.0, 1.0]:
		_rect(col, Vector2(cx + side * 90 - 6, top + 18), Vector2(12, 26), wood.darkened(0.35))

# Подъёмники уезжают вверх вместе с героями, потом вызывается done
func lift_up(done: Callable) -> void:
	var vs := Config.screen(self)
	var t := create_tween()
	t.set_parallel(true)
	for i in _cols.size():
		t.tween_property(_cols[i], "position:y", -vs.y, 1.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN).set_delay(0.1 * i)
	t.chain().tween_callback(done)

func _rect(parent: Node, pos: Vector2, s: Vector2, c: Color) -> void:
	var r := ColorRect.new()
	r.position = pos
	r.size = s
	r.color = c
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

func _change(slot: int, d: int) -> void:
	sel[slot] = Characters.step(sel[slot], d)
	_refresh()

func _toggle_mega(slot: int) -> void:
	Characters.mega_on[slot] = not Characters.mega_on[slot]
	_refresh()

# Вид кнопки «МЕГА»: включена — горит фиолетово-золотым, выключена — тусклая
func _mega_style(b: Button, on: bool) -> void:
	for st_name in ["normal", "hover", "pressed", "focus"]:
		var st := StyleBoxFlat.new()
		st.bg_color = Color(0.55, 0.2, 0.75) if on else Color(0.2, 0.18, 0.24, 0.9)
		st.border_color = Color(1.0, 0.85, 0.3) if on else Color(0.5, 0.45, 0.55)
		st.set_border_width_all(4)
		st.set_corner_radius_all(10)
		if on:
			st.shadow_color = Color(0.85, 0.5, 1.0, 0.6)
			st.shadow_size = 10
		b.add_theme_stylebox_override(st_name, st)
	b.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6) if on else Color(0.7, 0.68, 0.75))
	b.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.6) if on else Color(0.85, 0.82, 0.9))
	b.text = "МЕГА: ВКЛ" if on else "МЕГА: ВЫКЛ"

func _refresh() -> void:
	var all_open := true
	for i in _slots.size():
		var s: Dictionary = _slots[i]
		var open := Characters.unlocked(sel[i])
		all_open = all_open and open
		s["name"].text = Characters.LIST[sel[i]]["name"] if open else "???"
		var mb: Button = s["mega"]
		mb.visible = open and Save.has_mega(Characters.LIST[sel[i]]["name"])
		if mb.visible:
			_mega_style(mb, Characters.mega_on[i])
		for n in s["holder"].get_children():
			n.queue_free()
		var face := 1 if (count == 1 or i == 0) else -1
		HeroFigure.draw(s["holder"], Vector2(s["cx"], s["top"]), 2.6, sel[i],
				colors[i] if outlines else Color(0, 0, 0, 0), face, not open)
		if not open:
			# закрытая легенда: силуэт и подсказка, как её открыть
			var l := Label.new()
			l.text = Characters.unlock_text(sel[i])
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.size = Vector2(300, 60)
			l.position = Vector2(s["cx"] - 150, s["top"] - 230)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.add_theme_font_size_override("font_size", 18)
			l.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
			s["holder"].add_child(l)
	if _go:
		_go.disabled = not all_open

# Колонны поднимаются из-под экрана
func rise() -> void:
	var vs := Config.screen(self)
	for i in _cols.size():
		var c: Control = _cols[i]
		c.position.y = vs.y if style != "lift" else -vs.y      # подъёмник спускается сверху
		var tw := c.create_tween()
		tw.tween_interval(0.12 * i)
		tw.tween_property(c, "position:y", 0.0, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
