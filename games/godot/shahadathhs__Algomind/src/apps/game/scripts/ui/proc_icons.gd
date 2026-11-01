class_name ProcIcons
extends RefCounted
## Icons for the procedure tiles: "proc" (a bracket around two stacked bars: a named group of
## commands) and "call" (an arrow that ends at a bar: go and run it). UiKit.icon calls this for
## the kinds neither it nor IfIcons draws.


## Draws the icon `kind` in a square of side `s` centered on `c`. False for an unknown kind.
static func draw(canvas: CanvasItem, kind: String, c: Vector2, s: float, color: Color) -> bool:
	var w := maxf(2.0, s * 0.12)
	match kind:
		"proc":
			var left := c.x - s * 0.4
			var top := c.y - s * 0.4
			var bottom := c.y + s * 0.4
			canvas.draw_line(Vector2(left + s * 0.14, top), Vector2(left, top), color, w)
			canvas.draw_line(Vector2(left, top), Vector2(left, bottom), color, w)
			canvas.draw_line(Vector2(left, bottom), Vector2(left + s * 0.14, bottom), color, w)
			canvas.draw_line(
				Vector2(c.x - s * 0.12, c.y - s * 0.16),
				Vector2(c.x + s * 0.4, c.y - s * 0.16),
				color,
				w
			)
			canvas.draw_line(
				Vector2(c.x - s * 0.12, c.y + s * 0.16),
				Vector2(c.x + s * 0.4, c.y + s * 0.16),
				color,
				w
			)
		"call":
			canvas.draw_line(Vector2(c.x - s * 0.42, c.y), Vector2(c.x + s * 0.12, c.y), color, w)
			var tip := Vector2(c.x + s * 0.12, c.y)
			canvas.draw_colored_polygon(
				PackedVector2Array(
					[
						tip + Vector2(s * 0.22, 0),
						tip + Vector2(0, -s * 0.2),
						tip + Vector2(0, s * 0.2)
					]
				),
				color
			)
			canvas.draw_line(
				Vector2(c.x + s * 0.42, c.y - s * 0.34),
				Vector2(c.x + s * 0.42, c.y + s * 0.34),
				color,
				w
			)
		_:
			return false
	return true
