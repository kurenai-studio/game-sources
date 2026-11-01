# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name InkPen
extends RefCounted
## The drawing helper behind Silhouettes, MapArt, Wordmark and IconArt.
## Internal to src/theme/: other areas call those classes, not this one.
##
## Shapes are given in local units and placed by a transform set with begin(),
## so a drawing never touches the canvas item's own draw transform. Every
## shape gets one INK_LINE outline. With `flat` set (alpha above 0) every
## shape and outline uses that one color and details, glows and shadows are
## left out: that is the silhouette. With no canvas the pen records shapes
## instead of drawing them, which the tests use.

## One recorded shape: points in canvas coordinates. width 0 means a filled
## polygon; above 0, a line of that width.
class Shape:
	var points: PackedVector2Array
	var width: float
	var closed: bool
	var color: Color

var canvas: CanvasItem
var flat: Color = Color(0.0, 0.0, 0.0, 0.0)
## Outline width in canvas pixels.
var line_px: float = 3.0
var shapes: Array[Shape] = []

var _base: Transform2D = Transform2D.IDENTITY
var _xf: Transform2D = Transform2D.IDENTITY
var _scale: float = 1.0


func _init(target: CanvasItem = null, flat_color: Color = Color(0.0, 0.0, 0.0, 0.0)) -> void:
	canvas = target
	flat = flat_color


func is_flat() -> bool:
	return flat.a > 0.0


## Places local units: `origin` in canvas pixels, `scale` pixels per unit.
func begin(origin: Vector2, scale: float, flip: bool = false) -> void:
	_scale = scale
	_base = Transform2D(0.0, Vector2(-scale if flip else scale, scale), 0.0, origin)
	_xf = _base


## Rotates the following shapes by `angle` around a local pivot, until unrotate().
func rotate_about(pivot: Vector2, angle: float) -> void:
	_xf = _base * Transform2D(0.0, pivot) * Transform2D(angle, Vector2.ZERO) * Transform2D(0.0, -pivot)


func unrotate() -> void:
	_xf = _base


## Local units to canvas pixels.
func px(units: float) -> float:
	return units * _scale


func to_canvas(p: Vector2) -> Vector2:
	return _xf * p


# Colors.

func fill_color(c: Color) -> Color:
	return Color(flat, c.a) if is_flat() else c


func ink() -> Color:
	return flat if is_flat() else Palette.INK_LINE


# Shapes that stay in the silhouette.

func poly(pts: PackedVector2Array, fill: Color, outline: bool = true) -> void:
	var out: PackedVector2Array = _xf * pts
	_fill(out, fill_color(fill))
	if outline:
		var closed: PackedVector2Array = out.duplicate()
		closed.append(out[0])
		_line(closed, ink(), line_px, true)


func circle(c: Vector2, r: float, fill: Color, outline: bool = true) -> void:
	poly(ellipse_pts(c, r, r, _segments(r)), fill, outline)


func ellipse(c: Vector2, rx: float, ry: float, fill: Color, outline: bool = true) -> void:
	poly(ellipse_pts(c, rx, ry, _segments(maxf(rx, ry))), fill, outline)


func box(x0: float, y0: float, x1: float, y1: float, fill: Color, outline: bool = true) -> void:
	poly(PackedVector2Array([Vector2(x0, y0), Vector2(x1, y0), Vector2(x1, y1), Vector2(x0, y1)]), fill, outline)


## A thick line of `width` units with an ink casing.
func stroke(a: Vector2, b: Vector2, width: float, col: Color, cased: bool = true) -> void:
	path(PackedVector2Array([a, b]), width, col, cased)


## A thick polyline of `width` units with an ink casing.
func path(pts: PackedVector2Array, width: float, col: Color, cased: bool = true) -> void:
	var out: PackedVector2Array = _xf * pts
	if cased:
		_line(out, ink(), px(width) + line_px * 2.0, false)
	_line(out, fill_color(col), px(width), false)


# Details: left out of the silhouette.

func detail(a: Vector2, b: Vector2, width: float, col: Color) -> void:
	if not is_flat():
		_line(_xf * PackedVector2Array([a, b]), col, px(width), false)


func detail_path(pts: PackedVector2Array, width: float, col: Color) -> void:
	if not is_flat():
		_line(_xf * pts, col, px(width), false)


func detail_poly(pts: PackedVector2Array, col: Color) -> void:
	if not is_flat():
		_fill(_xf * pts, col)


