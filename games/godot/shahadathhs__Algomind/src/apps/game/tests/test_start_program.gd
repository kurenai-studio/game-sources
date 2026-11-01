extends GutTest
## A debug level: the tape starts with the level's start program, which the player edits.


func _model(limit: int = 12) -> TapeModel:
	var commands: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT"]
	return TapeModel.new(limit, commands)


func test_a_start_program_is_loaded_as_a_closed_copy() -> void:
	var tape := _model()
	var start := [
		{"op": "MOVE_FORWARD"},
		{"op": "REPEAT", "count": 3, "body": [{"op": "TURN_LEFT"}, {"op": "MOVE_FORWARD"}]},
	]
	assert_true(tape.load_program(start))
	assert_eq(tape.program(), start, "the program on the tape is the start program")
	assert_eq(tape.slots(), 4, "a loop is one slot plus its body")
	assert_eq(tape.selected, -1)
	assert_true(tape.open_chain().is_empty(), "nothing is open")
	start[0]["op"] = "TURN_RIGHT"
	assert_eq(tape.program()[0]["op"], "MOVE_FORWARD", "the tape holds a copy")


func test_the_player_can_edit_a_loaded_program() -> void:
	var tape := _model()
	tape.load_program([{"op": "MOVE_FORWARD"}, {"op": "TURN_LEFT"}])
	assert_true(tape.append("MOVE_FORWARD"), "a command can be added after it")
	assert_eq(tape.slots(), 3)
	tape.toggle_select(0)
	assert_true(tape.remove_selected(), "and a tile removed")
	assert_eq(tape.slots(), 2)
	assert_eq(tape.program()[0]["op"], "TURN_LEFT")


func test_a_program_that_does_not_fit_leaves_the_tape_empty() -> void:
	var tape := _model(2)
	assert_false(
		tape.load_program([{"op": "MOVE_FORWARD"}, {"op": "MOVE_FORWARD"}, {"op": "MOVE_FORWARD"}])
	)
	assert_eq(tape.slots(), 0)
	assert_false(tape.load_program("MOVE_FORWARD"), "a non-array is refused")
	assert_eq(tape.slots(), 0)


func test_the_level_mechanic_is_derived_and_supported() -> void:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	assert_false(LevelMechanics.derived(level).has("start_program"))
	level["startProgram"] = [{"op": "MOVE_FORWARD"}]
	assert_true(LevelMechanics.derived(level).has("start_program"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("start_program"))


func test_a_debug_level_asks_to_fix_the_program_not_to_reach_the_target() -> void:
	var tape := _model()
	tape.load_program([{"op": "MOVE_FORWARD"}])
	assert_eq(LoopMessages.building_text(tape, false, true), "FIX THE PROGRAM")
	assert_eq(LoopMessages.building_text(tape), "REACH THE TARGET")
	assert_eq(LoopMessages.building_text(tape, true, true), "FIX THE PROGRAM")
