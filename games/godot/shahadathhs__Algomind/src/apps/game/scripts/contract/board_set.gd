class_name BoardSet
extends RefCounted
## The boards of a level: its own and its extra test boards.
## Mirrors boardsOf and levelOnBoard in packages/level-contract/src/simulate-boards.ts.


## Every board of the level as {board, initialState, goal}: its own first, then the extra boards.
static func boards_of(level: Dictionary) -> Array:
	var out: Array = [
		{"board": level["board"], "initialState": level["initialState"], "goal": level["goal"]}
	]
	out.append_array(level.get("extraBoards", []))
	return out


## The level as if board `index` (0 is its own) were its only board: what simulate() runs.
static func level_on_board(level: Dictionary, index: int) -> Dictionary:
	var boards := boards_of(level)
	var out := level.duplicate()
	out.erase("extraBoards")
	out.merge(boards[index], true)
	return out
