extends GutTest
## PROC and CALL in the validator, the slot count and the simulator beyond the shared fixtures.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"


func test_slots_count_a_call_as_one_and_a_proc_as_one_plus_its_body() -> void:
	var program := [ProcSupport.proc("A", [{"op": M}, {"op": R}]), ProcSupport.call_node("A")]
	assert_eq(ProgramSlots.count(program), 4)
	var with_loop := [
		ProcSupport.proc("A", [{"op": "REPEAT", "count": 2, "body": [{"op": M}]}]),
	]
	assert_eq(ProgramSlots.count(with_loop), 3)


func test_a_call_runs_the_procedure_and_records_its_path() -> void:
	var level := ProcSupport.level()
	var program := [
		ProcSupport.proc("A", [{"op": M}, {"op": R}]),
		{"op": "REPEAT", "count": 2, "body": [ProcSupport.call_node("A")]},
	]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["steps"], 4)
	var trace: Array = result["trace"]
	assert_eq(trace[0]["node"], [0, 0])
	assert_eq(trace[0]["call"], [1, 0])
	assert_eq(trace[0]["round"], null, "a procedure's own top-level items have no round")
	assert_eq(trace[3]["call"], [1, 0])


func test_every_trace_entry_has_a_call_key() -> void:
	var result := LevelSimulator.simulate(ProcSupport.level(), [{"op": M}, {"op": R}])
	for entry: Dictionary in result["trace"]:
		assert_true(entry.has("call"))
		assert_eq(entry["call"], null)


func test_a_loop_inside_a_procedure_keeps_its_round() -> void:
	var program := [
		ProcSupport.proc("A", [{"op": "REPEAT", "count": 3, "body": [{"op": M}]}]),
		ProcSupport.call_node("A"),
	]
	var result := LevelSimulator.simulate(ProcSupport.level(), program)
	assert_eq(result["trace"][2]["node"], [0, 0, 0])
	assert_eq(result["trace"][2]["round"], 3)
	assert_eq(result["trace"][2]["call"], [1])


func test_a_call_to_a_missing_name_stops_the_run() -> void:
	var result := LevelSimulator.simulate(ProcSupport.level(), [ProcSupport.call_node("B")])
	assert_eq(result["reason"], "INVALID_INSTRUCTION")


func test_a_call_inside_a_procedure_stops_the_run() -> void:
	var program := [
		ProcSupport.proc("A", [{"op": M}]),
		ProcSupport.proc("B", [ProcSupport.call_node("A")]),
	]
	var result := LevelSimulator.simulate(ProcSupport.level(), program)
	assert_eq(result["reason"], "INVALID_INSTRUCTION")


func test_the_first_well_formed_definition_of_a_name_is_run() -> void:
	var program := [
		ProcSupport.proc("A", [{"op": "SPIN"}]),
		ProcSupport.proc("A", [{"op": M}]),
		ProcSupport.call_node("A"),
	]
	# The first definition is malformed, so reaching it in order stops the run.
	assert_eq(
		LevelSimulator.simulate(ProcSupport.level(), program)["reason"], "INVALID_INSTRUCTION"
	)
	var ok := [
		ProcSupport.proc("A", [{"op": M}]),
		ProcSupport.proc("A", [{"op": R}]),
		ProcSupport.call_node("A"),
	]
	var result := LevelSimulator.simulate(ProcSupport.level(), ok)
	assert_eq(result["trace"][0]["op"], M)


func test_a_failure_inside_a_procedure_names_the_primitive_there() -> void:
	var level := ProcSupport.level()
	var program := [ProcSupport.proc("A", [{"op": L}, {"op": M}]), ProcSupport.call_node("A")]
	var session := PlaySession.new(level)
	assert_true(session.start(program))
	while session.state == PlaySession.State.RUNNING:
		session.advance()
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.failing_node(), [0, 1])


func test_issue_codes_for_misplaced_and_undefined_procedures() -> void:
	var level := ProcSupport.level()
	var nested := [ProcSupport.proc("A", [ProcSupport.proc("B", [{"op": M}])])]
	assert_has(
		ProcSupport.pairs(LevelValidator.validate_program(level, nested)),
		"program[0].body[0].op|NESTED_PROC"
	)
	var inside := [
		ProcSupport.proc("A", [{"op": M}]), ProcSupport.proc("B", [ProcSupport.call_node("A")])
	]
	assert_has(
		ProcSupport.pairs(LevelValidator.validate_program(level, inside)),
		"program[1].body[0].op|CALL_NOT_ALLOWED"
	)
	var twice := [ProcSupport.proc("A", [{"op": M}]), ProcSupport.proc("A", [{"op": M}])]
	assert_has(
		ProcSupport.pairs(LevelValidator.validate_program(level, twice)),
		"program[1].name|DUPLICATE_PROCEDURE"
	)
	var missing := [ProcSupport.call_node("C")]
	assert_has(
		ProcSupport.pairs(LevelValidator.validate_program(level, missing)),
		"program[0].name|UNDEFINED_PROCEDURE"
	)


func test_proc_must_be_offered_for_both_nodes() -> void:
	var level := ProcSupport.level()
	level["availableCommands"] = [M, R]
	var program := [ProcSupport.proc("A", [{"op": M}]), ProcSupport.call_node("A")]
	var got := ProcSupport.pairs(LevelValidator.validate_program(level, program))
	assert_has(got, "program[0].op|COMMAND_NOT_AVAILABLE")
	assert_has(got, "program[1].op|COMMAND_NOT_AVAILABLE")


func test_a_level_may_offer_seven_commands_and_the_mechanic_is_supported() -> void:
	var level := ProcSupport.level()
	level["availableCommands"] = [M, L, R, "REPEAT", "REPEAT_UNTIL", "IF", "PROC"]
	assert_true(LevelValidator.validate_level(level)["ok"])
	assert_true(Campaign.SUPPORTED_MECHANICS.has("procedures"))
