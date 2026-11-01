extends RefCounted
## Helpers for the boosters tests: boards from GDD 19.0 (through the core
## fixtures, read only), session builders and a signal recorder.
## Not a test file: the runner only loads files named test_*.gd.

const F := preload("res://tests/core/core_fixtures.gd")
const NO_CELL: Vector2i = Vector2i(-1, -1)


## Board D1024: Board D with (2,0) = 1024. No valid move, B = 1024.
static func board_d1024() -> PackedInt64Array:
	return F.changed(F.board_d(), {Vector2i(2, 0): 1024})


## The AT-81 setup board: Board D with (2,0) = 1024 and (1,7) = 8. It has a
## valid move (row 7 reads 8, 8, 8, 16, 8). Used as a snapshot worth 40.
static func snapshot_board() -> PackedInt64Array:
	return F.changed(F.board_d(), {Vector2i(2, 0): 1024, Vector2i(1, 7): 8})


## The GDD section 19 default: every free booster the run's stars have earned
## counts as used, so none is held (D-46). Changes state and returns it.
static func none_held(state: RunState, config: GameConfig = null) -> RunState:
	var rules: GameConfig = config if config != null else GameConfig.new()
	state.free_used = CoreRules.free_earned(state.run_highest, rules)
	return state


## A state with the given run highest tile (a tile value up to 2^62) that
## holds held free boosters: free_used is the free boosters earned minus held
## (D-46). Scores and points are plain ints here.
static func holding(held: int, board: PackedInt64Array, score: int, run_highest: int, snapshot_cells: PackedInt64Array = PackedInt64Array(), snapshot_points: int = 0) -> RunState:
	return holding_big(held, board, F.big(score), F.e(run_highest), snapshot_cells, F.big(snapshot_points))


## As holding, with an exact score and points and the run highest tile as an
## exponent, for boards past 2^62 (section 17).
static func holding_big(held: int, board: PackedInt64Array, score: BigNum, run_highest: int, snapshot_cells: PackedInt64Array = PackedInt64Array(), snapshot_points: BigNum = null) -> RunState:
	var state: RunState = RunState.create(board, score, snapshot_cells, snapshot_points, run_highest)
	state.free_used = CoreRules.free_earned(state.run_highest, GameConfig.new()) - held
	return state


## TH1 with plain int scores: board in exponents, score, snapshot points and
## best_at_start as ints (best_at_start -1 means unknown, null), run_highest
## as a tile value (0 means the board's highest).
static func make(board: PackedInt64Array, score: int, snapshot_cells: PackedInt64Array = PackedInt64Array(), snapshot_points: int = 0, run_highest: int = 0, columns: int = 5, free_used: int = 0, best_at_start: int = -1) -> RunState:
	var best: BigNum = null if best_at_start < 0 else F.big(best_at_start)
	return RunState.create(board, F.big(score), snapshot_cells, F.big(snapshot_points), F.e(run_highest), columns, free_used, best)


## A BigNum that fits in an int, as that int, for assert_eq. A BigNum past
## 2^63 minus 1 is a mistake in the test: it fails loudly.
static func n(value: BigNum) -> int:
	if value == null:
		push_error("booster_fixtures.n: null")
		return -1
	return value.to_int()


## The price of a booster as a plain int (costs are exponents, section 17).
static func price(id: StringName, state: RunState, config: GameConfig) -> int:
	return F.v(BoosterRules.cost(id, state, config))


## 2^bits minus amount, exactly.
static func below_pow2(bits: int, amount: int) -> BigNum:
	return BigNum.pow2(bits).sub(F.big(amount))


## The ids whose status reads Free, in bar order.
static func free_ids(session: GameSession) -> Array[StringName]:
	var ids: Array[StringName] = []
	for status: BoosterStatus in session.booster_statuses():
		if status.free:
			ids.append(status.id)
	return ids


static func targets(cells: Array) -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	list.assign(cells)
	return list


