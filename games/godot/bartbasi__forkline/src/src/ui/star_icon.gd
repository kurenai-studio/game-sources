# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name StarIcon
extends Control
## One star. Earned is a filled honey star with an ink edge. Not earned is an
## outline only. The shapes differ, so color is never the only signal, and a
## word always sits beside it where it matters.

var earned: bool = false


func _init(side: float = 72.0, is_earned: bool = false) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(side, side)
	size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	earned = is_earned


func set_earned(value: bool) -> void:
	if value != earned:
		earned = value
		queue_redraw()


func _draw() -> void:
	var side: float = minf(size.x, size.y)
	if side <= 0.0:
		return
	var middle: Vector2 = size * 0.5 + Vector2(0.0, side * 0.03)
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var a: float = TAU * float(i) / 10.0 - PI / 2.0
		var r: float = (0.48 if i % 2 == 0 else 0.21) * side
		points.append(middle + Vector2(cos(a), sin(a)) * r)
	if earned:
		draw_colored_polygon(points, Palette.HONEY)
		var closed: PackedVector2Array = points.duplicate()
		closed.append(points[0])
		draw_polyline(closed, Palette.INK_LINE, maxf(2.0, side * 0.06), true)
	else:
		var open: PackedVector2Array = points.duplicate()
		open.append(points[0])
		draw_polyline(open, Palette.TEXT_SOFT, maxf(3.0, side * 0.07), true)
