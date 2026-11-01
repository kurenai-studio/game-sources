extends Control
## Looping motion demo for one direction's board. Run it in a window:
##     godot --path . res://tools/directions/<id>/board/board_demo.tscn
## The board spawns in, the mock chain builds tile by tile with the preview
## updating, it commits to CHAIN_PREVIEW, the other chain cells clear, tiles
## above fall and new tiles spawn at the top, then two seconds of Hammer
## targeting, then it starts over. Every value is scripted; no game rules.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const BoardBase: GDScript = preload("res://tools/directions/board_common/board_base.gd")
const BoardMock: GDScript = preload("res://tools/directions/board_common/board_mock.gd")

# Demo pacing only, not design tokens: the pauses between the scripted steps.
const PAUSE_AFTER_SPAWN: float = 0.5
const PAUSE_PER_CHAIN_STEP: float = 0.28
const PAUSE_BEFORE_COMMIT: float = 0.6
const PAUSE_AFTER_STEP: float = 0.25
const TARGETING_TIME: float = 2.0
const PAUSE_BEFORE_LOOP: float = 0.6
## Values the new tiles spawn with, in order, standing in for the spawn table.
const NEW_TILE_VALUES: PackedInt32Array = [2, 4, 8, 2, 4, 16, 2, 8]

## Folder name of the direction, for example "gumdrop".
@export var direction_id: String = ""
## Top edge of the board on the 1080 by 2400 canvas.
@export var board_top: float = 0.0

var _tokens: DirectionTokens = null
var _board: BoardBase = null


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tokens = Directions.load_tokens(direction_id)
	if _tokens == null:
		return
	_board = BoardMock.make_board(self, _tokens, board_top)
	queue_redraw()
	_run()


func _draw() -> void:
	if _tokens != null:
		draw_rect(Rect2(Vector2.ZERO, size), _tokens.color("bg"))


func _run() -> void:
	while is_inside_tree():
		await _cycle()


func _cycle() -> void:
	var no_chain: Array[Vector2i] = []
	var empty: Array[PackedInt32Array] = []
	_board.set_targeting(false)
	_board.set_target(BoardBase.NO_CELL)
	_board.set_chain(no_chain, Vector2.ZERO)
	_board.set_preview(0)
	_board.set_board(empty)

	# The board spawns in, top left to bottom right.
	var cells: Array[Vector2i] = []
	var values: PackedInt32Array = PackedInt32Array()
	var board_values: Array[PackedInt32Array] = MockState.board_values()
	for row: int in MockState.ROWS:
		for column: int in MockState.COLUMNS:
			cells.append(Vector2i(column, row))
			values.append(board_values[row][column])
	await _wait(_board.play_spawn(cells, values) + PAUSE_AFTER_SPAWN)

	# The chain builds tile by tile, the preview showing the running sum. The
	# mock chain's running sums are all powers of two, so no rounding rule.
	var chain: Array[Vector2i] = MockState.chain_cells()
	var built: Array[Vector2i] = []
	var total: int = 0
	for i: int in chain.size():
		built.append(chain[i])
		total += _board.value_at(chain[i])
		var drag: Vector2 = Vector2(chain[i]) + Vector2(0.5, 0.5)
		if i == chain.size() - 1:
			drag = MockState.drag_point()
		var step: float = _board.play_chain_to(built, drag)
		_board.set_preview(total if built.size() >= 2 else 0)
		await _wait(step + PAUSE_PER_CHAIN_STEP)
	await _wait(PAUSE_BEFORE_COMMIT)

	# Commit: travel and pop to the result, the other chain cells clear.
	await _wait(_board.play_merge(MockState.CHAIN_PREVIEW) + PAUSE_AFTER_STEP)

	# Tiles above the gaps fall, then new tiles spawn in the gaps at the top.
	var from_cells: Array[Vector2i] = []
	var to_cells: Array[Vector2i] = []
	var gaps: Array[Vector2i] = []
	for column: int in MockState.COLUMNS:
		var landing: int = MockState.ROWS - 1
		for row: int in range(MockState.ROWS - 1, -1, -1):
			var cell: Vector2i = Vector2i(column, row)
			if _board.value_at(cell) == 0:
				continue
			if row != landing:
				from_cells.append(cell)
				to_cells.append(Vector2i(column, landing))
			landing -= 1
		for row: int in landing + 1:
			gaps.append(Vector2i(column, row))
	if not from_cells.is_empty():
		await _wait(_board.play_fall(from_cells, to_cells) + PAUSE_AFTER_STEP * 0.5)
	gaps.sort_custom(_top_first)
	var new_values: PackedInt32Array = PackedInt32Array()
	for i: int in gaps.size():
		new_values.append(NEW_TILE_VALUES[i % NEW_TILE_VALUES.size()])
	await _wait(_board.play_spawn(gaps, new_values) + PAUSE_AFTER_STEP)

	# Hammer targeting on TARGET_CELL.
	_board.set_targeting(true)
	_board.set_target(MockState.TARGET_CELL)
	await _wait(TARGETING_TIME)
	_board.set_targeting(false)
	_board.set_target(BoardBase.NO_CELL)
	await _wait(PAUSE_BEFORE_LOOP)


func _wait(seconds: float) -> void:
	await get_tree().create_timer(maxf(seconds, 0.01)).timeout


static func _top_first(a: Vector2i, b: Vector2i) -> bool:
	return a.y < b.y or (a.y == b.y and a.x < b.x)
