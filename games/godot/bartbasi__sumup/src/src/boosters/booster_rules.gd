class_name BoosterRules extends RefCounted
## The five boosters (GDD section 13): costs, free boosters (13.9), usability,
## targets, the no moves offer's outcome and suggested rescue (12.2), and
## applying a booster to a RunState. All static and pure: no files, nodes,
## sounds or timers.
##
## A refused booster returns a MoveResult with a refusal and changes nothing:
## not the state, not the records, not the random generator, and no free
## booster is used (D-30, D-46, TH11).
##
## Tiles are exponents and the score is a BigNum (docs/ARCHITECTURE.md
## section 17). Costs are powers of two, so a cost is an exponent until it is
## compared with or taken from the score as BigNum.pow2. Every move check here
## passes the run's current score, so usability, outcome() and apply() agree
## with what RunRules.commit_chain accepts (GDD D-37).

const HAMMER: StringName = &"hammer"
const SWAP: StringName = &"swap"
const SHUFFLE: StringName = &"shuffle"
const DOUBLE: StringName = &"double"
const UNDO: StringName = &"undo"
const ALL: Array[StringName] = [HAMMER, SWAP, SHUFFLE, DOUBLE, UNDO]

enum Outcome { PLAY, OFFER, END }


## B (D-20, TH3) as an exponent: the larger of the highest exponent on the
## board and the exponent of COST_BASIS_MIN (128 is 7).
static func cost_basis(cells: PackedInt64Array, config: GameConfig) -> int:
	return maxi(CoreRules.highest(cells), _exponent_of(config.cost_basis_min))


## TH3. The booster's cost on the current board as an exponent (the price is
## 2^cost): B's exponent plus its cost_shift (D-20). It is the price whether
## or not a free booster is held (AT-56). Costs have no upper limit (D-37).
## 0 for an unknown id.
static func cost(id: StringName, state: RunState, config: GameConfig) -> int:
	if not ALL.has(id):
		return 0
	var shift: int = config.cost_shift.get(id, 0)
	return maxi(cost_basis(state.cells, config) + shift, 0)


## TH3, D-46. True while at least one free booster is held. A bad state can
## hold a negative count, so the test is above 0, never "not 0".
static func is_free(state: RunState, config: GameConfig) -> bool:
	return CoreRules.free_held(state, config) > 0


## D-46. What using the booster would take from the score now, exactly: 0
## while a free booster is held, else 2^cost.
static func charge(id: StringName, state: RunState, config: GameConfig) -> BigNum:
	if is_free(state, config):
		return BigNum.zero()
	return BigNum.pow2(cost(id, state, config))


## TH3, D-28 for Undo, measured against charge(). Checked in this order:
## - Undo needs a snapshot (NO_SNAPSHOT).
## - The score covers the charge (CANNOT_AFFORD): 2^cost is at most the score,
##   or a free booster is held. For Undo it is the score minus the snapshot's
##   points, even while free (FB4).
## - The booster can act on this board (NO_TARGET, D-37): Swap and Shuffle
##   need two tiles of different value, Double a tile below max_exponent.
##   Hammer and Undo can always act.
static func usability(id: StringName, state: RunState, config: GameConfig) -> BoosterStatus.Usability:
	if not ALL.has(id):
		return BoosterStatus.Usability.CANNOT_AFFORD
	var price: BigNum = charge(id, state, config)
	if id == UNDO:
		if not state.has_snapshot():
			return BoosterStatus.Usability.NO_SNAPSHOT
		var left: BigNum = state.score.sub(state.snapshot_points)
		if left == null or left.compare(price) < 0:
			return BoosterStatus.Usability.CANNOT_AFFORD
		return BoosterStatus.Usability.USABLE
	if state.score.compare(price) < 0:
		return BoosterStatus.Usability.CANNOT_AFFORD
	if (id == SWAP or id == SHUFFLE) and not _has_two_values(state.cells):
		return BoosterStatus.Usability.NO_TARGET
	if id == DOUBLE and not _has_double_target(state.cells, config):
		return BoosterStatus.Usability.NO_TARGET
	return BoosterStatus.Usability.USABLE


## How many tiles the booster needs: Hammer and Double 1, Swap 2, Shuffle and Undo 0.
static func target_count(id: StringName) -> int:
	if id == HAMMER or id == DOUBLE:
		return 1
	if id == SWAP:
		return 2
	return 0


## D-24. True when second may complete a Swap whose first tile is first: both
## are tiles on the board, they are different cells, and their values differ.
static func can_pick_second(state: RunState, first: Vector2i, second: Vector2i) -> bool:
	var first_value: int = state.value_at(first)
	var second_value: int = state.value_at(second)
	return first != second and first_value > 0 and second_value > 0 and first_value != second_value


## TH16, D-42. Shuffle when it is usable, otherwise Undo when it is usable,
## otherwise &"" for none.
static func suggested_rescue(state: RunState, config: GameConfig) -> StringName:
	if usability(SHUFFLE, state, config) == BoosterStatus.Usability.USABLE:
		return SHUFFLE
	if usability(UNDO, state, config) == BoosterStatus.Usability.USABLE:
		return UNDO
	return &""


