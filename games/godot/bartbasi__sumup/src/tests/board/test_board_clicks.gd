extends "res://tests/base_test.gd"
## The board's half of the click triggers (GDD 16, D-36, AT-98): the board
## asks the AudioService for a click on every tile added, including the
## first, and once per accepted commit. Never on backtrack, cancel or
## boosters. The audio tests prove that a request makes no sound with sound
## off; the board asks the same either way (TH20 counts every request).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")

var rig: BF.Rig = null


func after_each() -> void:
	if rig != null:
		rig.free_all()


## AT-98 (a) on Board P: drag 2, 2, 4, backtrack off the 4, onto the 4 again, lift.
func _drag_a() -> void:
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 6), Vector2i(3, 6)])
	rig.up(Vector2i(3, 6))


func test_at_98_a_drag_backtrack_rejoin_and_lift_clicks_five_times() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)])
	assert_eq(rig.clicks(), 3, "first 2, second 2, the 4")
	rig.move(Vector2i(2, 6))
	assert_eq(rig.clicks(), 3, "none for the backtrack")
	rig.move(Vector2i(3, 6))
	assert_eq(rig.clicks(), 4, "the 4 again")
	rig.up(Vector2i(3, 6))
	assert_eq(rig.clicks(), 5, "the commit")
	assert_eq(rig.score(), 8, "the chain committed")


func test_at_98_b_touching_one_tile_and_lifting_clicks_once() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.tap(Vector2i(1, 6))
	assert_eq(rig.clicks(), 1, "the first tile only; the cancel is silent")


func test_at_98_c_shuffle_makes_no_click() -> void:
	rig = BF.rig(F.board_p(), 5000)
	rig.session.press_booster(BoosterRules.SHUFFLE)
	assert_eq(rig.view().rearranges.size(), 1, "the Shuffle was shown")
	assert_eq(rig.clicks(), 0, "no click")


func test_at_98_d_the_board_asks_the_same_with_sound_off() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.audio.set_enabled(false)
	_drag_a()
	assert_eq(rig.clicks(), 5, "five requests, which the audio service keeps silent")
	assert_false(rig.audio.is_enabled(), "sound stays off")


func test_no_click_for_a_drag_cancelled_by_pause() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	rig.board.cancel_drag()
	assert_eq(rig.clicks(), 2, "the two tiles only")


func test_no_click_for_tiles_that_do_not_join() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(1, 5), Vector2i(1, 7)])
	assert_eq(rig.clicks(), 1, "the 4 and the 8 do not join")


func test_no_click_for_every_booster() -> void:
	rig = BF.rig(F.board_p(), 100000)
	rig.session.press_booster(BoosterRules.HAMMER)
	rig.tap(Vector2i(0, 0))
	rig.session.press_booster(BoosterRules.SWAP)
	rig.tap(Vector2i(0, 1))
	rig.tap(Vector2i(2, 7))
	rig.session.press_booster(BoosterRules.DOUBLE)
	rig.tap(Vector2i(4, 4))
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	var clicks_after_chain: int = rig.clicks()
	rig.session.press_booster(BoosterRules.UNDO)
	assert_eq(rig.view().rearranges.size(), 1, "the Undo was shown")
	assert_eq(clicks_after_chain, 3, "only the chain clicked: two tiles and the commit")
	assert_eq(rig.clicks(), clicks_after_chain, "Undo is silent")
