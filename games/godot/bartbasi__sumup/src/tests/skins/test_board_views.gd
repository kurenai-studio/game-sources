extends "res://tests/base_test.gd"
## The production board and tile views of every skin behave as
## docs/ARCHITECTURE.md section 6 and docs/DESIGN_SYSTEM.md sections 2 to 6
## say: the factories, the geometry, every setter at its edges, and every
## effect's length from the skin's motion tokens.
##
## Drawing itself is proven by the review captures in scenes/skins/, which
## the capture tool fails on any error.
##
## Every tile is given by its exponent k (the tile is 2^k, ARCHITECTURE.md
## 17): 1 is the tile 2, 10 is 1024.

const CommonBoardView: GDScript = preload("res://src/skins/common/common_board_view.gd")
const MotionMath: GDScript = preload("res://src/skins/common/motion_math.gd")
const GUMDROP_PAINTER: GDScript = preload("res://src/skins/gumdrop/gumdrop_tile_painter.gd")
const SLATE_PAINTER: GDScript = preload("res://src/skins/slate/slate_tile_painter.gd")
const NOVA_PAINTER: GDScript = preload("res://src/skins/nova/nova_tile_painter.gd")
const BOARD_VIEWS: Dictionary = {
	&"gumdrop": preload("res://src/skins/gumdrop/gumdrop_board_view.gd"),
	&"slate": preload("res://src/skins/slate/slate_board_view.gd"),
	&"nova": preload("res://src/skins/nova/nova_board_view.gd"),
}
const TILE_VIEWS: Dictionary = {
	&"gumdrop": preload("res://src/skins/gumdrop/gumdrop_tile_view.gd"),
	&"slate": preload("res://src/skins/slate/slate_tile_view.gd"),
	&"nova": preload("res://src/skins/nova/nova_tile_view.gd"),
}
const COLUMNS: int = 5
const ROWS: int = 8
const NO_CELL: Vector2i = Vector2i(-1, -1)
const NO_DRAG: Vector2 = Vector2(-1.0, -1.0)
## The highest exponent whose label keeps to 4 characters with no lowercase
## letter (512Q), and the highest a tile can hold (GameConfig.max_exponent).
const HIGHEST_SHORT_POWER: int = 59
const HIGHEST_POWER: int = 65535
const EPSILON: float = 0.001
## Whether the skin's merge_pop is a decorative tail that does not count in
## the merge's length (DESIGN_SYSTEM.md 6.6: Nova's bloom never blocks input).
const POP_IS_TAIL: Dictionary = {&"gumdrop": false, &"slate": false, &"nova": true}

var _nodes: Array[Node] = []


func after_each() -> void:
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


# Factories.

func test_make_board_view_returns_each_skins_view() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var view: SkinBoardView = SkinCatalog.make_board_view(SkinCatalog.get_skin(skin_id))
		_nodes.append(view)
		assert_true(view != null, "%s board view" % skin_id)
		assert_true(view is SkinBoardView, "%s board view is a SkinBoardView" % skin_id)
		assert_eq(view.get_script(), BOARD_VIEWS[skin_id], "%s board view script" % skin_id)


func test_make_tile_view_returns_each_skins_view_set_up() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var view: SkinTileView = SkinCatalog.make_tile_view(SkinCatalog.get_skin(skin_id))
		_nodes.append(view)
		assert_true(view != null, "%s tile view" % skin_id)
		assert_true(view is SkinTileView, "%s tile view is a SkinTileView" % skin_id)
		assert_eq(view.get_script(), TILE_VIEWS[skin_id], "%s tile view script" % skin_id)


func test_an_unknown_skin_id_gets_the_default_views() -> void:
	var other: SkinData = SkinCatalog.get_skin(SkinCatalog.DEFAULT_ID).duplicate() as SkinData
	other.id = &"no_such_skin"
	var board: SkinBoardView = SkinCatalog.make_board_view(other)
	var tile: SkinTileView = SkinCatalog.make_tile_view(other)
	_nodes.append(board)
	_nodes.append(tile)
	assert_eq(board.get_script(), BOARD_VIEWS[SkinCatalog.DEFAULT_ID], "default board view")
	assert_eq(tile.get_script(), TILE_VIEWS[SkinCatalog.DEFAULT_ID], "default tile view")


