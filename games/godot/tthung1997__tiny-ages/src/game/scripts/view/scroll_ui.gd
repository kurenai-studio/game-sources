class_name ScrollUi
extends Control
## The strip's panning controls: an arrow on each edge while there is more world that way, and
## a row of dots showing which page of the world is in view. Everything here sits inside the
## viewport and is clickable, so the arrows keep working in click-through strip mode.

signal pan_requested(direction: int)

const ARROW_TOP: float = 44.0
const ARROW_MARGIN: float = 1.0
const DOT_SIZE: float = 2.0
const DOT_GAP: float = 3.0
const DOT_Y: float = 75.0
const DOT_COLOR: Color = Color(1, 1, 1, 0.45)
const DOT_ACTIVE_COLOR: Color = Color(1, 1, 1, 0.95)
const DOT_OUTLINE: Color = Color(0.17, 0.18, 0.26, 0.7)

var _left: PanArrow = PanArrow.new(-1)
var _right: PanArrow = PanArrow.new(1)
var _pages: int = 1
var _page: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_left)
	add_child(_right)
	_left.pressed.connect(func() -> void: pan_requested.emit(-1))
	_right.pressed.connect(func() -> void: pan_requested.emit(1))


## `view_width` is the viewport's width in art pixels.
func layout(view_width: float) -> void:
	_left.position = Vector2(ARROW_MARGIN, ARROW_TOP)
	_right.position = Vector2(view_width - ARROW_MARGIN - PanArrow.SIZE.x, ARROW_TOP)
	size = Vector2(view_width, 80.0)
	queue_redraw()


func update_state(can_go_left: bool, can_go_right: bool, pages: int, page: int) -> void:
	_left.visible = can_go_left
	_right.visible = can_go_right
	if pages != _pages or page != _page:
		_pages = pages
		_page = page
		queue_redraw()


## The areas that must stay clickable in strip mode, in viewport art pixels.
func clickable_regions() -> Array[Rect2i]:
	var regions: Array[Rect2i] = []
	for arrow: PanArrow in [_left, _right]:
		regions.append(Rect2i(Vector2i(arrow.position), Vector2i(PanArrow.SIZE)))
	return regions


func _draw() -> void:
	if _pages < 2:
		return
	var total: float = float(_pages) * DOT_SIZE + float(_pages - 1) * DOT_GAP
	var left: float = floorf((size.x - total) / 2.0)
	for index: int in _pages:
		var dot := Rect2(left + float(index) * (DOT_SIZE + DOT_GAP), DOT_Y, DOT_SIZE, DOT_SIZE)
		draw_rect(dot.grow(1.0), DOT_OUTLINE)
		draw_rect(dot, DOT_ACTIVE_COLOR if index == _page else DOT_COLOR)
