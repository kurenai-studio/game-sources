extends GutTest
## IF and the GOAL condition beyond the shared fixtures: the run, its trace and the messages.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const IF := "IF"
const UNTIL := "REPEAT_UNTIL"


func test_sensors_read_the_board_edge_and_walls() -> void:
	var level := IfSupport.level()
	# At (0,4) facing north: ahead (0,3) is open, left (-1,4) is off the board, right (1,4) is open.
	var program := [
		IfSupport.if_node("CLEAR_AHEAD", [{"op": M}]),
		IfSupport.if_node("CLEAR_LEFT", [{"op": L}], [{"op": R}]),
	]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["trace"][0]["node"], [0, 0])
	assert_eq(result["trace"][1]["node"], [1, 1], "left is off the board, so the else command ran")
	assert_eq(result["finalState"]["direction"], "east")


func test_a_failure_inside_an_else_branch_names_its_path() -> void:
	var level := IfSupport.level()
	level["initialState"]["position"] = [0, 3]
	var program := [IfSupport.if_node("CLEAR_AHEAD", [{"op": L}], [{"op": L}, {"op": M}])]
	var session := PlaySession.new(level)
	assert_true(session.start(program))
	while session.state == PlaySession.State.RUNNING:
		session.advance()
	# Facing the wall at (0,2): else runs, turns left, then moves west off the board.
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.failing_node(), [0, 2])


func test_until_goal_runs_to_the_goal() -> void:
	var level := IfSupport.level()
	level["initialState"] = {"position": [1, 4], "direction": "east"}
	var program := [{"op": UNTIL, "until": "GOAL", "body": [{"op": M}]}]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["reason"], "GOAL_REACHED")
	assert_eq(result["steps"], 3)


func test_until_goal_that_cannot_arrive_says_so() -> void:
	var level := IfSupport.level()
	var program := [{"op": UNTIL, "until": "GOAL", "body": [{"op": L}]}]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["reason"], "STEP_LIMIT")
	assert_eq(result["steps"], 20)
	assert_eq(
		LoopMessages.for_result(level, program, result),
		"The loop never reached the goal, so it was stopped."
	)


func test_a_round_that_runs_nothing_stops_the_run_with_its_own_message() -> void:
	var level := IfSupport.level()
	# Left of the start is off the board, so the empty else is chosen and the round does nothing.
	var program := [
		{"op": UNTIL, "until": "GOAL", "body": [IfSupport.if_node("CLEAR_LEFT", [{"op": M}])]},
	]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["reason"], "STEP_LIMIT")
	assert_eq(result["steps"], 0)
	assert_eq(
		LoopMessages.for_result(level, program, result),
		"A round of the loop did nothing, so it was stopped."
	)


func test_the_right_hand_rule_program_is_six_slots() -> void:
	var program := [
		{
			"op": UNTIL,
			"until": "GOAL",
			"body":
			[
				IfSupport.if_node("CLEAR_RIGHT", [{"op": R}]),
				IfSupport.if_node("CLEAR_AHEAD", [{"op": M}], [{"op": L}]),
			]
		}
	]
	assert_eq(ProgramSlots.count(program), 6)
	var level := IfSupport.level()
	level["constraints"]["maxCommands"] = 6
	assert_true(LevelValidator.validate_program(level, program)["ok"])


func test_executed_paths_list_the_commands_shown_so_far() -> void:
	var session := PlaySession.new(IfSupport.level())
	assert_true(
		session.start(
			[IfSupport.if_node("CLEAR_AHEAD", [{"op": M}, {"op": L}])], PlaySession.State.PAUSED
		)
	)
	session.advance()
	assert_eq(PlayView.executed_paths(session), {"0_0": true})
	session.advance()
	assert_eq(PlayView.executed_paths(session), {"0_0": true, "0_1": true})


func test_the_incomplete_if_has_its_own_message_text() -> void:
	assert_true(TapeCells.has_empty_if([IfSupport.if_node("CLEAR_AHEAD", [])]))
	assert_false(TapeCells.has_empty_if([IfSupport.if_node("CLEAR_AHEAD", [{"op": M}])]))


func test_the_game_declares_the_if_mechanic() -> void:
	assert_true(Campaign.SUPPORTED_MECHANICS.has("if"))
