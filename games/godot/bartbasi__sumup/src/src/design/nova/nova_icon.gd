extends "res://src/design/shared/pen_icon.gd"
## Nova icons (DESIGN_SYSTEM.md 6.7): thin and precise line pictograms,
## icon_stroke on the 24 unit grid fitted to icon_fit of the icon box, round
## caps, and a small spark dot (icon_spark) where it suits.
## Ink normally. Active: ink_dark (it sits on the accent ring) with a soft
## accent glow at icon_glow_alpha behind it. Disabled: disabled_ink at
## disabled_icon_alpha.
##
## The star is slender: center (12, 12.9), outer radius 11, inner radius 0.40
## of it, points rounded 0.5 units and valleys 0.3. The icon is the filled
## star, and unlike the others it is not fitted to icon_fit: it fills its box
## like a glyph. The HUD counter draws its icon_stroke wide outline band.

const Glow: GDScript = preload("res://src/design/shared/glow.gd")

const STAR: Dictionary = {
	"center": Vector2(12.0, 12.9), "outer": 11.0, "inner_share": 0.40,
	"round_point": 0.5, "round_valley": 0.3, "outline": 1.5,
}

var _stroke: float = 1.0
var _spark: float = 1.0
var _fit: float = 1.0
var _glow_color: Color = Color.TRANSPARENT


func _on_setup() -> void:
	_fit = _skin.num(&"icon_fit")
	# Strokes widen with the fit, so they stay icon_stroke units of the full box.
	_stroke = _skin.num(&"icon_stroke") / _fit
	_spark = _skin.num(&"icon_spark")
	_glow_color = Color(_skin.color(&"accent"), _skin.num(&"icon_glow_alpha"))


func _look_color(for_look: int) -> Color:
	match for_look:
		LOOK_ACTIVE:
			return _skin.color(&"ink_dark")
		LOOK_DISABLED:
			return _skin.color(&"disabled_ink")
	return _skin.color(&"ink")


func _look_alpha(for_look: int) -> float:
	if for_look == LOOK_DISABLED:
		return _skin.num(&"disabled_icon_alpha")
	return 1.0


func _grid_area() -> Rect2:
	if _icon == &"star":
		return Rect2(Vector2.ZERO, size)
	return Rect2(size * (1.0 - _fit) * 0.5, size * _fit)


func _draw_under() -> void:
	if _look == LOOK_ACTIVE:
		Glow.draw(self, size * 0.5, minf(size.x, size.y) * 0.5, _glow_color)