## D-19, the move check: PLAY when the board has a valid move, else OFFER when
## any booster is usable, else END. It follows usability(), so while a free
## booster is held the offer opens instead of the run ending (FB8). The move
## check measures with the run's score, so a score that blocks every pair
## opens the offer (D-37, AT-167).
static func outcome(state: RunState, config: GameConfig) -> Outcome:
	if CoreRules.has_valid_move(state.cells, state.score, config):
		return Outcome.PLAY
	for id: StringName in ALL:
		if usability(id, state, config) == BoosterStatus.Usability.USABLE:
			return Outcome.OFFER
	return Outcome.END


## TH11. Applies a booster with its targets. Refuses (&"cannot_afford", &"no_snapshot", &"bad_target") and changes nothing when it may not run.
## Usability is checked first, then the targets: Hammer and Double need one
## tile, Swap two tiles of different value (D-24), Shuffle and Undo none. A
## booster with nothing on the board to act on (NO_TARGET) and a Double on a
## tile at max_exponent are bad targets.
## The charge is read before the effect and taken with it (D-21). While a free
## booster is held it is 0, and exactly one free booster is used (D-46).
## Hammer, Swap, Shuffle and Double leave the Undo snapshot alone; Undo
## restores it and clears it (13.7). Only that one use changes free_used, so
## Undo never gives a free booster back, and no booster touches best_at_start.
## Every accepted booster ends with records, this run's highest tile, stars
## and free boosters earned (step 7 of D-09, D-41, D-45, D-46).
static func apply(id: StringName, state: RunState, records: Records, targets: Array[Vector2i], rng: RunRandom, config: GameConfig) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	result.kind = _kind_of(id)
	result.booster_id = id
	result.targets = targets.duplicate()
	result.cells_before = state.cells.duplicate()
	result.cells_after = state.cells.duplicate()
	var refusal: StringName = _refusal(id, state, targets, config)
	if refusal != &"":
		result.refusal = refusal
		result.has_valid_move = CoreRules.has_valid_move(state.cells, state.score, config)
		return result

	var free: bool = is_free(state, config)
	var price: BigNum = charge(id, state, config)
	match id:
		HAMMER:
			_hammer(state, targets[0], price, result, rng, config)
		SWAP:
			_swap(state, targets[0], targets[1], price, config)
		SHUFFLE:
			_shuffle(state, price, rng, config)
		DOUBLE:
			_double(state, targets[0], price, result, rng, config)
		UNDO:
			_undo(state, price)
	if free:
		state.free_used += 1
	RunRules.update_records(state, records, result, config)

	result.accepted = true
	result.cost = price
	result.free_used = free
	result.cells_after = state.cells.duplicate()
	result.has_valid_move = CoreRules.has_valid_move(state.cells, state.score, config)
	return result


## D-23. Empty the cell, the tiles above fall one cell, one new tile spawns at
## the top of the column. Never clears small tiles (D-39).
static func _hammer(state: RunState, cell: Vector2i, price: BigNum, result: MoveResult, rng: RunRandom, config: GameConfig) -> void:
	state.score = state.score.sub(price)
	var board: PackedInt64Array = state.cells.duplicate()
	board[CoreRules.index_of(cell, config.columns)] = 0
	state.cells = board
	result.emptied.append(cell)
	RunRules.settle(state, result, rng, config)


## D-24. The two tiles change places. No gravity, no spawn.
static func _swap(state: RunState, first: Vector2i, second: Vector2i, price: BigNum, config: GameConfig) -> void:
	state.score = state.score.sub(price)
	var board: PackedInt64Array = state.cells.duplicate()
	var first_index: int = CoreRules.index_of(first, config.columns)
	var second_index: int = CoreRules.index_of(second, config.columns)
	var kept: int = board[first_index]
	board[first_index] = board[second_index]
	board[second_index] = kept
	state.cells = board


## D-25. Random arrangements until one has a valid move, at most
## SHUFFLE_MAX_ATTEMPTS, then the fallback on the last one. Sets
## rng.shuffle_attempts. The move check and the fallback measure with the
## score after the charge (D-25, D-37).
static func _shuffle(state: RunState, price: BigNum, rng: RunRandom, config: GameConfig) -> void:
	state.score = state.score.sub(price)
	var arranged: PackedInt64Array = state.cells.duplicate()
	var attempts: int = 0
	var found: bool = false
	while not found and (attempts == 0 or attempts < config.shuffle_max_attempts):
		arranged = rng.shuffle_attempt(state.cells)
		attempts += 1
		found = CoreRules.has_valid_move(arranged, state.score, config)
	rng.shuffle_attempts = attempts
	if not found:
		arranged = _shuffle_fallback(arranged, state.score, config)
	state.cells = arranged


