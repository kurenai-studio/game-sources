extends Control
## Mockup drawing of the four new icons of the 2026-10-13 additions on the 24
## unit grid (DESIGN_SYSTEM.md 4.7, 5.7 and 6.7): star (with a fill share
## for the counter's progress), chevron and arrow. tools/ only: the shipped
## icons are drawn by the ui-motion-artist's SkinIcon subclasses.
##
## The star is drawn as its outline band plus a fill from the bottom that
## covers fill_share of the star's area (0 is an outline only, 1 is a solid
## star). The band is the star minus the star inset by the outline width,
## built from one quad per edge with mitered corners, so sharp points stay
## sharp (Slate) and filleted points stay round (Gumdrop, Nova).

const Spec: GDScript = preload("res://tools/additions/additions_spec.gd")
const Glow: GDScript = preload("res://src/design/shared/glow.gd")

const GRID: float = 24.0
## Points per filleted corner.
const FILLET_STEPS: int = 6

var icon_name: StringName = &"star"
var color: Color = Color.WHITE
## Share of the star's area that is filled, from the bottom up.
var fill_share: float = 0.0
## A soft glow behind the star in this color; transparent for none.
var glow_color: Color = Color.TRANSPARENT
## Glow radius as a share of the icon side.
var glow_reach: float = 0.85

var _skin: SkinData = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(skin: SkinData, p_icon: StringName, p_color: Color, side: float) -> void:
	_skin = skin
	icon_name = p_icon
	color = p_color
	custom_minimum_size = Vector2(side, side)
	size = Vector2(side, side)
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var side: float = minf(size.x, size.y)
	var unit: float = side / GRID
	var origin: Vector2 = (size - Vector2(side, side)) * 0.5
	if glow_color.a > 0.0:
		Glow.draw(self, size * 0.5, side * glow_reach, glow_color)
	match icon_name:
		&"star":
			_draw_star(origin, unit)
		&"chevron":
			_draw_chevron(origin, unit)
		&"arrow":
			_draw_arrow(origin, unit)


func _draw_star(origin: Vector2, unit: float) -> void:
	var spec: Dictionary = Spec.star(_skin)
	var outline: PackedVector2Array = star_outline(spec)
	var center: Vector2 = spec["center"]
	var px: PackedVector2Array = _to_px(outline, origin, unit)
	var center_px: Vector2 = origin + center * unit
	if fill_share >= 0.999:
		draw_colored_polygon(px, color)
		draw_polyline(_closed(px), color, 1.0, true)
		return
	if fill_share > 0.001:
		var cut: float = fill_cut(outline, fill_share)
		var keep: PackedVector2Array = PackedVector2Array([
			Vector2(-1.0, cut), Vector2(GRID + 1.0, cut), Vector2(GRID + 1.0, GRID + 1.0), Vector2(-1.0, GRID + 1.0),
		])
		for part: PackedVector2Array in Geometry2D.intersect_polygons(outline, keep):
			draw_colored_polygon(_to_px(part, origin, unit), color)
	var width: float = float(spec["outline"]) * unit
	var inner: PackedVector2Array = inset(px, center_px, width)
	var colors: PackedColorArray = PackedColorArray([color, color, color, color])
	for i: int in px.size():
		var j: int = (i + 1) % px.size()
		# A quad drawn as is: no triangulation, so tiny fillet steps are fine.
		draw_primitive(PackedVector2Array([px[i], px[j], inner[j], inner[i]]), colors, PackedVector2Array())
	draw_polyline(_closed(px), color, 1.0, true)
	draw_polyline(_closed(inner), color, 1.0, true)


func _draw_chevron(origin: Vector2, unit: float) -> void:
	match _skin.id:
		&"gumdrop":
			_stroke(PackedVector2Array([Vector2(9.5, 6.0), Vector2(15.5, 12.0), Vector2(9.5, 18.0)]), 3.5, true, origin, unit)
		&"slate":
			_stroke(PackedVector2Array([Vector2(9.0, 5.0), Vector2(16.0, 12.0), Vector2(9.0, 19.0)]), 2.0, false, origin, unit)
		_:
			_stroke(PackedVector2Array([Vector2(10.0, 6.5), Vector2(15.5, 12.0), Vector2(10.0, 17.5)]), 1.5, true, origin, unit)


func _draw_arrow(origin: Vector2, unit: float) -> void:
	match _skin.id:
		&"gumdrop":
			_stroke(PackedVector2Array([Vector2(4.0, 12.0), Vector2(15.0, 12.0)]), 3.5, true, origin, unit)
			var head: PackedVector2Array = PackedVector2Array([Vector2(21.0, 12.0), Vector2(14.5, 6.5), Vector2(14.5, 17.5)])
			var head_px: PackedVector2Array = _to_px(head, origin, unit)
			draw_colored_polygon(head_px, color)
			for p: Vector2 in head_px:
				draw_circle(p, 1.0 * unit, color, true, -1.0, true)
			draw_polyline(_closed(head_px), color, 2.0 * unit, true)
		&"slate":
			_stroke(PackedVector2Array([Vector2(3.0, 12.0), Vector2(20.0, 12.0)]), 2.0, false, origin, unit)
			_stroke(PackedVector2Array([Vector2(15.0, 7.0), Vector2(20.0, 12.0), Vector2(15.0, 17.0)]), 2.0, false, origin, unit)
		_:
			_stroke(PackedVector2Array([Vector2(5.0, 12.0), Vector2(19.5, 12.0)]), 1.5, true, origin, unit)
			_stroke(PackedVector2Array([Vector2(15.5, 8.0), Vector2(19.5, 12.0), Vector2(15.5, 16.0)]), 1.5, true, origin, unit)
			draw_circle(origin + Vector2(2.5, 12.0) * unit, 1.0 * unit, color, true, -1.0, true)


