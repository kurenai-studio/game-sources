extends "res://src/skins/common/tile_painter.gd"
## Slate tile painter (DESIGN_SYSTEM.md 5.7): flat tiles with nearly square
## corners and the number top left. A resting tile is drawn in two parts so
## the board can lay the chain line between them: the body (fill and frames)
## under the line, the marks (nodes, label plate, number) over it. That gives
## the order fills, frames, line, nodes, label plates, numbers.
##
## Marks on blocks: paper vanishes on the light blocks, so on a block the
## chained frame, the joinable frame and the hollow node draw in ink_dark
## instead. Slab or block goes by the tile's color (its ramp position), not
## its tier, so a big tile above 128K with a slab color keeps the slab marks.

const CORNER_DETAIL: int = 8
## First ramp position drawn as a light block rather than a dark slab
## (DESIGN_SYSTEM.md 5.2: positions 0 to 5 are slabs, 6 to 16 blocks).
const BLOCK_FROM_POSITION: int = 6

var _fill_box: StyleBoxFlat = null
## Swap's selected frame, at the tile edge.
var _frame_box: StyleBoxFlat = null
## The chained and joinable frames, frame_inset inside the tile edge.
var _inset_frame_box: StyleBoxFlat = null
var _special_box: StyleBoxFlat = null
var _empty_box: StyleBoxFlat = null

var _radius_share: float = 0.0
var _number_inset: float = 0.0
var _number_plate: float = 0.0
var _line_edge: float = 0.0
var _node_size: float = 0.0
var _node_stroke: float = 0.0
var _selected_frame: float = 0.0
var _bracket: float = 0.0
var _special_inset: float = 0.0
var _frame_inset: float = 0.0
var _hairline: float = 0.0
var _chain_ring: float = 0.0
var _joinable_ring: float = 0.0
var _target_ring: float = 0.0
var _chain_color: Color = Color.MAGENTA
var _joinable_color: Color = Color.MAGENTA
var _target_color: Color = Color.MAGENTA
var _edge_color: Color = Color.MAGENTA
var _dark: Color = Color.MAGENTA
var _paper: Color = Color.MAGENTA


func _setup() -> void:
	_fill_box = make_box(CORNER_DETAIL)
	_frame_box = make_ring(CORNER_DETAIL)
	_inset_frame_box = make_ring(CORNER_DETAIL)
	_special_box = make_ring(CORNER_DETAIL)
	_empty_box = make_ring(CORNER_DETAIL)
	_radius_share = skin.num(&"tile_radius")
	_number_inset = skin.num(&"number_inset")
	_number_plate = skin.num(&"number_plate")
	_line_edge = skin.num(&"line_edge")
	_node_size = skin.num(&"node_size")
	_node_stroke = skin.num(&"joinable_node_stroke")
	_selected_frame = skin.num(&"selected_frame")
	_bracket = skin.num(&"target_bracket")
	_special_inset = skin.num(&"special_inset")
	_frame_inset = skin.num(&"frame_inset")
	_hairline = skin.num(&"hairline")
	_chain_ring = skin.num(&"chain_ring")
	_joinable_ring = skin.num(&"joinable_ring")
	_target_ring = skin.num(&"target_ring")
	_chain_color = skin.color(&"chain")
	_joinable_color = skin.color(&"joinable")
	_target_color = skin.color(&"target")
	_edge_color = skin.color(&"chain_edge")
	_dark = skin.color(&"ink_dark")
	_paper = skin.color(&"ink")
	_empty_box.border_color = skin.color(&"line")


func _on_side() -> void:
	var radius: int = roundi(_radius_share * side)
	_fill_box.set_corner_radius_all(radius)
	_frame_box.set_corner_radius_all(radius)
	_inset_frame_box.set_corner_radius_all(maxi(0, radius - roundi(_frame_inset * side)))
	_empty_box.set_corner_radius_all(radius)
	var hairline: int = maxi(1, roundi(_hairline * unit))
	_empty_box.set_border_width_all(hairline)
	_special_box.set_border_width_all(hairline)
	_special_box.set_corner_radius_all(maxi(0, radius - roundi(_special_inset * side)))


## Width of the chain line and of its dark edge each side, in px.
func line_widths() -> Vector2:
	return Vector2(skin.num(&"chain_width"), _line_edge) * unit


## An empty cell: a hairline frame in line.
func draw_empty(canvas: RID, rect: Rect2) -> void:
	_empty_box.draw(canvas, rect)


## Fill, the special inner frame in the tile's number color, and the chained
## or joinable frame, in tile space placed by base. flash shows the paper of
## the merge flash.
func draw_body(canvas: RID, base: Transform2D, exponent: int, flash: bool, chain: float, join: float) -> void:
	var index: int = style_of(exponent)
	if index < 0:
		return
	begin(canvas, base)
	var rect: Rect2 = _tile_rect()
	_fill_box.bg_color = _paper if flash else fills[index]
	_fill_box.draw(canvas, rect)
	if is_special(exponent) and not flash:
		_special_box.border_color = inks[index]
		_special_box.draw(canvas, rect.grow(-_special_inset * side))
	# The chained and joinable frames sit frame_inset inside the edge, so a
	# band of tile fill keeps an ink_dark frame visible on a light block.
	var block: bool = positions[index] >= BLOCK_FROM_POSITION
	var framed: Rect2 = rect.grow(-_frame_inset * side)
	if chain > 0.0:
		_frame(_inset_frame_box, canvas, framed, _chain_ring * unit, faded(_dark if block else _chain_color, chain))
	if join > 0.0:
		_frame(_inset_frame_box, canvas, framed, _joinable_ring * unit, faded(_dark if block else _joinable_color, join))
	end(canvas)


