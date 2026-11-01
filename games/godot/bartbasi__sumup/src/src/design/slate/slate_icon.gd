extends "res://src/design/shared/pen_icon.gd"
## Slate icons (DESIGN_SYSTEM.md 5.7): signage pictograms of straight
## segments and true circles, square caps, icon_stroke strokes on the 24 unit
## grid, no fills. Settings is three sliders; pause is two upright bars.
## Ink normally, ink_dark on the paper fill (active), disabled_ink disabled.
##
## The star is sharp: center (12, 12.9), outer radius 11, inner radius 0.42
## of it, no rounding. The icon is the filled star, a data mark that may fill
## like the chain nodes; the HUD counter draws its 2 unit mitered outline.

const STAR: Dictionary = {
	"center": Vector2(12.0, 12.9), "outer": 11.0, "inner_share": 0.42,
	"round_point": 0.0, "round_valley": 0.0, "outline": 2.0,
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
	_pen.cap = IconPen.CAP_SQUARE
	match icon_name:
		&"hammer":
			# Tipped over to strike, like a pictogram on a sign.
			_pen.rotate_around(-45.0)
			_pen.outline(_pen.rect_points(6.0, 4.0, 18.0, 9.0), _stroke)
			_pen.line(Vector2(12.0, 9.0), Vector2(12.0, 20.5), _stroke)
			_pen.rotate_around(0.0)
		&"swap":
			_pen.line(Vector2(4.0, 8.0), Vector2(19.0, 8.0), _stroke)
			_pen.chevron(Vector2(20.0, 8.0), 0.0, 4.0, 4.0, _stroke)
			_pen.line(Vector2(20.0, 16.0), Vector2(5.0, 16.0), _stroke)
			_pen.chevron(Vector2(4.0, 16.0), 180.0, 4.0, 4.0, _stroke)
		&"shuffle":
			_pen.polyline(PackedVector2Array([Vector2(3.0, 7.0), Vector2(8.0, 7.0), Vector2(15.0, 17.0), Vector2(20.0, 17.0)]), _stroke)
			_pen.chevron(Vector2(21.0, 17.0), 0.0, 3.5, 3.5, _stroke)
			_pen.polyline(PackedVector2Array([Vector2(3.0, 17.0), Vector2(8.0, 17.0), Vector2(15.0, 7.0), Vector2(20.0, 7.0)]), _stroke)
			_pen.chevron(Vector2(21.0, 7.0), 0.0, 3.5, 3.5, _stroke)
		&"double":
			# "x2" in strokes: a cross and a two built from straight segments.
			_pen.line(Vector2(4.0, 8.0), Vector2(10.0, 16.0), _stroke)
			_pen.line(Vector2(10.0, 8.0), Vector2(4.0, 16.0), _stroke)
			_pen.polyline(PackedVector2Array([
				Vector2(13.5, 8.0), Vector2(20.0, 8.0), Vector2(20.0, 12.0),
				Vector2(13.5, 12.0), Vector2(13.5, 16.0), Vector2(20.0, 16.0),
			]), _stroke)
		&"undo":
			_pen.polyline(PackedVector2Array([Vector2(5.0, 8.0), Vector2(19.0, 8.0), Vector2(19.0, 17.0), Vector2(10.0, 17.0)]), _stroke)
			_pen.chevron(Vector2(4.0, 8.0), 180.0, 4.0, 4.0, _stroke)
		&"pause":
			# Two upright bars.
			_pen.line(Vector2(9.0, 5.0), Vector2(9.0, 19.0), _stroke)
			_pen.line(Vector2(15.0, 5.0), Vector2(15.0, 19.0), _stroke)
		&"settings":
			# Three sliders, each with a square knob.
			_slider(5.0, 7.5)
			_slider(12.0, 16.5)
			_slider(19.0, 10.5)
		&"sound_on":
			_speaker()
			_pen.line(Vector2(15.5, 10.0), Vector2(15.5, 14.0), _stroke)
			_pen.line(Vector2(19.5, 7.5), Vector2(19.5, 16.5), _stroke)
		&"sound_off":
			_speaker()
			_pen.line(Vector2(15.5, 9.5), Vector2(20.5, 14.5), _stroke)
			_pen.line(Vector2(20.5, 9.5), Vector2(15.5, 14.5), _stroke)
		&"close":
			_pen.line(Vector2(6.0, 6.0), Vector2(18.0, 18.0), _stroke)
			_pen.line(Vector2(18.0, 6.0), Vector2(6.0, 18.0), _stroke)
		&"check":
			_pen.polyline(PackedVector2Array([Vector2(4.5, 12.5), Vector2(9.5, 17.5), Vector2(19.5, 7.5)]), _stroke)
		&"star":
			_pen.fill(StarShape.outline(STAR))
		&"chevron":
			_pen.polyline(PackedVector2Array([Vector2(9.0, 5.0), Vector2(16.0, 12.0), Vector2(9.0, 19.0)]), _stroke)
		&"arrow":
			_pen.line(Vector2(3.0, 12.0), Vector2(20.0, 12.0), _stroke)
			_pen.polyline(PackedVector2Array([Vector2(15.0, 7.0), Vector2(20.0, 12.0), Vector2(15.0, 17.0)]), _stroke)
		&"coffee":
			# A straight sided cup: rim, body, handle and two steam strokes.
			_pen.line(Vector2(2.0, 10.0), Vector2(17.0, 10.0), _stroke)
			_pen.polyline(PackedVector2Array([Vector2(4.0, 10.0), Vector2(4.0, 21.0), Vector2(15.0, 21.0), Vector2(15.0, 10.0)]), _stroke)
			_pen.polyline(PackedVector2Array([Vector2(15.0, 12.5), Vector2(20.0, 12.5), Vector2(20.0, 17.5), Vector2(15.0, 17.5)]), _stroke)
			_pen.line(Vector2(7.5, 3.5), Vector2(7.5, 7.0), _stroke)
			_pen.line(Vector2(11.5, 3.5), Vector2(11.5, 7.0), _stroke)


## One slider track at row y with a square knob centered at knob_x.
func _slider(y: float, knob_x: float) -> void:
	var half: float = 2.25
	_pen.line(Vector2(3.0, y), Vector2(knob_x - half, y), _stroke)
	_pen.outline(_pen.rect_points(knob_x - half, y - half, knob_x + half, y + half), _stroke)
	_pen.line(Vector2(knob_x + half, y), Vector2(21.0, y), _stroke)


## A speaker outline. Its sharp corners use plain joins: square ends would
## poke out past the acute corners.
func _speaker() -> void:
	_pen.cap = IconPen.CAP_BUTT
	_pen.outline(PackedVector2Array([
		Vector2(3.5, 9.5), Vector2(7.0, 9.5), Vector2(12.0, 5.5),
		Vector2(12.0, 18.5), Vector2(7.0, 14.5), Vector2(3.5, 14.5),
	]), _stroke)
	_pen.cap = IconPen.CAP_SQUARE
