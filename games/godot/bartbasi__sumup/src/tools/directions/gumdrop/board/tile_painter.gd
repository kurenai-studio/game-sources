extends RefCounted
## Gumdrop tile painter: draws squircle candy tiles with a darker lip, at one
## tile side at a time. TileView and BoardView both draw through this, so a
## tile looks the same alone and on the board.
##
## Every color, size and timing comes from the Gumdrop tokens. Lengths the
## tokens give in px are for the real board tile and scale with the side.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const TileFx: GDScript = preload("res://tools/directions/board_common/tile_fx.gd")
const TileText: GDScript = preload("res://tools/directions/board_common/tile_text.gd")
const MotionMath: GDScript = preload("res://tools/directions/board_common/motion_math.gd")

## Ramp colors the candy rim cycles through: values 2 to 256.
const RIM_RAMP_COLORS: int = 8
## Points sampled round the candy rim.
const RIM_POINTS: int = 192
## Corner smoothness of every squircle.
const CORNER_DETAIL: int = 16

var tokens: DirectionTokens = null
var text: TileText = null
## Tile side in px, and px per token px (1 on the real board tile).
var side: float = 0.0
var unit: float = 1.0

var _reference_side: float = 1.0
var _special_from: int = 0
var _press_scale: float = 1.0
var _lip_box: StyleBoxFlat = null
var _face_box: StyleBoxFlat = null
var _slot_box: StyleBoxFlat = null
var _ring_box: StyleBoxFlat = null
var _target_box: StyleBoxFlat = null
var _edge_box: StyleBoxFlat = null
var _rim_points: PackedVector2Array = PackedVector2Array()
var _rim_colors: PackedColorArray = PackedColorArray()


## Board geometry at the composed width: x is the cell pitch, y the tile side,
## z the distance from the board rect edge to the edge of the outer cell boxes
## (each cell box is the tile plus half a gap on every side).
static func reference_metrics(tile_tokens: DirectionTokens) -> Vector3:
	var width: float = MockState.CANVAS_SIZE.x - 2.0 * tile_tokens.num("board_margin")
	var pad: float = tile_tokens.num("tray_padding")
	var gap: float = tile_tokens.num("gap")
	var tile_side: float = (width - 2.0 * pad - (MockState.COLUMNS - 1) * gap) / MockState.COLUMNS
	return Vector3(tile_side + gap, tile_side, pad - gap * 0.5)


func setup(tile_tokens: DirectionTokens) -> void:
	tokens = tile_tokens
	text = TileText.new()
	text.setup(tokens)
	_reference_side = reference_metrics(tokens).y
	_special_from = int(tokens.num("special_from"))
	_press_scale = MotionMath.extra(tokens, "chain_add", "press_scale")
	_lip_box = _make_box()
	_face_box = _make_box()
	_slot_box = _make_box()
	_slot_box.bg_color = tokens.color("slot")
	_ring_box = _make_ring(tokens.color("chain"))
	_target_box = _make_ring(tokens.color("target"))
	_edge_box = _make_ring(tokens.color("target_edge"))
	side = 0.0


## Prepares everything that depends on the tile side. Returns at once when the
## side has not changed, so callers can call it every draw.
func set_side(tile_side: float) -> void:
	if is_equal_approx(tile_side, side):
		return
	side = tile_side
	unit = side / _reference_side
	text.set_side(side)
	var radius: float = tokens.num("tile_radius") * side
	_set_radius(_lip_box, radius)
	_set_radius(_face_box, radius)
	_set_radius(_slot_box, radius)
	var ring: float = tokens.num("ring_width") * unit
	_ring_box.set_border_width_all(maxi(1, roundi(ring)))
	var target_ring: float = tokens.num("target_ring_width") * unit
	_target_box.set_border_width_all(maxi(1, roundi(target_ring)))
	_edge_box.set_border_width_all(maxi(1, roundi(tokens.num("target_edge_width") * unit)))
	_build_rim(radius)


## Draws a flat empty slot centered on center.
func draw_slot(item: CanvasItem, center: Vector2) -> void:
	_slot_box.draw(item.get_canvas_item(), Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side)))