static func no_targets() -> Array[Vector2i]:
	var list: Array[Vector2i] = []
	return list


## Every value of a board, sorted.
static func sorted(cells: PackedInt64Array) -> PackedInt64Array:
	var values: PackedInt64Array = cells.duplicate()
	values.sort()
	return values


## How many cells hold the tile value.
static func count(cells: PackedInt64Array, value: int) -> int:
	var total: int = 0
	var exponent: int = F.e(value)
	for each: int in cells:
		if each == exponent:
			total += 1
	return total


## The lowest tile value on the board.
static func lowest(cells: PackedInt64Array) -> int:
	var low: int = cells[0]
	for each: int in cells:
		low = mini(low, each)
	return F.v(low)


## The first cell holding the tile value, or (-1, -1).
static func find(cells: PackedInt64Array, value: int) -> Vector2i:
	var exponent: int = F.e(value)
	for index: int in cells.size():
		if cells[index] == exponent:
			return CoreRules.cell_of(index, F.COLUMNS)
	return NO_CELL


## A session over a copy of the state, resumed and shown, so the move check
## has run. The generator is seeded after the resume so spawns repeat.
static func ready_session(state: RunState, records: Records = null, seed_value: int = 1, config: GameConfig = null) -> GameSession:
	var session: GameSession = GameSession.new(config, RunRandom.new(), records)
	session.resume(state)
	session.rng.set_seed(seed_value)
	session.move_shown()
	return session


static func status_of(session: GameSession, id: StringName) -> BoosterStatus:
	for status: BoosterStatus in session.booster_statuses():
		if status.id == id:
			return status
	return null


## The ids of the usable boosters, in bar order.
static func usable_ids(session: GameSession) -> Array[StringName]:
	var ids: Array[StringName] = []
	for status: BoosterStatus in session.booster_statuses():
		if status.usable:
			ids.append(status.id)
	return ids


## The id marked as suggested, or &"".
static func suggested_id(session: GameSession) -> StringName:
	for status: BoosterStatus in session.booster_statuses():
		if status.suggested:
			return status.id
	return &""


## Records every GameSession signal in order. It holds no reference to the
## session, so the two never keep each other alive.
class Recorder extends RefCounted:
	var names: PackedStringArray = PackedStringArray()
	var started: Array[MoveResult] = []
	var resolved: Array[MoveResult] = []
	var targeting: Array[Array] = []        # [booster_id, swap_first]
	var offers: Array[Array] = []           # [is_open, suggested]
	var summaries: Array[RunSummary] = []

	func watch(session: GameSession) -> void:
		session.run_started.connect(_on_run_started)
		session.move_resolved.connect(_on_move_resolved)
		session.status_changed.connect(_on_status_changed)
		session.targeting_changed.connect(_on_targeting_changed)
		session.offer_changed.connect(_on_offer_changed)
		session.run_ended.connect(_on_run_ended)
		session.save_requested.connect(_on_save_requested)

	func clear() -> void:
		names = PackedStringArray()
		started.clear()
		resolved.clear()
		targeting.clear()
		offers.clear()
		summaries.clear()

	func count(signal_name: String) -> int:
		var total: int = 0
		for each: String in names:
			if each == signal_name:
				total += 1
		return total

	func _on_run_started(result: MoveResult) -> void:
		names.append("run_started")
		started.append(result)

	func _on_move_resolved(result: MoveResult) -> void:
		names.append("move_resolved")
		resolved.append(result)

	func _on_status_changed() -> void:
		names.append("status_changed")

	func _on_targeting_changed(booster_id: StringName, first: Vector2i) -> void:
		names.append("targeting_changed")
		targeting.append([booster_id, first])

	func _on_offer_changed(is_open: bool, suggested: StringName) -> void:
		names.append("offer_changed")
		offers.append([is_open, suggested])

	func _on_run_ended(summary: RunSummary) -> void:
		names.append("run_ended")
		summaries.append(summary)

	func _on_save_requested() -> void:
		names.append("save_requested")
