extends GutTest
## The tape on the later mechanics: the counter in a loop count, loops in loops, and else-if
## chains. Pure data, no screen.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const REPEAT := "REPEAT"
const IF := "IF"


func _tape(nested: bool = true, commands: Array[String] = WorldSupport.ALL) -> TapeModel:
	return TapeModel.new(30, commands, nested)


func test_a_count_moves_from_11_to_n_only_when_inc_is_offered() -> void:
	var tape := _tape()
	tape.append(REPEAT)
	assert_eq(tape.count_values().size(), 11, "2 to 11 and N")
	tape.adjust_count(20)
	assert_eq(tape.program()[0]["count"], "N")
	assert_eq(tape.cells()[0]["count"], "N")
	assert_false(tape.adjust_count(1), "N is the last value")
	tape.adjust_count(-1)
	assert_eq(tape.program()[0]["count"], 11)
	var plain := _tape(false, ["MOVE_FORWARD", "REPEAT"])
	plain.append(REPEAT)
	plain.adjust_count(20)
	assert_eq(plain.program()[0]["count"], 11, "no N without INC")


func test_a_counter_program_validates_and_runs() -> void:
	var tape := _tape()
	tape.append("INC")
	tape.append("INC")
	tape.append(REPEAT)
	tape.adjust_count(20)
	tape.append(M)
	tape.end_loop()
	var level := WorldSupport.level()
	assert_true(LevelValidator.validate_program(level, tape.program())["ok"])
	var result := LevelSimulator.simulate(level, tape.program())
	assert_eq(result["finalState"]["position"], [3, 0], "N is 3 after two INC")
	assert_eq(result["trace"].back()["counter"], 3)


func test_a_loop_can_be_opened_inside_a_loop_only_when_the_level_allows_it() -> void:
	var tape := _tape()
	tape.append(REPEAT)
	assert_true(tape.can_append(REPEAT))
	assert_true(tape.can_append("REPEAT_UNTIL"))
	tape.append(REPEAT)
	assert_eq(tape.open_loop_path(), [0, 0], "the inner loop is the open one")
	assert_false(tape.can_append(REPEAT), "two levels at most")
	tape.append(M)
	assert_true(tape.end_loop(), "closes the inner loop")
	assert_eq(tape.open_loop_path(), [0], "the outer loop is open again")
	tape.append(L)
	assert_true(tape.end_loop())
	assert_eq(tape.open_chain(), [] as Array[Array])
	assert_eq(
		tape.program(), [{"op": REPEAT, "count": 2, "body": [_loop(2, [M]), {"op": L}]}] as Array
	)
	var strict := _tape(false)
	strict.append(REPEAT)
	assert_false(strict.can_append(REPEAT), "no loop in a loop without nested_loops")


func _loop(count: int, ops: Array) -> Dictionary:
	var body: Array = []
	for op: String in ops:
		body.append({"op": op})
	return {"op": REPEAT, "count": count, "body": body}


func test_nested_loops_draw_two_brackets_and_count_slots() -> void:
	var tape := _tape()
	tape.append(REPEAT)
	tape.append(REPEAT)
	tape.append(M)
	tape.end_loop()
	tape.end_loop()
	assert_eq(tape.slots(), 3)
	var cells := tape.cells()
	assert_eq(cells.size(), 3)
	assert_eq(cells[0]["groups"], ["0"])
	assert_eq(cells[1]["groups"], ["0", "0_0"])
	assert_eq(cells[2]["groups"], ["0", "0_0"])
	assert_true(cells[0]["nests"])
	assert_false(cells[1]["nests"])
	var level := WorldSupport.level(WorldSupport.ALL, ["nested_loops"])
	assert_true(LevelValidator.validate_program(level, tape.program())["ok"])
	assert_eq(
		ContractSupport.pairs(
			LevelValidator.validate_program(WorldSupport.level(), tape.program())["issues"]
		),
		["program[0].body[0].op|NESTED_REPEAT"]
	)


func test_nested_cells_move_and_remove_with_their_contents() -> void:
	var tape := _tape()
	tape.append(M)
	tape.append(REPEAT)
	tape.append(REPEAT)
	tape.append(L)
	tape.end_loop()
	tape.append(R)
	tape.end_loop()
	# Cells: M, outer, inner, L, R.
	tape.toggle_select(2)
	assert_true(tape.can_move(1))
	assert_true(tape.move_selected(1))
	assert_eq(tape.program()[1]["body"][0], {"op": R})
	assert_eq(tape.cells()[tape.selected]["path"], [1, 1])
	tape.remove_selected()
	assert_eq(tape.slots(), 3)
	tape.toggle_select(1)
	tape.remove_selected()
	assert_eq(tape.slots(), 1)


func test_the_outer_round_is_counted_from_the_trace() -> void:
	var tape := _tape()
	tape.append(REPEAT)
	tape.adjust_count(1)
	tape.append(REPEAT)
	tape.append(M)
	tape.end_loop()
	tape.append(R)
	tape.end_loop()
	var level := WorldSupport.level()
	var result := LevelSimulator.simulate(level, tape.program())
	var trace: Array = result["trace"]
	var outer: Dictionary = tape.nodes[0]
	# Round 1: M M R (entries 0 to 2), round 2: M M R, round 3: M M R.
	assert_eq(LoopRounds.outer_round(trace, 1, [0], outer, false), 1)
	assert_eq(LoopRounds.outer_round(trace, 3, [0], outer, false), 1)
	assert_eq(LoopRounds.outer_round(trace, 4, [0], outer, false), 2)
	assert_eq(LoopRounds.outer_round(trace, 8, [0], outer, false), 3)
	assert_eq(LoopRounds.outer_round(trace, 0, [0], outer, false), 0)


