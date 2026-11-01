class_name Patrol
extends RefCounted
## Where a patrol stands after a number of steps. Mirrors packages/level-contract/src/patrol.ts.
## Pure and deterministic: the cell depends only on the step number.


## The index into the patrol's cells after `step` steps (0 is the start of a run). Back and forth
## has a period of 2 (n - 1); loop has a period of n.
static func index(patrol: Dictionary, step: int) -> int:
	var n: int = (patrol["cells"] as Array).size()
	if patrol["pattern"] == "loop":
		return step % n
	var period := 2 * (n - 1)
	var t := step % period
	return t if t < n else period - t


## The cell [x, y] a patrol stands on after `step` steps.
static func cell(patrol: Dictionary, step: int) -> Array:
	return patrol["cells"][index(patrol, step)]


## The cell where a patrol meets the automaton in one step, or null. The automaton goes from `from`
## to `to` (the same cell for a turn, INC or MARK) as the step count goes from `step` to `step + 1`.
## They meet when a patrol stands on `to` afterwards, or when they swap cells.
static func meeting(patrols: Array, from: Array, to: Array, step: int) -> Variant:
	var moved: bool = int(from[0]) != int(to[0]) or int(from[1]) != int(to[1])
	for patrol: Dictionary in patrols:
		var now := cell(patrol, step + 1)
		if int(now[0]) == int(to[0]) and int(now[1]) == int(to[1]):
			return to
		var before := cell(patrol, step)
		if (
			moved
			and int(before[0]) == int(to[0])
			and int(before[1]) == int(to[1])
			and int(now[0]) == int(from[0])
			and int(now[1]) == int(from[1])
		):
			return to
	return null