func test_views_never_take_input() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var tile: SkinTileView = _tile(skin_id)
		assert_eq(board.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s board view ignores the mouse" % skin_id)
		assert_eq(tile.mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s tile view ignores the mouse" % skin_id)
		for child: Node in board.get_children():
			assert_eq((child as Control).mouse_filter, Control.MOUSE_FILTER_IGNORE, "%s board layers ignore the mouse" % skin_id)


# Board contents.

func test_setup_and_set_board_with_mixed_values_raise_no_errors() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _mixed_cells(HIGHEST_SHORT_POWER)
		board.set_board(cells)
		for index: int in cells.size():
			assert_eq(board.value_at(_cell(index)), cells[index], "%s cell %d" % [skin_id, index])
		board.set_board(_mixed_cells(HIGHEST_POWER))
		assert_eq(board.value_at(Vector2i(4, 7)), _mixed_cells(HIGHEST_POWER)[39], "%s up to 2^65535" % skin_id)
		assert_eq(board.value_at(Vector2i(0, 0)), HIGHEST_POWER, "%s the top tile" % skin_id)
		assert_false(board.has_running_effects(), "%s a set board is at rest" % skin_id)


func test_set_board_keeps_its_own_copy() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _filled(3)
		board.set_board(cells)
		cells[0] = 10
		assert_eq(board.value_at(Vector2i(0, 0)), 3, "%s the board is not changed through the caller's array" % skin_id)
		var spawned: Array[Vector2i] = [Vector2i(1, 0)]
		board.play_spawn(spawned, PackedInt64Array([2]))
		assert_eq(cells[1], 3, "%s an effect does not change the caller's array" % skin_id)


func test_set_board_ends_every_effect_at_once() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(3))
		var cleared: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1)]
		board.play_clear(cleared)
		var from: Array[Vector2i] = [Vector2i(2, 0)]
		var to: Array[Vector2i] = [Vector2i(2, 3)]
		board.play_fall(from, to)
		assert_true(board.has_running_effects(), "%s effects run" % skin_id)
		var after: PackedInt64Array = _filled(4)
		board.set_board(after)
		assert_false(board.has_running_effects(), "%s set_board ends them" % skin_id)
		for index: int in after.size():
			assert_eq(board.value_at(_cell(index)), 4, "%s cell %d shows the new board" % [skin_id, index])


# Geometry.

func test_cell_rect_grid_origin_and_pitch_agree_and_fit_the_preferred_height() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		for width: float in [_board_width(skin), 1000.0, 600.0, 1262.0]:
			var board: CommonBoardView = _board(skin_id)
			var height: float = board.preferred_height(width)
			board.size = Vector2(width, height)
			_check_geometry(board, "%s at %.0f px" % [skin_id, width])
			var first: Rect2 = board.cell_rect(Vector2i(0, 0))
			var last: Rect2 = board.cell_rect(Vector2i(COLUMNS - 1, ROWS - 1))
			assert_near(first.position.x, width - last.end.x, EPSILON, "%s at %.0f px is centered across" % [skin_id, width])
			assert_near(first.position.y, height - last.end.y, EPSILON, "%s at %.0f px fills its preferred height" % [skin_id, width])


func test_preferred_height_follows_the_design_system_formula() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		var width: float = _board_width(skin)
		var expected: float = 0.0
		if skin_id == &"nova":
			# 8 x pitch, the pitch being the width over 5 (DESIGN_SYSTEM.md 2.3).
			expected = float(ROWS) * width / float(COLUMNS)
			assert_near(board.tile_side(), width / float(COLUMNS) * skin.num(&"orb_scale"), EPSILON, "nova orb is orb_scale of the pitch")
		else:
			var gap: float = skin.num(&"board_gap")
			var pad: float = skin.num(&"board_padding")
			var side: float = (width - float(COLUMNS - 1) * gap - 2.0 * pad) / float(COLUMNS)
			expected = float(ROWS) * side + float(ROWS - 1) * gap + 2.0 * pad
			assert_near(board.tile_side(), side, EPSILON, "%s tile side" % skin_id)
		assert_near(board.preferred_height(width), expected, EPSILON, "%s preferred height" % skin_id)


func test_a_rect_too_short_shrinks_the_board_evenly_and_centers_it() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var width: float = _board_width(SkinCatalog.get_skin(skin_id))
		var full: float = board.preferred_height(width)
		var full_side: float = board.tile_side()
		var full_pitch: float = board.cell_pitch().x
		board.size = Vector2(width, full * 0.75)
		_check_geometry(board, "%s shrunk" % skin_id)
		assert_near(board.tile_side(), full_side * 0.75, EPSILON, "%s tiles shrink evenly" % skin_id)
		assert_near(board.cell_pitch().x, full_pitch * 0.75, EPSILON, "%s gaps shrink with them" % skin_id)
		var first: Rect2 = board.cell_rect(Vector2i(0, 0))
		var last: Rect2 = board.cell_rect(Vector2i(COLUMNS - 1, ROWS - 1))
		assert_near(first.position.x, width - last.end.x, EPSILON, "%s stays centered" % skin_id)


func test_preferred_height_of_nothing_is_nothing() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		assert_eq(board.preferred_height(0.0), 0.0, "%s zero width" % skin_id)


# Setters at their edges.

func test_set_chain_accepts_its_edge_values() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(2))
		var empty: Array[Vector2i] = []
		board.set_chain(empty, NO_DRAG)
		var one: Array[Vector2i] = [Vector2i(0, 0)]
		board.set_chain(one, NO_DRAG)
		var whole: Array[Vector2i] = []
		for index: int in COLUMNS * ROWS:
			whole.append(_cell(index))
		board.set_chain(whole, Vector2(-500.0, 99999.0))
		board.advance_effects(SkinCatalog.get_skin(skin_id).duration(&"chain_add"))
		var outside: Array[Vector2i] = [Vector2i(-3, 0), Vector2i(COLUMNS, ROWS), Vector2i(1, 1)]
		board.set_chain(outside, Vector2.ZERO)
		board.set_chain(empty, NO_DRAG)
		assert_false(board.has_running_effects(), "%s the chain is a look, not an effect" % skin_id)


