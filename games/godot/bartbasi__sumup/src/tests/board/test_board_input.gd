extends "res://tests/base_test.gd"
## Touch and mouse through one path, the first finger only (D-08, AT-22),
## emulated mouse events ignored, booster taps during a drag (AT-23), and
## dropping a drag with no penalty (cancel_drag, AT-24).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")

var rig: BF.Rig = null


func after_each() -> void:
	if rig != null:
		rig.free_all()


func _chain(list: Array) -> Array[Vector2i]:
	return BF.cells(list)


# One finger (D-08).

func test_at_22_only_the_first_finger_counts() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	var events: int = rig.chain_events.size()
	rig.down(Vector2i(0, 6), 1)
	rig.move(Vector2i(1, 5), 1)
	rig.move(Vector2i(3, 6), 1)
	rig.up(Vector2i(3, 6), 1)
	assert_eq(rig.chain_events.size(), events, "the second finger changes nothing")
	assert_true(rig.session.is_dragging(), "the second finger's lift does not end the drag")
	assert_eq(rig.score(), 0, "nor commit it")
	rig.move(Vector2i(3, 6))
	rig.up(Vector2i(3, 6))
	assert_eq(rig.score(), 8, "the first finger goes on and commits 2, 2, 4")
	assert_eq(rig.clicks(), 4, "three tiles and the commit")


func test_the_next_finger_counts_once_the_first_lifts() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.tap(Vector2i(1, 6), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)], 3)
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6)]), "another finger starts a chain")
	rig.up(Vector2i(2, 6), 3)
	assert_eq(rig.score(), 4, "and commits it")


func test_a_finger_held_before_the_first_lifted_stays_ignored() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.down(Vector2i(1, 6), 0)
	rig.down(Vector2i(0, 6), 1)
	rig.up(Vector2i(1, 6), 0)
	var events: int = rig.chain_events.size()
	rig.move(Vector2i(1, 6), 1)
	rig.up(Vector2i(1, 6), 1)
	assert_eq(rig.chain_events.size(), events, "the second finger never took over")
	assert_eq(rig.score(), 0, "nothing committed")


func test_a_lost_lift_never_locks_the_board() -> void:
	# A new touch with the same index means the old one's lift never came.
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	rig.down(Vector2i(0, 6))
	assert_eq(rig.last_chain(), _chain([Vector2i(0, 6)]), "the old chain is dropped and a new one starts")
	assert_eq(rig.score(), 0, "the dropped chain did not commit")
	rig.move(Vector2i(1, 6))
	rig.up(Vector2i(1, 6))
	assert_eq(rig.score(), 4, "the new chain commits")


func test_a_canceled_touch_cancels_the_chain() -> void:
	rig = BF.rig(F.board_p(), 0)
	var before: RunState = rig.session.state.copy()
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)])
	var lift: InputEventScreenTouch = BF.touch(0, rig.point(Vector2i(3, 6)), false)
	lift.canceled = true
	rig.send(lift)
	assert_true(rig.session.state.equals(before), "nothing committed")
	assert_false(rig.session.is_dragging(), "the drag is closed")
	assert_eq(rig.last_chain(), _chain([]), "the chain is cleared")
	assert_eq(rig.clicks(), 3, "no commit click")


# Mouse.

func test_a_real_mouse_builds_and_commits_a_chain() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.send(BF.mouse_button(rig.point(Vector2i(1, 6)), true))
	rig.send(BF.mouse_motion(rig.point(Vector2i(2, 6))))
	rig.send(BF.mouse_motion(rig.point(Vector2i(3, 6))))
	assert_eq(rig.last_chain(), _chain([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)]), "the mouse builds the chain")
	rig.send(BF.mouse_button(rig.point(Vector2i(3, 6)), false))
	assert_eq(rig.score(), 8, "the mouse release commits")
	assert_eq(rig.clicks(), 4, "the same clicks as a finger")


func test_emulated_mouse_events_are_ignored() -> void:
	rig = BF.rig(F.board_p(), 0)
	var emulated: int = InputEvent.DEVICE_ID_EMULATION
	rig.send(BF.mouse_button(rig.point(Vector2i(1, 6)), true, emulated))
	rig.send(BF.mouse_motion(rig.point(Vector2i(2, 6)), emulated))
	rig.send(BF.mouse_button(rig.point(Vector2i(2, 6)), false, emulated))
	assert_eq(rig.chain_events.size(), 0, "no chain")
	assert_false(rig.session.is_dragging(), "no drag")
	assert_eq(rig.clicks(), 0, "no click")
	assert_eq(rig.score(), 0, "nothing committed")


