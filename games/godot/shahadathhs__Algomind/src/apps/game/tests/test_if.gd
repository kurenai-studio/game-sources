extends GutTest
## IF and the GOAL condition beyond the shared fixtures: editing on the tape, cells, the run state
## and the messages.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const IF := "IF"
const UNTIL := "REPEAT_UNTIL"

# ----- editing ----------------------------------------------------------------------------------


func test_a_new_if_is_open_looks_ahead_and_selects_its_sensor_cell() -> void:
	var tape := IfSupport.tape()
	assert_true(tape.append(IF))
	assert_eq(tape.program(), [IfSupport.if_node("CLEAR_AHEAD", [])])
	assert_false(tape.open_if().is_empty())
	assert_eq(tape.open_branch(), "then")
	assert_eq(tape.selected_kind(), "if")
	assert_true(tape.is_incomplete())
	assert_false(tape.can_end_if())


func test_commands_go_to_then_until_else_is_started() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	assert_true(tape.start_else())
	assert_eq(tape.open_branch(), "else")
	tape.append(L)
	tape.append(R)
	assert_true(tape.end_if())
	tape.append(M)
	assert_eq(
		tape.program(),
		[IfSupport.if_node("CLEAR_AHEAD", [{"op": M}], [{"op": L}, {"op": R}]), {"op": M}]
	)
	assert_true(tape.open_if().is_empty())
	assert_false(tape.is_incomplete())


func test_else_needs_a_command_in_then_and_works_once() -> void:
	var tape := IfSupport.tape()
	tape.append(IF)
	assert_false(tape.start_else())
	tape.append(M)
	assert_true(tape.start_else())
	assert_false(tape.start_else())


func test_slots_are_one_plus_both_branches() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M, L])
	tape.start_else()
	tape.append(R)
	tape.end_if()
	assert_eq(tape.slots(), 4)
	assert_eq(ProgramSlots.count(tape.program()), 4)


func test_cells_show_header_then_divider_else_with_paths() -> void:
	var tape := IfSupport.tape()
	tape.append(M)
	IfSupport.open_if(tape, [M, L])
	tape.start_else()
	tape.append(R)
	tape.end_if()
	var cells := tape.cells()
	var kinds: Array[String] = []
	for cell in cells:
		kinds.append(cell["kind"])
	assert_eq(kinds, ["op", "if", "op", "op", "else", "op"])
	assert_eq(cells[1]["path"], [1])
	assert_eq(cells[2]["path"], [1, 0])
	assert_eq(cells[3]["path"], [1, 1])
	assert_eq(cells[5]["path"], [1, 2], "the else command counts after the then commands")
	assert_eq(cells[5]["branch"], "else")
	assert_eq(tape.cell_for_node([1, 2]), 5)
	assert_eq(tape.cell_for_node([1]), 1)


func test_the_else_divider_shows_while_else_is_open_even_when_empty() -> void:
	var tape := IfSupport.tape()
	IfSupport.open_if(tape, [M])
	assert_eq(tape.cells().size(), 2)
	tape.start_else()
	assert_eq(tape.cells().size(), 3)
	assert_eq(tape.cells()[2]["kind"], "else")
	tape.end_if()
	assert_eq(tape.cells().size(), 2, "a closed IF with an empty else has no divider")


func test_an_if_takes_primitives_only() -> void:
	var tape := IfSupport.tape()
	tape.append(IF)
	assert_false(tape.can_append(IF), "no IF inside an IF")
	assert_false(tape.can_append("REPEAT"))
	assert_false(tape.can_append(UNTIL))
	assert_true(tape.can_append(M))


func test_a_branch_holds_at_most_four_commands() -> void:
	var tape := IfSupport.tape(12)
	IfSupport.open_if(tape, [M, M, M, M])
	assert_false(tape.can_append(M))
	tape.start_else()
	assert_true(tape.can_append(M))


func test_an_if_closes_with_end_if_even_when_the_tape_is_full() -> void:
	var tape := IfSupport.tape(2)
	IfSupport.open_if(tape, [M])
	assert_true(tape.is_full())
	assert_false(tape.can_append(M))
	assert_true(tape.can_end_if())
	assert_true(tape.end_if())


func test_an_if_is_an_item_of_an_open_loop_and_the_loop_closes_last() -> void:
	var tape := IfSupport.tape()
	tape.append(UNTIL)
	IfSupport.open_if(tape, [M])
	assert_false(tape.can_end_loop(), "the IF is still open")
	assert_false(tape.end_loop())
	tape.end_if()
	tape.append(R)
	assert_true(tape.end_loop())
	assert_eq(
		tape.program(),
		[
			{
				"op": UNTIL,
				"until": "BLOCKED",
				"body": [IfSupport.if_node("CLEAR_AHEAD", [{"op": M}]), {"op": R}]
			}
		]
	)
	assert_eq(tape.slots(), 4)


func test_an_if_in_a_loop_has_paths_with_the_item_and_command() -> void:
	var tape := IfSupport.tape()
	tape.append("REPEAT")
	tape.append(M)
	IfSupport.open_if(tape, [L])
	tape.start_else()
	tape.append(R)
	tape.end_if()
	var cells := tape.cells()
	assert_eq(cells[2]["kind"], "if")
	assert_eq(cells[2]["path"], [0, 1])
	assert_eq(cells[3]["path"], [0, 1, 0])
	assert_eq(cells[5]["path"], [0, 1, 1])
	for cell in cells:
		assert_eq(cell["loop"], 0)
	assert_eq(cells[1]["iff"], "")
	assert_eq(cells[3]["iff"], "0_1")


func test_a_loop_cannot_open_while_an_if_is_open_and_the_if_cannot_nest() -> void:
	var tape := IfSupport.tape()
	tape.append(UNTIL)
	tape.append(IF)
	assert_false(tape.can_append("REPEAT"))
	assert_false(tape.can_append(IF))
