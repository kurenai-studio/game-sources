extends "res://tests/base_test.gd"
## The run's score through the board (docs/ARCHITECTURE.md section 17, GDD
## D-37). The board builds chains with the run's real score, so joining, the
## highlight and the commit always measure the same thing. Bart's stuck run
## (2026-10-21) now plays, and near the far ceiling a chain the commit would
## refuse never joins or lights up.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")
## Bart's score on 2026-10-21, when every chain was refused.
const BART_SCORE: String = "9221253119629040934"

var rig: BF.Rig = null


func after_each() -> void:
	if rig != null:
		rig.free_all()


func _n(text: String) -> BigNum:
	return BigNum.parse(text, 100)


## The ceiling less five: a pair of 2s (4 points) still fits, a pair of 4s
## (8 points) or any longer chain of 2s does not.
func _near_ceiling() -> BigNum:
	return BigNum.pow2(GameConfig.new().max_score_bits).sub(BigNum.from_int(5))


func test_bart_board_two_touching_50s_commit_through_the_board() -> void:
	rig = BF.rig_big(F.bart_board(), _n(BART_SCORE))
	assert_true(rig.session.phase() == GameSession.Phase.PLAYING, "Bart's run is playable, no offer")
	rig.down(Vector2i(1, 0))
	assert_true(rig.view().joinable.has(Vector2i(2, 1)), "the touching 50 is highlighted")
	rig.move(Vector2i(2, 1))
	assert_eq(rig.last_chain(), BF.cells([Vector2i(1, 0), Vector2i(2, 1)]), "the second 50 joins")
	assert_eq(rig.view().preview, 51, "preview 2^51")
	rig.up(Vector2i(2, 1))
	assert_eq(rig.clicks(), 3, "two joins and the accepted commit click")
	assert_eq(rig.view().merges, [[BF.cells([Vector2i(1, 0), Vector2i(2, 1)]), Vector2i(2, 1), 51]], "the merge played")
	assert_eq(rig.session.state.score.to_decimal(), _n(BART_SCORE).add(BigNum.pow2(51)).to_decimal(), "score past 2^63")
	assert_eq(rig.session.state.score.to_decimal(), "9223504919442726182", "exactly")
	assert_eq(rig.session.state.value_at(Vector2i(2, 1)), 51, "the 2^51 sits on the last tile")
	assert_false(rig.session.is_waiting_for_view(), "the move was shown")


func test_near_the_ceiling_a_pair_that_would_not_fit_is_neither_highlighted_nor_committed() -> void:
	rig = BF.rig_big(F.board_p(), _near_ceiling())
	assert_true(rig.session.phase() == GameSession.Phase.PLAYING, "pairs of 2s still fit, so no offer")
	var before: RunState = rig.session.state.copy()
	var fours: Array[Vector2i] = BF.cells([Vector2i(1, 5), Vector2i(1, 4)])
	assert_false(CoreRules.is_valid_chain(before.cells, before.score, fours, rig.session.config), "core refuses 4, 4 at this score")
	rig.down(Vector2i(1, 5))
	assert_eq(rig.view().joinable, BF.cells([]), "nothing is highlighted from the 4")
	assert_eq(rig.session.joinable_cells(BF.cells([Vector2i(1, 5)])), BF.cells([]), "the session agrees")
	rig.move(Vector2i(1, 4))
	assert_eq(rig.last_chain(), BF.cells([Vector2i(1, 5)]), "the touching 4 does not join")
	rig.up(Vector2i(1, 4))
	assert_true(rig.session.state.equals(before), "nothing committed: board and score unchanged")
	assert_eq(rig.view().merges.size(), 0, "no merge played")
	assert_false(rig.session.is_dragging(), "the drag is closed")
	assert_eq(rig.clicks(), 1, "only the first tile clicked")


func test_near_the_ceiling_the_highlight_shows_exactly_what_commits() -> void:
	rig = BF.rig_big(F.board_p(), _near_ceiling())
	rig.down(Vector2i(1, 6))
	assert_eq(rig.view().joinable, BF.cells([Vector2i(0, 6), Vector2i(2, 6)]), "the 2s next to the 2 still fit")
	rig.move(Vector2i(2, 6))
	assert_eq(rig.view().joinable, BF.cells([]), "a third tile would pass the ceiling, so nothing lights up")
	rig.move(Vector2i(3, 6))
	assert_eq(rig.last_chain(), BF.cells([Vector2i(1, 6), Vector2i(2, 6)]), "and the 4 does not join")
	rig.up(Vector2i(3, 6))
	assert_eq(rig.view().merges.size(), 1, "the pair of 2s commits")
	assert_eq(rig.session.state.score.to_decimal(), _near_ceiling().add(BigNum.from_int(4)).to_decimal(), "4 points, one below the ceiling")