func _record(icon_name: StringName) -> void:
	_pen.cap = IconPen.CAP_ROUND
	var w: float = _stroke
	match icon_name:
		&"hammer":
			_pen.rotate_around(-40.0)
			_pen.outline(_pen.round_rect_points(Rect2(6.5, 5.0, 11.0, 4.5), 1.2), w)
			_pen.line(Vector2(12.0, 9.5), Vector2(12.0, 19.5), w)
			_pen.rotate_around(0.0)
			_pen.disc(Vector2(5.0, 17.0), _spark)
		&"swap":
			# Two thin arrows passing each other, each trailing a spark.
			_pen.line(Vector2(7.0, 8.5), Vector2(19.0, 8.5), w)
			_pen.chevron(Vector2(19.5, 8.5), 0.0, 2.5, 2.5, w)
			_pen.disc(Vector2(4.25, 8.5), _spark)
			_pen.line(Vector2(17.0, 15.5), Vector2(5.0, 15.5), w)
			_pen.chevron(Vector2(4.5, 15.5), 180.0, 2.5, 2.5, w)
			_pen.disc(Vector2(19.75, 15.5), _spark)
		&"shuffle":
			_pen.polyline(_pen.curve_points(Vector2(4.5, 8.0), Vector2(10.5, 8.0), Vector2(11.5, 16.0), Vector2(18.5, 16.0)), w)
			_pen.chevron(Vector2(19.5, 16.0), 0.0, 2.5, 2.5, w)
			_pen.polyline(_pen.curve_points(Vector2(4.5, 16.0), Vector2(10.5, 16.0), Vector2(11.5, 8.0), Vector2(18.5, 8.0)), w)
			_pen.chevron(Vector2(19.5, 8.0), 0.0, 2.5, 2.5, w)
		&"double":
			# "x2" in strokes, with a spark.
			_pen.line(Vector2(5.0, 9.0), Vector2(10.0, 15.0), w)
			_pen.line(Vector2(10.0, 9.0), Vector2(5.0, 15.0), w)
			var two: PackedVector2Array = _pen.arc_points(Vector2(16.25, 10.75), 2.5, 190.0, 395.0)
			two.append(Vector2(13.5, 15.25))
			two.append(Vector2(19.25, 15.25))
			_pen.polyline(two, w)
			_pen.disc(Vector2(19.5, 5.5), _spark)
		&"undo":
			# A counterclockwise orbit ending in an arrow pointing down.
			_pen.arc(Vector2(12.5, 12.0), 6.5, 45.0, -180.0, w)
			_pen.chevron(Vector2(6.0, 12.75), 90.0, 2.5, 2.5, w)
		&"pause":
			# Two thin upright bars.
			_pen.line(Vector2(9.5, 6.5), Vector2(9.5, 17.5), w)
			_pen.line(Vector2(14.5, 6.5), Vector2(14.5, 17.5), w)
		&"settings":
			_pen.outline(_gear_points(), w)
			_pen.ring(Vector2(12.0, 12.0), 2.75, w)
		&"sound_on":
			_speaker(w)
			_pen.arc(Vector2(11.0, 12.0), 4.0, -45.0, 45.0, w)
			_pen.arc(Vector2(11.0, 12.0), 7.0, -45.0, 45.0, w)
		&"sound_off":
			_speaker(w)
			_pen.line(Vector2(15.0, 9.75), Vector2(19.5, 14.25), w)
			_pen.line(Vector2(19.5, 9.75), Vector2(15.0, 14.25), w)
		&"close":
			_pen.line(Vector2(7.0, 7.0), Vector2(17.0, 17.0), w)
			_pen.line(Vector2(17.0, 7.0), Vector2(7.0, 17.0), w)
		&"check":
			_pen.polyline(PackedVector2Array([Vector2(5.5, 12.5), Vector2(10.0, 17.0), Vector2(18.5, 7.5)]), w)
		&"star":
			_pen.fill(StarShape.outline(STAR))
		&"chevron":
			_pen.polyline(PackedVector2Array([Vector2(10.0, 6.5), Vector2(15.5, 12.0), Vector2(10.0, 17.5)]), w)
		&"arrow":
			# A thin arrow with a spark at its tail, like a trail of light.
			_pen.line(Vector2(5.0, 12.0), Vector2(19.5, 12.0), w)
			_pen.chevron(Vector2(19.5, 12.0), 0.0, 4.0, 4.0, w)
			_pen.disc(Vector2(2.5, 12.0), _spark)
		&"coffee":
			# An open cup with light rising from it: a U body, a handle arc,
			# one steam stroke and a spark.
			var cup: PackedVector2Array = PackedVector2Array([Vector2(5.5, 10.0)])
			cup.append_array(_pen.arc_points(Vector2(10.5, 15.5), 5.0, 180.0, 0.0))
			cup.append(Vector2(15.5, 10.0))
			_pen.polyline(cup, w)
			_pen.arc(Vector2(15.5, 13.5), 2.75, -90.0, 90.0, w)
			_pen.line(Vector2(9.0, 7.5), Vector2(9.0, 4.5), w)
			_pen.disc(Vector2(12.5, 5.0), _spark)


## A point on the circle of radius round the grid center.
func _on_circle(radius: float, degrees: float) -> Vector2:
	return Vector2(12.0, 12.0) + Vector2.from_angle(deg_to_rad(degrees)) * radius


## Outline of an eight tooth gear round the grid center.
func _gear_points() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	for i: int in 8:
		var middle: float = 45.0 * float(i)
		points.append(_on_circle(6.25, middle - 15.0))
		points.append(_on_circle(8.5, middle - 9.0))
		points.append(_on_circle(8.5, middle + 9.0))
		points.append(_on_circle(6.25, middle + 15.0))
	return points


func _speaker(w: float) -> void:
	_pen.outline(PackedVector2Array([
		Vector2(4.0, 9.75), Vector2(7.25, 9.75), Vector2(11.0, 6.5),
		Vector2(11.0, 17.5), Vector2(7.25, 14.25), Vector2(4.0, 14.25),
	]), w)
