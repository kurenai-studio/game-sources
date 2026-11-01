extends GutTest
## A level with crates and docks: what is carried, how a run ends at the target with a crate left,
## what the player is told, and what the board shows.


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	level["board"] = {"width": 5, "height": 3, "walls": []}
	level["initialState"] = {"position": [0, 1], "direction": "east"}
	level["goal"] = {"type": "reach_tile", "position": [4, 1]}
	level["constraints"] = {"maxCommands": 12, "maxSteps": 40}
	level["deliveries"] = [{"item": [1, 1], "dock": [3, 1]}]
	return level


func _program(ops: String) -> Array:
	var names := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var out: Array = []
	for letter in ops:
		out.append({"op": names[letter]})
	return out


func test_the_target_with_a_crate_left_fails_on_the_last_move() -> void:
	var level := _level()
	level["deliveries"] = [{"item": [1, 0], "dock": [2, 0]}]
	var session := PlaySession.new(level)
	assert_true(session.start(_program("MMMM"), PlaySession.State.PAUSED))
	assert_eq(session.result["reason"], "UNDELIVERED")
	while session.advance().size() > 0:
		pass
	assert_eq(session.failing_node(), [3], "the fourth move entered the target too early")
	assert_eq(
		ResultMessages.for_result(session.result),
		"The automaton reached the target before every item was delivered."
	)


func test_carrying_a_crate_to_its_dock_then_the_target_succeeds() -> void:
	var result := LevelSimulator.simulate(_level(), _program("MMMM"))
	assert_eq(result["status"], "SUCCEEDED", "%s" % [result["reason"]])
	var events: Array[String] = []
	for entry: Dictionary in result["trace"]:
		events.append(entry["event"])
	assert_eq(events, ["ITEM_TAKEN", "MOVED", "ITEM_DROPPED", "GOAL_REACHED"])


func test_full_hands_leave_a_second_crate_where_it_lies() -> void:
	var level := _level()
	level["deliveries"] = [{"item": [1, 1], "dock": [3, 0]}, {"item": [2, 1], "dock": [3, 2]}]
	var result := LevelSimulator.simulate(level, _program("MM"))
	assert_eq(result["trace"][1]["event"], "MOVED", "the crate at (2,1) was walked over")


func test_the_board_replays_what_is_carried_and_delivered_from_the_trail() -> void:
	var level := _level()
	var start := Vector2i(0, 1)
	var empty: Array[Vector2i] = [start]
	var carrying: Array[Vector2i] = [start, Vector2i(1, 1)]
	var done: Array[Vector2i] = [start, Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1)]
	assert_eq(ItemDraw.state(level, empty)["carrying"], -1)
	assert_eq(ItemDraw.state(level, carrying)["carrying"], 0)
	var after := ItemDraw.state(level, done)
	assert_eq(after["carrying"], -1)
	assert_true((after["delivered"] as Dictionary).has(0))


func test_the_mechanic_is_derived_and_supported() -> void:
	assert_true(LevelMechanics.derived(_level()).has("delivery"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("delivery"))
