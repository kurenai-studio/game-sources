extends GutTest
## Building, editing and reading definitions and calls on the tape.

const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"
const PROC := "PROC"


func test_the_proc_tile_opens_the_next_free_name() -> void:
	var tape := ProcSupport.tape()
	ProcSupport.define(tape, [M])
	ProcSupport.define(tape, [R])
	assert_eq(tape.defined_names(), ["A", "B"])
	assert_eq(tape.next_proc_name(), "C")
	ProcSupport.define(tape, [L])
	assert_eq(tape.next_proc_name(), "")
	assert_false(tape.can_append(PROC), "all three names are used")


func test_commands_go_into_the_open_definition_until_it_is_ended() -> void:
	var tape := ProcSupport.tape()
	assert_true(tape.append(PROC))
	assert_eq(tape.open_proc(), 0)
	assert_false(tape.can_end_proc(), "an empty definition cannot be ended")
	assert_true(tape.is_incomplete())
	tape.append(M)
	tape.append(R)
	assert_eq(tape.nodes[0]["body"].size(), 2)
	assert_true(tape.end_proc())
	assert_eq(tape.open_proc(), -1)
	tape.append(M)
	assert_eq(tape.nodes.size(), 2, "the next command goes to the main program")
	assert_eq(tape.program(), [ProcSupport.proc("A", [{"op": M}, {"op": R}]), {"op": M}])


func test_a_definition_goes_before_the_main_program() -> void:
	var tape := ProcSupport.tape()
	tape.append(M)
	tape.append(M)
	ProcSupport.define(tape, [R])
	assert_eq(tape.nodes[0]["op"], PROC)
	assert_eq(tape.nodes.size(), 3)
	assert_eq(tape.cells()[0]["kind"], "proc")
	assert_eq(tape.cells()[1]["proc"], 0)
	assert_eq(tape.cells()[2]["proc"], -1)


func test_a_loop_can_be_built_inside_a_definition() -> void:
	var tape := ProcSupport.tape()
	tape.append(PROC)
	tape.append("REPEAT")
	tape.append(M)
	assert_eq(tape.open_keys(), ["0", "0_0"])
	assert_false(tape.can_end_proc(), "the loop is still open")
	assert_false(tape.can_append(PROC))
	assert_true(tape.end_loop())
	assert_true(tape.end_proc())
	assert_eq(tape.slots(), 3)
	var cells := tape.cells()
	assert_eq(cells[1]["kind"], "count")
	assert_eq(cells[2]["path"], [0, 0, 0])
	assert_eq(cells[2]["groups"], ["0", "0_0"])
	assert_eq(tape.cell_for_node([0, 0, 0]), 2)


func test_a_definition_body_holds_at_most_eight_items() -> void:
	var tape := ProcSupport.tape(20)
	tape.append(PROC)
	for i in 8:
		assert_true(tape.append(M))
	assert_false(tape.can_append(M))
	assert_true(tape.open_loop_is_full())


func test_a_call_is_offered_only_for_a_defined_name_and_never_in_a_definition() -> void:
	var tape := ProcSupport.tape()
	assert_false(tape.can_call("A"))
	tape.append(PROC)
	tape.append(M)
	assert_false(tape.can_call("A"), "no CALL goes into a definition")
	tape.end_proc()
	assert_true(tape.can_call("A"))
	assert_false(tape.can_call("B"))
	assert_true(tape.append_call("A"))
	assert_eq(tape.program()[1], {"op": "CALL", "name": "A"})
	assert_eq(tape.cells()[2]["kind"], "call")
	assert_eq(tape.cells()[2]["name"], "A")


func test_a_call_goes_into_an_open_main_loop() -> void:
	var tape := ProcSupport.tape()
	ProcSupport.define(tape, [M])
	tape.append("REPEAT")
	assert_true(tape.append_call("A"))
	assert_eq(tape.nodes[1]["body"], [{"op": "CALL", "name": "A"}])
	assert_true(tape.end_loop())
	var cell := tape.cells()[3]
	assert_eq(cell["path"], [1, 0])
	assert_eq(cell["groups"], ["1"])


