extends "res://tests/base_test.gd"
## Info draws each example chain with the skin's own board view as a
## one row board (DESIGN_SYSTEM.md 7.12): setup(skin, n, 1) for n from 2 to
## 5, set_board, set_chain of every cell in drag order with no finger, no
## preview, no highlight, sized so its tiles are 112 px. Every skin must lay
## it out and show it with no error of any kind.

const CommonBoardView: GDScript = preload("res://src/skins/common/common_board_view.gd")
const EXAMPLE_TILE: float = 112.0
const NO_DRAG: Vector2 = Vector2(-1.0, -1.0)
## The example chain as exponents: 2, 2, 4, 8, 16.
const VALUES: Array[int] = [1, 1, 2, 3, 4]
const EPSILON: float = 0.01


## Every error logged while a test runs, of any kind: script errors,
## push_error and engine errors.
class AllErrors extends Logger:
	var mutex: Mutex = Mutex.new()
	var lines: PackedStringArray = PackedStringArray()

	func _log_error(function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, _error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		mutex.lock()
		lines.append("%s (at %s:%d in %s())" % [rationale if not rationale.is_empty() else code, file, line, function])
		mutex.unlock()


var _errors: AllErrors = null
var _nodes: Array[Node] = []


func before_each() -> void:
	_errors = AllErrors.new()
	OS.add_logger(_errors)


func after_each() -> void:
	OS.remove_logger(_errors)
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_one_row_boards_of_two_to_five_lay_out_with_112_px_tiles() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for count: int in range(2, 6):
			var what: String = "%s 1 x %d" % [skin_id, count]
			var board: CommonBoardView = _one_row(skin, count)
			var width: float = _width(skin, count)
			board.size = Vector2(width, board.preferred_height(width))
			assert_near(board.tile_side(), EXAMPLE_TILE, EPSILON, "%s tiles are 112 px" % what)
			var expected_height: float = EXAMPLE_TILE + 2.0 * skin.num(&"board_padding")
			if skin_id == &"nova":
				# One pitch: the orb is orb_scale of it.
				expected_height = EXAMPLE_TILE / skin.num(&"orb_scale")
			assert_near(board.size.y, expected_height, EPSILON, "%s height" % what)
			var bounds: Rect2 = Rect2(Vector2.ZERO, board.size).grow(EPSILON)
			var last_right: float = -INF
			for x: int in count:
				var rect: Rect2 = board.cell_rect(Vector2i(x, 0))
				assert_true(bounds.encloses(rect), "%s cell %d %s inside %s" % [what, x, rect, bounds])
				assert_near(rect.get_center().y, board.size.y * 0.5, EPSILON, "%s cell %d sits on the middle line" % [what, x])
				assert_true(rect.position.x > last_right, "%s cell %d is right of the one before" % [what, x])
				last_right = rect.end.x
			_assert_no_errors(what)


func test_one_row_boards_show_every_cell_chained_with_the_line_through_them() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for count: int in range(2, 6):
			var what: String = "%s 1 x %d" % [skin_id, count]
			var board: CommonBoardView = _one_row(skin, count)
			var width: float = _width(skin, count)
			board.size = Vector2(width, board.preferred_height(width))
			_show_example(board, count)
			for x: int in count:
				assert_eq(board.value_at(Vector2i(x, 0)), VALUES[x], "%s cell %d value" % [what, x])
				var fade: RefCounted = board.get("_chain_fade")
				assert_near(float((fade.get("value") as PackedFloat32Array)[x]), 1.0, EPSILON, "%s cell %d is fully chained" % [what, x])
			assert_false(bool(board.call("_show_preview")), "%s shows no preview" % what)
			assert_false(board.has_running_effects(), "%s is at rest" % what)
			# No finger, so the line runs center to center and stops at the last tile.
			var points: int = int(board.call("_build_line_points"))
			assert_eq(points, count, "%s line points" % what)
			var line: PackedVector2Array = board.get("_line_points")
			for x: int in mini(points, count):
				assert_true(line[x].is_equal_approx(board.cell_center(Vector2i(x, 0))), "%s line point %d on cell %d's center" % [what, x, x])
			_assert_no_errors(what)


## The Info rows set the board and the chain before the row has its
## size, as a container lays it out later.
func test_one_row_boards_take_the_board_and_chain_before_their_size() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for count: int in range(2, 6):
			var what: String = "%s 1 x %d, sized last" % [skin_id, count]
			var board: CommonBoardView = _one_row(skin, count)
			_show_example(board, count)
			var width: float = _width(skin, count)
			board.size = Vector2(width, board.preferred_height(width))
			board.advance_effects(1.0)
			assert_near(board.tile_side(), EXAMPLE_TILE, EPSILON, "%s tiles are 112 px" % what)
			assert_eq(int(board.call("_build_line_points")), count, "%s line points" % what)
			_assert_no_errors(what)


func _one_row(skin: SkinData, count: int) -> CommonBoardView:
	var board: CommonBoardView = SkinCatalog.make_board_view(skin) as CommonBoardView
	_nodes.append(board)
	board.effects_paused = true
	board.setup(skin, count, 1)
	return board


## DESIGN_SYSTEM.md 7.12: n x 112 + (n - 1) x board_gap + 2 x board_padding,
## Nova n x 112 / orb_scale.
func _width(skin: SkinData, count: int) -> float:
	if skin.id == &"nova":
		return float(count) * EXAMPLE_TILE / skin.num(&"orb_scale")
	return float(count) * EXAMPLE_TILE + float(count - 1) * skin.num(&"board_gap") + 2.0 * skin.num(&"board_padding")


func _show_example(board: CommonBoardView, count: int) -> void:
	var cells: PackedInt64Array = PackedInt64Array()
	var chain: Array[Vector2i] = []
	for x: int in count:
		cells.append(VALUES[x])
		chain.append(Vector2i(x, 0))
	board.set_board(cells)
	board.set_chain(chain, NO_DRAG)
	board.advance_effects(1.0)


func _assert_no_errors(what: String) -> void:
	_errors.mutex.lock()
	var lines: PackedStringArray = _errors.lines
	_errors.lines = PackedStringArray()
	_errors.mutex.unlock()
	for line: String in lines:
		fail("%s logged an error: %s" % [what, line])
