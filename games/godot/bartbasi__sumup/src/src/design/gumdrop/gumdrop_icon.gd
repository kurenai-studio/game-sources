extends "res://src/design/shared/pen_icon.gd"
## Gumdrop icons (DESIGN_SYSTEM.md 4.7): chunky candy pictograms with
## icon_stroke round strokes on the 24 unit grid, round caps and joins,
## filled where it helps. Ink normally, ink_dark on an accent fill (active),
## disabled_ink when disabled.
##
## The star is a plump candy star: center (12, 12.9), outer radius 11, inner
## radius half of it, points rounded by 1.8 units and valleys by 1.0. The
## icon is the filled star; the HUD counter draws its 2.5 unit outline band.

const STAR: Dictionary = {
	"center": Vector2(12.0, 12.9), "outer": 11.0, "inner_share": 0.50,
	"round_point": 1.8, "round_valley": 1.0, "outline": 2.5,
}

var _stroke: float = 1.0


func _on_setup() -> void:
	_stroke = _skin.num(&"icon_stroke")


func _look_color(for_look: int) -> Color:
	match for_look:
		LOOK_ACTIVE:
			return _skin.color(&"ink_dark")
		LOOK_DISABLED:
			return _skin.color(&"disabled_ink")
	return _skin.color(&"ink")


