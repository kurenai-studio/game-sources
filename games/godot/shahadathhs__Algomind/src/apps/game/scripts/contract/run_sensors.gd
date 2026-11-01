class_name RunSensors
extends RefCounted
## What an IF can look at during a run. Mirrors the sensor function of
## packages/level-contract/src/simulate.ts. A reading is free.


## True when the sensor reads true. CLEAR: the cell on that side is on the board and not a wall.
## FRESH: such a cell with no breadcrumb. BACK: the cell on that side is the one the breadcrumb
## of the automaton's own cell points to. A sensor is KIND_SIDE, such as FRESH_LEFT.
static func sense(run: Dictionary, sensor: String) -> bool:
	var parts := sensor.split("_")
	var kind := parts[0]
	var side := parts[1]
	var facing: String = run["direction"]
	if side == "LEFT":
		facing = LevelSimulator.turn(facing, "left")
	elif side == "RIGHT":
		facing = LevelSimulator.turn(facing, "right")
	var target := LevelSimulator.cell_ahead(run["position"], facing)
	var cell := Vector2i(int(target[0]), int(target[1]))
	if cell.x < 0 or cell.y < 0 or cell.x >= int(run["width"]) or cell.y >= int(run["height"]):
		return false
	if (
		(run["walls"] as Dictionary).has(cell)
		or RunLocks.closed_door(run, cell)
		or RunGates.shut_gate(run, cell)
	):
		return false
	if kind == "CLEAR":
		return true
	var crumbs: Dictionary = run["crumbs"]
	if kind == "FRESH":
		return not crumbs.has(cell)
	var here := Vector2i(int(run["position"][0]), int(run["position"][1]))
	if not crumbs.has(here):
		return false
	var delta: Array = ContractLimits.DIRECTION_DELTAS[ContractLimits.DIRECTIONS[crumbs[here]]]
	return cell == here + Vector2i(int(delta[0]), int(delta[1]))
