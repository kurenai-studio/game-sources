class_name RunWorld
extends RefCounted
## How the automaton moves through the board during a run: entering a cell and what lies there, the
## slide on ice, and the carry of a belt. Mirrors the World class of
## packages/level-contract/src/world.ts, so a rule lives in one place per language. A motion is
## { path: the cells entered (each [x, y]), event: the effect of the last cell that had one or "",
## goal: "none", "reached" or "undelivered" }.


static func new_motion() -> Dictionary:
	return {"path": [], "event": "", "goal": "none"}


## True when the automaton can step onto the cell: on the board, no wall, no shut door or gate.
static func can_enter(run: Dictionary, cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= int(run["width"]) or cell.y >= int(run["height"]):
		return false
	return (
		not (run["walls"] as Dictionary).has(cell)
		and not RunLocks.closed_door(run, cell)
		and not RunGates.shut_gate(run, cell)
	)


## Why a move ahead fails (the reason doubles as the trace event) and the cell in the way, or {}.
static func blocked_ahead(run: Dictionary) -> Dictionary:
	var ahead := LevelSimulator.cell_ahead(run["position"], run["direction"])
	var cell := Vector2i(int(ahead[0]), int(ahead[1]))
	var reason := ""
	if cell.x < 0 or cell.y < 0 or cell.x >= int(run["width"]) or cell.y >= int(run["height"]):
		reason = "BLOCKED_BY_BOUNDARY"
	elif (run["walls"] as Dictionary).has(cell):
		reason = "BLOCKED_BY_WALL"
	elif RunLocks.closed_door(run, cell):
		reason = "BLOCKED_BY_DOOR"
	elif RunGates.shut_gate(run, cell):
		reason = "BLOCKED_BY_GATE"
	if reason == "":
		return {}
	return {"event": reason, "cell": ahead}


## Moves one cell ahead (the way must not be blocked). On ice the automaton goes on sliding while
## the next cell is enterable; it stops on a cell that is not ice. Then a belt under it carries it
## one cell. The move ends the moment the target is entered.
static func move(run: Dictionary) -> Dictionary:
	var motion := new_motion()
	while true:
		var ahead := LevelSimulator.cell_ahead(run["position"], run["direction"])
		var next := Vector2i(int(ahead[0]), int(ahead[1]))
		if _enter(run, next, motion):
			return motion
		if motion["event"] == "TELEPORTED":
			break
		var after := LevelSimulator.cell_ahead(run["position"], run["direction"])
		if not (run["ice"] as Dictionary).has(next):
			break
		if not can_enter(run, Vector2i(int(after[0]), int(after[1]))):
			break
	_carry(run, motion)
	return motion


## After an action that does not move the automaton: a belt under it carries it one cell.
static func carry(run: Dictionary) -> Dictionary:
	var motion := new_motion()
	_carry(run, motion)
	return motion


static func _carry(run: Dictionary, motion: Dictionary) -> void:
	var position: Array = run["position"]
	var here := Vector2i(int(position[0]), int(position[1]))
	var belts: Dictionary = run["belts"]
	if not belts.has(here):
		return
	var delta: Array = ContractLimits.DIRECTION_DELTAS[belts[here]]
	var next := Vector2i(here.x + int(delta[0]), here.y + int(delta[1]))
	if can_enter(run, next):
		_enter(run, next, motion)


## Enters a cell and applies what lies there. Returns true when the target ended the move.
static func _enter(run: Dictionary, cell: Vector2i, motion: Dictionary) -> bool:
	run["position"] = [cell.x, cell.y]
	(run["visited"] as Dictionary)[cell] = true
	(motion["path"] as Array).append([cell.x, cell.y])
	var reached: bool
	if run["goal"] == null:
		reached = (run["visited"] as Dictionary).size() == int(run["floor_cells"])
	else:
		reached = cell == run["goal"]
	if reached:
		motion["goal"] = "undelivered" if RunItems.pending(run) else "reached"
		return true
	var portals: Dictionary = run["portals"]
	if portals.has(cell):
		var far: Vector2i = portals[cell]
		run["position"] = [far.x, far.y]
		(run["visited"] as Dictionary)[far] = true
		(motion["path"] as Array).append([far.x, far.y])
		motion["event"] = "TELEPORTED"
		return false
	var event := "KEY_TAKEN" if RunLocks.take_key(run, cell) else RunItems.settle(run, cell)
	if event == "" and RunGates.toggle(run, cell):
		event = "SWITCHED"
	if event != "":
		motion["event"] = event
	return false