## Draws one tile centered on center.
##   chain: 0 at rest, 1 fully pressed into the chain
##   target: the targeted look (lifted, double ring)
##   wobble: extra rotation in radians for the target pulse
func draw_tile(item: CanvasItem, center: Vector2, value: int, chain: float, target: bool, fx: TileFx, wobble: float = 0.0) -> void:
	if fx.hidden:
		return
	var index: int = TileText.index_of(value)
	if index < 0:
		return
	var fill: Color = tokens.fill_for(value)
	var ink: Color = tokens.ink_for(value)
	var lip_color: Color = fill.darkened(tokens.num("lip_darken"))
	fill.a *= fx.alpha
	ink.a *= fx.alpha
	lip_color.a *= fx.alpha

	var half: float = side * 0.5
	var lip_full: float = tokens.num("lip_depth") * side
	var lip: float = lerpf(lip_full, tokens.num("lip_pressed") * side, chain)
	var press: float = lerpf(1.0, _press_scale, chain)
	var lift: float = tokens.num("target_lift") * side if target else 0.0

	# Everything below is drawn in tile space: (0, 0) is the tile center.
	var tile_scale: Vector2 = fx.scale * press
	var turn: float = fx.rotation + wobble
	var pivot: Vector2 = fx.pivot * side
	var basis: Transform2D = Transform2D(turn, tile_scale, 0.0, Vector2.ZERO)
	var origin: Vector2 = center + fx.offset + Vector2(0.0, -lift) + pivot - basis.basis_xform(pivot)
	item.draw_set_transform(origin, turn, tile_scale)

	var canvas: RID = item.get_canvas_item()
	var top: float = -half + (lip_full - lip)
	var body: Rect2 = Rect2(-half, top, side, half - top)
	var face: Rect2 = Rect2(-half, top, side, side - lip_full)
	_lip_box.bg_color = lip_color
	_lip_box.draw(canvas, body)
	_face_box.bg_color = fill
	_face_box.draw(canvas, face)

	var outside: float = 0.0
	if value >= _special_from:
		_draw_rim(item, face.get_center(), turn, tile_scale, origin, fx.alpha)
		outside = tokens.num("special_rim_width") * unit
		item.draw_set_transform(origin, turn, tile_scale)
	if chain > 0.0:
		var ring_color: Color = tokens.color("chain")
		ring_color.a = chain * fx.alpha
		_ring_box.border_color = ring_color
		var grow: float = outside + float(_ring_box.border_width_top)
		_draw_ring(_ring_box, canvas, face, grow)
	if target:
		var ring_width: float = float(_target_box.border_width_top)
		var edge_width: float = float(_edge_box.border_width_top)
		_draw_ring(_target_box, canvas, body, ring_width)
		_draw_ring(_edge_box, canvas, body, ring_width + edge_width)

	text.draw_centered(item, face.get_center(), index, ink)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)


## Draws a ring width px wide in the chain color just outside a resting
## tile centered on center, round its lip and face. Used for the preview.
func draw_outer_ring(item: CanvasItem, center: Vector2, width: float) -> void:
	var ring_width: int = maxi(1, roundi(width))
	_ring_box.set_border_width_all(ring_width)
	_ring_box.border_color = tokens.color("chain")
	var body: Rect2 = Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
	_draw_ring(_ring_box, item.get_canvas_item(), body, float(ring_width))
	_ring_box.set_border_width_all(maxi(1, roundi(tokens.num("ring_width") * unit)))


## Draws a ring around rect, grown outward by grow px, keeping the squircle.
func _draw_ring(box: StyleBoxFlat, canvas: RID, rect: Rect2, grow: float) -> void:
	var radius: int = roundi(tokens.num("tile_radius") * side + grow)
	box.set_corner_radius_all(radius)
	box.draw(canvas, rect.grow(grow))


