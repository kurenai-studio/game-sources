class_name ProcSupport
extends RefCounted
## Shared builders of the procedure tests: a small level, PROC and CALL nodes and a tape.

const ALL: Array[String] = ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "PROC"]
const M := "MOVE_FORWARD"
const L := "TURN_LEFT"
const R := "TURN_RIGHT"


static func level() -> Dictionary:
	# 9x9, start (0,8) facing north, goal at (8,0), nothing in the way.
	return {
		"schemaVersion": 1,
		"levelId": "t",
		"levelVersion": 1,
		"slug": "t",
		"title": "T",
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": []},
		"board": {"width": 9, "height": 9, "walls": []},
		"initialState": {"position": [0, 8], "direction": "north"},
		"availableCommands": ALL,
		"constraints": {"maxCommands": 12, "maxSteps": 60},
		"goal": {"type": "reach_tile", "position": [8, 0]},
		"hints": [],
	}


static func prim(op: String) -> Dictionary:
	return {"op": op}


static func proc(name: String, body: Array) -> Dictionary:
	return {"op": "PROC", "name": name, "body": body}


static func call_node(name: String) -> Dictionary:
	return {"op": "CALL", "name": name}


static func tape(limit: int = 12) -> TapeModel:
	return TapeModel.new(limit, ALL)


## Opens the next definition on the tape, adds the commands to it and closes it.
static func define(target: TapeModel, ops: Array[String]) -> void:
	target.append("PROC")
	for op in ops:
		target.append(op)
	target.end_proc()


static func pairs(result: Dictionary) -> Array[String]:
	return ContractSupport.pairs(result["issues"])
