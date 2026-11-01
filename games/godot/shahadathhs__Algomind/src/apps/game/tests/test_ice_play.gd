extends GutTest
## A level with ice and belts: the route of a step, what the board replays from it, and the
## mechanics the game reports.


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	level["board"] = {"width": 7, "height": 3, "walls": []}
	level["initialState"] = {"position": [0, 1], "direction": "east"}
	level["goal"] = {"type": "reach_tile", "position": [6, 1]}
	level["constraints"] = {"maxCommands": 12, "maxSteps": 40}
	level["ice"] = [[2, 1], [3, 1], [4, 1]]
	return level


func _program(ops: String) -> Array:
	var names := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var out: Array = []
	for letter in ops:
		out.append({"op": names[letter]})
	return out


func test_a_slide_lists_every_cell_it_went_through() -> void:
	var result := LevelSimulator.simulate(_level(), _program("MM"))
	assert_eq(result["trace"][1]["event"], "SLID")
	assert_eq(result["trace"][1]["path"], [[2, 1], [3, 1], [4, 1], [5, 1]])
	assert_eq(result["finalState"]["position"], [5, 1])


func test_a_level_without_ice_or_belts_has_no_path_in_its_trace() -> void:
	var level := _level()
	level.erase("ice")
	var result := LevelSimulator.simulate(level, _program("M"))
	assert_false(result["trace"][0].has("path"))


func test_the_route_has_every_cell_entered_and_the_trail_each_once() -> void:
	var session := PlaySession.new(_level())
	assert_true(session.start(_program("MMLR"), PlaySession.State.PAUSED))
	while session.advance().size() > 0:
		pass
	var route := session.route()
	assert_eq(route.size(), 1 + 1 + 4, "the start, one cell, and the four cells of the slide")
	assert_eq(route[2], Vector2i(2, 1))
	var trail := session.trail()
	assert_eq(trail.size(), route.size(), "no cell was entered twice")


func test_a_key_taken_mid_slide_is_held_by_the_board() -> void:
	var level := _level()
	level["locks"] = [{"key": [3, 1], "door": [5, 1]}]
	var session := PlaySession.new(level)
	assert_true(session.start(_program("MM"), PlaySession.State.PAUSED))
	while session.advance().size() > 0:
		pass
	assert_true(LockDraw.held(level, session.route()).has(0))
	assert_false(LockDraw.held(level, session.trail().slice(0, 2)).has(0))


func test_the_mechanics_are_derived_and_supported() -> void:
	var level := _level()
	level["belts"] = [{"cell": [1, 1], "direction": "east"}]
	assert_true(LevelMechanics.derived(level).has("ice"))
	assert_true(LevelMechanics.derived(level).has("belts"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("ice"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("belts"))