## The candy rim, drawn round the face just outside its edge.
func _draw_rim(item: CanvasItem, face_center: Vector2, turn: float, tile_scale: Vector2, origin: Vector2, alpha: float) -> void:
	var basis: Transform2D = Transform2D(turn, tile_scale, 0.0, Vector2.ZERO)
	item.draw_set_transform(origin + basis.basis_xform(face_center), turn, tile_scale)
	var colors: PackedColorArray = _rim_colors
	if alpha < 1.0:
		colors = _rim_colors.duplicate()
		for i: int in colors.size():
			colors[i].a *= alpha
	item.draw_polyline_colors(_rim_points, colors, tokens.num("special_rim_width") * unit, true)


## Samples the candy rim path: a rounded rect round the face, offset out by
## half the rim width, with a ramp color per segment.
func _build_rim(radius: float) -> void:
	var rim: float = tokens.num("special_rim_width") * unit
	var face_size: Vector2 = Vector2(side, side - tokens.num("lip_depth") * side)
	var path_size: Vector2 = face_size + Vector2(rim, rim)
	var path_radius: float = minf(radius + rim * 0.5, minf(path_size.x, path_size.y) * 0.5)
	_rim_points = _rounded_rect_path(path_size, path_radius, RIM_POINTS)
	_rim_colors.resize(_rim_points.size())
	var per_segment: float = float(RIM_POINTS) / maxf(1.0, tokens.num("special_rim_segments"))
	for i: int in _rim_points.size():
		var segment: int = int(floorf(float(i % RIM_POINTS) / per_segment))
		_rim_colors[i] = tokens.fill_for(2 << (segment % RIM_RAMP_COLORS))


## Closed path round a rounded rect centered on (0, 0), clockwise from the
## top left, count points plus the first point again at the end.
static func _rounded_rect_path(rect_size: Vector2, radius: float, count: int) -> PackedVector2Array:
	var straight_x: float = rect_size.x - 2.0 * radius
	var straight_y: float = rect_size.y - 2.0 * radius
	var arc: float = PI * 0.5 * radius
	var perimeter: float = 2.0 * straight_x + 2.0 * straight_y + 4.0 * arc
	var half: Vector2 = rect_size * 0.5
	# Corner centers, clockwise from top right, and the angle each arc starts at.
	var corners: PackedVector2Array = PackedVector2Array([
		Vector2(half.x - radius, -half.y + radius), Vector2(half.x - radius, half.y - radius),
		Vector2(-half.x + radius, half.y - radius), Vector2(-half.x + radius, -half.y + radius),
	])
	var starts: PackedFloat32Array = PackedFloat32Array([-PI * 0.5, 0.0, PI * 0.5, PI])
	var edge_lengths: PackedFloat32Array = PackedFloat32Array([straight_x, straight_y, straight_x, straight_y])
	var edge_starts: PackedVector2Array = PackedVector2Array([
		Vector2(-half.x + radius, -half.y), Vector2(half.x, -half.y + radius),
		Vector2(half.x - radius, half.y), Vector2(-half.x, half.y - radius),
	])
	var edge_dirs: PackedVector2Array = PackedVector2Array([Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP])
	var points: PackedVector2Array = PackedVector2Array()
	points.resize(count + 1)
	for i: int in count:
		var distance: float = perimeter * float(i) / float(count)
		var side_index: int = 0
		var point: Vector2 = Vector2.ZERO
		while side_index < 4:
			if distance <= edge_lengths[side_index]:
				point = edge_starts[side_index] + edge_dirs[side_index] * distance
				break
			distance -= edge_lengths[side_index]
			if distance <= arc:
				var angle: float = starts[side_index] + distance / maxf(radius, 0.001)
				point = corners[side_index] + Vector2(cos(angle), sin(angle)) * radius
				break
			distance -= arc
			side_index += 1
		points[i] = point
	points[count] = points[0]
	return points


func _make_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.anti_aliasing = true
	box.corner_detail = CORNER_DETAIL
	return box


func _make_ring(ring_color: Color) -> StyleBoxFlat:
	var box: StyleBoxFlat = _make_box()
	box.draw_center = false
	box.border_color = ring_color
	return box


func _set_radius(box: StyleBoxFlat, radius: float) -> void:
	box.set_corner_radius_all(roundi(radius))