func _chain(tape: TapeModel) -> void:
	tape.append(IF)
	tape.append(M)
	tape.start_else()
	assert_true(tape.start_else_if())


func test_an_else_if_chain_is_built_and_closed_as_one() -> void:
	var tape := _tape()
	_chain(tape)
	assert_eq(tape.open_if()["op"], IF)
	assert_eq(tape.open_branch(), "then", "the new IF starts on its then branch")
	tape.append(L)
	assert_true(tape.start_else())
	tape.append(R)
	assert_true(tape.end_if(), "ends the innermost IF and the chain that leads to it")
	assert_eq(tape.open_chain(), [] as Array[Array])
	var expected := IfSupport.if_node(
		"CLEAR_AHEAD", [{"op": M}], [IfSupport.if_node("CLEAR_AHEAD", [{"op": L}], [{"op": R}])]
	)
	assert_eq(tape.program(), [expected])
	assert_eq(tape.slots(), 5, "1 + then 1 + (1 + then 1 + else 1)")
	assert_true(LevelValidator.validate_program(WorldSupport.level(), tape.program())["ok"])


func test_the_chain_cells_share_one_bracket_and_the_else_if_header_leads_the_else() -> void:
	var tape := _tape()
	_chain(tape)
	tape.append(L)
	tape.end_if()
	var cells := tape.cells()
	var kinds: Array[String] = []
	for cell in cells:
		kinds.append(String(cell["kind"]))
	assert_eq(kinds, ["if", "op", "if", "op"], "no ELSE divider in front of an ELSE IF")
	assert_false(cells[0].has("elseif"))
	assert_true(cells[2]["elseif"])
	assert_eq(cells[2]["groups"], cells[0]["groups"], "one bracket")
	assert_eq(cells[2]["path"], [0, 1])
	assert_eq(cells[3]["path"], [0, 1, 0], "the trace path goes into the nested IF")
	var level := WorldSupport.level()
	var result := LevelSimulator.simulate(level, tape.program())
	assert_eq(result["trace"][0]["node"], [0, 0])
	assert_eq(cells[tape.cell_for_node([0, 0])]["op"], M)


func test_the_chain_cells_can_be_selected_cycled_and_removed() -> void:
	var tape := _tape()
	_chain(tape)
	tape.append(L)
	tape.end_if()
	tape.toggle_select(2)
	assert_eq(tape.selected_kind(), "if")
	assert_true(tape.cycle_condition())
	assert_eq(tape.program()[0]["else"][0]["when"], "CLEAR_LEFT")
	assert_eq(tape.slots(), 4)
	tape.remove_selected()
	assert_eq(tape.slots(), 2, "removing the ELSE IF removes what it holds")
	assert_eq(tape.program()[0]["else"], [])


func test_else_if_needs_room_and_an_empty_else() -> void:
	var tape := _tape()
	tape.append(IF)
	assert_false(tape.can_start_else_if(), "the then branch is empty")
	tape.append(M)
	assert_false(tape.can_start_else_if(), "still on the then branch")
	tape.start_else()
	tape.append(M)
	assert_false(tape.can_start_else_if(), "an else with actions cannot hold an IF")
	var chain := _tape()
	chain.append(IF)
	for k in ContractLimits.IF_CHAIN_MAX - 1:
		chain.append(M)
		chain.start_else()
		assert_true(chain.start_else_if(), "IF %d" % (k + 2))
	chain.append(M)
	chain.start_else()
	assert_false(chain.start_else_if(), "six IFs is the most")
	assert_true(chain.end_if())
	assert_true(LevelValidator.validate_program(WorldSupport.level(), chain.program())["ok"])


func test_sensor_options_follow_mark() -> void:
	var tape := _tape()
	assert_eq(tape.sensor_options().size(), 9)
	var plain := _tape(false, ["MOVE_FORWARD", "IF"])
	assert_eq(plain.sensor_options(), ["CLEAR_AHEAD", "CLEAR_LEFT", "CLEAR_RIGHT"] as Array[String])
	tape.append(IF)
	tape.append(M)
	tape.end_if()
	tape.toggle_select(0)
	var seen: Array[String] = []
	for k in 9:
		tape.cycle_condition()
		seen.append(tape.program()[0]["when"])
	assert_eq(seen[2], "FRESH_AHEAD", "after the clear ones come the fresh ones")
	assert_eq(seen[5], "BACK_AHEAD")
	assert_eq(seen[8], "CLEAR_AHEAD", "and round again")


func test_marks_and_inc_are_actions_everywhere() -> void:
	var tape := _tape()
	tape.append("PROC")
	tape.append("MARK")
	tape.append(REPEAT)
	tape.append("INC")
	tape.end_loop()
	tape.end_proc()
	tape.append(IF)
	tape.append("MARK")
	tape.end_if()
	assert_true(LevelValidator.validate_program(WorldSupport.level(), tape.program())["ok"])
