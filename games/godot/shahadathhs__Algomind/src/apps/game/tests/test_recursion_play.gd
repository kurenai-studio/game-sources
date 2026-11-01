extends GutTest
## A level with the mechanic recursion: where a CALL may go on the tape, how its sensor is set, what
## program the tape hands to the simulator, and how a run that never stops ends.

const M := "MOVE_FORWARD"


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("long-hall")["level"].duplicate(
		true
	)
	return level


func _tape(recursion: bool = true) -> TapeModel:
	var available: Array[String] = [M, "TURN_LEFT", "TURN_RIGHT", "PROC"]
	return TapeModel.new(12, available, false, recursion)


func test_a_call_goes_into_an_open_definition_only_with_the_mechanic() -> void:
	var with_it := _tape()
	assert_true(with_it.append("PROC"))
	assert_true(with_it.append(M))
	assert_true(with_it.can_call("A"), "A is defined (it is the open definition)")
	assert_true(with_it.append_call("A"))
	var without := _tape(false)
	assert_true(without.append("PROC"))
	assert_true(without.append(M))
	assert_false(without.can_call("A"))


func test_a_selected_call_cycles_through_the_sensors_and_back_to_none() -> void:
	var tape := _tape()
	tape.append("PROC")
	tape.append(M)
	tape.append_call("A")
	tape.end_proc()
	tape.selected = tape.cells().size() - 1
	assert_eq(tape.selected_kind(), "call")
	assert_true(tape.cycle_condition())
	assert_eq(tape.program()[0]["body"][1]["when"], "CLEAR_AHEAD")
	for i in tape.sensor_options().size():
		tape.cycle_condition()
	assert_false(tape.program()[0]["body"][1].has("when"), "the last step is back to no sensor")


func test_the_tape_program_runs_as_a_recursion_and_stops_at_the_wall() -> void:
	var tape := _tape()
	tape.append("PROC")
	tape.append(M)
	tape.append_call("A")
	tape.end_proc()
	tape.selected = tape.cells().size() - 1
	tape.cycle_condition()
	tape.append_call("A")
	var result := LevelSimulator.simulate(_level(), tape.program())
	assert_eq(result["status"], "SUCCEEDED", "%s" % [result["reason"]])


func test_a_recursion_without_a_base_case_ends_with_the_depth_message() -> void:
	var program := [
		{"op": "PROC", "name": "A", "body": [{"op": "TURN_LEFT"}, {"op": "CALL", "name": "A"}]},
		{"op": "CALL", "name": "A"},
	]
	var result := LevelSimulator.simulate(_level(), program)
	assert_eq(result["reason"], "TOO_DEEP")
	assert_eq(ResultMessages.for_result(result), "The procedures called each other too many times.")


func test_the_mechanic_is_read_from_the_level_and_supported() -> void:
	assert_true(LevelMechanics.recursion(_level()))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("recursion"))
