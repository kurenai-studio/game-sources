extends GutTest
## Changing, removing and moving the parts of an IF on the tape.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const IF := "IF"
const UNTIL := "REPEAT_UNTIL"


func test_the_sensor_cycles_ahead_left_right() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	tape.toggle_select(0)
	assert_eq(tape.selected_kind(), "if")
	var seen: Array[String] = []
	for i in 4:
		tape.cycle_condition()
		seen.append(tape.nodes[0]["when"])
	assert_eq(seen, ["CLEAR_LEFT", "CLEAR_RIGHT", "CLEAR_AHEAD", "CLEAR_LEFT"])


func test_the_until_condition_cycles_when_it_is_selected() -> void:
	var tape := IfSupport.tape()
	tape.append(UNTIL)
	assert_eq(tape.selected_kind(), "until", "offered IF selects the header so GOAL can be chosen")
	tape.cycle_condition()
	assert_eq(tape.nodes[0]["until"], "GOAL")
	tape.cycle_condition()
	assert_eq(tape.nodes[0]["until"], "BLOCKED")
	assert_eq(tape.cells()[0]["until"], "BLOCKED")


func test_an_else_divider_cannot_be_selected() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	tape.start_else()
	tape.toggle_select(2)
	assert_eq(tape.selected, -1)


func test_removing_the_if_header_removes_the_whole_group_and_closes_it() -> void:
	var tape := IfSupport.tape()
	tape.append(M)
	IfSupport.open_if(tape, [M])
	tape.toggle_select(1)
	assert_true(tape.remove_selected())
	assert_eq(tape.program(), [{"op": M}])
	assert_true(tape.open_if().is_empty())


func test_removing_a_command_of_a_branch_keeps_the_group() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M, L])
	tape.end_if()
	tape.toggle_select(2)
	assert_true(tape.remove_selected())
	assert_eq(tape.program(), [IfSupport.if_node("CLEAR_AHEAD", [{"op": M}])])


func test_removing_the_last_then_command_makes_the_tape_incomplete() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	tape.end_if()
	tape.toggle_select(1)
	tape.remove_selected()
	assert_true(tape.is_incomplete())


func test_moving_an_if_moves_it_with_its_commands() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [L])
	tape.start_else()
	tape.append(R)
	tape.end_if()
	tape.append(M)
	tape.toggle_select(0)
	assert_true(tape.move_selected(1))
	assert_eq(
		tape.program(), [{"op": M}, IfSupport.if_node("CLEAR_AHEAD", [{"op": L}], [{"op": R}])]
	)
	assert_eq(tape.selected, 1)
	assert_false(tape.move_selected(1))


func test_commands_move_within_their_branch_only() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M, L])
	tape.start_else()
	tape.append(R)
	tape.end_if()
	tape.toggle_select(1)
	assert_true(tape.move_selected(1))
	assert_false(tape.move_selected(1), "the else command is not a sibling")
	assert_eq(tape.program()[0]["then"], [{"op": L}, {"op": M}])
	assert_eq(tape.program()[0]["else"], [{"op": R}])


func test_an_open_if_stays_open_when_it_is_moved() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	tape.append("MOVE_FORWARD")
	tape.toggle_select(0)
	tape.move_selected(-1)
	assert_false(tape.open_if().is_empty())


func test_clearing_closes_everything() -> void:
	var tape := IfSupport.tape()
	tape.append(UNTIL)
	IfSupport.open_if(tape, [M])
	tape.clear()
	assert_true(tape.open_if().is_empty())
	assert_eq(tape.open_loop(), -1)
	assert_true(tape.is_empty())


func test_the_program_has_no_editing_flags() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	assert_false(tape.program()[0].has("_open"))
	assert_false(tape.program()[0].has("_branch"))
	assert_true(tape.nodes[0].has("_open"))


func test_an_if_is_refused_when_the_level_does_not_offer_it() -> void:
	var tape := TapeModel.new(8, ["MOVE_FORWARD"])
	assert_false(tape.append(IF))


func test_palette_commands_end_and_switch_groups() -> void:
	var tape := IfSupport.tape()
	PlayView.apply_command(tape, IF)
	PlayView.apply_command(tape, M)
	PlayView.apply_command(tape, "ELSE")
	PlayView.apply_command(tape, L)
	PlayView.apply_command(tape, IF)
	assert_true(tape.open_if().is_empty(), "the IF tile ends an open IF")
	assert_eq(tape.program(), [IfSupport.if_node("CLEAR_AHEAD", [{"op": M}], [{"op": L}])])


func test_a_tape_with_an_if_passes_program_validation() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	tape.end_if()
	assert_true(LevelValidator.validate_program(IfSupport.level(), tape.program())["ok"])


func test_an_incomplete_if_fails_program_validation() -> void:
	var tape := IfSupport.tape()
	tape.append(IF)
	assert_false(LevelValidator.validate_program(IfSupport.level(), tape.program())["ok"])
