class_name RunStep
extends RefCounted
## Runs one action of a program for LevelSimulator and builds its trace entry and final result.
## Mirrors the step function of packages/level-contract/src/simulate.ts.

const LEFT := "TURN_LEFT"
const RIGHT := "TURN_RIGHT"


## Runs one primitive. Returns the final result Dictionary when the run ends here, else null.
static func step(
	run: Dictionary, command: String, node: Array, round_number: Variant, call_path: Variant
) -> Variant:
	var trace: Array = run["trace"]
	if trace.size() >= int(run["max_steps"]):
		return finish("FAILED", "STEP_LIMIT", null, run)
	var index := trace.size()
	var from: Array = (run["position"] as Array).duplicate()
	var motion := RunWorld.new_motion()
	var base := "MOVED"
	if command == LEFT or command == RIGHT:
		run["direction"] = LevelSimulator.turn(
			run["direction"], "left" if command == LEFT else "right"
		)
		base = "TURNED"
	elif command == ContractLimits.INC_OP:
		run["counter"] = mini(int(run["counter"]) + 1, ContractLimits.COUNTER_MAX)
		base = "COUNTED"
	elif command == ContractLimits.MARK_OP:
		var position: Array = run["position"]
		var here := Vector2i(int(position[0]), int(position[1]))
		var crumbs: Dictionary = run["crumbs"]
		if not crumbs.has(here):
			crumbs[here] = (ContractLimits.DIRECTIONS.find(run["direction"]) + 2) % 4
		base = "MARKED"
	else:
		var blocked := RunWorld.blocked_ahead(run)
		if not blocked.is_empty():
			trace.append(
				_entry(run, index, command, node, call_path, round_number, blocked["event"], [])
			)
			return finish("FAILED", blocked["event"], blocked["cell"], run)
		motion = RunWorld.move(run)
	if command != "MOVE_FORWARD":
		motion = RunWorld.carry(run)

	# A patrol that reaches the automaton in this step ends the run (checked before the goal).
	var path: Array = motion["path"]
	var found: Variant = Patrol.meeting(run["patrols"], from, run["position"], index)
	if found != null:
		trace.append(
			_entry(run, index, command, node, call_path, round_number, "HIT_BY_PATROL", path)
		)
		return finish("FAILED", "HIT_BY_PATROL", found, run)
	if motion["goal"] == "undelivered":
		trace.append(
			_entry(run, index, command, node, call_path, round_number, "UNDELIVERED", path)
		)
		return finish("FAILED", "UNDELIVERED", null, run)
	if motion["goal"] == "reached":
		trace.append(
			_entry(run, index, command, node, call_path, round_number, "GOAL_REACHED", path)
		)
		return finish("SUCCEEDED", "GOAL_REACHED", null, run)
	var event: String = motion["event"]
	if event == "":
		var slid := path.size() > (1 if command == "MOVE_FORWARD" else 0)
		event = ("SLID" if command == "MOVE_FORWARD" else "CARRIED") if slid else base
	trace.append(_entry(run, index, command, node, call_path, round_number, event, path))
	return null


## A trace entry for the state after the step; `path` is kept only on a level with ice or belts.
static func _entry(
	run: Dictionary,
	index: int,
	op: String,
	node: Array,
	call_path: Variant,
	round_number: Variant,
	event: String,
	path: Array
) -> Dictionary:
	var result := entry(
		run, index, op, node, call_path, round_number, run["position"], run["direction"], event
	)
	if run["routed"]:
		result["path"] = path.duplicate(true)
	return result


static func entry(
	run: Dictionary,
	index: int,
	op: String,
	node: Array,
	call_path: Variant,
	round_number: Variant,
	position: Array,
	direction: String,
	event: String
) -> Dictionary:
	return {
		"index": index,
		"op": op,
		"node": node,
		"call": call_path,
		"counter": run["counter"],
		"round": round_number,
		"position": [position[0], position[1]],
		"direction": direction,
		"event": event,
	}


static func finish(
	status: String, reason: String, blocked_cell: Variant, run: Dictionary
) -> Dictionary:
	var position: Array = run["position"]
	return {
		"status": status,
		"reason": reason,
		"steps": (run["trace"] as Array).size(),
		"finalState": {"position": [position[0], position[1]], "direction": run["direction"]},
		"blockedCell": blocked_cell,
		"trace": run["trace"],
	}
