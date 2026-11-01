class_name LevelSimulator
extends RefCounted
## Runs a program on a level. Pure and deterministic: no scene, clock, randomness, or I/O,
## and the inputs are never modified. Animation displays the returned trace.
##
## Mirrors packages/level-contract/src/simulate.ts. Expects a level that passed
## LevelValidator.validate_level and does not check availableCommands or maxCommands;
## callers run LevelValidator.validate_program first.
##
## Numbers: JSON parsing yields floats, so every coordinate is read with int(). Positions in
## the result are Arrays of two ints, [x, y], and blockedCell is such an Array or null.


## Rotates a direction name 90 degrees. "left" is counterclockwise, "right" clockwise.
static func turn(direction: String, side: String) -> String:
	var i := ContractLimits.DIRECTIONS.find(direction)
	var next := (i + (1 if side == "right" else 3)) % 4
	return ContractLimits.DIRECTIONS[next]


## The cell one step ahead of position [x, y] when facing direction. May lie outside the board.
static func cell_ahead(position: Array, direction: String) -> Array:
	var delta: Array = ContractLimits.DIRECTION_DELTAS[direction]
	return [int(position[0]) + int(delta[0]), int(position[1]) + int(delta[1])]


## True when a wall or the board edge is straight ahead of position facing direction.
static func blocked_ahead(level: Dictionary, position: Array, direction: String) -> bool:
	var board: Dictionary = level["board"]
	var target := cell_ahead(position, direction)
	var tx := int(target[0])
	var ty := int(target[1])
	if tx < 0 or ty < 0 or tx >= int(board["width"]) or ty >= int(board["height"]):
		return true
	for wall: Array in board["walls"]:
		if int(wall[0]) == tx and int(wall[1]) == ty:
			return true
	return false


## Runs one checked node at path. round_number is the round of the loop it stands in and call the
## path of the CALL that is running it (or null). Returns the final result or null.
static func _run(
	run: Dictionary, node: Dictionary, path: Array, round_number: Variant, call_path: Variant
) -> Variant:
	var op: String = node["op"]
	if ProgramShape.is_primitive(node):
		return RunStep.step(run, op, path, round_number, call_path)
	var result: Variant = null
	if ContractLimits.is_if(op):
		return _run_if(run, node, path, round_number, call_path)
	if ContractLimits.is_call(op):
		if node.has("when") and not RunSensors.sense(run, String(node["when"])):
			return null
		if not (run["procs"] as Dictionary).has(node["name"]):
			return RunStep.finish("FAILED", "INVALID_INSTRUCTION", null, run)
		run["depth"] = int(run["depth"]) + 1
		if int(run["depth"]) > ContractLimits.CALL_DEPTH_MAX:
			return RunStep.finish("FAILED", "TOO_DEEP", null, run)
		var target: Dictionary = run["procs"][node["name"]]
		var body: Array = target["node"]["body"]
		for j in body.size():
			result = _run(run, body[j], [target["index"], j], null, path)
			if result != null:
				return result
		run["depth"] = int(run["depth"]) - 1
		return null

	var items: Array = node["body"]
	if ContractLimits.is_repeat(op):
		var rounds: int = (
			int(run["counter"]) if typeof(node["count"]) == TYPE_STRING else int(node["count"])
		)
		for r in range(1, rounds + 1):
			result = _run_body(run, items, path, r, call_path)
			if result != null:
				return result
		return null

	# REPEAT_UNTIL: the condition is checked before every round and costs no step. GOAL is never
	# true at the start of a round. A round that ran no primitive would repeat for ever.
	var round_number_until := 1
	while not (node["until"] == "BLOCKED" and not RunSensors.sense(run, "CLEAR_AHEAD")):
		var before := (run["trace"] as Array).size()
		result = _run_body(run, items, path, round_number_until, call_path)
		if result != null:
			return result
		if (run["trace"] as Array).size() == before:
			return RunStep.finish("FAILED", "STEP_LIMIT", null, run)
		round_number_until += 1
	return null


## Runs an IF: its then actions, or its else (actions, or the next IF of an else-if chain).
static func _run_if(
	run: Dictionary, node: Dictionary, path: Array, round_number: Variant, call_path: Variant
) -> Variant:
	var then: Array = node["then"]
	var other: Array = node["else"]
	var taken_then := RunSensors.sense(run, String(node["when"]))
	if not taken_then and other.size() == 1 and ContractLimits.is_if(other[0]["op"]):
		var next_path := path.duplicate()
		next_path.append(then.size())
		return _run_if(run, other[0], next_path, round_number, call_path)
	var branch: Array = then if taken_then else other
	var offset: int = 0 if taken_then else then.size()
	for k in branch.size():
		var inner_path := path.duplicate()
		inner_path.append(offset + k)
		var result: Variant = RunStep.step(
			run, String(branch[k]["op"]), inner_path, round_number, call_path
		)
		if result != null:
			return result
	return null


## Runs the body of the loop at path once, as round_number. Returns the final result or null.
static func _run_body(
	run: Dictionary, body: Array, path: Array, round_number: int, call_path: Variant
) -> Variant:
	for j in body.size():
		var inner_path := path.duplicate()
		inner_path.append(j)
		var result: Variant = _run(run, body[j], inner_path, round_number, call_path)
		if result != null:
			return result
	return null