func test_a_call_counts_one_slot_and_the_limit_applies() -> void:
	var tape := ProcSupport.tape(3)
	ProcSupport.define(tape, [M])
	assert_eq(tape.slots(), 2)
	assert_true(tape.append_call("A"))
	assert_false(tape.can_call("A"), "the tape is full")


func test_removing_a_called_definition_leaves_the_calls_and_says_so() -> void:
	var tape := ProcSupport.tape()
	ProcSupport.define(tape, [M])
	tape.append_call("A")
	tape.toggle_select(0)
	assert_eq(tape.selected_kind(), "proc")
	assert_true(tape.remove_selected())
	assert_eq(tape.program(), [{"op": "CALL", "name": "A"}])
	assert_eq(tape.undefined_calls(), ["A"])
	assert_true(tape.is_incomplete(), "Run stays off")
	assert_eq(LoopMessages.building_text(tape), "PROCEDURE A IS NOT DEFINED")
	assert_false(LevelValidator.validate_program(ProcSupport.level(), tape.program())["ok"])


func test_a_definition_never_moves_past_the_main_program() -> void:
	var tape := ProcSupport.tape()
	ProcSupport.define(tape, [M])
	ProcSupport.define(tape, [R])
	tape.append(L)
	tape.toggle_select(0)
	assert_false(tape.can_move(-1))
	assert_true(tape.can_move(1))
	assert_true(tape.move_selected(1))
	assert_eq(tape.nodes[0]["name"], "B")
	assert_eq(tape.selected, tape.cell_for_node([1]))
	assert_false(tape.can_move(1), "the next node is the main program")
	tape.toggle_select(tape.cell_for_node([2]))
	assert_false(tape.can_move(-1), "a main command does not enter the definitions")


func test_the_message_asks_for_a_command_in_an_empty_definition() -> void:
	var tape := ProcSupport.tape()
	tape.append(PROC)
	assert_eq(LoopMessages.building_text(tape), "ADD A COMMAND TO THE PROCEDURE")
	tape.append(M)
	assert_eq(LoopMessages.building_text(tape), "REACH THE TARGET")


func test_if_inside_a_definition_uses_the_open_if_rules() -> void:
	var offered: Array[String] = ["MOVE_FORWARD", "TURN_RIGHT", "IF", "PROC"]
	var tape := TapeModel.new(12, offered)
	tape.append(PROC)
	tape.append("IF")
	tape.append(M)
	assert_eq(tape.open_keys(), ["0", "0_0"])
	assert_true(tape.start_else())
	tape.append(R)
	assert_true(tape.end_if())
	assert_true(tape.end_proc())
	var node: Dictionary = tape.program()[0]["body"][0]
	assert_eq(node["then"], [{"op": M}])
	assert_eq(node["else"], [{"op": R}])
	assert_eq(tape.cell_for_node([0, 0, 1]), 4)


func test_the_palette_tile_ends_the_open_definition() -> void:
	var tape := ProcSupport.tape()
	PlayView.apply_command(tape, PROC)
	PlayView.apply_command(tape, M)
	assert_true(PlayView.group_is_open(tape, PROC))
	PlayView.apply_command(tape, PROC)
	assert_false(PlayView.group_is_open(tape, PROC))
	assert_eq(tape.nodes.size(), 1)


func test_a_tape_program_passes_validation_and_runs() -> void:
	var tape := ProcSupport.tape(20)
	ProcSupport.define(tape, [M, M, R, M, M, L])
	tape.append_call("A")
	tape.append_call("A")
	var level := ProcSupport.level()
	assert_true(LevelValidator.validate_program(level, tape.program())["ok"])
	var result := LevelSimulator.simulate(level, tape.program())
	assert_eq(result["steps"], 12)
	assert_eq(result["finalState"]["position"], [4, 4])
