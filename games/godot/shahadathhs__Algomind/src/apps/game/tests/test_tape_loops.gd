extends GutTest
## Editing loops: a count tile and a body, slots, the open loop, and the tools that apply to it.

const ALL: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT"]
const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const LOOP := "REPEAT"


func _tape(limit: int = 12) -> TapeModel:
	return TapeModel.new(limit, ALL)


## A loop of `count` rounds over `body`, closed.
func _with_loop(tape: TapeModel, count: int, body: Array) -> void:
	tape.append(LOOP)
	tape.adjust_count(count - ContractLimits.REPEAT_COUNT_MIN)
	for op: String in body:
		tape.append(op)
	tape.end_loop()


func test_a_new_loop_has_two_rounds_an_empty_body_and_is_selected() -> void:
	var tape := _tape()
	assert_true(tape.append(LOOP))
	assert_eq(tape.program(), [{"op": LOOP, "count": 2, "body": []}])
	assert_true(tape.selected_is_count())
	assert_eq(tape.open_loop(), 0)
	assert_true(tape.has_empty_loop())


func test_commands_go_into_the_open_loop_until_it_is_ended() -> void:
	var tape := _tape()
	tape.append(LOOP)
	tape.append(M)
	tape.append(R)
	assert_true(tape.end_loop())
	tape.append(M)
	assert_eq(
		tape.program(),
		[{"op": LOOP, "count": 2, "body": [{"op": M}, {"op": R}]}, {"op": M}],
		"after the loop is ended, commands go after it"
	)


func test_slots_count_the_loop_and_its_body() -> void:
	var tape := _tape()
	_with_loop(tape, 6, [M, R, M, L])
	assert_eq(tape.slots(), 5, "1 for the loop and 4 for the body")
	tape.append(M)
	assert_eq(tape.slots(), 6)


func test_the_limit_counts_slots() -> void:
	var tape := _tape(3)
	tape.append(LOOP)
	tape.append(M)
	tape.append(M)
	assert_true(tape.is_full())
	assert_false(tape.append(M), "the third body command would be a fourth slot")
	assert_eq(tape.slots(), 3)


func test_a_loop_cannot_hold_a_loop() -> void:
	var tape := _tape()
	tape.append(LOOP)
	assert_false(tape.append(LOOP), "Repeat while a loop is open does not nest")
	assert_false(tape.can_append(LOOP))


func test_a_loop_body_holds_at_most_eight_commands() -> void:
	var tape := _tape(20)
	tape.append(LOOP)
	for i in ContractLimits.REPEAT_BODY_MAX:
		assert_true(tape.append(M))
	assert_true(tape.open_loop_is_full())
	assert_false(tape.append(M))


func test_an_empty_loop_cannot_be_ended() -> void:
	var tape := _tape()
	tape.append(LOOP)
	assert_false(tape.can_end_loop())
	assert_false(tape.end_loop())
	assert_eq(tape.open_loop(), 0)


func test_repeat_is_refused_when_the_level_does_not_offer_it() -> void:
	var tape := TapeModel.new(8, ["MOVE_FORWARD"] as Array[String])
	assert_false(tape.append(LOOP))
	assert_true(tape.is_empty())


func test_the_count_stays_within_two_to_eleven() -> void:
	var tape := _tape()
	tape.append(LOOP)
	assert_false(tape.adjust_count(-1), "already at the least")
	for i in 20:
		tape.adjust_count(1)
	assert_eq(tape.program()[0]["count"], ContractLimits.REPEAT_COUNT_MAX)
	assert_false(tape.adjust_count(1))


func test_only_a_count_cell_changes_the_count() -> void:
	var tape := _tape()
	_with_loop(tape, 3, [M])
	tape.toggle_select(1)
	assert_false(tape.selected_is_count())
	assert_false(tape.adjust_count(1))