func test_the_line_runs_to_the_finger_in_local_pixels_where_the_skin_has_a_tail() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(2))
		var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1)]
		var finger: Vector2 = Vector2(123.0, 456.0)
		board.set_chain(chain, finger)
		var count: int = board._build_line_points()
		if skin_id == &"slate":
			# Slate draws no tail toward the finger (DESIGN_SYSTEM.md 5.7).
			assert_eq(count, 2, "slate line ends at the last node")
		else:
			assert_eq(count, 3, "%s line runs on to the finger" % skin_id)
			assert_eq(board._line_points[2], finger, "%s the tail ends at the finger" % skin_id)
		assert_eq(board._line_points[0], board.cell_center(Vector2i(0, 0)), "%s line starts on the first tile" % skin_id)
		board.set_chain(chain, NO_DRAG)
		assert_eq(board._build_line_points(), 2, "%s no finger, no tail" % skin_id)


func test_the_tail_stops_at_the_board_edge_but_the_chain_stays() -> void:
	# DESIGN_SYSTEM.md 3.6 and AT-19: the finger left the board. The tail's
	# round end reaches the edge (Gumdrop: the tray) and no further.
	for skin_id: StringName in [&"gumdrop", &"nova"]:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(2))
		var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1)]
		var edge: Rect2 = board.board_rect() if skin_id == &"gumdrop" else Rect2(Vector2.ZERO, board.size)
		var half: float = skin.num(&"chain_width") * board.tile_side() / _reference_side(skin) * 0.5
		var inside: Rect2 = edge.grow(-half)
		for finger: Vector2 in [Vector2(-500.0, 99999.0), Vector2(5000.0, -300.0), Vector2(0.0, 0.0)]:
			board.set_chain(chain, finger)
			assert_eq(board._build_line_points(), 3, "%s the chain and its tail stay" % skin_id)
			var tail: Vector2 = board._line_points[2]
			var kept: bool = tail.x >= inside.position.x - EPSILON and tail.x <= inside.end.x + EPSILON 					and tail.y >= inside.position.y - EPSILON and tail.y <= inside.end.y + EPSILON
			assert_true(kept, "%s tail end %s for a finger at %s stays inside %s" % [skin_id, tail, finger, inside])
		var on_board: Vector2 = board.cell_center(Vector2i(2, 3))
		board.set_chain(chain, on_board)
		board._build_line_points()
		assert_eq(board._line_points[2], on_board, "%s a finger on the board is not moved" % skin_id)


func test_new_tiles_draw_under_falling_tiles() -> void:
	# DESIGN_SYSTEM.md 3.6: falls and spawns start together, and a new tile
	# appears from behind the tile falling away from its cell.
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _filled(2)
		cells[CoreRules.index_of(Vector2i(0, 7), COLUMNS)] = 0
		board.set_board(cells)
		var from: Array[Vector2i] = []
		var to: Array[Vector2i] = []
		for row: int in range(6, -1, -1):
			from.append(Vector2i(0, row))
			to.append(Vector2i(0, row + 1))
		board.play_fall(from, to)
		var spawned: Array[Vector2i] = [Vector2i(0, 0)]
		var length: float = board.play_spawn(spawned, PackedInt64Array([3]))
		board.advance_effects(0.01)
		var new_tile: int = CoreRules.index_of(Vector2i(0, 0), COLUMNS)
		for index: int in COLUMNS * ROWS:
			if index != new_tile and board._item_shown[index] != 0:
				assert_true(board._item_order[new_tile] < board._item_order[index], "%s the new tile draws under tile %d" % [skin_id, index])
		board.advance_effects(maxf(length, skin.duration(&"fall")) + EPSILON)
		assert_true(board._item_order[new_tile] >= CommonBoardView.RANK_REST * CommonBoardView.RANK_STEP, "%s a grown tile rests with the others" % skin_id)


func test_the_preview_sits_on_the_gap_crossing() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(1))
		var origin: Vector2 = board.grid_origin()
		var pitch: Vector2 = board.cell_pitch()
		var chain: Array[Vector2i] = [Vector2i(3, 4), Vector2i(2, 3)]
		board.set_chain(chain, NO_DRAG)
		board.set_preview(2)
		assert_eq(board._preview_center(), origin + Vector2(2.0, 3.0) * pitch, "%s top left crossing" % skin_id)
		var left: Array[Vector2i] = [Vector2i(1, 5), Vector2i(0, 5)]
		board.set_chain(left, NO_DRAG)
		assert_eq(board._preview_center(), origin + Vector2(1.0, 5.0) * pitch, "%s top right crossing in column 0" % skin_id)


func test_set_preview_accepts_its_edge_values() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(2))
		var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
		board.set_chain(chain, NO_DRAG)
		for value: int in [0, 1, HIGHEST_SHORT_POWER, 67, 5827, HIGHEST_POWER, 0]:
			board.set_preview(value)
		board.set_preview(-8)
		assert_false(board._show_preview(), "%s a value below 1 hides the preview" % skin_id)


