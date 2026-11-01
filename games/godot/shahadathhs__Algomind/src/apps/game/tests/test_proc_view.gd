extends GutTest
## The tape view with definitions: the layout, what a run has reached, and drawing every state.

const M := "MOVE_FORWARD"
const R := "TURN_RIGHT"


func _view(tape: TapeModel) -> TapeView:
	var view := TapeView.new()
	view.size = Vector2(360.0, 112.0)
	add_child_autofree(view)
	view.set_content(tape.cells(), tape.slots(), tape.limit, tape.selected, tape.open_keys())
	return view


func _tape_with_call() -> TapeModel:
	var tape := ProcSupport.tape(20)
	ProcSupport.define(tape, [M, R])
	tape.append("REPEAT")
	tape.append_call("A")
	tape.end_loop()
	return tape


func test_the_layout_nests_brackets_and_puts_a_divider_after_the_definitions() -> void:
	var tape := _tape_with_call()
	var view := _view(tape)
	# One bracket for the definition and one for the main loop.
	assert_eq(view._groups.size(), 2)
	assert_gt(view._divider, view._groups[0].end.x - 1.0)
	assert_lt(view._divider, view._groups[1].position.x)
	for i in view._rects.size() - 1:
		assert_lt(view._rects[i].position.x, view._rects[i + 1].position.x)


func test_a_loop_inside_a_definition_gets_a_bracket_inside_the_definition_bracket() -> void:
	var tape := ProcSupport.tape(20)
	tape.append("PROC")
	tape.append("REPEAT")
	tape.append(M)
	tape.end_loop()
	tape.end_proc()
	var view := _view(tape)
	assert_eq(view._groups.size(), 2)
	var inner: Rect2 = view._groups[0]
	var outer: Rect2 = view._groups[1]
	assert_true(outer.encloses(inner))


func test_the_dashed_slot_goes_inside_the_open_definition() -> void:
	var tape := ProcSupport.tape(20)
	ProcSupport.define(tape, [M])
	tape.append(M)
	tape.append("PROC")
	tape.append(R)
	var view := _view(tape)
	var open_group: Rect2 = view._groups.back()
	assert_true(open_group.encloses(view._slot), "the slot of an open definition is inside it")
	assert_true(view._group_dashed.back())
	assert_false(view._group_dashed[0])
	assert_true(view.append_scroll() <= view.edit_scroll())


func test_the_run_marks_the_running_call_and_the_definition_tile() -> void:
	var tape := _tape_with_call()
	var view := _view(tape)
	var result := LevelSimulator.simulate(ProcSupport.level(), tape.program())
	view.running = true
	view.set_content(tape.cells(), tape.slots(), tape.limit, -1, [])
	# After the first move of round 1, inside the procedure.
	var entry: Dictionary = result["trace"][0]
	view.executed = {"0_0": true}
	view.current = tape.cell_for_node(entry["node"])
	view.call_index = tape.cell_for_node(entry["call"])
	view.current_round = 1
	assert_eq(view.current, 1)
	assert_eq(view.call_index, 4)
	assert_true(view.header_passed(0), "the definition header is reached")
	assert_true(view.header_passed(3), "the loop that holds the running call is reached")
	assert_true(view.group_holds(3, view.call_index))
	assert_false(view.is_passed(2), "the second tile of the definition is still upcoming")
	assert_false(view.is_passed(1))
	# Later: the read-head is on the second tile; the first is passed.
	view.current = 2
	view.executed = {"0_0": true, "0_1": true}
	assert_true(view.is_passed(1))


func test_main_tiles_before_the_running_call_count_as_passed() -> void:
	var tape := ProcSupport.tape(20)
	ProcSupport.define(tape, [M])
	tape.append(M)
	tape.append_call("A")
	var view := _view(tape)
	view.running = true
	view.current = 0
	view.call_index = 3
	view.executed = {"0_0": true}
	assert_true(view.is_passed(2), "the move before the call is behind the read-head")
	assert_false(view.is_passed(3), "the running call is not passed yet")


func test_every_state_draws_without_errors() -> void:
	var tape := _tape_with_call()
	tape.toggle_select(0)
	var view := _view(tape)
	await wait_process_frames(2)
	view.running = true
	view.set_content(tape.cells(), tape.slots(), tape.limit, -1, [])
	view.current = 1
	view.call_index = 4
	view.current_round = 1
	view.failed_index = 2
	view.executed = {"0_0": true}
	view.queue_redraw()
	await wait_process_frames(2)
	view.current = 4
	view.call_index = -1
	view.queue_redraw()
	await wait_process_frames(2)
	assert_true(is_instance_valid(view))


func test_a_wide_palette_wraps_to_two_rows() -> void:
	assert_eq(PlayLayout.palette_row_count(5), 1)
	assert_eq(PlayLayout.palette_row_count(6), 1)
	assert_eq(PlayLayout.palette_row_count(7), 2)
	assert_eq(PlayLayout.palette_row_count(11), 2)
