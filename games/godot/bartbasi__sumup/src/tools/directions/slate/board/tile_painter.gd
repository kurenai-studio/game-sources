extends RefCounted
## Slate tile painter: flat, nearly square tiles with the number set top left.
## Slabs (2 to 64) and blocks (128 up) are both just their fill. Drawing is
## split into passes (body, number, node, brackets) so the board can put the
## chain line between the fills and the numbers.
##
## Every color, size and timing comes from the Slate tokens. Lengths the
## tokens give in px are for the real board tile and scale with the side.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const TileFx: GDScript = preload("res://tools/directions/board_common/tile_fx.gd")
const TileText: GDScript = preload("res://tools/directions/board_common/tile_text.gd")

const CORNER_DETAIL: int = 8

var tokens: DirectionTokens = null
var text: TileText = null
## Tile side in px, and px per token px (1 on the real board tile).
var side: float = 0.0
var unit: float = 1.0

var _reference_side: float = 1.0
var _special_from: int = 0
var _fill_box: StyleBoxFlat = null
var _frame_box: StyleBoxFlat = null
var _special_box: StyleBoxFlat = null
var _empty_box: StyleBoxFlat = null


## Board geometry at the composed width: x is the cell pitch, y the tile side,
## z the distance from the board rect edge to the edge of the outer cell boxes
## (negative here: there is no tray, the rect ends at the outer tile edges).
static func reference_metrics(tile_tokens: DirectionTokens) -> Vector3:
	var width: float = MockState.CANVAS_SIZE.x - 2.0 * tile_tokens.num("board_margin")
	var gap: float = tile_tokens.num("gap")
	var tile_side: float = (width - (MockState.COLUMNS - 1) * gap) / MockState.COLUMNS
	return Vector3(tile_side + gap, tile_side, -gap * 0.5)


func setup(tile_tokens: DirectionTokens) -> void:
	tokens = tile_tokens
	text = TileText.new()
	text.setup(tokens)
	_reference_side = reference_metrics(tokens).y
	_special_from = int(tokens.num("special_from"))
	_fill_box = _make_box()
	_frame_box = _make_box()
	_frame_box.draw_center = false
	_frame_box.border_color = tokens.color("chain")
	_special_box = _make_box()
	_special_box.draw_center = false
	_special_box.border_color = tokens.color("ink_dark")
	_empty_box = _make_box()
	_empty_box.draw_center = false
	_empty_box.border_color = tokens.color("rule")
	side = 0.0


## Prepares everything that depends on the tile side. Returns at once when the
## side has not changed, so callers can call it every draw.
func set_side(tile_side: float) -> void:
	if is_equal_approx(tile_side, side):
		return
	side = tile_side
	unit = side / _reference_side
	text.set_side(side)
	var radius: int = roundi(tokens.num("tile_radius") * unit)
	_fill_box.set_corner_radius_all(radius)
	_frame_box.set_corner_radius_all(radius)
	_empty_box.set_corner_radius_all(radius)
	_empty_box.set_border_width_all(maxi(1, roundi(tokens.num("rule_width") * unit)))
	_special_box.set_border_width_all(maxi(1, roundi(tokens.num("rule_width") * unit)))


## A whole tile in one go, for TileView: body, node, number, brackets.
func draw_tile(item: CanvasItem, center: Vector2, value: int, chain: float, target: bool, fx: TileFx) -> void:
	draw_body(item, center, value, chain, fx)
	if chain > 0.0:
		draw_node(item, center + fx.offset, chain)
	draw_number(item, center, value, fx, chain)
	if target:
		draw_brackets(item, center + fx.offset)


## The empty cell: a hairline frame in rule.
func draw_empty(item: CanvasItem, center: Vector2) -> void:
	_empty_box.draw(item.get_canvas_item(), _tile_rect(center))


## Fill, the special inner frame, and the chain frame when chained.
func draw_body(item: CanvasItem, center: Vector2, value: int, chain: float, fx: TileFx) -> void:
	if not _visible(fx) or TileText.index_of(value) < 0:
		return
	var local: Rect2 = _begin(item, center, fx)
	var canvas: RID = item.get_canvas_item()
	var fill: Color = tokens.color("ink") if fx.flash else tokens.fill_for(value)
	fill.a *= fx.alpha
	_fill_box.bg_color = fill
	_fill_box.draw(canvas, local)
	if value >= _special_from and not fx.flash:
		_special_box.draw(canvas, local.grow(-tokens.num("special_inset") * side))
	if chain > 0.0:
		_frame_box.set_border_width_all(maxi(1, roundi(tokens.num("chain_frame") * unit * chain)))
		_frame_box.draw(canvas, local)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)


