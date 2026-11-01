extends Control
## One Nova orb as a Control: the orb fills a square of side
## min(size.x, size.y), centered in the rect, so the side is the orb diameter.
## Its glow, corona rays and target orbit draw outside the rect, by at most
## 30 percent of the side.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const TileFx: GDScript = preload("res://tools/directions/board_common/tile_fx.gd")
const TilePainter: GDScript = preload("res://tools/directions/nova/board/tile_painter.gd")

const STATE_NORMAL: int = 0
const STATE_CHAINED: int = 1
const STATE_TARGET: int = 2

var _painter: TilePainter = null
var _fx: TileFx = TileFx.new()
var _value: int = 0
var _state: int = STATE_NORMAL


func setup(tokens: DirectionTokens) -> void:
	_painter = TilePainter.new()
	_painter.setup(tokens)
	queue_redraw()


func set_value(value: int) -> void:
	_value = value
	queue_redraw()


func set_state(state: int) -> void:
	_state = state
	queue_redraw()


## Shows the tile frozen partway through an effect. The fx comes from one of
## the frame functions in board_view.gd. Pass a fresh TileFx to clear it.
func set_fx(fx: TileFx) -> void:
	_fx = fx
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _painter == null or _value <= 0:
		return
	var side: float = minf(size.x, size.y)
	if side < 1.0:
		return
	_painter.set_side(side)
	var chain: float = 1.0 if _state == STATE_CHAINED else 0.0
	_painter.draw_tile(self, size * 0.5, _value, chain, _state == STATE_TARGET, _fx)
