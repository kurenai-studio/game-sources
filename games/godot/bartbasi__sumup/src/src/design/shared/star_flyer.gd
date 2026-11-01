extends Control
## One flying star of the star moment (DESIGN_SYSTEM.md 3.6, 4.7, 6.7): the
## skin's filled star icon in one color, on an edge, with an optional soft
## glow behind both (Nova's spark). Its size is the star's box; the HUD that
## owns it moves, scales and fades it, centered on a point, and the edge and
## glow scale and fade with it. It ignores the mouse.
##
## The edge (2026-10-13 review) keeps the star visible while it crosses the
## notice pill of its own color: the star's outline grown outward by the edge
## width, filled, under the star. Built once per setup, never in _draw().

const Glow: GDScript = preload("res://src/design/shared/glow.gd")
const StarShape: GDScript = preload("res://src/design/shared/star_shape.gd")
const GRID: float = 24.0

var _icon: SkinIcon = null
var _glow_color: Color = Color.TRANSPARENT
var _glow_reach: float = 0.0
var _edge_color: Color = Color.TRANSPARENT
var _edge_width: float = 0.0
## The grown outline in px, its triangles, and the closed line for its
## antialiased rim.
var _edge_points: PackedVector2Array = PackedVector2Array()
var _edge_indices: PackedInt32Array = PackedInt32Array()
var _edge_rim: PackedVector2Array = PackedVector2Array()
var _edge_colors: PackedColorArray = PackedColorArray([Color.TRANSPARENT])


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## glow_reach: the glow's radius as a share of side; 0 for no glow.
## star: the skin icon class's STAR; edge_width: the edge in px at full size,
## 0 for none.
func setup(skin: SkinData, color: Color, side: float, glow_color: Color, glow_reach: float, star: Dictionary = {}, edge_width: float = 0.0, edge_color: Color = Color.TRANSPARENT) -> void:
	size = Vector2(side, side)
	pivot_offset = size * 0.5
	_glow_color = glow_color
	_glow_reach = glow_reach
	_edge_color = edge_color
	_edge_width = edge_width
	_edge_colors[0] = edge_color
	if _icon == null:
		_icon = UiKit.make_icon(skin)
		_icon.name = "Star"
		add_child(_icon)
		_icon.set_icon(&"star")
	_icon.set_color(color)
	_icon.position = Vector2.ZERO
	_icon.size = size
	_build_edge(star, side)
	queue_redraw()


## Centers the star on point, in its parent's space, at a scale.
func show_at(point: Vector2, at_scale: float, alpha: float) -> void:
	visible = alpha > 0.0
	position = point - size * 0.5
	scale = Vector2(at_scale, at_scale)
	modulate.a = alpha


## The edge's color and its width in px at full size (0 for none). For tests.
func edge_color() -> Color:
	return _edge_color


func edge_width() -> float:
	return _edge_width if not _edge_points.is_empty() else 0.0


## The edge's outline in px, local. For tests.
func edge_points() -> PackedVector2Array:
	return _edge_points


## The star the icon draws, as an outline in px, local, for tests.
func star_points(star: Dictionary) -> PackedVector2Array:
	return _scaled(StarShape.outline(star), size.x)


func _build_edge(star: Dictionary, side: float) -> void:
	_edge_points = PackedVector2Array()
	_edge_indices = PackedInt32Array()
	_edge_rim = PackedVector2Array()
	if star.is_empty() or _edge_width <= 0.0 or side <= 0.0:
		return
	# Grown outward by the edge width with mitered corners: an inset by a
	# negative width, in grid units.
	var unit: float = side / GRID
	var grown: PackedVector2Array = StarShape.inset(StarShape.outline(star), star["center"], -_edge_width / unit)
	_edge_points = _scaled(grown, side)
	_edge_indices = Geometry2D.triangulate_polygon(_edge_points)
	_edge_rim = _edge_points.duplicate()
	_edge_rim.append(_edge_points[0])


func _scaled(points: PackedVector2Array, side: float) -> PackedVector2Array:
	var unit: float = side / GRID
	var origin: Vector2 = (size - Vector2(side, side)) * 0.5
	var out: PackedVector2Array = PackedVector2Array()
	out.resize(points.size())
	for i: int in points.size():
		out[i] = origin + points[i] * unit
	return out


func _draw() -> void:
	if _glow_reach > 0.0 and _glow_color.a > 0.0:
		Glow.draw(self, size * 0.5, minf(size.x, size.y) * _glow_reach, _glow_color)
	# The edge sits between the glow and the star (the icon, a child, draws
	# after this).
	if not _edge_indices.is_empty():
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _edge_indices, _edge_points, _edge_colors)
		draw_polyline(_edge_rim, _edge_color, 1.0, true)