func test_joinable_highlight_is_never_on_a_chained_tile() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(2))
		var chain: Array[Vector2i] = [Vector2i(0, 0)]
		board.set_chain(chain, NO_DRAG)
		var joinable: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(9, 9)]
		board.set_joinable(joinable)
		assert_false(board._join_fade.is_on(0), "%s the chained tile is not highlighted" % skin_id)
		assert_true(board._join_fade.is_on(1), "%s the joinable tile is" % skin_id)
		var none: Array[Vector2i] = []
		board.set_joinable(none)
		assert_false(board._join_fade.is_on(1), "%s an empty set clears it" % skin_id)
		var all_cells: Array[Vector2i] = []
		for index: int in COLUMNS * ROWS:
			all_cells.append(_cell(index))
		board.set_joinable(all_cells)
		board.advance_effects(SkinCatalog.get_skin(skin_id).duration(&"joinable_in"))
		assert_near(board._join_fade.value[COLUMNS * ROWS - 1], 1.0, EPSILON, "%s eases fully in over joinable_in" % skin_id)


func test_targeting_press_and_swap_selection_accept_their_edge_values() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(4))
		for booster_id: StringName in [&"hammer", &"swap", &"double", &"shuffle", &"undo", &""]:
			board.set_targeting(booster_id)
		board.set_targeting(&"swap")
		for cell: Vector2i in [Vector2i(0, 0), Vector2i(COLUMNS - 1, ROWS - 1), NO_CELL, Vector2i(COLUMNS, 0), Vector2i(0, ROWS)]:
			board.set_pressed_cell(cell)
			board.set_swap_selected(cell)
		assert_eq(board._pressed, NO_CELL, "%s a cell off the board presses nothing" % skin_id)
		board.set_swap_selected(Vector2i(2, 2))
		board.set_pressed_cell(Vector2i(3, 3))
		board.advance_effects(SkinCatalog.get_skin(skin_id).duration(&"target_pulse") * 1.5)
		board.set_targeting(&"")
		assert_eq(board._pressed, NO_CELL, "%s ending targeting drops the press" % skin_id)
		assert_eq(board._selected, NO_CELL, "%s and the selection" % skin_id)


# Effects: lengths from the motion tokens, and the board they leave.

func test_play_spawn_lasts_spawn_plus_the_stagger() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(1))
		var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
		var length: float = board.play_spawn(cells, PackedInt64Array([2, 3, 4]))
		var stagger: float = MotionMath.extra(skin, &"spawn", "stagger")
		assert_near(length, skin.duration(&"spawn") + 2.0 * stagger, EPSILON, "%s spawn length" % skin_id)
		assert_eq(board.value_at(Vector2i(2, 0)), 4, "%s spawned value" % skin_id)
		_settle(board, length, "%s spawn" % skin_id)
		var none: Array[Vector2i] = []
		assert_eq(board.play_spawn(none, PackedInt64Array()), 0.0, "%s spawning nothing takes no time" % skin_id)


func test_play_merge_lasts_travel_and_pop() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(3))
		var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 1)]
		board.set_chain(chain, Vector2(10.0, 10.0))
		board.set_preview(5)
		var length: float = board.play_merge(chain, Vector2i(2, 1), 5)
		var expected: float = skin.duration(&"merge_travel")
		if not POP_IS_TAIL[skin_id]:
			expected += skin.duration(&"merge_pop")
		assert_near(length, expected, EPSILON, "%s merge length" % skin_id)
		assert_eq(board.value_at(Vector2i(0, 0)), 0, "%s chain cells empty" % skin_id)
		assert_eq(board.value_at(Vector2i(2, 1)), 5, "%s result placed" % skin_id)
		assert_false(board._show_preview(), "%s the preview goes with the chain" % skin_id)
		_settle(board, length, "%s merge" % skin_id)
		assert_eq(board._build_line_points(), 0, "%s no line is left" % skin_id)


func test_play_clear_lasts_clear() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(1))
		var cleared: Array[Vector2i] = [Vector2i(0, 7), Vector2i(4, 0)]
		var length: float = board.play_clear(cleared)
		assert_near(length, skin.duration(&"clear"), EPSILON, "%s clear length" % skin_id)
		assert_eq(board.value_at(Vector2i(0, 7)), 0, "%s cleared cell empty" % skin_id)
		_settle(board, length, "%s clear" % skin_id)
		var empty: Array[Vector2i] = [Vector2i(0, 7)]
		assert_eq(board.play_clear(empty), 0.0, "%s clearing an empty cell takes no time" % skin_id)


