class_name BloomPaint
extends RefCounted
## אבני חן מצוירות: פאות, ברק, ובאר שקועה. בלי קובץ PNG.


static func gem(ci: CanvasItem, r: Rect2, col: Color, filled: bool, pulse: float = 0.0) -> void:
	if r.size.x < 2.0 or r.size.y < 2.0:
		return
	var shrink := clampf(r.size.x * 0.07, 1.0, 3.5)
	var body := r.grow(-shrink)
	if not filled:
		ci.draw_rect(r, Color(0.015, 0.02, 0.04, 0.94))
		ci.draw_rect(body, Color(0.008, 0.012, 0.028, 0.98))
		var lip := maxf(body.size.y * 0.28, 3.0)
		ci.draw_rect(Rect2(body.position, Vector2(body.size.x, lip)), Color(0.0, 0.0, 0.0, 0.42))
		ci.draw_rect(
			Rect2(body.position + Vector2(0.0, body.size.y - 2.0), Vector2(body.size.x, 2.0)),
			Color(0.45, 0.62, 0.82, 0.16)
		)
		ci.draw_rect(r, Color(0.28, 0.40, 0.58, 0.28), false, 1.0)
		return
	ci.draw_rect(Rect2(r.position + Vector2(1.6, 3.2), r.size), Color(0, 0, 0, 0.32))
	var glow_a := 0.18 + pulse * 0.24
	ci.draw_rect(r.grow(3.0), Color(col.r, col.g, col.b, glow_a * 0.55))
	ci.draw_rect(r.grow(1.2), Color(col.r, col.g, col.b, glow_a))
	ci.draw_rect(body, col.darkened(0.24))
	var tl := body.position
	var tr := tl + Vector2(body.size.x, 0.0)
	var br := body.end
	var bl := tl + Vector2(0.0, body.size.y)
	var center := body.get_center() + Vector2(-body.size.x * 0.08, -body.size.y * 0.1)
	ci.draw_colored_polygon(PackedVector2Array([tl, tr, center]), col.lightened(0.42))
	ci.draw_colored_polygon(PackedVector2Array([tr, br, center]), col.darkened(0.05))
	ci.draw_colored_polygon(PackedVector2Array([br, bl, center]), col.darkened(0.34))
	ci.draw_colored_polygon(PackedVector2Array([bl, tl, center]), col.lightened(0.1))
	var spec := Rect2(
		tl + Vector2(body.size.x * 0.16, body.size.y * 0.1),
		Vector2(maxf(body.size.x * 0.34, 3.0), maxf(body.size.y * 0.1, 2.0))
	)
	ci.draw_rect(spec, Color(1, 1, 1, 0.48 + pulse * 0.28))
	ci.draw_rect(
		Rect2(tl + Vector2(body.size.x * 0.22, body.size.y * 0.24), Vector2(maxf(body.size.x * 0.12, 2.0), 2.0)),
		Color(1, 1, 1, 0.22)
	)
	ci.draw_rect(body, Color(1, 1, 1, 0.28 + pulse * 0.16), false, 1.15)
	ci.draw_rect(r, Color(col.r, col.g, col.b, 0.7), false, 1.15)


static func glass_panel(ci: CanvasItem, r: Rect2, fill: Color, rim: Color) -> void:
	ci.draw_rect(Rect2(r.position + Vector2(0, 4), r.size), Color(0, 0, 0, 0.28))
	ci.draw_rect(r.grow(3.0), Color(rim.r, rim.g, rim.b, 0.14))
	ci.draw_rect(r, fill)
	ci.draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4.0, r.size.y * 0.22)), Color(1, 1, 1, 0.07))
	ci.draw_rect(r, rim, false, 1.6)
	ci.draw_rect(r.grow(-2.0), Color(rim.r, rim.g, rim.b, 0.22), false, 1.0)


static func piece_cells(
	ci: CanvasItem,
	origin: Vector2,
	step: float,
	gap: float,
	cells: Array,
	col: Color,
	pulse: float = 0.0
) -> void:
	for c in cells:
		var p: Vector2 = origin + Vector2(float(c.x), float(c.y)) * (step + gap)
		gem(ci, Rect2(p, Vector2(step, step)), col, true, pulse)


static func centered_piece(
	ci: CanvasItem,
	box: Rect2,
	key: String,
	col: Color,
	pulse: float = 0.0,
	rot: int = 0
) -> void:
	var cells: Array = PieceCatalog.cells_of(key, rot)
	var wh: Vector2i = PieceCatalog.size_of(key, rot)
	var pad := 14.0
	var usable: float = minf(box.size.x, box.size.y) - pad * 2.0
	var span: float = float(maxi(wh.x, wh.y))
	var step: float = usable / maxf(span, 1.0)
	var gap := maxf(step * 0.08, 1.5)
	step -= gap
	var pw: float = float(wh.x) * (step + gap) - gap
	var ph: float = float(wh.y) * (step + gap) - gap
	var o := box.position + (box.size - Vector2(pw, ph)) * 0.5
	piece_cells(ci, o, step, gap, cells, col, pulse)
