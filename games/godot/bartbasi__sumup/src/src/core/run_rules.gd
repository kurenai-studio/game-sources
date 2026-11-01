class_name RunRules extends RefCounted
## The moves that change a RunState. All static. Each returns a MoveResult; a
## refused move changes nothing: not the state, not the records, not the
## random generator.


## D-14. New run: score 0, no snapshot, records updated from the board. Sets rng.start_attempts.
## Draws whole boards from the starting window until one has a valid move, at
## most START_BOARD_MAX_ATTEMPTS times. If none has, the last attempt gets the
## second cell of the bottom row set to the exponent of the first, so (0,7) and
## (1,7) match. run_highest starts at the board's highest tile (D-41).
static func new_run(rng: RunRandom, records: Records, config: GameConfig) -> RunState:
	var board: PackedInt64Array = PackedInt64Array()
	var attempts: int = 0
	var found: bool = false
	while not found and (attempts == 0 or attempts < config.start_board_max_attempts):
		board = rng.start_board_attempt(config)
		attempts += 1
		found = CoreRules.has_valid_move(board, BigNum.zero(), config)
	if not found and board.size() == config.cell_count() and config.columns >= 2:
		var bottom: int = config.rows - 1
		var first: int = CoreRules.index_of(Vector2i(0, bottom), config.columns)
		var second: int = CoreRules.index_of(Vector2i(1, bottom), config.columns)
		board[second] = board[first]
	rng.start_attempts = attempts
	var state: RunState = RunState.create(board, BigNum.zero(), PackedInt64Array(), BigNum.zero(), 0, config.columns)
	records.update_from(state)
	return state


## D-09 steps 1 to 7 and the valid move check. Refuses with &"invalid_chain" if the chain breaks any rule (TH10).
## That includes the fit test (D-37, section 17): a merge result above
## max_exponent, or points that would take the score to 2^max_score_bits.
## It is the same test joining, the highlight and the move check use, given
## the run's score, so a chain the player can drag always commits.
static func commit_chain(state: RunState, records: Records, chain: Array[Vector2i], rng: RunRandom, config: GameConfig) -> MoveResult:
	var result: MoveResult = MoveResult.new()
	result.kind = MoveResult.Kind.CHAIN
	result.chain = chain.duplicate()
	result.cells_before = state.cells.duplicate()
	result.cells_after = state.cells.duplicate()
	if not _fits(state, config) or not CoreRules.is_valid_chain(state.cells, state.score, chain, config):
		result.refusal = &"invalid_chain"
		result.has_valid_move = CoreRules.has_valid_move(state.cells, state.score, config)
		return result

	var values: PackedInt64Array = _values_of(state, chain, config)
	var points: BigNum = CoreRules._points_of(values)
	var floor_before: int = CoreRules.window_floor(CoreRules.highest(state.cells), config)
	var last: Vector2i = chain[chain.size() - 1]
	var value: int = CoreRules.merge_result(values)
	# Step 1: the Undo snapshot replaces any older one.
	state.snapshot_cells = state.cells.duplicate()
	state.snapshot_points = points
	# Step 2: the score.
	state.score = state.score.add(points)
	# Steps 3 and 4: the result on the last cell, the other chain cells emptied.
	var board: PackedInt64Array = state.cells.duplicate()
	board[CoreRules.index_of(last, config.columns)] = value
	for position: int in chain.size() - 1:
		var cell: Vector2i = chain[position]
		board[CoreRules.index_of(cell, config.columns)] = 0
		result.emptied.append(cell)
	state.cells = board
	# Step 4, second half: small tile clearing (D-38).
	clear_small(state, floor_before, result, config)
	# Steps 5 and 6: gravity, then spawns.
	settle(state, result, rng, config)
	# Step 7: records, this run's highest tile, stars and free boosters.
	update_records(state, records, result, config)

	result.accepted = true
	result.points = points
	result.result_cell = last
	result.result_value = value
	result.cells_after = state.cells.duplicate()
	result.has_valid_move = CoreRules.has_valid_move(state.cells, state.score, config)
	return result