func test_play_fall_lasts_fall_and_moves_the_values() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _filled(1)
		cells[CoreRules.index_of(Vector2i(1, 0), COLUMNS)] = 6
		cells[CoreRules.index_of(Vector2i(1, 1), COLUMNS)] = 7
		cells[CoreRules.index_of(Vector2i(1, 6), COLUMNS)] = 0
		cells[CoreRules.index_of(Vector2i(1, 7), COLUMNS)] = 0
		board.set_board(cells)
		var from: Array[Vector2i] = [Vector2i(1, 5), Vector2i(1, 4), Vector2i(1, 3), Vector2i(1, 2), Vector2i(1, 1), Vector2i(1, 0)]
		var to: Array[Vector2i] = [Vector2i(1, 7), Vector2i(1, 6), Vector2i(1, 5), Vector2i(1, 4), Vector2i(1, 3), Vector2i(1, 2)]
		var length: float = board.play_fall(from, to)
		assert_near(length, skin.duration(&"fall"), EPSILON, "%s fall length" % skin_id)
		assert_eq(board.value_at(Vector2i(1, 2)), 6, "%s the top tile fell two rows" % skin_id)
		assert_eq(board.value_at(Vector2i(1, 3)), 7, "%s the next one too" % skin_id)
		assert_eq(board.value_at(Vector2i(1, 0)), 0, "%s the top is empty" % skin_id)
		assert_eq(board.value_at(Vector2i(1, 1)), 0, "%s the row under it too" % skin_id)
		_settle(board, length, "%s fall" % skin_id)


func test_a_running_pop_falls_with_its_tile() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _filled(2)
		cells[CoreRules.index_of(Vector2i(0, 7), COLUMNS)] = 0
		board.set_board(cells)
		board.play_value_change(Vector2i(0, 6), 3)
		var from: Array[Vector2i] = [Vector2i(0, 6)]
		var to: Array[Vector2i] = [Vector2i(0, 7)]
		board.play_fall(from, to)
		for effect: RefCounted in board._effects:
			assert_ne(effect.get("index"), CoreRules.index_of(Vector2i(0, 6), COLUMNS), "%s no effect stays on the emptied cell" % skin_id)


func test_play_value_change_lasts_the_pop() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(10))
		var length: float = board.play_value_change(Vector2i(2, 2), 11)
		var expected: float = 0.0 if POP_IS_TAIL[skin_id] else skin.duration(&"merge_pop")
		assert_near(length, expected, EPSILON, "%s Double length" % skin_id)
		assert_eq(board.value_at(Vector2i(2, 2)), 11, "%s doubled" % skin_id)
		_settle(board, length, "%s Double" % skin_id)


func test_play_swap_lasts_a_fall_and_swaps_the_values() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _filled(1)
		cells[0] = 9
		board.set_board(cells)
		var length: float = board.play_swap(Vector2i(0, 0), Vector2i(4, 7))
		assert_near(length, skin.duration(&"fall"), EPSILON, "%s Swap length" % skin_id)
		assert_eq(board.value_at(Vector2i(4, 7)), 9, "%s swapped" % skin_id)
		assert_eq(board.value_at(Vector2i(0, 0)), 1, "%s both ways" % skin_id)
		_settle(board, length, "%s Swap" % skin_id)
		assert_eq(board.play_swap(Vector2i(1, 1), Vector2i(1, 1)), 0.0, "%s a tile with itself does nothing" % skin_id)


func test_play_rearrange_slides_a_shuffle_and_spawns_what_is_new() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var board: CommonBoardView = _board(skin_id)
		var before: PackedInt64Array = _mixed_cells(12)
		board.set_board(before)
		var shuffled: PackedInt64Array = before.duplicate()
		shuffled.reverse()
		var length: float = board.play_rearrange(shuffled)
		assert_near(length, skin.duration(&"fall"), EPSILON, "%s a Shuffle only slides" % skin_id)
		for index: int in shuffled.size():
			assert_eq(board.value_at(_cell(index)), shuffled[index], "%s cell %d after Shuffle" % [skin_id, index])
		_settle(board, length, "%s Shuffle" % skin_id)
		var undone: PackedInt64Array = shuffled.duplicate()
		undone[0] = 20
		length = board.play_rearrange(undone)
		var expected: float = maxf(skin.duration(&"spawn"), skin.duration(&"clear"))
		assert_near(length, expected, EPSILON, "%s a new value spawns and the old one leaves" % skin_id)
		_settle(board, length, "%s Undo" % skin_id)
		assert_eq(board.play_rearrange(undone), 0.0, "%s nothing to change takes no time" % skin_id)


func test_a_whole_move_ends_on_the_board_the_move_says() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var cells: PackedInt64Array = _filled(2)
		cells[CoreRules.index_of(Vector2i(0, 7), COLUMNS)] = 1
		cells[CoreRules.index_of(Vector2i(1, 7), COLUMNS)] = 1
		board.set_board(cells)
		var chain: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7)]
		board.set_chain(chain, NO_DRAG)
		var total: float = board.play_merge(chain, Vector2i(1, 7), 2)
		board.advance_effects(total + EPSILON)
		var from: Array[Vector2i] = [Vector2i(0, 6), Vector2i(0, 5), Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1), Vector2i(0, 0)]
		var to: Array[Vector2i] = [Vector2i(0, 7), Vector2i(0, 6), Vector2i(0, 5), Vector2i(0, 4), Vector2i(0, 3), Vector2i(0, 2), Vector2i(0, 1)]
		total = board.play_fall(from, to)
		var spawned: Array[Vector2i] = [Vector2i(0, 0)]
		total = maxf(total, board.play_spawn(spawned, PackedInt64Array([3])))
		board.advance_effects(total + EPSILON)
		var after: PackedInt64Array = _filled(2)
		after[CoreRules.index_of(Vector2i(0, 0), COLUMNS)] = 3
		for index: int in after.size():
			assert_eq(board.value_at(_cell(index)), after[index], "%s cell %d" % [skin_id, index])
		assert_false(board.has_running_effects(), "%s at rest" % skin_id)