func test_a_touch_and_its_emulated_mouse_twin_count_once() -> void:
	rig = BF.rig(F.board_p(), 0)
	var emulated: int = InputEvent.DEVICE_ID_EMULATION
	var a: Vector2 = rig.point(Vector2i(1, 6))
	var b: Vector2 = rig.point(Vector2i(2, 6))
	rig.down_at(a)
	rig.send(BF.mouse_button(a, true, emulated))
	rig.move_to(b)
	rig.send(BF.mouse_motion(b, emulated))
	rig.up_at(b)
	rig.send(BF.mouse_button(b, false, emulated))
	assert_eq(rig.clicks(), 3, "two tiles and one commit, each once")
	assert_eq(rig.score(), 4, "one commit")


func test_mouse_motion_without_a_press_does_nothing() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.send(BF.mouse_motion(rig.point(Vector2i(1, 6))))
	rig.send(BF.mouse_motion(rig.point(Vector2i(2, 6))))
	assert_eq(rig.chain_events.size(), 0, "hovering builds nothing")
	assert_false(rig.session.is_dragging(), "no drag")


func test_other_mouse_buttons_are_ignored() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.send(BF.mouse_button(rig.point(Vector2i(1, 6)), true, BF.REAL_DEVICE, MOUSE_BUTTON_RIGHT))
	rig.send(BF.mouse_motion(rig.point(Vector2i(2, 6))))
	assert_eq(rig.chain_events.size(), 0, "the right button builds nothing")
	assert_false(rig.session.is_dragging(), "no drag")


func test_the_board_takes_pointer_events() -> void:
	rig = BF.rig(F.board_p(), 0)
	assert_eq(rig.board.mouse_filter, Control.MOUSE_FILTER_STOP, "the board stops pointer events")


# Booster taps during a drag (D-08).

func test_at_23_booster_taps_are_ignored_during_a_drag() -> void:
	rig = BF.rig(F.board_p(), 5000)
	var before: RunState = rig.session.state.copy()
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	assert_true(rig.session.press_booster(BoosterRules.SHUFFLE) == null, "Shuffle does nothing")
	assert_true(rig.session.press_booster(BoosterRules.HAMMER) == null, "Hammer does nothing")
	assert_true(rig.session.state.equals(before), "nothing charged, nothing moved")
	assert_eq(rig.session.targeting_booster(), &"", "no targeting")
	assert_eq(rig.view().rearranges.size(), 0, "no Shuffle shown")
	rig.move(Vector2i(3, 6))
	rig.up(Vector2i(3, 6))
	assert_eq(rig.score(), 5008, "the drag goes on and commits")


# cancel_drag (13.1, 6.5).

func test_at_24_a_drag_is_cancelled_with_no_penalty() -> void:
	rig = BF.rig(F.board_p(), 1000)
	var before: RunState = rig.session.state.copy()
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6)])
	rig.board.cancel_drag()
	assert_false(rig.session.is_dragging(), "no chain in progress")
	assert_eq(rig.last_chain(), _chain([]), "chain_changed reports the cancel")
	assert_eq(rig.view().chain, _chain([]), "the view's chain is cleared")
	assert_eq(rig.view().drag_point, BF.NO_DRAG, "with no finger")
	assert_eq(rig.view_preview(), 0, "and no preview")
	assert_eq(rig.view().joinable, _chain([]), "and no highlight")
	assert_true(rig.session.state.equals(before), "board and score unchanged")
	assert_eq(rig.clicks(), 3, "no click for the cancel")
	var events: int = rig.chain_events.size()
	rig.move(Vector2i(2, 5))
	rig.up(Vector2i(2, 5))
	assert_eq(rig.chain_events.size(), events, "the finger still down does nothing more")
	assert_true(rig.session.state.equals(before), "and its lift commits nothing")
	rig.play([Vector2i(1, 6), Vector2i(2, 6)])
	assert_eq(rig.score(), 1004, "the next drag works")


func test_cancel_drag_with_no_drag_changes_nothing() -> void:
	rig = BF.rig(F.board_p(), 0)
	var before: RunState = rig.session.state.copy()
	rig.board.cancel_drag()
	assert_eq(rig.chain_events.size(), 0, "nothing to report")
	assert_true(rig.session.state.equals(before), "nothing changed")
	assert_true(rig.session.can_start_chain(), "chains can start")