func test_cells_are_one_per_slot_with_paths() -> void:
	var tape := _tape()
	tape.append(M)
	_with_loop(tape, 3, [R, M])
	var cells := tape.cells()
	assert_eq(cells.size(), tape.slots())
	assert_eq(cells[0]["path"], [0])
	assert_eq(cells[1]["kind"], "count")
	assert_eq(cells[1]["path"], [1])
	assert_eq(cells[2]["path"], [1, 0])
	assert_eq(cells[3]["path"], [1, 1])
	assert_eq(tape.cell_for_node([1, 1]), 3)
	assert_eq(tape.cell_for_node([5]), -1)


func test_removing_a_count_cell_removes_the_whole_loop() -> void:
	var tape := _tape()
	_with_loop(tape, 3, [M, M])
	tape.append(R)
	tape.toggle_select(0)
	assert_true(tape.remove_selected())
	assert_eq(tape.program(), [{"op": R}])


func test_removing_a_body_command_leaves_the_loop() -> void:
	var tape := _tape()
	_with_loop(tape, 3, [M, R])
	tape.toggle_select(1)
	tape.remove_selected()
	assert_eq(tape.program(), [{"op": LOOP, "count": 3, "body": [{"op": R}]}])


func test_removing_the_open_loop_closes_it() -> void:
	var tape := _tape()
	tape.append(LOOP)
	tape.remove_selected()
	assert_eq(tape.open_loop(), -1)
	assert_true(tape.is_empty())


func test_moving_a_loop_moves_its_body_with_it() -> void:
	var tape := _tape()
	_with_loop(tape, 2, [M, R])
	tape.append(L)
	tape.toggle_select(0)
	assert_true(tape.move_selected(1))
	assert_eq(tape.program()[0], {"op": L})
	assert_eq(tape.program()[1]["op"], LOOP)
	assert_eq(tape.selected, 1, "the selection follows the count cell")


func test_moving_a_body_command_stays_in_the_body() -> void:
	var tape := _tape()
	_with_loop(tape, 2, [M, R])
	tape.toggle_select(1)
	assert_true(tape.move_selected(1))
	assert_eq(tape.program()[0]["body"], [{"op": R}, {"op": M}])
	assert_false(tape.move_selected(1), "it is last in the body")


func test_moving_the_open_loop_keeps_it_open() -> void:
	var tape := _tape()
	tape.append(M)
	tape.append(LOOP)
	tape.append(R)
	tape.selected = 1
	assert_true(tape.move_selected(-1))
	assert_eq(tape.open_loop(), 0)
	tape.append(M)
	assert_eq(tape.program()[0]["body"], [{"op": R}, {"op": M}])


func test_the_program_passes_validation_and_the_simulator_runs_it() -> void:
	var tape := _tape(5)
	_with_loop(tape, 6, [M, R, M, L])
	var level: Dictionary = {
		"schemaVersion": 1,
		"levelId": "stairs",
		"levelVersion": 1,
		"slug": "stairs",
		"title": "Stairs",
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": []},
		"board": {"width": 7, "height": 7, "walls": []},
		"initialState": {"position": [0, 6], "direction": "north"},
		"availableCommands": ALL,
		"constraints": {"maxCommands": 5, "maxSteps": 100},
		"goal": {"type": "reach_tile", "position": [6, 0]},
		"hints": [],
	}
	assert_true(LevelValidator.validate_program(level, tape.program())["ok"])
	var result := LevelSimulator.simulate(level, tape.program())
	assert_eq(result["status"], "SUCCEEDED")
	assert_eq(result["steps"], 23)
	assert_eq(tape.slots(), 5)


func test_an_empty_loop_fails_program_validation() -> void:
	var tape := _tape()
	tape.append(LOOP)
	var level: Dictionary = (
		ContractSupport.load_fixture("runs", "repeat-staircase-succeeds.json")["level"]
	)
	assert_false(LevelValidator.validate_program(level, tape.program())["ok"])


func test_clear_empties_everything() -> void:
	var tape := _tape()
	_with_loop(tape, 3, [M])
	tape.clear()
	assert_true(tape.is_empty())
	assert_eq(tape.open_loop(), -1)
	assert_eq(tape.selected, -1)