## A stroke through grid points; round caps and joins, or square caps.
func _stroke(points: PackedVector2Array, width: float, round_ends: bool, origin: Vector2, unit: float) -> void:
	var px: PackedVector2Array = _to_px(points, origin, unit)
	var w: float = width * unit
	if round_ends:
		draw_polyline(px, color, w, true)
		for p: Vector2 in px:
			draw_circle(p, w * 0.5, color, true, -1.0, true)
		return
	for i: int in px.size() - 1:
		var reach: Vector2 = (px[i + 1] - px[i]).normalized() * (w * 0.5)
		draw_line(px[i] - reach, px[i + 1] + reach, color, w, true)


## The star outline polygon in grid units: ten corners from the top point
## clockwise, each filleted by the skin's rounding.
static func star_outline(spec: Dictionary) -> PackedVector2Array:
	var center: Vector2 = spec["center"]
	var outer: float = float(spec["outer"])
	var inner: float = outer * float(spec["inner_share"])
	var corners: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var angle: float = deg_to_rad(-90.0 + 36.0 * float(i))
		var radius: float = outer if i % 2 == 0 else inner
		corners.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return fillet(corners, float(spec["round_point"]), float(spec["round_valley"]))


## Rounds every corner: even corners (the points) by point_radius, odd ones
## (the valleys) by valley_radius. 0 keeps a corner sharp.
static func fillet(corners: PackedVector2Array, point_radius: float, valley_radius: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var count: int = corners.size()
	for i: int in count:
		var radius: float = point_radius if i % 2 == 0 else valley_radius
		var here: Vector2 = corners[i]
		if radius <= 0.0:
			out.append(here)
			continue
		var to_prev: Vector2 = (corners[(i - 1 + count) % count] - here).normalized()
		var to_next: Vector2 = (corners[(i + 1) % count] - here).normalized()
		var half: float = acos(clampf(to_prev.dot(to_next), -1.0, 1.0)) * 0.5
		var reach: float = radius / tan(half)
		var a: Vector2 = here + to_prev * reach
		var b: Vector2 = here + to_next * reach
		var middle: Vector2 = here + (to_prev + to_next).normalized() * (radius / sin(half))
		var from_angle: float = (a - middle).angle()
		var sweep: float = wrapf((b - middle).angle() - from_angle, -PI, PI)
		for step: int in FILLET_STEPS + 1:
			var angle: float = from_angle + sweep * float(step) / float(FILLET_STEPS)
			out.append(middle + Vector2(cos(angle), sin(angle)) * radius)
	return out


## The polygon moved inward by width with mitered corners. Every edge's
## inner side faces center (true for a star).
static func inset(points: PackedVector2Array, center: Vector2, width: float) -> PackedVector2Array:
	var count: int = points.size()
	var normals: PackedVector2Array = PackedVector2Array()
	for i: int in count:
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % count]
		var normal: Vector2 = (b - a).orthogonal().normalized()
		if normal.dot(center - (a + b) * 0.5) < 0.0:
			normal = -normal
		normals.append(normal)
	var out: PackedVector2Array = PackedVector2Array()
	for i: int in count:
		var n1: Vector2 = normals[(i - 1 + count) % count]
		var n2: Vector2 = normals[i]
		var denominator: float = maxf(1.0 + n1.dot(n2), 0.05)
		out.append(points[i] + (n1 + n2) * (width / denominator))
	return out


## The grid y above which nothing is filled, so that the part of the star
## below it covers share of its area.
static func fill_cut(outline: PackedVector2Array, share: float) -> float:
	var total: float = polygon_area(outline)
	var top: float = 0.0
	var bottom: float = GRID
	for _i: int in 40:
		var cut: float = (top + bottom) * 0.5
		var keep: PackedVector2Array = PackedVector2Array([
			Vector2(-1.0, cut), Vector2(GRID + 1.0, cut), Vector2(GRID + 1.0, GRID + 1.0), Vector2(-1.0, GRID + 1.0),
		])
		var area: float = 0.0
		for part: PackedVector2Array in Geometry2D.intersect_polygons(outline, keep):
			area += polygon_area(part)
		if area / total > share:
			top = cut
		else:
			bottom = cut
	return (top + bottom) * 0.5


static func polygon_area(points: PackedVector2Array) -> float:
	var sum: float = 0.0
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5


func _to_px(points: PackedVector2Array, origin: Vector2, unit: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	for p: Vector2 in points:
		out.append(origin + p * unit)
	return out


func _closed(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = points.duplicate()
	out.append(points[0])
	return out
