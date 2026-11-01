class_name IfSupport
extends RefCounted
## Shared builders of the IF tests: a small level, IF nodes and an open IF on a tape.

const ALL: Array[String] = [
	"MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL", "IF"
]


static func level() -> Dictionary:
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
		"availableCommands": ALL,
		"constraints": {"maxCommands": 8, "maxSteps": 20},
		"goal": {"type": "reach_tile", "position": [4, 4]},
		"hints": [],
	}


static func if_node(when: String, then_list: Array, else_list: Array = []) -> Dictionary:
	return {"op": "IF", "when": when, "then": then_list, "else": else_list}


static func tape(limit: int = 12) -> TapeModel:
	return TapeModel.new(limit, ALL)


## Opens an IF on the tape and adds the commands to its then branch.
static func open_if(target: TapeModel, then_ops: Array[String]) -> void:
	target.append("IF")
	for op in then_ops:
		target.append(op)
