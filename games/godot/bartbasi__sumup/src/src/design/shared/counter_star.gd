extends Control
## The HUD star counter's star (DESIGN_SYSTEM.md 4.7, 5.7, 6.7): the star's
## outline band, filled from the bottom by the progress to the next free
## booster: nothing, a third or two thirds of its area, or full while a star
## turns into a free booster (and Slate's paper flash). Nova adds a soft glow
## behind it while it holds any fill.
##
## The shapes are worked out once per star in grid units and scaled once per
## size; _draw() only replays them. It ignores the mouse.

const StarShape: GDScript = preload("res://src/design/shared/star_shape.gd")
const Glow: GDScript = preload("res://src/design/shared/glow.gd")
const GRID: float = 24.0
## Fill steps: thirds of the star's area.
const STEPS: int = 3

## Grid shapes per star, worked out once: key "outline", "inner", and
## "fills" (one Array[PackedVector2Array] per step 0 to 3).
static var _grids: Dictionary = {}

var _star: Dictionary = {}
var _color: Color = Color.WHITE
var _steps: int = 0
var _fill_alpha: float = 1.0
var _glow_color: Color = Color.TRANSPARENT
var _glow_reach: float = 0.0
var _glow_scale: float = 1.0
var _built_size: Vector2 = Vector2(-1.0, -1.0)
# Pixel shapes for the current size.
var _band_points: PackedVector2Array = PackedVector2Array()
var _band_indices: PackedInt32Array = PackedInt32Array()
var _outer_edge: PackedVector2Array = PackedVector2Array()
var _inner_edge: PackedVector2Array = PackedVector2Array()
var _fill_points: Array[PackedVector2Array] = []
var _fill_indices: Array[PackedInt32Array] = []
var _fill_of_step: PackedInt32Array = PackedInt32Array()
var _band_colors: PackedColorArray = PackedColorArray([Color.WHITE])
var _fill_colors: PackedColorArray = PackedColorArray([Color.WHITE])


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## star: the skin icon class's STAR. side: the star_icon box.
func setup(star: Dictionary, color: Color, side: float) -> void:
	_star = star
	_color = color
	size = Vector2(side, side)
	pivot_offset = size * 0.5
	_update_colors()
	_build()
	queue_redraw()


## Thirds filled, 0 to 3, the fill's alpha (the fill fading to empty after a
## conversion), and the color of band and fill.
func show_progress(steps: int, fill_alpha: float, color: Color) -> void:
	var clamped: int = clampi(steps, 0, STEPS)
	if clamped == _steps and is_equal_approx(fill_alpha, _fill_alpha) and color == _color:
		return
	_steps = clamped
	_fill_alpha = fill_alpha
	_color = color
	_update_colors()
	queue_redraw()


## A glow in color behind the star while it holds any fill, reaching reach
## of the star's side (Nova). Transparent for none.
func set_glow(color: Color, reach: float) -> void:
	_glow_color = color
	_glow_reach = reach
	queue_redraw()


## The glow's size multiplier, for a bloom.
func set_glow_scale(multiplier: float) -> void:
	if is_equal_approx(multiplier, _glow_scale):
		return
	_glow_scale = multiplier
	queue_redraw()


## Thirds filled now.
func steps() -> int:
	return _steps


## The fill's alpha now.
func fill_alpha() -> float:
	return _fill_alpha


## The color now.
func color() -> Color:
	return _color


## Whether the glow draws now.
func glows() -> bool:
	return _glow_color.a > 0.0 and _steps > 0 and _fill_alpha > 0.0


func _update_colors() -> void:
	_band_colors[0] = _color
	_fill_colors[0] = Color(_color, _color.a * _fill_alpha)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		pivot_offset = size * 0.5
		_build()
		queue_redraw()


func _draw() -> void:
	if _star.is_empty():
		return
	if size != _built_size:
		_build()
	var item: RID = get_canvas_item()
	if glows():
		var side: float = minf(size.x, size.y)
		Glow.draw(self, size * 0.5, side * _glow_reach * _glow_scale, Color(_glow_color, _glow_color.a * _fill_alpha))
	if _steps > 0 and _fill_alpha > 0.0:
		var from: int = _fill_of_step[_steps]
		var to: int = _fill_of_step[_steps + 1]
		for i: int in range(from, to):
			RenderingServer.canvas_item_add_triangle_array(item, _fill_indices[i], _fill_points[i], _fill_colors)
	RenderingServer.canvas_item_add_triangle_array(item, _band_indices, _band_points, _band_colors)
	draw_polyline(_outer_edge, _color, 1.0, true)
	draw_polyline(_inner_edge, _color, 1.0, true)


func _build() -> void:
	_built_size = size
	if _star.is_empty():
		return
	var grid: Dictionary = _grid(_star)
	var side: float = minf(size.x, size.y)
	var unit: float = side / GRID
	var origin: Vector2 = (size - Vector2(side, side)) * 0.5
	var outer: PackedVector2Array = _scaled(grid["outline"], origin, unit)
	var inner: PackedVector2Array = _scaled(grid["inner"], origin, unit)
	# The band: one quad per side between the outer edge and the inner edge,
	# as two triangles, in one triangle array.
	var count: int = outer.size()
	_band_points = outer.duplicate()
	_band_points.append_array(inner)
	_band_indices = PackedInt32Array()
	for i: int in count:
		var j: int = (i + 1) % count
		_band_indices.append_array(PackedInt32Array([i, j, count + j, i, count + j, count + i]))
	_outer_edge = outer.duplicate()
	_outer_edge.append(outer[0])
	_inner_edge = inner.duplicate()
	_inner_edge.append(inner[0])
	# Fills: every part of every step, triangulated once.
	_fill_points.clear()
	_fill_indices.clear()
	_fill_of_step = PackedInt32Array([0])
	var fills: Array = grid["fills"]
	for step: int in STEPS + 1:
		var parts: Array[PackedVector2Array] = fills[step]
		for part: PackedVector2Array in parts:
			var indices: PackedInt32Array = Geometry2D.triangulate_polygon(part)
			if indices.is_empty():
				continue
			_fill_points.append(_scaled(part, origin, unit))
			_fill_indices.append(indices)
		_fill_of_step.append(_fill_points.size())


static func _grid(star: Dictionary) -> Dictionary:
	var key: String = var_to_str(star)
	if _grids.has(key):
		return _grids[key]
	var star_outline: PackedVector2Array = StarShape.outline(star)
	var fills: Array = []
	for step: int in STEPS + 1:
		fills.append(StarShape.fill_parts(star_outline, float(step) / float(STEPS)))
	var made: Dictionary = {
		"outline": star_outline,
		"inner": StarShape.inset(star_outline, star["center"], float(star["outline"])),
		"fills": fills,
	}
	_grids[key] = made
	return made


static func _scaled(points: PackedVector2Array, origin: Vector2, unit: float) -> PackedVector2Array:
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(points.size())
	for i: int in points.size():
		out[i] = origin + points[i] * unit
	return out