## The marks over the line: the square nodes on the center (the filled chain
## node growing in with chain, the hollow joinable node fading in with join,
## both with a line_edge outline in chain_edge like the line), then the label
## plate on a chained tile and the number. The plate is the tile's own fill
## over the whole label box grown by number_plate px, so the line never shows
## between the glyphs. The number's cap top sits number_inset of the side
## from the top and left edges.
func draw_marks(canvas: RID, base: Transform2D, exponent: int, flash: bool, chain: float, join: float) -> void:
	var index: int = style_of(exponent)
	if index < 0:
		return
	begin(canvas, base)
	var edge: float = _line_edge * unit
	if chain > 0.0:
		var node: float = _node_size * unit * clampf(chain, 0.0, 1.0)
		var outer: float = node + 2.0 * edge
		RenderingServer.canvas_item_add_rect(canvas, Rect2(Vector2(outer, outer) * -0.5, Vector2(outer, outer)), _edge_color)
		RenderingServer.canvas_item_add_rect(canvas, Rect2(Vector2(node, node) * -0.5, Vector2(node, node)), _chain_color)
	if join > 0.0:
		var node: float = _node_size * unit
		var stroke: float = _node_stroke * unit
		var square: Rect2 = Rect2(Vector2(node, node) * -0.5, Vector2(node, node))
		var mark: Color = _dark if positions[index] >= BLOCK_FROM_POSITION else _joinable_color
		_outline(canvas, square, stroke + 2.0 * edge, faded(_edge_color, join))
		_outline(canvas, square, stroke, faded(mark, join))
	if not label_shown:
		end(canvas)
		return
	var top_left: Vector2 = _tile_rect().position + Vector2.ONE * _number_inset * side
	if chain > 0.0:
		var plate: Rect2 = labels.box_top_left(top_left, exponent).grow(_number_plate * unit)
		RenderingServer.canvas_item_add_rect(canvas, plate, _paper if flash else fills[index])
	labels.draw_top_left(canvas, top_left, exponent, _dark if flash else inks[index])
	end(canvas)


## A whole tile in one go, for moving tiles, ghosts and the tile view.
func draw_whole(canvas: RID, base: Transform2D, exponent: int, flash: bool, chain: float, join: float) -> void:
	draw_body(canvas, base, exponent, flash, chain, join)
	draw_marks(canvas, base, exponent, flash, chain, join)


func draw_single(canvas: RID, center: Vector2, exponent: int) -> void:
	draw_whole(canvas, at(center), exponent, false, 0.0, 0.0)


## Four corner brackets in target, target_ring thick, arms target_bracket of
## the side, hugging the outside of the tile edge with no offset.
func draw_brackets(canvas: RID, rect: Rect2, alpha: float) -> void:
	var arm: float = _bracket * side
	var width: float = _target_ring * unit
	var color: Color = faded(_target_color, alpha)
	var length: float = arm + width
	var left: float = rect.position.x - width
	var right: float = rect.end.x
	var top: float = rect.position.y - width
	var bottom: float = rect.end.y
	RenderingServer.canvas_item_add_rect(canvas, Rect2(left, top, length, width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(left, top, width, length), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(right + width - length, top, length, width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(right, top, width, length), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(right + width - length, bottom, length, width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(right, bottom + width - length, width, length), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(left, bottom, length, width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(left, bottom + width - length, width, length), color)


## Swap's selected tile: a selected_frame frame in target at the edge, next
## to its brackets.
func draw_selected_frame(canvas: RID, rect: Rect2, alpha: float) -> void:
	_frame(_frame_box, canvas, rect, _selected_frame * unit, faded(_target_color, alpha))


func _frame(box: StyleBoxFlat, canvas: RID, rect: Rect2, width: float, frame_color: Color) -> void:
	box.set_border_width_all(maxi(1, roundi(width)))
	box.border_color = frame_color
	box.draw(canvas, rect)


## A square outline width px wide, centered on rect's edges.
static func _outline(canvas: RID, rect: Rect2, width: float, color: Color) -> void:
	var half: float = width * 0.5
	var full: float = rect.size.x + width
	RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x - half, rect.position.y - half, full, width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x - half, rect.end.y - half, full, width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.position.x - half, rect.position.y + half, width, rect.size.y - width), color)
	RenderingServer.canvas_item_add_rect(canvas, Rect2(rect.end.x - half, rect.position.y + half, width, rect.size.y - width), color)


func _tile_rect() -> Rect2:
	return Rect2(-side * 0.5, -side * 0.5, side, side)
