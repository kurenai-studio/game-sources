extends GutTest
## The tape view and the board view on the later mechanics: nested brackets, an else-if chain in
## one bracket, the N count tile, breadcrumbs and the sweep board. Drawing is exercised headless;
## how it looks is not checked here.

const M := "MOVE_FORWARD"
const R := "TURN_RIGHT"


func _view(tape: TapeModel, height: float = 112.0) -> TapeView:
	var view := TapeView.new()
	view.size = Vector2(360.0, height)
	add_child_autofree(view)
	view.set_content(tape.cells(), tape.slots(), tape.limit, tape.selected, tape.open_keys())
	return view


func _nested_tape() -> TapeModel:
	var tape := TapeModel.new(30, WorldSupport.ALL, true)
	tape.append("REPEAT")
	tape.adjust_count(20)
	tape.append("REPEAT")
	tape.append(M)
	tape.end_loop()
	tape.append(R)
	tape.end_loop()
	return tape


func _chain_tape() -> TapeModel:
	var tape := TapeModel.new(30, WorldSupport.ALL, true)
	tape.append("IF")
	tape.append(M)
	tape.start_else()
	tape.start_else_if()
	tape.append(R)
	tape.start_else()
	tape.append("MARK")
	tape.end_if()
	return tape


func test_nested_loops_get_nested_brackets() -> void:
	var view := _view(_nested_tape())
	assert_eq(view._groups.size(), 2)
	var inner: Rect2 = view._groups[0]
	var outer: Rect2 = view._groups[1]
	assert_true(outer.encloses(inner))
	assert_eq(view.cells[0]["count"], "N")


func test_the_open_inner_loop_holds_the_slot() -> void:
	var tape := TapeModel.new(30, WorldSupport.ALL, true)
	tape.append("REPEAT")
	tape.append("REPEAT")
	tape.append(M)
	var view := _view(tape)
	assert_true(view._groups[0].encloses(view._slot), "the slot is in the inner bracket")
	assert_true(view._group_dashed[0], "the inner bracket is the open one")
	assert_false(view._group_dashed[1], "the outer one is not the one being filled")


func test_an_else_if_chain_is_one_bracket_with_no_divider_before_the_else_if() -> void:
	var tape := _chain_tape()
	var view := _view(tape)
	assert_eq(view._groups.size(), 1)
	var kinds: Array[String] = []
	for cell in view.cells:
		kinds.append(String(cell["kind"]))
	assert_eq(kinds, ["if", "op", "if", "op", "else", "op"])
	view.running = true
	view.current = 3
	view.executed = {"0_1_0": true}
	assert_true(view.header_passed(2), "the ELSE IF header is reached once its branch runs")
	assert_true(view.header_passed(0))


func test_every_new_tile_draws_in_both_tile_sizes() -> void:
	for height in [84.0, 112.0]:
		for tape in [_nested_tape(), _chain_tape()]:
			tape.toggle_select(0)
			var view := _view(tape, height)
			await wait_process_frames(2)
			view.running = true
			view.current = 1
			view.current_round = 2
			view.outer_rounds = {0: 3}
			view.queue_redraw()
			await wait_process_frames(2)
			assert_true(is_instance_valid(view))
		var inc := TapeModel.new(30, WorldSupport.ALL, true)
		for op in ["INC", "MARK", "IF", "INC", "END"]:
			if op == "END":
				inc.end_if()
			else:
				inc.append(op)
		var sensors := _view(inc, height)
		for sensor in ContractLimits.SENSORS:
			sensors.cells[2]["when"] = sensor
			sensors.queue_redraw()
			await wait_process_frames(1)
		assert_true(is_instance_valid(sensors))


func test_sensor_cells_name_their_family_and_side() -> void:
	assert_eq(TapeIfCells.word("BACK_LEFT"), "LEFT")
	assert_eq(TapeIfCells.family_word("BACK_LEFT"), "BACK")
	assert_eq(TapeIfCells.family_word("FRESH_RIGHT"), "NEW")
	assert_eq(TapeIfCells.family_word("CLEAR_RIGHT"), "")
	assert_eq(TapeIfCells.icon("FRESH_RIGHT"), "fresh_right")
	assert_eq(TapeIfCells.icon("CLEAR_LEFT"), "sense_left")


func test_the_board_draws_crumbs_and_a_sweep_without_a_target() -> void:
	var board := BoardView.new()
	board.size = Vector2(300, 300)
	add_child_autofree(board)
	board.set_level(WorldSupport.sweep_level())
	board.show_state(
		[1, 0],
		"east",
		[Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i],
		null,
		{Vector2i(0, 0): "west"}
	)
	await wait_process_frames(2)
	assert_eq(board.crumbs.size(), 1)
	board.set_level(WorldSupport.level())
	await wait_process_frames(2)
	assert_true(is_instance_valid(board))
