extends GutTest
## A level with guards: where they stand while a run is shown, how a run ends when one reaches the
## automaton, and what the player is told.


func _level() -> Dictionary:
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-step")["level"].duplicate(
		true
	)
	level["board"] = {"width": 5, "height": 3, "walls": []}
	level["initialState"] = {"position": [0, 1], "direction": "east"}
	level["goal"] = {"type": "reach_tile", "position": [4, 1]}
	level["constraints"] = {"maxCommands": 8, "maxSteps": 40}
	# A guard walks up and down the middle row of column 2: (2,1), (2,2), (2,1), (2,2), ...
	level["patrols"] = [{"pattern": "back_and_forth", "cells": [[2, 1], [2, 2]]}]
	return level


func test_guards_stand_by_the_step_count_and_slide_between_steps() -> void:
	var level := _level()
	assert_eq(GuardDraw.positions(level, 0.0), [Vector2(2, 1)] as Array[Vector2])
	assert_eq(GuardDraw.positions(level, 1.0), [Vector2(2, 2)] as Array[Vector2])
	assert_eq(GuardDraw.positions(level, 1.5), [Vector2(2, 1.5)] as Array[Vector2])
	assert_eq(GuardDraw.positions(level, 4.0), [Vector2(2, 1)] as Array[Vector2], "period two")


func test_a_ring_returns_to_its_first_cell_on_the_route() -> void:
	var ring := {"pattern": "loop", "cells": [[0, 0], [1, 0], [1, 1], [0, 1]]}
	var points := GuardDraw.route(ring)
	assert_eq(points.size(), 5)
	assert_eq(points[0], points[4])
	var line := {"pattern": "back_and_forth", "cells": [[0, 0], [1, 0]]}
	assert_eq(GuardDraw.route(line).size(), 2)


func test_a_run_that_meets_a_guard_fails_on_that_cell() -> void:
	var session := PlaySession.new(_level())
	var program := [{"op": "MOVE_FORWARD"}, {"op": "MOVE_FORWARD"}, {"op": "MOVE_FORWARD"}]
	assert_true(session.start(program, PlaySession.State.PAUSED))
	assert_eq(session.result["reason"], "HIT_BY_PATROL")
	assert_eq(session.result["blockedCell"], [2, 1])
	while session.advance().size() > 0:
		pass
	assert_eq(session.state, PlaySession.State.FAILED)
	assert_eq(session.blocked_cell(), Vector2i(2, 1), "the board marks the meeting")
	assert_eq(session.failing_node(), [1], "the second move walked into the guard")
	assert_eq(LoopMessages.for_result(_level(), program, session.result), "")
	assert_eq(ResultMessages.for_result(session.result), "A guard reached the automaton.")


func test_a_route_around_the_guard_reaches_the_target() -> void:
	var ops := ["M", "L", "M", "R", "M", "M", "R", "M", "L", "M"]
	var names := {"M": "MOVE_FORWARD", "L": "TURN_LEFT", "R": "TURN_RIGHT"}
	var program: Array = []
	for op: String in ops:
		program.append({"op": names[op]})
	var result := LevelSimulator.simulate(_level(), program)
	assert_eq(result["status"], "SUCCEEDED", "%s" % [result["reason"]])


func test_the_mechanic_is_derived_and_supported() -> void:
	assert_true(LevelMechanics.derived(_level()).has("patrol"))
	assert_true(Campaign.SUPPORTED_MECHANICS.has("patrol"))
