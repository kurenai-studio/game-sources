extends "res://tests/base_test.gd"
## Chains built through BoardController from synthetic touch events on a
## real GameSession: joining, the preview, backtracking (AT-14 to AT-16),
## crossing paths (AT-20), leaving the board and lifting (D-06, AT-18,
## AT-19), commit and cancel, and the joinable highlight (D-40).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)

var rig: BF.Rig = null


func after_each() -> void:
	if rig != null:
		rig.free_all()


func _chain(list: Array) -> Array[Vector2i]:
	return BF.cells(list)


## The previews of every chain_changed so far, as tile values.
func _previews() -> Array[int]:
	return rig.previews()


## The chain lengths of every chain_changed so far.
func _lengths() -> Array[int]:
	var list: Array[int] = []
	for event: Array in rig.chain_events:
		list.append((event[0] as Array).size())
	return list


func _unchanged(before: RunState, message: String) -> void:
	assert_true(rig.session.state.equals(before), "%s: board, score and Undo state unchanged" % message)
	assert_eq(rig.view().merges.size(), 0, "%s: no merge played" % message)
	assert_false(rig.session.is_dragging(), "%s: the drag is closed" % message)
	assert_false(rig.session.is_waiting_for_view(), "%s: no move to show" % message)


# Joining (D-04) and the preview (D-03).

func test_at_07_an_equal_second_tile_joins() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6)]), "chain 2, 2")
	assert_eq(rig.last_preview(), 4, "preview 4")
	assert_eq(rig.view_preview(), 4, "the view shows preview 4")
	assert_eq(rig.view().chain, _chain([Vector2i(1, 6), Vector2i(2, 6)]), "the view shows the chain")
	assert_eq(_previews(), [0, 4] as Array[int], "no preview at 1 tile, then 4")
	assert_true(rig.session.is_dragging(), "the drag is open")


func test_at_06_the_first_two_tiles_must_be_equal_and_lifting_cancels() -> void:
	rig = BF.rig(F.board_p(), 0)
	var before: RunState = rig.session.state.copy()
	var rng_state: int = rig.session.rng.get_state()
	rig.drag_cells([Vector2i(1, 6), Vector2i(1, 5)])
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6)]), "the 4 does not join")
	assert_eq(rig.view_preview(), 0, "no preview")
	rig.up(Vector2i(1, 5))
	assert_eq(rig.last_chain(), _chain([]), "lifting clears the chain")
	assert_eq(rig.last_preview(), 0, "and the preview")
	_unchanged(before, "AT-06")
	assert_eq(rig.session.rng.get_state(), rng_state, "the random generator was not used")


func test_c1_to_c9_worked_example_through_the_board() -> void:
	# GDD 6.6: the finger path C1 to C9, previews as listed.
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 7)])
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]), "C4: 32 does not join")
	rig.move(Vector2i(3, 6))
	rig.move(Vector2i(2, 5))
	assert_eq(rig.last_preview(), 16, "C5: the diagonal 8 joins, preview 16")
	rig.move(Vector2i(1, 5))
	assert_eq(rig.last_chain().size(), 4, "C6: half does not join")
	rig.move(Vector2i(2, 5))
	rig.move(Vector2i(3, 5))
	assert_eq(rig.last_preview(), 32, "C7: 16 joins, preview 32")
	rig.move(Vector2i(2, 5))
	assert_eq(rig.last_chain().size(), 4, "C8: back to the previous tile, 16 leaves")
	assert_eq(rig.last_preview(), 16, "C8: preview 16")
	rig.move(Vector2i(2, 6))
	assert_eq(rig.last_chain().size(), 4, "C9: another chain tile is ignored")
	assert_eq(rig.last_preview(), 16, "C9: preview 16")


# Backtracking (D-05).

func test_at_14_backtracking_shrinks_the_chain_step_by_step() -> void:
	rig = BF.rig(F.board_p(), 0)
	var before: RunState = rig.session.state.copy()
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5)])
	assert_eq(_previews(), [0, 4, 8, 16, 32] as Array[int], "previews while building")
	rig.chain_events.clear()
	rig.move(Vector2i(2, 5))
	rig.move(Vector2i(3, 6))
	rig.move(Vector2i(2, 6))
	rig.move(Vector2i(1, 6))
	assert_eq(_lengths(), [4, 3, 2, 1] as Array[int], "one tile leaves per backtrack")
	assert_eq(_previews(), [16, 8, 4, 0] as Array[int], "previews 16, 8, 4, then none")
	assert_eq(rig.view_preview(), 0, "the view hides the preview at 1 tile")
	rig.up(Vector2i(1, 6))
	assert_eq(rig.last_chain(), _chain([]), "lifting cancels")
	_unchanged(before, "AT-14")