func test_effects_on_cells_off_the_board_do_nothing() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		board.set_board(_filled(1))
		assert_eq(board.play_value_change(Vector2i(COLUMNS, 0), 2), 0.0, "%s Double off the board" % skin_id)
		var off: Array[Vector2i] = [Vector2i(-1, 0)]
		assert_eq(board.play_clear(off), 0.0, "%s clear off the board" % skin_id)


# Design review fixes (docs/design/briefs/tile-board-artist-prod-fixes.md).

func test_slate_label_plate_clears_the_inset_chained_frame() -> void:
	# The chained frame sits frame_inset inside the edge (DESIGN_SYSTEM.md
	# 5.7). The plate over the number must stay inside the frame for every
	# label up to 64M, at the board tile and smaller ones. (128M to 512M are
	# wider than any real board reaches; reported to the designer.)
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var painter: RefCounted = SLATE_PAINTER.new()
	painter.call("setup", skin)
	var highest_power: int = 26
	for side: float in [_reference_side(skin), 168.0, 148.0, 120.0]:
		var unit: float = side / float(painter.call("reference_side"))
		painter.call("set_side", side, unit)
		var tile: Rect2 = Rect2(Vector2(-side, -side) * 0.5, Vector2(side, side))
		var inner: Rect2 = tile.grow(-(skin.num(&"frame_inset") * side + skin.num(&"chain_ring") * unit))
		var top_left: Vector2 = tile.position + Vector2.ONE * skin.num(&"number_inset") * side
		var labels: RefCounted = painter.get("labels")
		for power: int in range(1, highest_power + 1):
			var box: Rect2 = labels.call("box_top_left", top_left, power)
			var plate: Rect2 = box.grow(skin.num(&"number_plate") * unit)
			if not inner.encloses(plate):
				fail("slate label %s at a %.0f px tile: plate %s crosses the frame %s" % [labels.call("label", power), side, plate, inner])


## QA6-02: the candy rim and the shine are each one triangle array, so each
## costs one draw call, built when a tile first needs them at a side. Every
## index points at a point, every point has a color, and the rim still
## cycles the tier 1 and 2 fills in its segments.
func test_gumdrop_rim_and_shine_are_one_valid_triangle_array_each() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"gumdrop")
	var painter: RefCounted = GUMDROP_PAINTER.new()
	painter.call("setup", skin)
	var reference: float = float(painter.call("reference_side"))
	var expected_colors: Dictionary = {}
	for power: int in range(1, SkinData.RAMP_SIZE + 1):
		var tier: int = skin.tier_for(power)
		if tier == 1 or tier == 2:
			expected_colors[skin.fill_for(power)] = true
	var shine_index: int = int(painter.call("style_of", 11))
	for side: float in [reference, 112.0, 72.0]:
		painter.call("set_side", side, side / reference)
		var item: RID = RenderingServer.canvas_item_create()
		painter.call("draw_tile", item, Transform2D.IDENTITY, 9, 0.0, 0.0, 0.0, 0.0)
		assert_eq(painter.get("_rim_face"), -Vector2.ONE, "gumdrop builds no rim while only plain tiles draw at %.0f px" % side)
		painter.call("draw_tile", item, Transform2D.IDENTITY, 17, 1.0, 1.0, 0.0, 0.0)
		painter.call("draw_tile", item, Transform2D.IDENTITY, 11, 0.0, 0.0, 0.0, 0.0)
		RenderingServer.free_rid(item)
		for part: String in ["_rim", "_shine"]:
			var strokes: RefCounted = painter.get(part)
			var points: PackedVector2Array = strokes.get("points")
			var colors: PackedColorArray = strokes.get("colors")
			var indices: PackedInt32Array = strokes.get("indices")
			assert_false(indices.is_empty(), "gumdrop %s has triangles at a %.0f px tile" % [part, side])
			assert_eq(colors.size(), points.size(), "gumdrop %s: a color per point at %.0f px" % [part, side])
			assert_eq(indices.size() % 3, 0, "gumdrop %s: whole triangles at %.0f px" % [part, side])
			var bad: int = 0
			for i: int in indices:
				if i < 0 or i >= points.size():
					bad += 1
			assert_eq(bad, 0, "gumdrop %s: every index points at a point at %.0f px" % [part, side])
		var rim_colors: Dictionary = {}
		for color: Color in (painter.get("_rim") as RefCounted).get("colors") as PackedColorArray:
			if color.a > 0.0:
				rim_colors[color] = true
		assert_eq(rim_colors.size(), expected_colors.size(), "gumdrop rim cycles every tier 1 and 2 fill at %.0f px" % side)
		for color: Color in rim_colors:
			assert_true(expected_colors.has(color), "gumdrop rim color %s is a tier 1 or 2 fill" % color.to_html())
		var shine_arrays: Array = painter.get("_shine_arrays")
		var shine_points: int = ((painter.get("_shine") as RefCounted).get("points") as PackedVector2Array).size()
		assert_eq((shine_arrays[shine_index] as PackedColorArray).size(), shine_points, "gumdrop shine colors made for 2048 at %.0f px" % side)


