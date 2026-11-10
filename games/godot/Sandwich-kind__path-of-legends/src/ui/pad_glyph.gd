class_name PadGlyph
extends Control
# ---------- Значок кнопки геймпада ----------
# Маленькая плашка «LB», «A», «B»… рядом с кнопкой интерфейса: подсказывает,
# что нажать на контроллере. Видна, только когда контроллер подключён.

var label := "A"
static var force := false     # показывать всегда (для снимков экрана)
const COLORS := {"A": Color(0.35, 0.8, 0.35), "B": Color(0.9, 0.3, 0.25), "X": Color(0.3, 0.55, 0.95),
		"Y": Color(0.95, 0.8, 0.2)}

static func make(t: String) -> PadGlyph:
	var g := PadGlyph.new()
	g.label = t
	return g

# Прикрепить к кнопке: слева (side = -1), справа (1) или в правом верхнем углу (0)
static func attach(c: Control, t: String, side := 0) -> PadGlyph:
	var g := make(t)
	c.add_child(g)
	g._place(c, side)
	return g

func _place(c: Control, side: int) -> void:
	var s := _size()
	match side:
		-1:
			position = Vector2(-s.x - 6, (c.size.y - s.y) / 2)
		1:
			position = Vector2(c.size.x + 6, (c.size.y - s.y) / 2)
		_:
			position = Vector2(c.size.x - s.x * 0.7, -s.y * 0.35)

func _size() -> Vector2:
	var short := label.length() <= 1
	return Vector2(28, 28) if short else Vector2(maxf(40.0, 10.0 + label.length() * 10.0), 28)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = _size()
	z_index = 5
	var p := Panel.new()
	p.size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	st.border_color = COLORS.get(label, Color(0.85, 0.85, 0.9))
	st.set_border_width_all(2)
	st.set_corner_radius_all(14 if label.length() <= 1 else 8)
	p.add_theme_stylebox_override("panel", st)
	add_child(p)
	var l := Label.new()
	l.text = label
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 15 if label.length() <= 3 else 12)
	l.add_theme_color_override("font_color", COLORS.get(label, Color(1, 1, 1)))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	visible = (Pad.connected() and Pad.using_pad) or force

func _process(_d: float) -> void:
	visible = (Pad.connected() and Pad.using_pad) or force
