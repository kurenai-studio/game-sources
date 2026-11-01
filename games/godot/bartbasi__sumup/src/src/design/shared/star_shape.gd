extends RefCounted
## The star of the 2026-10-13 additions (DESIGN_SYSTEM.md 4.7, 5.7, 6.7) on
## the 24 unit icon grid: five points, one up, each skin with its own center,
## radii and rounding. Each skin's icon class holds its star as a STAR
## dictionary:
##   center: Vector2, outer: outer radius, inner_share: inner radius as a
##   share of the outer, round_point and round_valley: corner radii at the
##   points and in the valleys (0 keeps a corner sharp), outline: the width
##   of the counter star's outline band.
## Everything here is in grid units and built once per star; drawing code
## scales the results and never calls this from _draw().

## Points per rounded corner.
const FILLET_STEPS: int = 6
## Bisection steps when finding the fill line, enough for well under a
## thousandth of the star's area.
const _CUT_STEPS: int = 40
## Grid units past the grid's edge for the clipping box.
const _BEYOND: float = 1.0


## The star outline: ten corners from the top point clockwise, each rounded
## by the skin's radii.
static func outline(star: Dictionary) -> PackedVector2Array:
	var center: Vector2 = star["center"]
	var outer: float = float(star["outer"])
	var inner: float = outer * float(star["inner_share"])
	var corners: PackedVector2Array = PackedVector2Array()
	for i: int in 10:
		var angle: float = deg_to_rad(-90.0 + 36.0 * float(i))
		var radius: float = outer if i % 2 == 0 else inner
		corners.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return fillet(corners, float(star["round_point"]), float(star["round_valley"]))


## Rounds every corner of a closed polygon inside its sides: even corners by
## even_radius, odd ones by odd_radius. 0 keeps a corner sharp.
static func fillet(corners: PackedVector2Array, even_radius: float, odd_radius: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	var count: int = corners.size()
	for i: int in count:
		var radius: float = even_radius if i % 2 == 0 else odd_radius
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


## The polygon moved inward by width with mitered corners: the inner edge of
## the counter star's outline band. Every side's inner side faces center,
## which holds for a star.
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
		# Clamped so a very sharp point cannot throw its miter far away.
		var denominator: float = maxf(1.0 + n1.dot(n2), 0.05)
		out.append(points[i] + (n1 + n2) * (width / denominator))
	return out


## The parts of the star below the line that leaves share of its area
## filled, from the bottom up (the counter's progress fill). Empty for 0, the
## whole star for 1.
static func fill_parts(star_outline: PackedVector2Array, share: float) -> Array[PackedVector2Array]:
	var parts: Array[PackedVector2Array] = []
	if share <= 0.0:
		return parts
	if share >= 1.0:
		parts.append(star_outline)
		return parts
	parts.assign(Geometry2D.intersect_polygons(star_outline, _below(fill_cut(star_outline, share))))
	return parts


## The grid y of the fill line for share of the star's area.
static func fill_cut(star_outline: PackedVector2Array, share: float) -> float:
	var total: float = area(star_outline)
	var top: float = 0.0
	var bottom: float = 24.0
	for _i: int in _CUT_STEPS:
		var cut: float = (top + bottom) * 0.5
		var below: float = 0.0
		for part: PackedVector2Array in Geometry2D.intersect_polygons(star_outline, _below(cut)):
			below += area(part)
		if below / total > share:
			top = cut
		else:
			bottom = cut
	return (top + bottom) * 0.5


## The area of a simple polygon.
static func area(points: PackedVector2Array) -> float:
	var sum: float = 0.0
	for i: int in points.size():
		var a: Vector2 = points[i]
		var b: Vector2 = points[(i + 1) % points.size()]
		sum += a.x * b.y - b.x * a.y
	return absf(sum) * 0.5


## The lowest and highest grid y of the outline.
static func y_range(points: PackedVector2Array) -> Vector2:
	var low: float = INF
	var high: float = -INF
	for p: Vector2 in points:
		low = minf(low, p.y)
		high = maxf(high, p.y)
	return Vector2(low, high)


## A box covering the grid below y.
static func _below(y: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(-_BEYOND, y), Vector2(24.0 + _BEYOND, y),
		Vector2(24.0 + _BEYOND, 24.0 + _BEYOND), Vector2(-_BEYOND, 24.0 + _BEYOND),
	])