## The feather of Gumdrop's strokes, measured from Godot's polyline, joins
## up where its three ranges meet.
func test_gumdrop_stroke_feather_is_continuous() -> void:
	var strokes: GDScript = GUMDROP_PAINTER.Strokes
	for width: float in [2.0, 5.0]:
		var below: Vector2 = strokes.call("stroke_edges", width - 0.0001)
		var above: Vector2 = strokes.call("stroke_edges", width + 0.0001)
		assert_near(below.x, above.x, 0.01, "solid edge meets at %.0f px" % width)
		assert_near(below.y, above.y, 0.01, "clear edge meets at %.0f px" % width)
	var wide: Vector2 = strokes.call("stroke_edges", 8.0)
	assert_near(wide.x, 4.0 - 0.3125, EPSILON, "an 8 px stroke is solid to a quarter feather inside its edge")
	assert_near(wide.y, 4.0 + 0.9375, EPSILON, "and clear three quarters of a feather outside")


## The dark rim goes by color (DESIGN_SYSTEM.md 6.5, 14.3): every orb with
## the white hole's colors (ramp position 16), 128K, 8B (2^33), 512T (2^49)
## and every 16 doublings on, and no other.
func test_nova_chained_rim_is_dark_on_the_white_hole() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"nova")
	var painter: RefCounted = NOVA_PAINTER.new()
	painter.call("setup", skin)
	var rims: PackedColorArray = painter.get("_chain_rims")
	assert_eq(int(skin.num(&"dark_rim_from")), 131072, "dark_rim_from is the white hole")
	var dark: Color = skin.color(&"ink_dark")
	for power: int in [17, 33, 49, 65521]:
		assert_eq(rims[int(painter.call("style_of", power))], dark, "nova chained rim is dark on 2^%d" % power)
	for power: int in [16, 18, 50, 65535]:
		assert_eq(rims[int(painter.call("style_of", power))], skin.color(&"chain"), "nova chained rim is chain on 2^%d" % power)
	for power: int in range(1, 1001):
		var expected: Color = dark if power >= 17 and (power - 17) % 16 == 0 else skin.color(&"chain")
		var style: int = int(painter.call("style_of", power))
		if rims[style] != expected:
			fail("nova chained rim for 2^%d" % power)


## Slate marks go by color (DESIGN_SYSTEM.md 5.7): on a big tile above 128K
## with a slab color (256K, forest slab) the frames keep chain and joinable
## and the special frame takes the slab's bright number; on a big block color
## (16M, amber) they are ink_dark.
func test_slate_marks_on_big_tiles_follow_the_color() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"slate")
	var painter: RefCounted = SLATE_PAINTER.new()
	painter.call("setup", skin)
	var reference: float = float(painter.call("reference_side"))
	painter.call("set_side", reference, 1.0)
	var item: RID = RenderingServer.canvas_item_create()
	# Exponents: 256K, 16M, 32B, 64, 128.
	var cases: Dictionary = {18: false, 24: true, 35: false, 6: false, 7: true}
	for value: int in cases:
		var block: bool = cases[value]
		var frame_box: StyleBoxFlat = painter.get("_inset_frame_box")
		painter.call("draw_body", item, Transform2D.IDENTITY, value, false, 1.0, 0.0)
		var chain_expected: Color = skin.color(&"ink_dark") if block else skin.color(&"chain")
		assert_eq(frame_box.border_color, chain_expected, "slate chained frame on %d" % value)
		painter.call("draw_body", item, Transform2D.IDENTITY, value, false, 0.0, 1.0)
		var join_expected: Color = skin.color(&"ink_dark") if block else skin.color(&"joinable")
		assert_eq(frame_box.border_color, join_expected, "slate joinable frame on %d" % value)
		if value >= SkinData.exponent_of(int(skin.num(&"special_from"))):
			var special_box: StyleBoxFlat = painter.get("_special_box")
			assert_eq(special_box.border_color, skin.ink_for(value), "slate special frame on %d in its number color" % value)
	RenderingServer.free_rid(item)


func test_nova_sparks_take_the_lightened_fill() -> void:
	var skin: SkinData = SkinCatalog.get_skin(&"nova")
	var painter: RefCounted = NOVA_PAINTER.new()
	painter.call("setup", skin)
	var sparks: PackedColorArray = painter.get("_spark_colors")
	for power: int in [1, 2, 16, 17, 18, 33, 64, 1000, 65535]:
		var style: int = int(painter.call("style_of", power))
		assert_eq(sparks[style], skin.fill_for(power).lightened(skin.num(&"ray_lighten")), "nova spark color for 2^%d" % power)
	assert_eq(MotionMath.extra(skin, &"clear", "spark_size"), 8.0, "nova spark size")


# Tile views.

func test_tile_view_accepts_its_edge_values() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var tile: SkinTileView = _tile(skin_id)
		for side: float in [0.0, 1.0, 72.0, 112.0, 400.0]:
			tile.size = Vector2(side, side * 2.0)
			for value: int in [0, 1, 2, -2, 17, HIGHEST_POWER + 1, HIGHEST_SHORT_POWER, 67, 5827, HIGHEST_POWER]:
				tile.set_value(value)
		assert_eq(tile.get("_value"), HIGHEST_POWER, "%s keeps the last value" % skin_id)


