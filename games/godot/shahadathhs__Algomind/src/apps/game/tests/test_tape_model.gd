extends GutTest
## Editing the program: add, remove, reorder, and the command limit.

const ALL: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"]


func _tape(limit: int = 4) -> TapeModel:
	return TapeModel.new(limit, ALL)


func test_append_adds_in_order() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	tape.append("TURN_LEFT")
	assert_eq(tape.program(), [{"op": "MOVE_FORWARD"}, {"op": "TURN_LEFT"}])


func test_append_stops_at_the_limit() -> void:
	var tape := _tape(2)
	assert_true(tape.append("MOVE_FORWARD"))
	assert_true(tape.append("MOVE_FORWARD"))
	assert_true(tape.is_full())
	assert_false(tape.append("MOVE_FORWARD"))
	assert_eq(tape.slots(), 2)


func test_append_refuses_a_command_the_level_does_not_offer() -> void:
	var tape := TapeModel.new(4, ["MOVE_FORWARD"] as Array[String])
	assert_false(tape.append("TURN_LEFT"))
	assert_eq(tape.slots(), 0)


func test_selecting_a_tile_twice_clears_the_selection() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	tape.toggle_select(0)
	assert_eq(tape.selected, 0)
	tape.toggle_select(0)
	assert_eq(tape.selected, -1)


func test_selecting_outside_the_tape_clears_the_selection() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	tape.toggle_select(0)
	tape.toggle_select(-1)
	assert_eq(tape.selected, -1)
	tape.toggle_select(5)
	assert_eq(tape.selected, -1)


func test_remove_selected_removes_that_tile_only() -> void:
	var tape := _tape()
	for op in ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"]:
		tape.append(op)
	tape.toggle_select(1)
	assert_true(tape.remove_selected())
	assert_eq(tape.program(), [{"op": "MOVE_FORWARD"}, {"op": "TURN_RIGHT"}])
	assert_eq(tape.selected, -1)


func test_remove_without_a_selection_does_nothing() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	assert_false(tape.remove_selected())
	assert_eq(tape.slots(), 1)


func test_removing_frees_a_slot() -> void:
	var tape := _tape(1)
	tape.append("MOVE_FORWARD")
	tape.toggle_select(0)
	tape.remove_selected()
	assert_true(tape.append("TURN_LEFT"))


func test_move_selected_swaps_and_the_selection_follows() -> void:
	var tape := _tape()
	for op in ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"]:
		tape.append(op)
	tape.toggle_select(0)
	assert_true(tape.move_selected(1))
	assert_eq(tape.program(), [{"op": "TURN_LEFT"}, {"op": "MOVE_FORWARD"}, {"op": "TURN_RIGHT"}])
	assert_eq(tape.selected, 1)
	assert_true(tape.move_selected(-1))
	assert_eq(tape.selected, 0)


func test_move_selected_stops_at_the_ends() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	tape.append("TURN_LEFT")
	tape.toggle_select(0)
	assert_false(tape.move_selected(-1))
	tape.toggle_select(1)
	assert_false(tape.move_selected(1))


func test_appending_clears_the_selection() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	tape.toggle_select(0)
	tape.append("TURN_LEFT")
	assert_eq(tape.selected, -1)


func test_program_is_a_list_of_instruction_nodes() -> void:
	var tape := _tape()
	tape.append("MOVE_FORWARD")
	tape.append("TURN_RIGHT")
	assert_eq(tape.program(), [{"op": "MOVE_FORWARD"}, {"op": "TURN_RIGHT"}])


func test_a_tape_program_passes_program_validation() -> void:
	var tape := _tape(2)
	tape.append("MOVE_FORWARD")
	var level: Dictionary = (
		ContractSupport.load_fixture("levels/valid", "typical-first-steps.json")["level"]
	)
	assert_true(LevelValidator.validate_program(level, tape.program())["ok"])