func test_at_15_a_backtracked_tile_can_join_again() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5), Vector2i(2, 5)])
	assert_eq(rig.last_chain().size(), 4, "backtracked to 4 tiles")
	rig.move(Vector2i(3, 5))
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5), Vector2i(3, 5)]), "(3,5) joins again")
	assert_eq(rig.last_preview(), 32, "preview 32")


func test_at_16_other_chain_tiles_are_ignored() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)])
	var events: int = rig.chain_events.size()
	rig.move(Vector2i(2, 6))
	assert_eq(rig.chain_events.size(), events, "no change signalled")
	assert_eq(rig.view().chain, _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)]), "chain 2, 2, 4, 8")
	assert_eq(rig.view_preview(), 16, "preview 16")


# Path, leaving the board, lifting (D-06).

func test_at_20_the_path_may_cross_itself() -> void:
	rig = BF.rig(F.board_all(4), 0)
	rig.play([Vector2i(1, 1), Vector2i(2, 2), Vector2i(2, 1), Vector2i(1, 2)])
	assert_eq(_lengths().slice(0, 4), [1, 2, 3, 4] as Array[int], "all four join")
	assert_eq(_previews()[3], 16, "preview 16")
	assert_eq(rig.score(), 16, "score 16")
	assert_eq(rig.value_at(Vector2i(1, 2)), 16, "the 16 stays on (1,2)")


func test_at_18_lifting_off_the_board_commits() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	var off_board: Vector2 = Vector2(rig.point(Vector2i(2, 6)).x, BF.BELOW_BOARD_Y)
	rig.move_to(off_board)
	rig.up_at(off_board)
	assert_eq(rig.score(), 4, "the chain 2, 2 committed")
	assert_eq(rig.value_at(Vector2i(2, 6)), 4, "the result landed on the last tile")
	assert_false(rig.session.is_dragging(), "the drag is closed")


func test_at_19_leaving_the_board_keeps_the_chain() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	var below_2: Vector2 = Vector2(rig.point(Vector2i(2, 6)).x, BF.BELOW_BOARD_Y)
	var below_3: Vector2 = Vector2(rig.point(Vector2i(3, 6)).x, BF.BELOW_BOARD_Y)
	rig.move_to(below_2)
	rig.move_to(below_3)
	assert_eq(rig.last_chain().size(), 2, "the chain stays at 2 tiles off the board")
	assert_true(rig.session.is_dragging(), "the drag stays open off the board")
	assert_eq(rig.view().drag_point, below_3, "the chain line follows the finger off the board")
	rig.move(Vector2i(3, 6))
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]), "the 2x tile joins on return")
	rig.up(Vector2i(3, 6))
	assert_eq(rig.score(), 8, "the 3 tile chain commits")
	assert_eq(rig.value_at(Vector2i(3, 6)), 8, "result 8 on (3,6)")


func test_a_touch_in_a_gap_starts_on_the_first_tile_entered() -> void:
	rig = BF.rig(F.board_p(), 0)
	var corner: Vector2 = rig.point(Vector2i(1, 5), Vector2(50.0, 50.0))
	rig.down_at(corner)
	assert_true(rig.session.is_dragging(), "the drag is open")
	assert_eq(rig.chain_events.size(), 0, "no tile yet")
	rig.move(Vector2i(2, 6))
	assert_eq(rig.last_chain(), _chain([Vector2i(2, 6)]), "the first tile entered starts the chain")


func test_lifting_with_no_tile_closes_the_drag() -> void:
	rig = BF.rig(F.board_p(), 0)
	var before: RunState = rig.session.state.copy()
	var corner: Vector2 = rig.point(Vector2i(1, 5), Vector2(50.0, 50.0))
	rig.down_at(corner)
	rig.up_at(corner)
	assert_eq(rig.chain_events.size(), 1, "one cancel")
	assert_eq(rig.last_chain(), _chain([]), "an empty chain")
	_unchanged(before, "a lift with no tile")


func test_at_17_lifting_commits_through_the_board() -> void:
	rig = BF.rig(F.board_p(), 1000)
	var path: Array[Vector2i] = _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)])
	rig.play(path)
	assert_eq(rig.score(), 1016, "score 1,016")
	assert_eq(rig.value_at(Vector2i(2, 6)), 16, "the 16 fell to (2,6)")
	assert_eq(rig.view().merges, [[path, Vector2i(2, 5), F.e(16)]], "the merge played on the chain in drag order")
	assert_eq(rig.last_chain(), _chain([]), "commit clears the chain")
	assert_eq(rig.last_preview(), 0, "and the preview")
	assert_eq(rig.view().chain, _chain([]), "the view's chain is cleared")
	assert_eq(rig.view().drag_point, BF.NO_DRAG, "with no finger")
	assert_false(rig.session.is_dragging(), "the drag is closed")
	assert_false(rig.session.is_waiting_for_view(), "the move was shown")