## The number, top left, its cap top on the inset line. On a chained tile
## (chain above 0) it first gets a number_knockout outline in the tile's own
## fill, so the chain line stops cleanly short of the glyphs and the number
## keeps its exact contrast.
func draw_number(item: CanvasItem, center: Vector2, value: int, fx: TileFx, chain: float = 0.0) -> void:
	var index: int = TileText.index_of(value)
	if not _visible(fx) or index < 0:
		return
	var local: Rect2 = _begin(item, center, fx)
	var ink: Color = tokens.color("ink_dark") if fx.flash else tokens.ink_for(value)
	ink.a *= fx.alpha
	var top_left: Vector2 = local.position + Vector2.ONE * tokens.num("number_inset") * side
	if chain > 0.0:
		var knockout: Color = tokens.color("ink") if fx.flash else tokens.fill_for(value)
		knockout.a *= fx.alpha
		text.draw_top_left_outline(item, top_left, index, tokens.num("number_knockout") * unit, knockout)
	text.draw_top_left(item, top_left, index, ink)
	item.draw_set_transform_matrix(Transform2D.IDENTITY)


## The square chain node on a tile center, with its dark edge. amount grows
## it in as the tile joins.
func draw_node(item: CanvasItem, center: Vector2, amount: float = 1.0) -> void:
	var node: float = tokens.num("node_size") * unit * clampf(amount, 0.0, 1.0)
	if node <= 0.0:
		return
	var edge: float = tokens.num("line_edge") * unit
	var outer: float = node + 2.0 * edge
	item.draw_rect(Rect2(center - Vector2(outer, outer) * 0.5, Vector2(outer, outer)), tokens.color("chain_edge"))
	item.draw_rect(Rect2(center - Vector2(node, node) * 0.5, Vector2(node, node)), tokens.color("chain"))


## Four corner brackets hugging the outside of the tile corners, with no
## offset, target_bracket_width thick, so they stay inside the gap and never
## reach the neighbor tile. They hold still.
func draw_brackets(item: CanvasItem, center: Vector2) -> void:
	var rect: Rect2 = _tile_rect(center)
	var arm: float = tokens.num("target_bracket") * side
	var width: float = tokens.num("target_bracket_width") * unit
	var bracket_color: Color = tokens.color("target")
	var length: float = arm + width
	var left: float = rect.position.x - width
	var right: float = rect.end.x
	var top: float = rect.position.y - width
	var bottom: float = rect.end.y
	# Top left, top right, bottom right, bottom left: one bar along the
	# horizontal edge and one along the vertical edge, meeting at the corner.
	item.draw_rect(Rect2(left, top, length, width), bracket_color)
	item.draw_rect(Rect2(left, top, width, length), bracket_color)
	item.draw_rect(Rect2(right + width - length, top, length, width), bracket_color)
	item.draw_rect(Rect2(right, top, width, length), bracket_color)
	item.draw_rect(Rect2(right + width - length, bottom, length, width), bracket_color)
	item.draw_rect(Rect2(right, bottom + width - length, width, length), bracket_color)
	item.draw_rect(Rect2(left, bottom, length, width), bracket_color)
	item.draw_rect(Rect2(left, bottom + width - length, width, length), bracket_color)


## A tile wiped down to nothing is not drawn: a zero scale would make the
## draw transform singular.
func _visible(fx: TileFx) -> bool:
	return not fx.hidden and fx.scale.x > 0.001 and fx.scale.y > 0.001


func _tile_rect(center: Vector2) -> Rect2:
	return Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))


## Sets the draw transform for a tile with fx and returns the tile rect in
## that space.
func _begin(item: CanvasItem, center: Vector2, fx: TileFx) -> Rect2:
	var pivot: Vector2 = fx.pivot * side
	var basis: Transform2D = Transform2D(fx.rotation, fx.scale, 0.0, Vector2.ZERO)
	var origin: Vector2 = center + fx.offset + pivot - basis.basis_xform(pivot)
	item.draw_set_transform(origin, fx.rotation, fx.scale)
	return Rect2(-side * 0.5, -side * 0.5, side, side)


func _make_box() -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.anti_aliasing = true
	box.corner_detail = CORNER_DETAIL
	return box
