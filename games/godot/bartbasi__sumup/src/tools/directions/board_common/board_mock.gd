extends Control
## Review scene: one direction's BoardView placed as in the composed board
## screen, on a plain bg rect, showing the MockState board with the chain
## being dragged, or in Hammer targeting mode when targeting is on.
## Each direction's board_mock.tscn and board_mock_target.tscn set the
## exported values.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const BoardBase: GDScript = preload("res://tools/directions/board_common/board_base.gd")

## Folder name of the direction, for example "gumdrop".
@export var direction_id: String = ""
## Top edge of the board on the 1080 by 2400 canvas.
@export var board_top: float = 0.0
## Hammer targeting on TARGET_CELL instead of the chain.
@export var targeting: bool = false

var _tokens: DirectionTokens = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tokens = Directions.load_tokens(direction_id)
	if _tokens == null:
		return
	var board: BoardBase = make_board(self, _tokens, board_top)
	board.set_board(MockState.board_values())
	if targeting:
		board.set_targeting(true)
		board.set_target(MockState.TARGET_CELL)
	else:
		board.set_chain(MockState.chain_cells(), MockState.drag_point())
		board.set_preview(MockState.CHAIN_PREVIEW)
	queue_redraw()


## A direction's BoardView, set up, added to parent and placed as in the
## composition: board_margin from the screen sides, its preferred height, top
## edge at top.
static func make_board(parent: Node, tokens: DirectionTokens, top: float) -> BoardBase:
	var path: String = "%s/%s/board/board_view.gd" % [Directions.ROOT, tokens.id]
	var script: GDScript = load(path) as GDScript
	var board: BoardBase = script.new() as BoardBase
	parent.add_child(board)
	board.setup(tokens)
	var margin: float = tokens.num("board_margin")
	var width: float = MockState.CANVAS_SIZE.x - 2.0 * margin
	board.position = Vector2(margin, top)
	board.size = Vector2(width, board.preferred_height(width))
	return board


func _draw() -> void:
	if _tokens != null:
		draw_rect(Rect2(Vector2.ZERO, size), _tokens.color("bg"))
