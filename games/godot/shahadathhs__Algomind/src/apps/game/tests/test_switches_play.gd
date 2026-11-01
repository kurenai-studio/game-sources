extends GutTest
## A level with switches and gates: how often a switch has flipped its gate, how a run ends at a
## shut gate, what the player is told, and which gates the board shows open.


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	level["board"] = {"width": 5, "height": 3, "walls": []}
	level["initialState"] = {"position": [0, 1], "direction": "east"}
	level["goal"] = {"type": "reach_tile", "position": [4, 1]}
	level["constraints"] = {"maxCommands": 12, "maxSteps": 40}
	level["switches"] = [{"switch": [1, 1], "gate": [3, 1]}]
	return level


func _program(ops: String) -> Array:
	var names := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var out: Array = []
	for letter in ops:
		out.append({"op": names[letter]})
	return out


func test_a_run_into_a_shut_gate_fails_on_the_gate() -> void:
	var level := _level()
	level["switches"] = [{"switch": [1, 0], "gate": [3, 1]}]
	var session := PlaySession.new(level)
	assert_true(session.start(_program("MMMM"), PlaySession.State.PAUSED))
	assert_eq(session.result["reason"], "BLOCKED_BY_GATE")
	assert_eq(session.result["blockedCell"], [3, 1])
	while session.advance().size() > 0:
		pass
	assert_eq(session.failing_node(), [2], "the third move reached the gate")
	assert_eq(
		ResultMessages.for_result(session.result), "The automaton tried to go through a shut gate."
	)


func test_a_switch_flips_its_gate_every_time_it_is_entered() -> void:
	var twice := LevelSimulator.simulate(_level(), _program("MLLMLLMMM"))
	assert_eq(twice["reason"], "BLOCKED_BY_GATE", "the second entry shut the gate again")
	var switched := 0
	for entry: Dictionary in twice["trace"]:
		if entry["event"] == "SWITCHED":
			switched += 1
	assert_eq(switched, 2)
	var once := LevelSimulator.simulate(_level(), _program("MMMM"))
	assert_eq(once["status"], "SUCCEEDED", "%s" % [once["reason"]])


func test_a_shut_gate_is_not_clear_for_a_sensor() -> void:
	var level := _level()
	level["switches"] = [{"switch": [1, 0], "gate": [3, 1]}]
	level["availableCommands"] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT_UNTIL"]
	var program := [{"op": "REPEAT_UNTIL", "until": "BLOCKED", "body": [{"op": "MOVE_FORWARD"}]}]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["finalState"]["position"], [2, 1], "the loop stops in front of the gate")


func test_the_board_replays_the_gates_from_the_trail() -> void:
	var level := _level()
	level["switches"] = [{"switch": [1, 1], "gate": [3, 1], "open": true}]
	var start := Vector2i(0, 1)
	var before: Array[Vector2i] = [start]
	var once: Array[Vector2i] = [start, Vector2i(1, 1)]
	var twice: Array[Vector2i] = [start, Vector2i(1, 1), Vector2i(0, 1), Vector2i(1, 1)]
	assert_true((SwitchDraw.state(level, before)["open"] as Dictionary).has(0))
	assert_false((SwitchDraw.state(level, once)["open"] as Dictionary).has(0))
	assert_true((SwitchDraw.state(level, twice)["open"] as Dictionary).has(0))


func test_the_mechanic_is_derived_and_supported() -> void:
	assert_true(LevelMechanics.derived(_level()).has("switch"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("switch"))