# Hit testing through the board.

func test_a_fast_swipe_catches_every_tile_it_crosses() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.down(Vector2i(1, 6))
	rig.move(Vector2i(3, 6))
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]), "one event over two cells still steps through (2,6)")
	assert_eq(_previews(), [0, 4, 8] as Array[int], "every step shown")


func test_at_21_a_diagonal_swipe_never_catches_side_tiles() -> void:
	# The AT-21 play check through the board: on Board A4, a diagonal from
	# (1,1) to (2,2), once in one event and once in small steps.
	for steps: int in [1, 20]:
		rig = BF.rig(F.board_all(4), 0)
		var from: Vector2 = rig.point(Vector2i(1, 1))
		var to: Vector2 = rig.point(Vector2i(2, 2))
		rig.down_at(from)
		for i: int in steps:
			rig.move_to(from.lerp(to, float(i + 1) / float(steps)))
		assert_eq(rig.last_chain(), _chain([Vector2i(1, 1), Vector2i(2, 2)]), "%d steps: only the diagonal tile joins" % steps)
		rig.free_all()
	rig = null


func test_the_chain_line_follows_the_finger() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	var inside: Vector2 = rig.point(Vector2i(2, 6), Vector2(10.0, -12.0))
	var events: int = rig.chain_events.size()
	rig.move_to(inside)
	assert_eq(rig.view().drag_point, inside, "the view gets the finger")
	assert_eq(rig.chain_events.size(), events, "moving inside a tile changes no chain")


func test_chains_use_the_join_circle_not_the_tile_rect() -> void:
	# A tile corner is on the tile but outside the D-07 circle: it starts no
	# chain. A gap point inside the circle joins the tile.
	rig = BF.rig(F.board_p(), 0)
	var corner: Vector2 = rig.point(Vector2i(1, 6), Vector2(-37.0, -37.0))
	assert_true(rig.view().cell_rect(Vector2i(1, 6)).has_point(corner), "the corner is on the tile")
	rig.down_at(corner)
	assert_true(rig.session.is_dragging(), "the drag is open")
	assert_eq(rig.chain_events.size(), 0, "a tile corner is not over the tile for chains")
	rig.move(Vector2i(1, 6))
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6)]), "the tile joins once the finger reaches its circle")
	rig.move_to(rig.point(Vector2i(2, 6), Vector2(-41.0, 0.0)))
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6)]), "a point in the gap within the radius joins")


# The joinable highlight (D-40).

func test_at_105_hl1_to_hl3_highlight_through_the_board() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.down(Vector2i(1, 6))
	assert_eq(rig.view().joinable, _chain([Vector2i(0, 6), Vector2i(2, 6)]), "HL1")
	rig.move(Vector2i(2, 6))
	assert_eq(rig.view().joinable, _chain([Vector2i(1, 5), Vector2i(3, 6)]), "HL2")
	rig.move(Vector2i(3, 6))
	assert_eq(rig.view().joinable, _chain([Vector2i(2, 5), Vector2i(4, 5), Vector2i(3, 7), Vector2i(4, 7)]), "HL3")


func test_at_107_no_highlight_before_touching_or_after_lifting() -> void:
	rig = BF.rig(F.board_p(), 0)
	assert_eq(rig.view().joinable_calls, 0, "nothing highlighted before the first touch")
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	assert_false(rig.view().joinable.is_empty(), "highlighted while dragging")
	rig.up(Vector2i(1, 6))
	assert_eq(rig.view().joinable, _chain([]), "nothing highlighted after the lift")


func test_at_107_no_chain_and_no_highlight_with_the_offer_open() -> void:
	# Board D1024 has no valid move, so the no moves offer is open.
	rig = BF.rig(F.changed(F.board_d(), {Vector2i(2, 0): 1024}), 5000)
	assert_true(rig.session.is_offer_open(), "the offer is open")
	rig.drag_cells([Vector2i(0, 0), Vector2i(1, 1), Vector2i(2, 2)])
	rig.up(Vector2i(2, 2))
	assert_false(rig.session.is_dragging(), "no drag")
	assert_eq(rig.chain_events.size(), 0, "no chain")
	assert_eq(rig.view().joinable_calls, 0, "no highlight")
	assert_eq(rig.clicks(), 0, "no click")
