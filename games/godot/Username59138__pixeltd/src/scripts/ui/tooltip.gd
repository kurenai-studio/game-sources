extends Control
## Custom-drawn pixel tooltip. Lines: {"t": text, "c": color, "r": right text, "rc": right color,
## "bar": 0..1 (draws an HP bar), "bc": bar colour, "wrap": bool}

const LINE_H := 10
const W := 132

var lines: Array = []
var anchor := Vector2.ZERO
var _layout: Array = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 50
	visible = false


func show_lines(p_lines: Array, at: Vector2) -> void:
	lines = p_lines
	anchor = at
	_relayout()
	visible = true
	queue_redraw()


func hide_tip() -> void:
	visible = false


func _relayout() -> void:
	var f := UI.font()
	_layout.clear()
	for l in lines:
		if l.has("bar"):
			_layout.append(l)
			continue
		var text: String = l.get("t", "")
		if l.get("wrap", false):
			var words := text.split(" ")
			var cur := ""
			for w in words:
				var cand := w if cur == "" else cur + " " + w
				if f.get_string_size(cand, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x > W - 10:
					_layout.append({"t": cur, "c": l.get("c", Color.WHITE)})
					cur = w
				else:
					cur = cand
			if cur != "":
				_layout.append({"t": cur, "c": l.get("c", Color.WHITE)})
		else:
			_layout.append(l)
	var h := 0
	for l in _layout:
		h += 6 if l.has("bar") else (4 if l.get("t", "x") == "" and not l.has("r") else LINE_H)
	size = Vector2(W, h + 8)
	var p := anchor + Vector2(10, 6)
	var vp := Vector2(640, 360)
	if p.x + size.x > vp.x - 2:
		p.x = anchor.x - size.x - 6
	if p.y + size.y > vp.y - 2:
		p.y = vp.y - size.y - 2
	position = p.round()


func _draw() -> void:
	var f := UI.font()
	draw_style_box(UI.box("panel_dark"), Rect2(Vector2.ZERO, size))
	var y := 4
	for l in _layout:
		if l.has("bar"):
			var bw := W - 10
			draw_rect(Rect2(5, y, bw, 4), Color("181425"))
			draw_rect(Rect2(6, y + 1, bw - 2, 2), Color("3a4466"))
			draw_rect(Rect2(6, y + 1, roundf((bw - 2) * clampf(l["bar"], 0, 1)), 2), l.get("bc", Color("63c74d")))
			y += 6
			continue
		var t: String = l.get("t", "")
		if t == "" and not l.has("r"):
			y += 4
			continue
		var base := Vector2(5, y + 8)
		draw_string(f, base + Vector2(1, 1), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("181425"))
		draw_string(f, base, t, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, l.get("c", Color.WHITE))
		if l.has("r"):
			var rt: String = l["r"]
			var rw := f.get_string_size(rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
			var rp := Vector2(W - 5 - rw, y + 8)
			draw_string(f, rp + Vector2(1, 1), rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("181425"))
			draw_string(f, rp, rt, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, l.get("rc", Color.WHITE))
		y += LINE_H
