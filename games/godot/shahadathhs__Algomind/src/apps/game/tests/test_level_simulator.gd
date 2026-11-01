extends GutTest
## Edge cases of the simulator beyond the shared fixtures.

const MOVE := "MOVE_FORWARD"
const LEFT := "TURN_LEFT"
const RIGHT := "TURN_RIGHT"


func _run(level: Dictionary, ops: Array) -> Dictionary:
	return LevelSimulator.simulate(level, ContractSupport.program_of(ops))


func test_reaching_the_goal_succeeds() -> void:
	# Start (0,4) facing north, goal (4,0): up 4, turn right, east 4.
	var ops: Array = [MOVE, MOVE, MOVE, MOVE, RIGHT, MOVE, MOVE, MOVE, MOVE]
	var result := _run(ContractSupport.base_level(), ops)
	assert_eq(result["status"], "SUCCEEDED")
	assert_eq(result["reason"], "GOAL_REACHED")
	assert_eq(result["steps"], 9)
	assert_eq(result["blockedCell"], null)
	assert_eq(result["trace"][8]["event"], "GOAL_REACHED")


func test_instructions_after_the_goal_are_ignored() -> void:
	var ops: Array = [MOVE, MOVE, MOVE, MOVE, RIGHT, MOVE, MOVE, MOVE, MOVE, "JUMP", MOVE]
	var result := _run(ContractSupport.base_level(), ops)
	assert_eq(result["reason"], "GOAL_REACHED")
	assert_eq(result["steps"], 9)


func test_results_hold_ints_even_though_the_level_holds_floats() -> void:
	var result := _run(ContractSupport.base_level(), [MOVE, MOVE])
	assert_eq(typeof(result["finalState"]["position"][0]), TYPE_INT)
	assert_eq(typeof(result["trace"][0]["position"][1]), TYPE_INT)
	assert_eq(result["finalState"]["position"], [0, 2])


func test_boundary_block_reports_the_off_board_cell() -> void:
	var level := ContractSupport.base_level()
	var result := _run(level, [LEFT, MOVE])
	assert_eq(result["reason"], "BLOCKED_BY_BOUNDARY")
	assert_eq(result["blockedCell"], [-1, 4])
	assert_eq(result["steps"], 2)
	assert_eq(result["finalState"]["position"], [0, 4])
	assert_eq(result["finalState"]["direction"], "west")
	assert_eq(result["trace"][1]["event"], "BLOCKED_BY_BOUNDARY")


func test_wall_block_counts_as_a_step() -> void:
	var level := ContractSupport.base_level()
	level["initialState"]["position"] = [0, 1]
	level["initialState"]["direction"] = "east"
	var result := _run(level, [MOVE])
	assert_eq(result["reason"], "BLOCKED_BY_WALL")
	assert_eq(result["blockedCell"], [1, 1])
	assert_eq(result["steps"], 1)


func test_step_limit_is_checked_before_the_instruction() -> void:
	var level := ContractSupport.base_level()
	level["constraints"]["maxSteps"] = 2
	var result := _run(level, [LEFT, RIGHT, LEFT])
	assert_eq(result["reason"], "STEP_LIMIT")
	assert_eq(result["steps"], 2)
	var exact := _run(level, [LEFT, RIGHT])
	assert_eq(exact["reason"], "PROGRAM_ENDED")
	var invalid_after_limit := _run(level, [LEFT, RIGHT, "JUMP"])
	assert_eq(invalid_after_limit["reason"], "STEP_LIMIT")


func test_invalid_instructions_stop_the_run_uncounted() -> void:
	var level := ContractSupport.base_level()
	for bad: Variant in [{"op": "JUMP"}, {"op": 3}, {}, null, "MOVE_FORWARD", [MOVE]]:
		var result := LevelSimulator.simulate(level, [{"op": LEFT}, bad, {"op": MOVE}])
		assert_eq(result["reason"], "INVALID_INSTRUCTION", str(bad))
		assert_eq(result["steps"], 1)


func test_empty_program_ends_with_zero_steps() -> void:
	var result := LevelSimulator.simulate(ContractSupport.base_level(), [])
	assert_eq(result["reason"], "PROGRAM_ENDED")
	assert_eq(result["steps"], 0)
	assert_eq(result["trace"], [])
	assert_eq(result["finalState"]["position"], [0, 4])
	assert_eq(result["finalState"]["direction"], "north")


func test_turns_wrap_in_both_directions() -> void:
	assert_eq(LevelSimulator.turn("north", "left"), "west")
	assert_eq(LevelSimulator.turn("west", "left"), "south")
	assert_eq(LevelSimulator.turn("south", "left"), "east")
	assert_eq(LevelSimulator.turn("east", "left"), "north")
	assert_eq(LevelSimulator.turn("north", "right"), "east")
	assert_eq(LevelSimulator.turn("west", "right"), "north")


func test_commands_not_offered_by_the_level_still_run() -> void:
	var level := ContractSupport.base_level()
	level["availableCommands"] = ["TURN_LEFT"]
	var result := _run(level, [MOVE])
	assert_eq(result["steps"], 1)
	assert_eq(result["finalState"]["position"], [0, 3])


func test_simulate_does_not_modify_its_inputs_and_is_repeatable() -> void:
	var level := ContractSupport.base_level()
	var program := ContractSupport.program_of([MOVE, LEFT, MOVE, "JUMP"])
	var level_before := level.duplicate(true)
	var program_before := program.duplicate(true)
	var first := LevelSimulator.simulate(level, program)
	var second := LevelSimulator.simulate(level, program)
	assert_true(ContractSupport.same(level, level_before))
	assert_true(ContractSupport.same(program, program_before))
	assert_true(ContractSupport.same(first, second))
	first["finalState"]["position"][0] = 99
	assert_eq(LevelSimulator.simulate(level, program)["finalState"]["position"][0], 0)
