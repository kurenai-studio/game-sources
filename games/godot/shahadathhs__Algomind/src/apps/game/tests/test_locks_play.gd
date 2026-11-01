extends GutTest
## A level with keys and doors: when a key counts as taken, how a run ends at a shut door, what the
## player is told, and which doors the board shows open.


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	level["board"] = {"width": 5, "height": 3, "walls": []}
	level["initialState"] = {"position": [0, 1], "direction": "east"}
	level["goal"] = {"type": "reach_tile", "position": [4, 1]}
	level["constraints"] = {"maxCommands": 12, "maxSteps": 40}
	level["locks"] = [{"key": [1, 0], "door": [3, 1]}]
	return level


func _program(ops: String) -> Array:
	var names := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var out: Array = []
	for letter in ops:
		out.append({"op": names[letter]})
	return out


func test_a_run_into_a_shut_door_fails_on_the_door() -> void:
	var session := PlaySession.new(_level())
	assert_true(session.start(_program("MMMM"), PlaySession.State.PAUSED))
	assert_eq(session.result["reason"], "BLOCKED_BY_DOOR")
	assert_eq(session.result["blockedCell"], [3, 1])
	while session.advance().size() > 0:
		pass
	assert_eq(session.blocked_cell(), Vector2i(3, 1))
	assert_eq(session.failing_node(), [2], "the third move reached the door")
	assert_eq(
		ResultMessages.for_result(session.result),
		"The automaton tried to go through a locked door."
	)


func test_fetching_the_key_first_opens_the_door() -> void:
	# Left to face north, up to the key at (1,0)? The key is one up and one along: M, L, M, R, M ...
	var result := LevelSimulator.simulate(_level(), _program("MLMRMRMLMM"))
	assert_eq(result["status"], "SUCCEEDED", "%s" % [result["reason"]])
	var taken := 0
	for entry: Dictionary in result["trace"]:
		if entry["event"] == "KEY_TAKEN":
			taken += 1
	assert_eq(taken, 1, "one key, taken once")


func test_a_shut_door_is_not_clear_for_a_sensor() -> void:
	var level := _level()
	level["availableCommands"] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT_UNTIL"]
	var program := [{"op": "REPEAT_UNTIL", "until": "BLOCKED", "body": [{"op": "MOVE_FORWARD"}]}]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["finalState"]["position"], [2, 1], "the loop stops in front of the door")


func test_the_board_shows_a_key_held_once_its_cell_is_entered() -> void:
	var level := _level()
	var before: Array[Vector2i] = [Vector2i(0, 1)]
	var after: Array[Vector2i] = [Vector2i(0, 1), Vector2i(0, 0), Vector2i(1, 0)]
	assert_false(LockDraw.held(level, before).has(0))
	assert_true(LockDraw.held(level, after).has(0))


func test_the_mechanic_is_derived_and_supported() -> void:
	assert_true(LevelMechanics.derived(_level()).has("keys"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("keys"))
