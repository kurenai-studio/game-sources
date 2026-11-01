extends Control
## One Nova ring (DESIGN_SYSTEM.md 6.7), drawn centered in its rect: a solid
## ring, a filled disc, or a dashed ring. It is its own control so Motion
## can breathe its alpha (the Suggested ring) without touching the icon.

const STYLE_SOLID: int = 0
const STYLE_FILLED: int = 1
const STYLE_DASHED: int = 2

## Points per dash arc, enough to look round at ring sizes.
const _DASH_POINTS: int = 8

var _style: int = STYLE_SOLID
var _color: Color = Color.WHITE
var _width: float = 1.0
var _dashes: int = 1
var _dash_fill: float = 1.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## dashes and dash_fill are for STYLE_DASHED: how many dashes round the ring
## and the share of each step that is drawn.
func show_ring(style: int, color: Color, width: float, dashes: int = 1, dash_fill: float = 1.0) -> void:
	_style = style
	_color = color
	_width = width
	_dashes = maxi(dashes, 1)
	_dash_fill = dash_fill
	queue_redraw()


func _draw() -> void:
	var center: Vector2 = size * 0.5
	var radius: float = minf(size.x, size.y) * 0.5
	match _style:
		STYLE_FILLED:
			draw_circle(center, radius, _color, true, -1.0, true)
		STYLE_DASHED:
			var step: float = TAU / float(_dashes)
			for i: int in _dashes:
				var start: float = step * float(i) - PI * 0.5
				draw_arc(center, radius - _width * 0.5, start, start + step * _dash_fill, _DASH_POINTS, _color, _width, true)
		_:
			draw_circle(center, radius - _width * 0.5, _color, false, _width, true)