## The fallback of GDD 13.5. In reading order, P is the first cell whose value
## fits as a pair with the score after the charge (CoreRules.pair_fits) and
## appears again later, and Q the first later cell with that value. Q's tile
## swaps with the tile right of P, or below P when P is in the last column, so
## P and its twin touch. A board with no such value is returned unchanged.
static func _shuffle_fallback(cells: PackedInt64Array, score: BigNum, config: GameConfig) -> PackedInt64Array:
	var board: PackedInt64Array = cells.duplicate()
	for p: int in board.size():
		if not CoreRules.pair_fits(board[p], score, config):
			continue
		for q: int in range(p + 1, board.size()):
			if board[q] != board[p]:
				continue
			var p_cell: Vector2i = CoreRules.cell_of(p, config.columns)
			var neighbor: Vector2i = p_cell + Vector2i(1, 0)
			if p_cell.x == config.columns - 1:
				neighbor = p_cell + Vector2i(0, 1)
			if not CoreRules.in_bounds(neighbor, config):
				return board
			var n: int = CoreRules.index_of(neighbor, config.columns)
			var kept: int = board[n]
			board[n] = board[q]
			board[q] = kept
			return board
	return board


## D-26. The tile doubles in place: its exponent goes up by 1. If that raised
## the window floor, small tiles clear (D-38) and only then gravity and spawns
## follow.
static func _double(state: RunState, cell: Vector2i, price: BigNum, result: MoveResult, rng: RunRandom, config: GameConfig) -> void:
	var floor_before: int = CoreRules.window_floor(CoreRules.highest(state.cells), config)
	state.score = state.score.sub(price)
	var board: PackedInt64Array = state.cells.duplicate()
	var index: int = CoreRules.index_of(cell, config.columns)
	board[index] = board[index] + 1
	state.cells = board
	result.result_cell = cell
	result.result_value = board[index]
	RunRules.clear_small(state, floor_before, result, config)
	if not result.cleared_small.is_empty():
		RunRules.settle(state, result, rng, config)


## D-27. The board becomes the snapshot board exactly, the score loses the
## snapshot's points and the Undo charge, and the snapshot is cleared. Never
## clears small tiles and never touches the random generator (D-29, D-39).
static func _undo(state: RunState, price: BigNum) -> void:
	state.score = state.score.sub(state.snapshot_points).sub(price)
	state.cells = state.snapshot_cells.duplicate()
	state.snapshot_cells = PackedInt64Array()
	state.snapshot_points = BigNum.zero()


## The refusal for this booster call, or &"" when it may run. NO_TARGET is
## refused as &"bad_target": nothing on the board is a target.
static func _refusal(id: StringName, state: RunState, targets: Array[Vector2i], config: GameConfig) -> StringName:
	if not ALL.has(id) or state.columns != config.columns or state.cells.size() != config.cell_count():
		return &"bad_target"
	match usability(id, state, config):
		BoosterStatus.Usability.NO_SNAPSHOT:
			return &"no_snapshot"
		BoosterStatus.Usability.CANNOT_AFFORD:
			return &"cannot_afford"
		BoosterStatus.Usability.NO_TARGET:
			return &"bad_target"
	if targets.size() != target_count(id):
		return &"bad_target"
	if id == HAMMER and state.value_at(targets[0]) <= 0:
		return &"bad_target"
	if id == DOUBLE and not _is_double_target(state.value_at(targets[0]), config):
		return &"bad_target"
	if id == SWAP and not can_pick_second(state, targets[0], targets[1]):
		return &"bad_target"
	return &""


## 13.1. True when the board holds two tiles of different value, so Swap has
## a legal pair (D-24) and Shuffle can change the board.
static func _has_two_values(cells: PackedInt64Array) -> bool:
	for value: int in cells:
		if value > 0 and value != cells[0]:
			return true
	return false


## 13.6, D-37. True when the board holds a tile Double can double.
static func _has_double_target(cells: PackedInt64Array, config: GameConfig) -> bool:
	for value: int in cells:
		if _is_double_target(value, config):
			return true
	return false


## 13.6, D-37. A tile Double may double: its exponent is below max_exponent,
## so the doubled tile is at most the ceiling. The score plays no part, since
## Double adds no points.
static func _is_double_target(value: int, config: GameConfig) -> bool:
	return value > 0 and value < config.max_exponent


static func _kind_of(id: StringName) -> MoveResult.Kind:
	match id:
		HAMMER:
			return MoveResult.Kind.HAMMER
		SWAP:
			return MoveResult.Kind.SWAP
		SHUFFLE:
			return MoveResult.Kind.SHUFFLE
		DOUBLE:
			return MoveResult.Kind.DOUBLE
		UNDO:
			return MoveResult.Kind.UNDO
	return MoveResult.Kind.NEW_RUN


## The exponent of a power of two from GameConfig (log2, rounded down for
## other values). 0 for values of 1 or less.
static func _exponent_of(value: int) -> int:
	var exponent: int = 0
	var rest: int = value
	while rest > 1:
		rest >>= 1
		exponent += 1
	return exponent