func _record(icon_name: StringName) -> void:
	_pen.cap = IconPen.CAP_ROUND
	match icon_name:
		&"hammer":
			# A mallet tipped over to strike: a filled rounded head on a thick handle.
			_pen.rotate_around(-40.0)
			_pen.fill(_pen.round_rect_points(Rect2(5.5, 4.0, 13.0, 6.5), 2.2))
			_pen.line(Vector2(12.0, 10.0), Vector2(12.0, 20.0), _stroke)
			_pen.rotate_around(0.0)
		&"swap":
			# Two fat arrows passing each other.
			_pen.line(Vector2(4.5, 8.5), Vector2(15.5, 8.5), _stroke)
			_pen.head(Vector2(20.5, 8.5), 0.0, 5.5, 4.2)
			_pen.line(Vector2(19.5, 15.5), Vector2(8.5, 15.5), _stroke)
			_pen.head(Vector2(3.5, 15.5), 180.0, 5.5, 4.2)
		&"shuffle":
			# Two soft ropes that cross, each ending in a fat arrow.
			_pen.polyline(_pen.curve_points(Vector2(4.0, 7.5), Vector2(10.5, 7.5), Vector2(10.5, 16.5), Vector2(16.0, 16.5)), _stroke)
			_pen.head(Vector2(20.5, 16.5), 0.0, 5.0, 4.0)
			_pen.polyline(_pen.curve_points(Vector2(4.0, 16.5), Vector2(10.5, 16.5), Vector2(10.5, 7.5), Vector2(16.0, 7.5)), _stroke)
			_pen.head(Vector2(20.5, 7.5), 0.0, 5.0, 4.0)
		&"double":
			# "x2" in strokes: a cross, then a two with a round bowl.
			_pen.line(Vector2(4.0, 9.0), Vector2(10.0, 15.5), _stroke)
			_pen.line(Vector2(10.0, 9.0), Vector2(4.0, 15.5), _stroke)
			var two: PackedVector2Array = _pen.arc_points(Vector2(16.75, 10.25), 3.0, 180.0, 395.0)
			two.append(Vector2(13.5, 16.25))
			two.append(Vector2(20.25, 16.25))
			_pen.polyline(two, _stroke)
		&"undo":
			# A hook arrow turning back to the left.
			var path: PackedVector2Array = PackedVector2Array([Vector2(9.0, 8.5), Vector2(14.5, 8.5)])
			path.append_array(_pen.arc_points(Vector2(14.5, 13.0), 4.5, -90.0, 90.0))
			path.append(Vector2(8.5, 17.5))
			_pen.polyline(path, _stroke)
			_pen.head(Vector2(3.5, 8.5), 180.0, 5.5, 4.2)
		&"pause":
			# Two chunky rounded candy bars.
			_pen.fill(_pen.round_rect_points(Rect2(6.25, 5.0, 4.5, 14.0), 2.25))
			_pen.fill(_pen.round_rect_points(Rect2(13.25, 5.0, 4.5, 14.0), 2.25))
		&"settings":
			# A ring with eight round candy teeth.
			_pen.ring(Vector2(12.0, 12.0), 4.75, _stroke)
			for i: int in 8:
				var reach: Vector2 = Vector2.from_angle(deg_to_rad(22.5 + 45.0 * float(i)))
				_pen.line(Vector2(12.0, 12.0) + reach * 7.25, Vector2(12.0, 12.0) + reach * 8.5, _stroke)
		&"sound_on":
			_speaker()
			_pen.arc(Vector2(10.0, 12.0), 5.25, -42.0, 42.0, _stroke)
			_pen.arc(Vector2(10.0, 12.0), 9.25, -42.0, 42.0, _stroke)
		&"sound_off":
			_speaker()
			_pen.line(Vector2(14.5, 9.25), Vector2(20.0, 14.75), _stroke)
			_pen.line(Vector2(20.0, 9.25), Vector2(14.5, 14.75), _stroke)
		&"close":
			_pen.line(Vector2(6.5, 6.5), Vector2(17.5, 17.5), _stroke)
			_pen.line(Vector2(17.5, 6.5), Vector2(6.5, 17.5), _stroke)
		&"check":
			_pen.polyline(PackedVector2Array([Vector2(5.0, 12.5), Vector2(10.0, 17.0), Vector2(19.0, 7.5)]), _stroke)
		&"star":
			_pen.fill(StarShape.outline(STAR))
		&"chevron":
			_pen.polyline(PackedVector2Array([Vector2(9.5, 6.0), Vector2(15.5, 12.0), Vector2(9.5, 18.0)]), _stroke)
		&"arrow":
			# A round capped shaft and a filled head, its corners rounded by 1.
			_pen.line(Vector2(4.0, 12.0), Vector2(15.0, 12.0), _stroke)
			var head: PackedVector2Array = PackedVector2Array([Vector2(21.0, 12.0), Vector2(14.5, 17.5), Vector2(14.5, 6.5)])
			_pen.fill(StarShape.fillet(head, 1.0, 1.0))
		&"coffee":
			# A candy mug: a filled body, a handle arc tucked into its right
			# edge, and two steam strokes centered over it.
			_pen.fill(_mug_body())
			_pen.arc(Vector2(16.0, 15.5), 3.25, -90.0, 90.0, _stroke)
			_pen.line(Vector2(7.5, 4.0), Vector2(7.5, 6.5), _stroke)
			_pen.line(Vector2(11.5, 4.0), Vector2(11.5, 6.5), _stroke)


## The coffee mug's body: x 3 to 16, y 10 to 21.5, straight sides, top
## corners rounded by 1 unit and bottom corners by 4, clockwise from the top
## left.
func _mug_body() -> PackedVector2Array:
	var points: PackedVector2Array = PackedVector2Array()
	points.append_array(_pen.arc_points(Vector2(4.0, 11.0), 1.0, 180.0, 270.0))
	points.append_array(_pen.arc_points(Vector2(15.0, 11.0), 1.0, 270.0, 360.0))
	points.append_array(_pen.arc_points(Vector2(12.0, 17.5), 4.0, 0.0, 90.0))
	points.append_array(_pen.arc_points(Vector2(7.0, 17.5), 4.0, 90.0, 180.0))
	return points


## A filled speaker with softened corners.
func _speaker() -> void:
	var body: PackedVector2Array = PackedVector2Array([
		Vector2(3.0, 9.5), Vector2(6.25, 9.5), Vector2(10.0, 6.0),
		Vector2(10.0, 18.0), Vector2(6.25, 14.5), Vector2(3.0, 14.5),
	])
	_pen.fill(body)
	_pen.outline(body, 2.0)
