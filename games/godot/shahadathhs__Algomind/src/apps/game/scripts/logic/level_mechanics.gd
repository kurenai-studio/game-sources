class_name LevelMechanics
extends RefCounted
## What a level asks of the game, read from its content: the mechanic names a client must
## support (`derived`), the commands it offers, and the board features that change the screen.
## A level lists some mechanics itself (requires.mechanics); the others follow from its content,
## so an older client refuses a level that needs them.

const NESTED_LOOPS := ContractLimits.NESTED_LOOPS_MECHANIC


## The commands the level offers, as typed strings.
static func available(level: Dictionary) -> Array[String]:
	var out: Array[String] = []
	for op: String in level["availableCommands"]:
		out.append(op)
	return out


## True when the level lists the mechanic nested_loops (a loop may hold a loop).
static func nested_loops(level: Dictionary) -> bool:
	var requires: Dictionary = level.get("requires", {})
	return (requires.get("mechanics", []) as Array).has(NESTED_LOOPS)


## True when the level lists the mechanic recursion (a procedure may CALL, and a CALL may carry a
## sensor).
static func recursion(level: Dictionary) -> bool:
	var requires: Dictionary = level.get("requires", {})
	return (requires.get("mechanics", []) as Array).has(ContractLimits.RECURSION_MECHANIC)


## True when the level offers INC, so a loop can count with N and the screen shows the counter.
static func has_counter(level: Dictionary) -> bool:
	return (level.get("availableCommands", []) as Array).has(ContractLimits.INC_OP)


## True when the level offers MARK, so the board shows breadcrumbs.
static func has_markers(level: Dictionary) -> bool:
	return (level.get("availableCommands", []) as Array).has(ContractLimits.MARK_OP)


## True when a goal is "visit every cell" (a board has no target).
static func is_sweep(goal: Dictionary) -> bool:
	return goal.get("type") == "visit_all"


## True when any board of the level (its own or an extra one) has a visit_all goal.
static func has_sweep(level: Dictionary) -> bool:
	for one: Dictionary in BoardSet.boards_of(level):
		if is_sweep(one["goal"]):
			return true
	return false


## The floor cells of a board: width times height minus the walls.
static func floor_cells(level: Dictionary) -> int:
	var board: Dictionary = level["board"]
	return int(board["width"]) * int(board["height"]) - (board["walls"] as Array).size()


## The mechanic names the level needs beyond requires.mechanics, in a stable order.
static func derived(level: Dictionary) -> Array[String]:
	var out: Array[String] = []
	if level.has("extraBoards"):
		out.append("multi_board")
	if has_counter(level):
		out.append("counter")
	if has_markers(level):
		out.append("markers")
	if has_sweep(level):
		out.append("visit_all")
	if level.has("startProgram"):
		out.append("start_program")
	if level.has("patrols"):
		out.append("patrol")
	if level.has("locks"):
		out.append("keys")
	if level.has("deliveries"):
		out.append("delivery")
	if level.has("switches"):
		out.append("switch")
	if level.has("teleports"):
		out.append("teleport")
	if level.has("ice"):
		out.append("ice")
	if level.has("belts"):
		out.append("belts")
	return out