## D-38. Empties every cell below the new floor and records them in result. Used by commit_chain and by Double.
## Floors and values are exponents. floor_before is the window floor of the board before the move. The new
## floor comes from the board as it is now, after the result is placed or the
## tile doubled. Only a floor that went up clears anything. Records
## floor_before, floor_after and the notice values (D-45: every value that
## left the window, even when no tile of it was on the board) either way.
static func clear_small(state: RunState, floor_before: int, result: MoveResult, config: GameConfig) -> void:
	var floor_after: int = CoreRules.window_floor(CoreRules.highest(state.cells), config)
	result.floor_before = floor_before
	result.floor_after = floor_after
	result.notice_values = CoreRules._left_window(floor_before, floor_after)
	if floor_after <= floor_before:
		return
	var board: PackedInt64Array = state.cells.duplicate()
	var values: PackedInt64Array = PackedInt64Array()
	for index: int in board.size():
		var value: int = board[index]
		if value > 0 and value < floor_after:
			board[index] = 0
			result.cleared_small.append(CoreRules.cell_of(index, config.columns))
			if not values.has(value):
				values.append(value)
	values.sort()
	state.cells = board
	result.cleared_values = values


## Gravity, then spawns into every empty cell (D-11, D-12), recorded in result. Used by chains, Hammer and Double.
## Gravity moves tiles straight down, keeping their order, and records each
## move column by column from the left, lowest tile first. The spawn window is
## worked out once from the board after gravity, and empty cells fill column
## by column from the left, top row down. Also sets result.cells_after to the
## settled board. A full board is left as it is and uses no draws.
static func settle(state: RunState, result: MoveResult, rng: RunRandom, config: GameConfig) -> void:
	if not _fits(state, config):
		push_error("RunRules.settle: the board does not match the GameConfig")
		return
	var board: PackedInt64Array = state.cells.duplicate()
	for column: int in config.columns:
		var landing: int = config.rows - 1
		for row: int in range(config.rows - 1, -1, -1):
			var from_index: int = CoreRules.index_of(Vector2i(column, row), config.columns)
			var value: int = board[from_index]
			if value == 0:
				continue
			if row != landing:
				board[CoreRules.index_of(Vector2i(column, landing), config.columns)] = value
				board[from_index] = 0
				result.fall_from.append(Vector2i(column, row))
				result.fall_to.append(Vector2i(column, landing))
			landing -= 1
	var window: PackedInt64Array = CoreRules.spawn_window(CoreRules.highest(board), config)
	for column: int in config.columns:
		for row: int in config.rows:
			var cell: Vector2i = Vector2i(column, row)
			var index: int = CoreRules.index_of(cell, config.columns)
			if board[index] != 0:
				continue
			var value: int = rng.next_spawn(window, config)
			board[index] = value
			result.spawn_cells.append(cell)
			result.spawn_values.append(value)
	state.cells = board
	result.cells_after = board.duplicate()


## Step 7 plus D-41, D-45 and D-46: records and run_highest. Sets result.new_best_score, new_best_tile,
## stars_earned and free_earned (the counts after the move minus before). A null config means the defaults.
## run_highest only ever rises, so a Hammer or Undo that lowers H keeps it,
## and the stars and free boosters it gave stay. A loaded run already holds
## its run_highest, so the update on load earns nothing.
static func update_records(state: RunState, records: Records, result: MoveResult, config: GameConfig = null) -> void:
	var rules: GameConfig = config if config != null else GameConfig.new()
	var stars_before: int = CoreRules.stars(state.run_highest, rules)
	var free_before: int = CoreRules.free_earned(state.run_highest, rules)
	var top: int = state.highest()
	if top > state.run_highest:
		state.run_highest = top
	result.stars_earned = CoreRules.stars(state.run_highest, rules) - stars_before
	result.free_earned = CoreRules.free_earned(state.run_highest, rules) - free_before
	var old_score: BigNum = records.best_score
	var old_tile: int = records.best_tile
	records.update_from(state)
	result.new_best_score = records.best_score.compare(old_score) > 0
	result.new_best_tile = records.best_tile > old_tile


## True when the state's board has the shape the config describes.
static func _fits(state: RunState, config: GameConfig) -> bool:
	return state.columns == config.columns and state.cells.size() == config.cell_count()


static func _values_of(state: RunState, chain: Array[Vector2i], config: GameConfig) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in chain:
		values.append(state.cells[CoreRules.index_of(cell, config.columns)])
	return values
