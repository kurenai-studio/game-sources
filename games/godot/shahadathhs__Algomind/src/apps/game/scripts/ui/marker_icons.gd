class_name MarkerIcons
extends RefCounted
## Icons for the counter and the breadcrumbs: "inc" (+1), "counter" (three rising bars: a number
## that grows), "mark" (a dot with an arrow behind it: a breadcrumb that points back), and the
## breadcrumb sensors "fresh_ahead", "fresh_left", "fresh_right" (an arrow that ends at an empty
## square: a cell with no breadcrumb) and "back_ahead", "back_left", "back_right" (a dot with an
## arrow leaving it: the way the breadcrumb points). UiKit.icon calls this for the kinds it, IfIcons
## and ProcIcons do not draw.

const SIDES := {
	"ahead": Vector2(0, -1),
	"left": Vector2(-1, 0),
	"right": Vector2(1, 0),
}


## Draws the icon `kind` in a square of side `s` centered on `c`. False for an unknown kind.
static func draw(canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color) -> bool:
	var w := maxf(2.0, s * 0.12)
	match kind:
		"inc":
			var box := Rect2(c.x - s * 0.5, c.y - s * 0.5, s, s)
			UiKit.text(canvas, "+1", box, int(s * 0.95), color, 0)
		"counter":
			for i in 3:
				var height := s * (0.3 + 0.25 * float(i))
				var left := c.x - s * 0.42 + float(i) * s * 0.3
				canvas.draw_rect(Rect2(left, c.y + s * 0.4 - height, s * 0.22, height), color)
		"mark":
			canvas.draw_circle(c + Vector2(0, -s * 0.2), s * 0.17, color)
			canvas.draw_line(c + Vector2(0, -s * 0.05), c + Vector2(0, s * 0.18), color, w)
			_head(canvas, c + Vector2(0, s * 0.44), Vector2(0, 1), s, color)
		_:
			return _sensor(canvas, kind, c, s, color, w)
	return true


static func _sensor(
	canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color, w: float
) -> bool:
	var parts := kind.split("_")
	if parts.size() != 2 or not SIDES.has(parts[1]):
		return false
	var direction: Vector2 = SIDES[parts[1]]
	if parts[0] == "fresh":
		canvas.draw_line(c - direction * s * 0.44, c - direction * s * 0.02, color, w)
		_head(canvas, c + direction * s * 0.08, direction, s * 0.8, color)
		var square := Rect2(c + direction * s * 0.32 - Vector2(s, s) * 0.16, Vector2(s, s) * 0.32)
		canvas.draw_rect(square, color, false, maxf(2.0, s * 0.1))
	elif parts[0] == "back":
		canvas.draw_circle(c - direction * s * 0.32, s * 0.14, color)
		canvas.draw_line(c - direction * s * 0.32, c + direction * s * 0.1, color, w)
		_head(canvas, c + direction * s * 0.46, direction, s, color)
	else:
		return false
	return true


## A filled triangle whose tip is at `tip` and which points along `direction`.
static func _head(
	canvas: CanvasItem, tip: Vector2, direction: Vector2, s: float, color: Color
) -> void:
	var base := tip - direction * s * 0.34
	var side := Vector2(-direction.y, direction.x) * s * 0.18
	canvas.draw_colored_polygon(PackedVector2Array([tip, base + side, base - side]), color)
