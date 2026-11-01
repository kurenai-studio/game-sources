class_name PlaySession
extends RefCounted
## One attempt at a level: the run state machine over a precomputed simulation.
##
## `start` asks LevelSimulator for the full event list in one call. The session then hands
## the events out one at a time with `advance`; the screen animates each one. Nothing here
## reads a clock or a frame, so the outcome cannot depend on animation.
## States: READY, RUNNING, PAUSED, SUCCEEDED, FAILED (docs/README_GAME_RULES.md section 4).

enum State { READY, RUNNING, PAUSED, SUCCEEDED, FAILED }

## The failures that an instruction caused (the others end the run without one).
const FAILING_REASONS := [
	"BLOCKED_BY_WALL",
	"BLOCKED_BY_BOUNDARY",
	"BLOCKED_BY_DOOR",
	"HIT_BY_PATROL",
	"UNDELIVERED",
	"BLOCKED_BY_GATE",
]

var level: Dictionary
var state := State.READY
## The simulator result for the program that was started; empty while READY.
var result: Dictionary = {}
## How many trace entries have been shown so far.
var cursor := 0


func _init(level_data: Dictionary) -> void:
	level = level_data


## Simulates `program` (Array of instruction nodes) and enters `next_state` (RUNNING or PAUSED).
## Returns false, and stays READY, when the program is not valid for this level.
func start(program: Array, next_state: State = State.RUNNING) -> bool:
	if not LevelValidator.validate_program(level, program)["ok"]:
		return false
	result = LevelSimulator.simulate(level, program)
	cursor = 0
	state = next_state
	_finish_if_done()
	return true


func is_active() -> bool:
	return state == State.RUNNING or state == State.PAUSED


func is_finished() -> bool:
	return state == State.SUCCEEDED or state == State.FAILED


func pause() -> void:
	if state == State.RUNNING:
		state = State.PAUSED


func resume() -> void:
	if state == State.PAUSED:
		state = State.RUNNING


## Shows the next event. Returns it, or an empty Dictionary when there is none left.
func advance() -> Dictionary:
	if not is_active() or cursor >= trace().size():
		return {}
	var entry: Dictionary = trace()[cursor]
	cursor += 1
	_finish_if_done()
	return entry


func reset() -> void:
	state = State.READY
	result = {}
	cursor = 0


func trace() -> Array:
	return result.get("trace", [])


## The event shown last, or an empty Dictionary before the first step.
func current_entry() -> Dictionary:
	if cursor == 0:
		return {}
	return trace()[cursor - 1]


## Automaton position and direction after `cursor` events.
func automaton_state() -> Dictionary:
	var entry := current_entry()
	if entry.is_empty():
		var initial: Dictionary = level["initialState"]
		var start_cell: Array = initial["position"]
		return {
			"position": [int(start_cell[0]), int(start_cell[1])], "direction": initial["direction"]
		}
	return {"position": entry["position"], "direction": entry["direction"]}


## Every cell the automaton has entered so far, in order and with repeats, the start first. A step
## on a level with ice or belts lists all the cells it went through (its `path`); otherwise a move
## that was not blocked entered the cell it ended on. Effects of the board (keys, crates, switches)
## are replayed from this list.
func route() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var start_cell: Array = level["initialState"]["position"]
	cells.append(Vector2i(int(start_cell[0]), int(start_cell[1])))
	for i in cursor:
		var entry: Dictionary = trace()[i]
		var entered: Array = []
		if entry.has("path"):
			entered = entry["path"]
		elif entry["op"] == "MOVE_FORWARD" and not str(entry["event"]).begins_with("BLOCKED"):
			entered = [entry["position"]]
		for cell: Array in entered:
			cells.append(Vector2i(int(cell[0]), int(cell[1])))
	return cells


## Cells the automaton has stood on so far, start included, as Vector2i, each once.
func trail() -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for point in route():
		if not cells.has(point):
			cells.append(point)
	return cells


## The breadcrumbs dropped so far: cell to the name of the direction its arrow points. The arrow
## points away from where the automaton faced; a cell keeps its first crumb.
func crumbs() -> Dictionary:
	var out := {}
	for i in cursor:
		var entry: Dictionary = trace()[i]
		if entry["event"] != "MARKED":
			continue
		var cell: Array = entry["position"]
		var point := Vector2i(int(cell[0]), int(cell[1]))
		if not out.has(point):
			var facing := ContractLimits.DIRECTIONS.find(entry["direction"])
			out[point] = ContractLimits.DIRECTIONS[(facing + 2) % 4]
	return out


## The wall or edge cell that stopped a failed run (shown once the run has ended), else null.
func blocked_cell() -> Variant:
	if state != State.FAILED:
		return null
	var cell: Variant = result.get("blockedCell")
	if cell == null:
		return null
	return Vector2i(int(cell[0]), int(cell[1]))


## The program node ([i] or [i, j] in a loop) that caused a failure, or an empty Array when no
## instruction did (program ended, step limit).
func failing_node() -> Array:
	if state != State.FAILED:
		return []
	var reason: String = result.get("reason", "")
	if FAILING_REASONS.has(reason):
		return trace()[trace().size() - 1]["node"]
	return []


func _finish_if_done() -> void:
	if cursor < trace().size():
		return
	state = State.SUCCEEDED if result.get("status") == "SUCCEEDED" else State.FAILED