func detail_circle(c: Vector2, r: float, col: Color) -> void:
	if not is_flat():
		_fill(_xf * ellipse_pts(c, r, r, _segments(r)), col)


## A soft round light: stacked faint discs.
func glow(c: Vector2, r: float, col: Color, strength: float = 1.0) -> void:
	if is_flat():
		return
	for i: int in 6:
		var k: float = 1.0 - float(i) / 6.0
		_fill(_xf * ellipse_pts(c, r * k, r * k, 20), Color(col, 0.07 * strength))


## The soft shadow under a tower or creature, `rx` units wide each side.
func shadow(c: Vector2, rx: float) -> void:
	detail_poly(ellipse_pts(c, rx, rx * 0.24, 20), Palette.SHADOW)


# Composite pieces shared by several drawings.

func window(x0: float, y0: float, x1: float, y1: float, bright: float = 1.0) -> void:
	glow(Vector2((x0 + x1) * 0.5, (y0 + y1) * 0.5), (x1 - x0) * 1.5, Palette.GLOW, bright * 0.8)
	box(x0, y0, x1, y1, Palette.LANTERN)
	detail(Vector2((x0 + x1) * 0.5, y0 + 1.5), Vector2((x0 + x1) * 0.5, y1 - 1.5), 1.6, Palette.TIMBER)
	detail(Vector2(x0 + 1.5, (y0 + y1) * 0.5), Vector2(x1 - 1.5, (y0 + y1) * 0.5), 1.6, Palette.TIMBER)


## A hanging lantern centered on `c`, `r` units across.
func lantern(c: Vector2, r: float, bright: float = 1.0) -> void:
	glow(c, r * 4.0, Palette.GLOW, bright)
	poly(PackedVector2Array([c + Vector2(-r * 0.9, -r * 1.1), c + Vector2(r * 0.9, -r * 1.1), c + Vector2(0.0, -r * 1.9)]), Palette.TIMBER)
	box(c.x - r * 0.75, c.y - r * 1.1, c.x + r * 0.75, c.y + r * 1.0, Palette.LANTERN)
	detail_circle(c, r * 0.45, Palette.LANTERN_CORE)


## An arched door: bottom center at `foot`.
func door(foot: Vector2, half: float, height: float, col: Color) -> void:
	var pts: PackedVector2Array = arc_pts(foot + Vector2(0.0, -height + half), half, half, PI, TAU, 8)
	pts.append(foot + Vector2(half, 0.0))
	pts.append(foot + Vector2(-half, 0.0))
	poly(pts, col)


## An eye with a glow, looking right.
func eye(c: Vector2, r: float) -> void:
	glow(c, r * 2.6, Palette.EYE, 0.7)
	ellipse(c, r, r * 1.2, Palette.EYE)
	detail_circle(c + Vector2(r * 0.35, r * 0.1), r * 0.5, Palette.INK_LINE)


## A four point star, filled, no outline.
func star(c: Vector2, r: float, col: Color) -> void:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in 8:
		var a: float = TAU * float(i) / 8.0 - PI / 2.0
		var rr: float = r if i % 2 == 0 else r * 0.38
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	_fill(_xf * pts, fill_color(col))


# Point helpers.

static func ellipse_pts(c: Vector2, rx: float, ry: float, n: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in n:
		var a: float = TAU * float(i) / float(n)
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


## Points along an elliptical arc from angle `from` to `to`, both included.
static func arc_pts(c: Vector2, rx: float, ry: float, from: float, to: float, n: int) -> PackedVector2Array:
	var pts: PackedVector2Array = PackedVector2Array()
	for i: int in n + 1:
		var a: float = lerpf(from, to, float(i) / float(n))
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return pts


# Output.

func _segments(r: float) -> int:
	return clampi(int(px(r) * 0.6), 12, 40)


func _fill(pts: PackedVector2Array, col: Color) -> void:
	if pts.size() < 3:
		return
	if canvas == null:
		_record(pts, 0.0, true, col)
		return
	canvas.draw_colored_polygon(pts, col)


func _line(pts: PackedVector2Array, col: Color, width: float, closed: bool) -> void:
	if pts.size() < 2:
		return
	if canvas == null:
		_record(pts, width, closed, col)
		return
	canvas.draw_polyline(pts, col, maxf(width, 1.0), true)


func _record(pts: PackedVector2Array, width: float, closed: bool, col: Color) -> void:
	var s: Shape = Shape.new()
	s.points = pts
	s.width = width
	s.closed = closed
	s.color = col
	shapes.append(s)
