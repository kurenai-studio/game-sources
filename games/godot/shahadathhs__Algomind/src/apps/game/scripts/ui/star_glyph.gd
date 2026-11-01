class_name StarGlyph
extends RefCounted
## A five-pointed star drawn from shapes, for the stars on level tiles and the star icon. A star
## earned is solid and one not earned is an outline, so the count reads without color.


## One star of outer radius `radius` centered on `c`; solid or an outline.
static func draw(
	canvas: CanvasItem, c: Vector2, radius: float, color: Color, solid: bool = true
) -> void:
	var points := PackedVector2Array()
	for i in 10:
		var angle := -PI / 2.0 + float(i) * PI / 5.0
		var r := radius if i % 2 == 0 else radius * 0.42
		points.append(c + Vector2(cos(angle), sin(angle)) * r)
	if solid:
		canvas.draw_colored_polygon(points, color)
	else:
		points.append(points[0])
		canvas.draw_polyline(points, color, maxf(1.5, radius * 0.2))


## `total` stars in a row centered on `c`; the first `earned` are solid.
static func row(
	canvas: CanvasItem, c: Vector2, earned: int, total: int, radius: float, color: Color
) -> void:
	var step := radius * 2.3
	var x := c.x - step * (total - 1) / 2.0
	for i in total:
		draw(canvas, Vector2(x + i * step, c.y), radius, color, i < earned)
