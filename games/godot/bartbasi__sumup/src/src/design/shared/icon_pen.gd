extends RefCounted
## Records an icon drawn on the 24 unit design grid (DESIGN_SYSTEM.md 7.9) as
## pixel space draw commands. An icon calls begin() and its drawing code only
## when its name or size changes; its _draw() calls replay(), which walks the
## cached arrays and allocates nothing.
##
## Grid coordinates run from (0, 0) at the top left to (24, 24) at the bottom
## right. Widths and radii are in grid units too. The grid is scaled to
## min(width, height) of the area and centered in it.

const GRID: float = 24.0

## Line ends. Round also rounds the joins. Square also squares the corners, by
## drawing each segment on its own with extended ends. Butt leaves plain ends.
const CAP_BUTT: int = 0
const CAP_ROUND: int = 1
const CAP_SQUARE: int = 2

const _KIND_LINE: int = 0
const _KIND_FILL: int = 1
const _KIND_DISC: int = 2
const _KIND_RING: int = 3

## Width in px of the antialiased edge drawn round filled polygons.
const _FILL_EDGE: float = 1.0
## Turns sharper than this, in radians, get a round join disc.
const _SHARP_TURN: float = 0.35
## Arc and curve points every this many px, so curves stay smooth when big.
const _STEP_PX: float = 3.0
## Fewest points on an arc and on a curve.
const _MIN_ARC_STEPS: int = 4
const _MIN_CURVE_STEPS: int = 8

## Line end style for the next strokes.
var cap: int = CAP_ROUND

var _scale: float = 1.0
var _origin: Vector2 = Vector2.ZERO
var _turn: float = 0.0
var _pivot: Vector2 = Vector2(12.0, 12.0)

var _kinds: PackedInt32Array = PackedInt32Array()
var _shapes: Array[PackedVector2Array] = []
var _widths: PackedFloat32Array = PackedFloat32Array()
var _radii: PackedFloat32Array = PackedFloat32Array()


## Clears the recording and fits the grid into area.
func begin(area: Rect2) -> void:
	_kinds.clear()
	_shapes.clear()
	_widths.clear()
	_radii.clear()
	_scale = minf(area.size.x, area.size.y) / GRID
	_origin = area.get_center() - Vector2(GRID, GRID) * 0.5 * _scale
	_turn = 0.0
	cap = CAP_ROUND


## Number of recorded draw commands.
func part_count() -> int:
	return _kinds.size()


## Rotates the strokes that follow by degrees around pivot (grid units).
## Call with 0 to stop rotating.
func rotate_around(degrees: float, pivot: Vector2 = Vector2(12.0, 12.0)) -> void:
	_turn = deg_to_rad(degrees)
	_pivot = pivot


## One straight stroke.
func line(a: Vector2, b: Vector2, width: float) -> void:
	polyline(PackedVector2Array([a, b]), width)


## An open stroke through points.
func polyline(points: PackedVector2Array, width: float) -> void:
	if points.size() < 2:
		return
	var px: PackedVector2Array = _to_px(points)
	var w: float = width * _scale
	if cap == CAP_SQUARE:
		for i: int in px.size() - 1:
			var a: Vector2 = px[i]
			var b: Vector2 = px[i + 1]
			var reach: Vector2 = (b - a).normalized() * (w * 0.5)
			_add(_KIND_LINE, PackedVector2Array([a - reach, b + reach]), w, 0.0)
		return
	_add(_KIND_LINE, px, w, 0.0)
	if cap == CAP_ROUND:
		_round_joins(px, w, true)


## A closed stroke through points.
func outline(points: PackedVector2Array, width: float) -> void:
	if points.size() < 2:
		return
	var closed: PackedVector2Array = points.duplicate()
	closed.append(points[0])
	if cap == CAP_SQUARE:
		# Each side is drawn with extended ends, which squares the corners.
		polyline(closed, width)
		return
	# Run one point past the start so the closing corner gets a proper join.
	closed.append(points[1])
	var px: PackedVector2Array = _to_px(closed)
	var w: float = width * _scale
	_add(_KIND_LINE, px, w, 0.0)
	if cap == CAP_ROUND:
		_round_joins(px, w, false)


## A filled polygon with an antialiased edge.
func fill(points: PackedVector2Array) -> void:
	var px: PackedVector2Array = _to_px(points)
	px.append(px[0])
	_add(_KIND_FILL, px, _FILL_EDGE, 0.0)


## A filled circle.
func disc(center: Vector2, radius: float) -> void:
	_add(_KIND_DISC, PackedVector2Array([_point(center)]), 0.0, radius * _scale)


## A circle outline.
func ring(center: Vector2, radius: float, width: float) -> void:
	_add(_KIND_RING, PackedVector2Array([_point(center)]), width * _scale, radius * _scale)