## Counts the labels a painter draws, standing in for its TileLabels.
class LabelSpy extends "res://src/skins/common/tile_labels.gd":
	var drawn: int = 0

	func draw_centered(_canvas: RID, _center: Vector2, _exponent: int, _ink: Color) -> void:
		drawn += 1

	func draw_top_left(_canvas: RID, _top_left: Vector2, _exponent: int, _ink: Color) -> void:
		drawn += 1


## ARCHITECTURE.md 17 additions: set_label_shown(false) draws the tile with
## no label in every skin; the default draws it; true brings it back.
func test_tile_view_label_can_be_hidden() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var tile: SkinTileView = _tile(skin_id)
		tile.size = Vector2(96.0, 96.0)
		var painter: RefCounted = tile.get("_painter") as RefCounted
		var spy: LabelSpy = LabelSpy.new()
		spy.setup(SkinCatalog.get_skin(skin_id))
		painter.set("labels", spy)
		for exponent: int in [1, 17, 67]:
			tile.set_value(exponent)
			spy.drawn = 0
			tile.call("_draw")
			assert_eq(spy.drawn, 1, "%s 2^%d draws its label by default" % [skin_id, exponent])
			tile.set_label_shown(false)
			spy.drawn = 0
			tile.call("_draw")
			assert_eq(spy.drawn, 0, "%s 2^%d draws no label when hidden" % [skin_id, exponent])
			assert_false(bool(painter.get("label_shown")), "%s the painter is told" % skin_id)
			tile.set_label_shown(true)
			spy.drawn = 0
			tile.call("_draw")
			assert_eq(spy.drawn, 1, "%s 2^%d draws its label again" % [skin_id, exponent])
		RenderingServer.canvas_item_clear(tile.get_canvas_item())


## Only tile views hide labels: the board's painters keep the default.
func test_board_painters_keep_their_labels() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		var board: CommonBoardView = _board(skin_id)
		var painter: RefCounted = board.get("_tiles") as RefCounted
		assert_true(bool(painter.get("label_shown")), "%s board tiles show labels" % skin_id)


# Helpers.

func _board(skin_id: StringName) -> CommonBoardView:
	var skin: SkinData = SkinCatalog.get_skin(skin_id)
	var board: CommonBoardView = SkinCatalog.make_board_view(skin) as CommonBoardView
	board.effects_paused = true
	board.setup(skin, COLUMNS, ROWS)
	var width: float = _board_width(skin)
	board.size = Vector2(width, board.preferred_height(width))
	_nodes.append(board)
	return board


func _tile(skin_id: StringName) -> SkinTileView:
	var tile: SkinTileView = SkinCatalog.make_tile_view(SkinCatalog.get_skin(skin_id))
	_nodes.append(tile)
	return tile


func _board_width(skin: SkinData) -> float:
	return float(ProjectSettings.get_setting("display/window/size/viewport_width")) - 2.0 * skin.num(&"board_margin")


## The board tile side on the base canvas.
func _reference_side(skin: SkinData) -> float:
	var board: CommonBoardView = _board(skin.id)
	return board.tile_side()


func _cell(index: int) -> Vector2i:
	return CoreRules.cell_of(index, COLUMNS)


func _filled(value: int) -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	cells.resize(COLUMNS * ROWS)
	cells.fill(value)
	return cells


## Exponents from 1 up to highest_power, repeating, one per cell.
func _mixed_cells(highest_power: int) -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for index: int in COLUMNS * ROWS:
		cells.append(1 + (index * 7) % highest_power)
	cells[0] = highest_power
	return cells


## Steps the clock just past an effect's length; then no tile may still move.
func _settle(board: CommonBoardView, length: float, what: String) -> void:
	board.advance_effects(length + EPSILON)
	assert_false(board.has_running_effects(), "%s is at rest after its length" % what)


func _check_geometry(board: CommonBoardView, what: String) -> void:
	var origin: Vector2 = board.grid_origin()
	var pitch: Vector2 = board.cell_pitch()
	var bounds: Rect2 = Rect2(Vector2.ZERO, board.size).grow(EPSILON)
	assert_near(pitch.x, pitch.y, EPSILON, "%s pitch is square" % what)
	assert_true(pitch.x > 0.0, "%s pitch is set" % what)
	for index: int in COLUMNS * ROWS:
		var cell: Vector2i = _cell(index)
		var rect: Rect2 = board.cell_rect(cell)
		var center: Vector2 = origin + (Vector2(cell) + Vector2(0.5, 0.5)) * pitch
		if not rect.get_center().is_equal_approx(center):
			fail("%s cell %s: rect center %s, grid says %s" % [what, cell, rect.get_center(), center])
		assert_near(rect.size.x, rect.size.y, EPSILON, "%s tiles are square" % what)
		assert_true(rect.size.x <= pitch.x + EPSILON, "%s a tile fits its pitch" % what)
		if not bounds.encloses(rect):
			fail("%s cell %s rect %s leaves the view %s" % [what, cell, rect, board.size])
