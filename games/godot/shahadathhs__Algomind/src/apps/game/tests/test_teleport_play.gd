extends GutTest
## A level with teleporters: where a step leaves the automaton, the route the board replays, and the
## mechanic the game reports.


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	level["board"] = {"width": 7, "height": 3, "walls": []}
	level["initialState"] = {"position": [0, 1], "direction": "east"}
	level["goal"] = {"type": "reach_tile", "position": [6, 1]}
	level["constraints"] = {"maxCommands": 12, "maxSteps": 40}
	level["teleports"] = [{"a": [2, 1], "b": [5, 1]}]
	return level


func _program(ops: String) -> Array:
	var names := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var out: Array = []
	for letter in ops:
		out.append({"op": names[letter]})
	return out


func test_entering_one_end_puts_the_automaton_on_the_other() -> void:
	var result := LevelSimulator.simulate(_level(), _program("MM"))
	assert_eq(result["trace"][1]["event"], "TELEPORTED")
	assert_eq(result["trace"][1]["path"], [[2, 1], [5, 1]])
	assert_eq(result["finalState"]["position"], [5, 1])
	assert_eq(result["finalState"]["direction"], "east")


func test_the_route_lists_both_ends_and_the_run_can_finish() -> void:
	var session := PlaySession.new(_level())
	assert_true(session.start(_program("MMM"), PlaySession.State.PAUSED))
	while session.advance().size() > 0:
		pass
	assert_eq(session.state, PlaySession.State.SUCCEEDED)
	var route := session.route()
	assert_eq(
		route, [Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1), Vector2i(5, 1), Vector2i(6, 1)]
	)


func test_the_mechanic_is_derived_and_supported() -> void:
	assert_true(LevelMechanics.derived(_level()).has("teleport"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("teleport"))
