class_name RunState extends RefCounted
## The current run (GDD 15.1): the board, the score, the Undo snapshot, this
## run's highest tile and the free boosters used. Plain data with small
## helpers. Only RunRules, BoosterRules and SaveCodec create or change one.
## Boards and run_highest hold exponents (the tile is 2^k, 0 is empty); the
## score and points are BigNum (docs/ARCHITECTURE.md section 17).
##
## Packed arrays are shared by reference in GDScript, so code that changes a
## board works on a duplicate and assigns it back.

var columns: int = 5
var cells: PackedInt64Array = PackedInt64Array()             # the board, row by row
var score: BigNum = BigNum.zero()
var snapshot_cells: PackedInt64Array = PackedInt64Array()    # Undo snapshot board; empty when there is no snapshot
var snapshot_points: BigNum = BigNum.zero()                  # the snapshot chain's points
var run_highest: int = 0                                     # D-41, an exponent
var free_used: int = 0                                       # D-46: free boosters used this run. Only ever goes up. Not part of the Undo snapshot.
var best_at_start: BigNum = null                             # QA6-03: Best Score when this run began. null means unknown (a format 1 run file). Core never sets it. Not part of the Undo snapshot.


## TH1. Builds a state directly. run_highest 0 means "the highest exponent on cells".
## The arrays are copied, so the caller may keep changing its own. A null
## score or snapshot_points means 0.
@warning_ignore("shadowed_variable")
static func create(cells: PackedInt64Array, score: BigNum, snapshot_cells: PackedInt64Array = PackedInt64Array(), snapshot_points: BigNum = null, run_highest: int = 0, columns: int = 5, free_used: int = 0, best_at_start: BigNum = null) -> RunState:
	var state: RunState = RunState.new()
	state.columns = columns
	state.cells = cells.duplicate()
	state.score = score if score != null else BigNum.zero()
	state.snapshot_cells = snapshot_cells.duplicate()
	state.snapshot_points = snapshot_points if snapshot_points != null else BigNum.zero()
	state.run_highest = run_highest if run_highest != 0 else CoreRules.highest(cells)
	state.free_used = free_used
	state.best_at_start = best_at_start
	return state


func has_snapshot() -> bool:
	return not snapshot_cells.is_empty()


## The exponent on cell, or 0 when the cell is off the board.
func value_at(cell: Vector2i) -> int:
	if cell.x < 0 or cell.x >= columns or cell.y < 0:
		return 0
	var index: int = CoreRules.index_of(cell, columns)
	if index >= cells.size():
		return 0
	return cells[index]


## H: the highest exponent on the board.
func highest() -> int:
	return CoreRules.highest(cells)


## A deep copy that shares no arrays with this state. BigNum values are
## immutable, so sharing them is safe.
func copy() -> RunState:
	var other: RunState = RunState.new()
	other.columns = columns
	other.cells = cells.duplicate()
	other.score = score
	other.snapshot_cells = snapshot_cells.duplicate()
	other.snapshot_points = snapshot_points
	other.run_highest = run_highest
	other.free_used = free_used
	other.best_at_start = best_at_start
	return other


## TH2. True when every field matches.
func equals(other: RunState) -> bool:
	if other == null:
		return false
	return (columns == other.columns
		and cells == other.cells
		and score.equals(other.score)
		and snapshot_cells == other.snapshot_cells
		and snapshot_points.equals(other.snapshot_points)
		and run_highest == other.run_highest
		and free_used == other.free_used
		and _same_or_both_null(best_at_start, other.best_at_start))


static func _same_or_both_null(a: BigNum, b: BigNum) -> bool:
	if a == null or b == null:
		return a == null and b == null
	return a.equals(b)