## Runs program (an Array of instruction nodes) on level (parsed JSON Dictionary).
## Returns { status, reason, steps, finalState, blockedCell, trace }.
##
## Every executed primitive is one step; a loop, IF, CALL or PROC itself costs none, and
## choosing an IF branch is free. A REPEAT_UNTIL checks its condition before every round (free),
## so it may run zero rounds; a round that runs no primitive stops the run with STEP_LIMIT. A PROC
## is a definition: skipped where it stands. A CALL runs the body of the first well-formed PROC of
## its name. The step limit is checked before each top-level node and before each primitive. The
## run succeeds the moment the goal cell is entered, even in the middle of a loop or a procedure.
static func simulate(level: Dictionary, program: Array) -> Dictionary:
	var board: Dictionary = level["board"]
	var walls := {}
	for wall: Array in board["walls"]:
		walls[Vector2i(int(wall[0]), int(wall[1]))] = true

	var initial: Dictionary = level["initialState"]
	var start: Array = initial["position"]
	var goal: Dictionary = level["goal"]
	var goal_cell: Variant = null
	if goal.has("position"):
		goal_cell = Vector2i(int(goal["position"][0]), int(goal["position"][1]))
	var start_cell := Vector2i(int(start[0]), int(start[1]))
	var top := ProgramShape.top_place(_has_recursion(level))
	var names := ProgramShape.proc_names(program)
	# The run state lives in one Dictionary so that step() can change it.
	var run := {
		"width": int(board["width"]),
		"height": int(board["height"]),
		"walls": walls,
		"goal": goal_cell,
		"counter": ContractLimits.COUNTER_START,
		"crumbs": {},
		"visited": {start_cell: true},
		"floor_cells": int(board["width"]) * int(board["height"]) - walls.size(),
		"position": [int(start[0]), int(start[1])],
		"direction": String(initial["direction"]),
		"trace": [],
		"max_steps": int(level["constraints"]["maxSteps"]),
		"procs": ProgramShape.reachable_procs(program, top),
		"depth": 0,
		"patrols": level.get("patrols", []),
		"keys": RunLocks.tables(level)["keys"],
		"doors": RunLocks.tables(level)["doors"],
		"held": {},
		"items": RunItems.tables(level)["items"],
		"docks": RunItems.tables(level)["docks"],
		"ice": _ice_cells(level),
		"belts": _belt_cells(level),
		"portals": _portal_cells(level),
		"routed": level.has("ice") or level.has("belts") or level.has("teleports"),
		"switches": RunGates.tables(level)["switches"],
		"gates": RunGates.tables(level)["gates"],
		"starts_open": RunGates.tables(level)["starts_open"],
		"flipped": {},
		"carrying": -1,
		"delivered": {},
	}

	for i in program.size():
		var node: Variant = program[i]
		if typeof(node) == TYPE_DICTIONARY and ContractLimits.is_proc(node.get("op")):
			# A definition: skipped when well formed, a content error when not.
			if not ProgramShape.is_runnable(node, top, names):
				return RunStep.finish("FAILED", "INVALID_INSTRUCTION", null, run)
			continue
		if (run["trace"] as Array).size() >= int(run["max_steps"]):
			return RunStep.finish("FAILED", "STEP_LIMIT", null, run)
		if not ProgramShape.is_runnable(node, top, run["procs"]):
			return RunStep.finish("FAILED", "INVALID_INSTRUCTION", null, run)
		var result: Variant = _run(run, node, [i], null, null)
		if result != null:
			return result

	return RunStep.finish("FAILED", "PROGRAM_ENDED", null, run)


## Runs program on every board (all are always run).
## Returns { status, firstFailure, steps, results }. firstFailure is the index of the first
## failed board or null, steps the sum over all boards.
static func simulate_all(level: Dictionary, program: Array) -> Dictionary:
	var results: Array = []
	var steps := 0
	var failed: Variant = null
	for i in BoardSet.boards_of(level).size():
		var result := simulate(BoardSet.level_on_board(level, i), program)
		results.append(result)
		steps += int(result["steps"])
		if failed == null and result["status"] != "SUCCEEDED":
			failed = i
	return {
		"status": "SUCCEEDED" if failed == null else "FAILED",
		"firstFailure": failed,
		"steps": steps,
		"results": results,
	}


## The ice cells of a level as a set of cells.
static func _ice_cells(level: Dictionary) -> Dictionary:
	var out := {}
	for cell: Array in level.get("ice", []):
		out[Vector2i(int(cell[0]), int(cell[1]))] = true
	return out


## The belts of a level: cell to the name of the direction it carries.
static func _belt_cells(level: Dictionary) -> Dictionary:
	var out := {}
	for belt: Dictionary in level.get("belts", []):
		out[Vector2i(int(belt["cell"][0]), int(belt["cell"][1]))] = String(belt["direction"])
	return out


## The teleporters of a level: each end to the cell of the other end.
static func _portal_cells(level: Dictionary) -> Dictionary:
	var out := {}
	for pair: Dictionary in level.get("teleports", []):
		var a := Vector2i(int(pair["a"][0]), int(pair["a"][1]))
		var b := Vector2i(int(pair["b"][0]), int(pair["b"][1]))
		out[a] = b
		out[b] = a
	return out


## True when the level lists the mechanic recursion.
static func _has_recursion(level: Dictionary) -> bool:
	var requires: Variant = level.get("requires")
	if typeof(requires) != TYPE_DICTIONARY:
		return false
	var mechanics: Variant = requires.get("mechanics")
	return (
		typeof(mechanics) == TYPE_ARRAY
		and (mechanics as Array).has(ContractLimits.RECURSION_MECHANIC)
	)
