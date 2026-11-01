extends GutTest
## Player-facing text for run results.


func test_every_reason_has_the_documented_text() -> void:
	assert_eq(ResultMessages.for_reason("GOAL_REACHED"), "Level solved.")
	assert_eq(
		ResultMessages.for_reason("BLOCKED_BY_WALL"), "The automaton tried to move into a wall."
	)
	assert_eq(
		ResultMessages.for_reason("BLOCKED_BY_BOUNDARY"),
		"The automaton tried to move off the board."
	)
	assert_eq(ResultMessages.for_reason("PROGRAM_ENDED"), "The program ended before the goal.")
	assert_eq(ResultMessages.for_reason("STEP_LIMIT"), "The program ran too long and was stopped.")
	assert_eq(
		ResultMessages.for_reason("INVALID_INSTRUCTION"),
		"The program contains an instruction this level cannot run."
	)


func test_every_simulator_reason_is_covered() -> void:
	for reason: String in [
		"GOAL_REACHED",
		"BLOCKED_BY_WALL",
		"BLOCKED_BY_BOUNDARY",
		"PROGRAM_ENDED",
		"STEP_LIMIT",
		"INVALID_INSTRUCTION"
	]:
		assert_ne(ResultMessages.for_reason(reason), "", reason)


func test_unknown_input_gives_an_empty_string() -> void:
	assert_eq(ResultMessages.for_reason("NOPE"), "")
	assert_eq(ResultMessages.for_reason(null), "")
	assert_eq(ResultMessages.for_reason(3), "")
	assert_eq(ResultMessages.for_result(null), "")


func test_for_result_reads_the_reason() -> void:
	var result := LevelSimulator.simulate(ContractSupport.base_level(), [])
	assert_eq(ResultMessages.for_result(result), "The program ended before the goal.")
