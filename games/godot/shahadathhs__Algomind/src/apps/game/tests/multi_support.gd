class_name MultiSupport
extends RefCounted
## Shared builders of the test-board tests: a level with extra boards and two programs for it.

const M := "MOVE_FORWARD"


## Own board 5 by 3 (goal at the far end of the middle row), extra boards 8 and 3 wide.
static func level(extra_count: int = 2) -> Dictionary:
	var extras: Array = [_board(8), _board(3), _board(6), _board(7), _board(9)]
	var out := {
		"schemaVersion": 1,
		"levelId": "mb",
		"levelVersion": 1,
		"slug": "mb",
		"title": "Boards",
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": ["multi_board"]},
		"availableCommands": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL"],
		"constraints": {"maxCommands": 8, "maxSteps": 60},
		"hints": [],
		"extraBoards": extras.slice(0, extra_count),
	}
	out.merge(_board(5))
	return out


static func _board(width: int) -> Dictionary:
	return {
		"board": {"width": width, "height": 3, "walls": []},
		"initialState": {"position": [0, 1], "direction": "east"},
		"goal": {"type": "reach_tile", "position": [width - 1, 1]},
	}


## Move until blocked: reaches the far end of any corridor.
static func general() -> Array:
	return [{"op": "REPEAT_UNTIL", "until": "BLOCKED", "body": [{"op": M}]}]


## Four moves: right for the first board only.
static func overfit() -> Array:
	return [{"op": "REPEAT", "count": 4, "body": [{"op": M}]}]
