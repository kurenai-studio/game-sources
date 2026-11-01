extends GutTest
## The run state machine over a precomputed simulation. Animation is not involved.


func _level() -> Dictionary:
	# 5x5, start (0,4) facing north, wall at (0,2), goal at (4,4).
	return {
		"schemaVersion": 1,
		"levelId": "t",
		"levelVersion": 1,
		"slug": "t",
		"title": "T",
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": []},
		"board": {"width": 5, "height": 5, "walls": [[0, 2]]},
		"initialState": {"position": [0, 4], "direction": "north"},
		"availableCommands": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
		"constraints": {"maxCommands": 8, "maxSteps": 20},
		"goal": {"type": "reach_tile", "position": [4, 4]},
		"hints": [],
	}


func _program(letters: String) -> Array:
	var ops := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var nodes: Array = []
	for letter in letters:
		nodes.append({"op": ops[letter]})
	return nodes


func test_starts_ready_with_the_initial_state() -> void:
	var session := PlaySession.new(_level())
	assert_eq(session.state, PlaySession.State.READY)
	assert_eq(session.automaton_state()["position"], [0, 4])
	assert_eq(session.automaton_state()["direction"], "north")


func test_run_reveals_one_event_per_advance_and_then_succeeds() -> void:
	var session := PlaySession.new(_level())
	assert_true(session.start(_program("RMMMM")))
	assert_eq(session.state, PlaySession.State.RUNNING)
	for i in 4:
		assert_false(session.advance().is_empty())
		assert_eq(session.state, PlaySession.State.RUNNING)
	assert_eq(session.advance()["event"], "GOAL_REACHED")
	assert_eq(session.state, PlaySession.State.SUCCEEDED)
	assert_true(session.advance().is_empty(), "nothing left after the end")


func test_blocked_move_fails_and_names_the_wall_and_tile() -> void:
	var session := PlaySession.new(_level())
	session.start(_program("MMM"))
	while session.state == PlaySession.State.RUNNING:
		session.advance()
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.result["reason"], "BLOCKED_BY_WALL")
	assert_eq(session.blocked_cell(), Vector2i(0, 2))
	assert_eq(session.failing_node(), [1])


func test_blocked_cell_is_hidden_until_the_run_has_ended() -> void:
	var session := PlaySession.new(_level())
	session.start(_program("MMM"))
	session.advance()
	assert_null(session.blocked_cell())


func test_program_ending_early_has_no_failing_tile() -> void:
	var session := PlaySession.new(_level())
	session.start(_program("R"))
	session.advance()
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.result["reason"], "PROGRAM_ENDED")
	assert_eq(session.failing_node(), [])


func test_empty_program_fails_at_once() -> void:
	var session := PlaySession.new(_level())
	assert_true(session.start([]))
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.result["reason"], "PROGRAM_ENDED")


func test_invalid_program_is_refused_and_stays_ready() -> void:
	var session := PlaySession.new(_level())
	assert_false(session.start([{"op": "JUMP"}]))
	assert_eq(session.state, PlaySession.State.READY)
	var too_long := _program("MMMMMMMMM")
	assert_false(session.start(too_long))
	assert_eq(session.state, PlaySession.State.READY)


func test_pause_and_resume_do_not_change_the_outcome() -> void:
	var straight := PlaySession.new(_level())
	straight.start(_program("RMMMM"))
	while straight.state == PlaySession.State.RUNNING:
		straight.advance()
	var paused := PlaySession.new(_level())
	paused.start(_program("RMMMM"))
	paused.advance()
	paused.pause()
	assert_eq(paused.state, PlaySession.State.PAUSED)
	assert_true(paused.is_active())
	paused.advance()
	paused.resume()
	while paused.state == PlaySession.State.RUNNING:
		paused.advance()
	assert_eq(paused.state, straight.state)
	assert_eq(paused.result, straight.result)


func test_step_start_enters_paused() -> void:
	var session := PlaySession.new(_level())
	session.start(_program("RMMMM"), PlaySession.State.PAUSED)
	assert_eq(session.state, PlaySession.State.PAUSED)
	session.advance()
	assert_eq(session.cursor, 1)
	assert_eq(session.automaton_state()["direction"], "east")


func test_reset_returns_to_the_initial_state() -> void:
	var session := PlaySession.new(_level())
	session.start(_program("RMM"))
	session.advance()
	session.advance()
	session.reset()
	assert_eq(session.state, PlaySession.State.READY)
	assert_eq(session.cursor, 0)
	assert_eq(session.automaton_state()["position"], [0, 4])
	assert_eq(session.trail(), [Vector2i(0, 4)] as Array[Vector2i])


func test_same_program_gives_the_same_result_every_time() -> void:
	var first := PlaySession.new(_level())
	var second := PlaySession.new(_level())
	first.start(_program("RMMMM"))
	second.start(_program("RMMMM"))
	assert_eq(first.result, second.result)


func test_trail_lists_each_visited_cell_once() -> void:
	var session := PlaySession.new(_level())
	session.start(_program("RMMLLMM"))
	while session.state == PlaySession.State.RUNNING:
		session.advance()
	assert_eq(session.trail(), [Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4)] as Array[Vector2i])


func test_a_failure_inside_a_loop_names_the_node_and_the_round() -> void:
	var level := _level()
	level["availableCommands"] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT"]
	var session := PlaySession.new(level)
	var loop := {"op": "REPEAT", "count": 3, "body": [{"op": "MOVE_FORWARD"}]}
	assert_true(session.start([loop]))
	while session.state == PlaySession.State.RUNNING:
		session.advance()
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.failing_node(), [0, 0])
	assert_eq(session.current_entry()["round"], 2)
