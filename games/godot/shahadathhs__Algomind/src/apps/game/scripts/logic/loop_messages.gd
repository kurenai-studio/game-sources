class_name LoopMessages
extends RefCounted
## Plain-language failure text that depends on which loop was running. ResultMessages holds the
## text for each reason code; this adds the cases a code alone cannot tell apart.


## The text for a finished run that depends on a loop or on the sweep goal, or "" when the
## standard text for the result's reason applies. `program` is the program that was run.
static func for_result(level: Dictionary, program: Array, result: Dictionary) -> String:
	if result.get("status") != "FAILED":
		return ""
	var reason: String = result.get("reason", "")
	var base := _loop_text(level, program, result) if reason == "STEP_LIMIT" else ""
	if not LevelMechanics.is_sweep(level["goal"]):
		return base
	if reason == "PROGRAM_ENDED":
		base = "The program ended before every cell was visited."
	elif reason == "STEP_LIMIT" and base == "":
		base = ResultMessages.for_reason(reason)
	elif reason != "STEP_LIMIT":
		return base
	return "%s Cells left: %d." % [base, cells_left(level, result)]


## The floor cells the run did not enter (the start cell counts as entered).
static func cells_left(level: Dictionary, result: Dictionary) -> int:
	var seen := {}
	var start: Array = level["initialState"]["position"]
	seen[Vector2i(int(start[0]), int(start[1]))] = true
	for entry: Dictionary in result.get("trace", []):
		seen[Vector2i(int(entry["position"][0]), int(entry["position"][1]))] = true
	return LevelMechanics.floor_cells(level) - seen.size()


## The text for a run stopped by the step limit when a loop explains it, else "".
static func _loop_text(level: Dictionary, program: Array, result: Dictionary) -> String:
	var trace: Array = result.get("trace", [])
	if int(result.get("steps", 0)) < int(level["constraints"]["maxSteps"]):
		# Stopped below the step limit: a round of a REPEAT_UNTIL ran no command at all.
		return "A round of the loop did nothing, so it was stopped."
	if trace.is_empty():
		return ""
	var loops := _loops_on(program, trace[trace.size() - 1]["node"])
	loops.reverse()
	for loop in loops:
		if ContractLimits.is_repeat(loop["op"]) and loop["count"] is String:
			return "The loop that counts with N ran for too many steps, so it was stopped."
		if not ContractLimits.is_repeat_until(loop["op"]):
			continue
		if loop["until"] == "GOAL":
			return "The loop never reached the goal, so it was stopped."
		if _blocked_ahead(level, result):
			return ""
		return "The loop never reached a wall, so it was stopped."
	return ""


## The loops that the step at `node` ran in, outermost first (a loop of a procedure body
## included). An IF ends the search: its branches hold no loops.
static func _loops_on(program: Array, node: Array) -> Array:
	var out: Array = []
	if node.size() < 2 or int(node[0]) >= program.size():
		return out
	var current: Dictionary = program[int(node[0])]
	for depth in range(1, node.size()):
		if not (ContractLimits.is_loop(current["op"]) or ContractLimits.is_proc(current["op"])):
			break
		if ContractLimits.is_loop(current["op"]):
			out.append(current)
		if depth == node.size() - 1:
			break
		current = (current["body"] as Array)[int(node[depth])]
	return out


## True when the way ahead of the automaton is blocked at the end of the run.
static func _blocked_ahead(level: Dictionary, result: Dictionary) -> bool:
	var state: Dictionary = result["finalState"]
	return LevelSimulator.blocked_ahead(level, state["position"], String(state["direction"]))


## The objective text while the program is being built: what is missing, else the goal.
static func building_text(tape: TapeModel, sweep: bool = false, fix: bool = false) -> String:
	if TapeCells.has_empty_loop(tape.nodes):
		return "ADD A COMMAND TO THE LOOP"
	if TapeCells.has_empty_if(tape.nodes):
		return "ADD A COMMAND TO THE IF"
	if tape.has_empty_proc():
		return "ADD A COMMAND TO THE PROCEDURE"
	var missing := tape.undefined_calls()
	if not missing.is_empty():
		return "PROCEDURE %s IS NOT DEFINED" % " AND ".join(missing)
	if fix:
		# A debug level: the program is already on the tape and the job is to correct it.
		return "FIX THE PROGRAM"
	return "VISIT EVERY CELL" if sweep else "REACH THE TARGET"
