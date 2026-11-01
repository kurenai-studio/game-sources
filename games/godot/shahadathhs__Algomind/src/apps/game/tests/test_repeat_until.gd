extends GutTest
## REPEAT_UNTIL beyond the shared fixtures: editing on the tape, the run state, and the message.

const ALL: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL"]
const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const UNTIL := "REPEAT_UNTIL"


func _level() -> Dictionary:
	# 5x5, start (0,4) facing north, wall at (0,2), goal at (4,4).
	return {
		"schemaVersion": 1,
		"levelId": "t",
		"levelVersion": 1,
		"slug": "t",
		"title": "T",
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": []},
		"board": {"width": 5, "height": 5, "walls": [[0, 2]]},
		"initialState": {"position": [0, 4], "direction": "north"},
		"availableCommands": ALL,
		"constraints": {"maxCommands": 8, "maxSteps": 20},
		"goal": {"type": "reach_tile", "position": [4, 4]},
		"hints": [],
	}


func _until(body: Array) -> Dictionary:
	return {"op": UNTIL, "until": "BLOCKED", "body": body}


func _tape(limit: int = 12) -> TapeModel:
	return TapeModel.new(limit, ALL)


func test_a_new_until_loop_is_open_and_empty_with_nothing_selected() -> void:
	var tape := _tape()
	assert_true(tape.append(UNTIL))
	assert_eq(tape.program(), [_until([])])
	assert_eq(tape.open_loop(), 0)
	assert_eq(PlayView.open_op(tape), UNTIL)
	assert_eq(tape.selected, -1)
	assert_true(tape.has_empty_loop())
	assert_false(tape.can_end_loop())


func test_commands_go_into_the_until_loop_until_it_is_ended() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	tape.append(M)
	tape.append(R)
	assert_true(tape.end_loop())
	tape.append(M)
	assert_eq(tape.program(), [_until([{"op": M}, {"op": R}]), {"op": M}])
	assert_eq(PlayView.open_op(tape), "")


func test_slots_are_one_plus_the_body() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	tape.append(M)
	tape.append(L)
	tape.end_loop()
	assert_eq(tape.slots(), 3)


func test_only_one_loop_is_open_at_a_time_of_either_kind() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	assert_false(tape.can_append("REPEAT"))
	assert_false(tape.can_append(UNTIL))
	tape.append(M)
	tape.end_loop()
	tape.append("REPEAT")
	assert_false(tape.can_append(UNTIL))


func test_until_is_refused_when_the_level_does_not_offer_it() -> void:
	var tape := TapeModel.new(8, ["MOVE_FORWARD"] as Array[String])
	assert_false(tape.append(UNTIL))


func test_cells_have_an_until_header_and_no_count() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	tape.append(M)
	tape.end_loop()
	var cells := tape.cells()
	assert_eq(cells.size(), 2)
	assert_eq(cells[0]["kind"], "until")
	assert_eq(cells[0]["body"], 1)
	assert_true(TapeHeaders.is_header(cells[0]))
	assert_false(TapeHeaders.is_header(cells[1]))
	assert_false(cells[0].has("count"))


func test_the_header_has_no_rounds_to_change() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	tape.append(M)
	tape.end_loop()
	tape.toggle_select(0)
	assert_false(tape.selected_is_count())
	assert_false(tape.adjust_count(1))


func test_removing_the_header_removes_the_whole_loop_and_closes_it() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	tape.append(M)
	tape.toggle_select(0)
	assert_true(tape.remove_selected())
	assert_true(tape.is_empty())
	assert_eq(tape.open_loop(), -1)


func test_moving_an_until_loop_moves_its_body_with_it() -> void:
	var tape := _tape()
	tape.append(M)
	tape.append(UNTIL)
	tape.append(L)
	tape.end_loop()
	tape.toggle_select(1)
	assert_true(tape.move_selected(-1))
	assert_eq(tape.program(), [_until([{"op": L}]), {"op": M}])


func test_the_tape_program_validates_and_runs() -> void:
	var tape := _tape(4)
	tape.append(UNTIL)
	tape.append(M)
	tape.end_loop()
	var level := _level()
	assert_true(LevelValidator.validate_program(level, tape.program())["ok"])
	var result := LevelSimulator.simulate(level, tape.program())
	assert_eq(result["reason"], "PROGRAM_ENDED")
	assert_eq(result["finalState"]["position"], [0, 3])
	assert_eq(result["steps"], 1)


func test_an_empty_until_loop_fails_program_validation() -> void:
	var tape := _tape()
	tape.append(UNTIL)
	assert_false(LevelValidator.validate_program(_level(), tape.program())["ok"])


func test_a_blocked_start_runs_the_body_zero_times() -> void:
	var level := _level()
	level["initialState"]["position"] = [0, 3]
	var result := LevelSimulator.simulate(level, [_until([{"op": M}])])
	assert_eq(result["steps"], 0)
	assert_eq(result["reason"], "PROGRAM_ENDED")


func test_blocked_ahead_sees_walls_and_the_edge() -> void:
	var level := _level()
	assert_false(LevelSimulator.blocked_ahead(level, [0, 4], "north"))
	assert_true(LevelSimulator.blocked_ahead(level, [0, 3], "north"))
	assert_true(LevelSimulator.blocked_ahead(level, [0, 0], "north"))
	assert_true(LevelSimulator.blocked_ahead(level, [0, 4], "west"))


func test_a_failure_inside_the_body_names_the_node_and_the_round() -> void:
	# Round 1: the first move reaches (0,3), the second hits the wall at (0,2).
	var session := PlaySession.new(_level())
	assert_true(session.start([_until([{"op": M}, {"op": M}])]))
	while session.state == PlaySession.State.RUNNING:
		session.advance()
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.failing_node(), [0, 1])
	assert_eq(session.current_entry()["round"], 1)


func test_a_never_blocked_loop_has_its_own_step_limit_message() -> void:
	var level := _level()
	# Four turns bring it back to face north, so the way ahead is open again every round.
	var program := [_until([{"op": L}, {"op": L}, {"op": L}, {"op": L}])]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["reason"], "STEP_LIMIT")
	assert_eq(
		LoopMessages.for_result(level, program, result),
		"The loop never reached a wall, so it was stopped."
	)


func test_other_results_keep_the_standard_text() -> void:
	var level := _level()
	var program := [_until([{"op": M}])]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(LoopMessages.for_result(level, program, result), "")
	var plain := [{"op": L}, {"op": L}, {"op": L}, {"op": L}, {"op": L}]
	level["constraints"]["maxSteps"] = 3
	var limited := LevelSimulator.simulate(level, plain)
	assert_eq(limited["reason"], "STEP_LIMIT")
	assert_eq(LoopMessages.for_result(level, plain, limited), "")