## An arc stroke from from_degrees to to_degrees (0 points right, 90 down).
func arc(center: Vector2, radius: float, from_degrees: float, to_degrees: float, width: float) -> void:
	polyline(arc_points(center, radius, from_degrees, to_degrees), width)


## Points along an arc, in grid units, for building longer paths.
func arc_points(center: Vector2, radius: float, from_degrees: float, to_degrees: float) -> PackedVector2Array:
	var sweep: float = deg_to_rad(to_degrees - from_degrees)
	var steps: int = maxi(_MIN_ARC_STEPS, ceili(absf(sweep) * radius * _scale / _STEP_PX))
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in steps + 1:
		var angle: float = deg_to_rad(from_degrees) + sweep * float(i) / float(steps)
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


## Points along a cubic curve, in grid units.
func curve_points(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	var steps: int = maxi(_MIN_CURVE_STEPS, ceili(p0.distance_to(p3) * _scale / _STEP_PX))
	for i: int in steps + 1:
		points.append(p0.bezier_interpolate(p1, p2, p3, float(i) / float(steps)))
	return points


## Points round a rounded rectangle, in grid units, clockwise from the top
## left corner.
func round_rect_points(rect: Rect2, radius: float) -> PackedVector2Array:
	var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
	var points: PackedVector2Array = PackedVector2Array()
	var corners: Array[Vector2] = [
		Vector2(rect.position.x + r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.position.y + r),
		Vector2(rect.end.x - r, rect.end.y - r),
		Vector2(rect.position.x + r, rect.end.y - r),
	]
	var starts: Array[float] = [180.0, 270.0, 0.0, 90.0]
	for i: int in 4:
		points.append_array(arc_points(corners[i], r, starts[i], starts[i] + 90.0))
	return points


## Corner points of a rectangle, in grid units.
func rect_points(left: float, top: float, right: float, bottom: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(left, top), Vector2(right, top), Vector2(right, bottom), Vector2(left, bottom)])


## A filled triangle arrow head with its tip at tip, pointing along
## direction_degrees.
func head(tip: Vector2, direction_degrees: float, length: float, half_width: float) -> void:
	var forward: Vector2 = Vector2.from_angle(deg_to_rad(direction_degrees))
	var side: Vector2 = Vector2(-forward.y, forward.x)
	var base: Vector2 = tip - forward * length
	fill(PackedVector2Array([tip, base + side * half_width, base - side * half_width]))


## An open chevron arrow head with its tip at tip, pointing along
## direction_degrees.
func chevron(tip: Vector2, direction_degrees: float, length: float, half_width: float, width: float) -> void:
	var forward: Vector2 = Vector2.from_angle(deg_to_rad(direction_degrees))
	var side: Vector2 = Vector2(-forward.y, forward.x)
	var base: Vector2 = tip - forward * length
	polyline(PackedVector2Array([base + side * half_width, tip, base - side * half_width]), width)


## Draws the recording onto item in one color. Allocates nothing.
func replay(item: CanvasItem, color: Color) -> void:
	for i: int in _kinds.size():
		match _kinds[i]:
			_KIND_LINE:
				item.draw_polyline(_shapes[i], color, _widths[i], true)
			_KIND_FILL:
				item.draw_colored_polygon(_shapes[i], color)
				item.draw_polyline(_shapes[i], color, _widths[i], true)
			_KIND_DISC:
				item.draw_circle(_shapes[i][0], _radii[i], color, true, -1.0, true)
			_KIND_RING:
				item.draw_circle(_shapes[i][0], _radii[i], color, false, _widths[i], true)


## Round caps on the two ends (when with_ends) and round joins where the path
## turns sharply. Gentle turns, such as the points along an arc, need no disc.
func _round_joins(px: PackedVector2Array, w: float, with_ends: bool) -> void:
	var last: int = px.size() - 1
	if with_ends:
		_add(_KIND_DISC, PackedVector2Array([px[0]]), 0.0, w * 0.5)
		_add(_KIND_DISC, PackedVector2Array([px[last]]), 0.0, w * 0.5)
	for i: int in range(1, last):
		var turn: float = absf((px[i] - px[i - 1]).angle_to(px[i + 1] - px[i]))
		if turn > _SHARP_TURN:
			_add(_KIND_DISC, PackedVector2Array([px[i]]), 0.0, w * 0.5)


func _add(kind: int, shape: PackedVector2Array, width: float, radius: float) -> void:
	_kinds.append(kind)
	_shapes.append(shape)
	_widths.append(width)
	_radii.append(radius)


func _to_px(points: PackedVector2Array) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(points.size())
	for i: int in points.size():
		out[i] = _point(points[i])
	return out


func _point(grid_point: Vector2) -> Vector2:
	var p: Vector2 = grid_point
	if _turn != 0.0:
		p = _pivot + (p - _pivot).rotated(_turn)
	return _origin + p * _scale
