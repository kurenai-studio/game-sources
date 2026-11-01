class_name CoreRules extends RefCounted
## Pure queries on boards and chains. All static.
##
## Covers adjacency, the joining and backtracking rules (GDD 6.1, 6.2), the
## joinable highlight (6.7), the merge result (7.1), the spawn window and the
## weighted draw (9.1), the move check (12.1), and stars and free boosters
## (11.5, 13.9). A board is a PackedInt64Array in row order
## (docs/ARCHITECTURE.md section 3). Every cell holds a tile's exponent k (the
## tile is 2^k, section 17), and 0 means empty. Off board cells and empty
## cells never take part in a chain or a pair.
##
## The ceiling (D-37, section 17) has one fit test, _chain_fits: the chain's
## merge result is at most max_exponent, and the score after the chain stays
## below 2^max_score_bits. Joining, the full chain check, the move check and
## RunRules.commit_chain all use it, so what the player can drag, what is
## highlighted, what counts as a move and what commits always agree. The
## run's score is a required argument right after the board, so no caller
## can leave the score part out (SEC-01, 2026-10-21). A null score is a
## programming error: it is reported and nothing fits.

## Steps from a cell to the four neighbors that cover every touching pair
## exactly once (GDD 12.1): right, lower left, below and lower right.
const _PAIR_STEPS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]


static func index_of(cell: Vector2i, columns: int) -> int:
	return cell.y * columns + cell.x


@warning_ignore("integer_division")
static func cell_of(index: int, columns: int) -> Vector2i:
	return Vector2i(index % columns, index / columns)


static func in_bounds(cell: Vector2i, config: GameConfig) -> bool:
	return cell.x >= 0 and cell.x < config.columns and cell.y >= 0 and cell.y < config.rows


## Two different cells whose column and row each differ by at most 1 (eight directions).
static func touching(a: Vector2i, b: Vector2i) -> bool:
	return a != b and absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


static func is_power_of_two(value: int) -> bool:
	return value > 0 and (value & (value - 1)) == 0


## H: the highest exponent on the board, 0 for an empty board.
static func highest(cells: PackedInt64Array) -> int:
	var top: int = 0
	for value: int in cells:
		if value > top:
			top = value
	return top


## TH15, D-02. The exponent of the largest power of two that is not more than
## the sum of 2^k over every exponent k in values: the sum's bit length minus
## 1. Worked out exactly from the exponents with a binary counter, so it needs
## no big numbers. 0 for fewer than 2 values or for any value of 0 or less.
## It applies no ceiling: joining and commit_chain refuse a result above
## GameConfig.max_exponent.
static func merge_result(values: PackedInt64Array) -> int:
	if values.size() < 2:
		return 0
	for value: int in values:
		if value <= 0:
			return 0
	return _sum_exponent(values)


## SEC-01 and the section 17 ceiling (GDD D-37 "fits"). True when two
## touching tiles of exponent may merge: the result, exponent + 1, is at most
## max_exponent, and score plus the pair's sum (2^(exponent + 1)) stays below
## 2^max_score_bits. False for 0 and negative exponents.
## It is the fit test of joining, the highlight, the move check and the
## commit, applied to a pair. Boosters use it too.
static func pair_fits(exponent: int, score: BigNum, config: GameConfig) -> bool:
	if exponent <= 0 or exponent >= config.max_exponent:
		return false
	return _chain_fits(PackedInt64Array([exponent, exponent]), score, config)


## D-10. The spawn window for highest exponent h, smallest first. The top is
## the larger of SPAWN_TOP_MIN and 2^h / SPAWN_TOP_DIVISOR, in exponents:
## the larger of log2(SPAWN_TOP_MIN) and h - log2(SPAWN_TOP_DIVISOR). Each
## exponent below it is one less than the next. An empty board (h of 0) gets
## the starting window.
static func spawn_window(h: int, config: GameConfig) -> PackedInt64Array:
	var top: int = _exponent_of(config.spawn_top_min)
	if config.spawn_top_divisor > 0:
		top = maxi(top, h - _exponent_of(config.spawn_top_divisor))
	var size: int = maxi(1, config.spawn_window_size)
	var window: PackedInt64Array = PackedInt64Array()
	for position: int in size:
		window.append(top - (size - 1 - position))
	return window


## The window floor: the smallest exponent in the spawn window for h.
static func window_floor(h: int, config: GameConfig) -> int:
	return spawn_window(h, config)[0]


## TH3, D-45. How many times the window floor of run_highest has doubled above
## the floor of an empty board: the difference of the two floor exponents,
## never below 0. With the GDD 18 values that is 0 up to exponent 10 (1024),
## then run_highest minus 10: 11 (2K) gives 1, 17 (128K) gives 7, 62 gives
## 52. It never goes down as run_highest rises.
static func stars(run_highest: int, config: GameConfig) -> int:
	return maxi(0, window_floor(run_highest, config) - window_floor(0, config))


## TH3, D-46. Free boosters earned: stars divided by STARS_PER_FREE_BOOSTER,
## rounded down. 0 when that constant is not positive.
@warning_ignore("integer_division")
static func free_earned(run_highest: int, config: GameConfig) -> int:
	if config.stars_per_free_booster <= 0:
		return 0
	return stars(run_highest, config) / config.stars_per_free_booster


## TH3, D-46. Free boosters held: earned from state.run_highest minus
## state.free_used. A valid run never uses more than it earned (GDD 15.1), so
## this is 0 or more for every state the save code accepts.
static func free_held(state: RunState, config: GameConfig) -> int:
	return free_earned(state.run_highest, config) - state.free_used


## D-45. Every exponent that leaves the spawn window when the floor rises from
## floor_before to floor_after, ascending: floor_before, the next one up, and
## so on below floor_after. Empty when the floor did not rise, and for a
## floor_before of 0 or less, which is no floor. Internal to core:
## RunRules.clear_small fills MoveResult.notice_values with it.
static func _left_window(floor_before: int, floor_after: int) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	if floor_before <= 0:
		return values
	for value: int in range(floor_before, floor_after):
		values.append(value)
	return values


## TH9. Maps one draw (0 to 99 with the default weights) to a window exponent:
## the first one whose running weight total is above the draw.
static func draw_value(draw: int, window: PackedInt64Array, config: GameConfig) -> int:
	var count: int = mini(window.size(), config.spawn_weights.size())
	if count == 0:
		return 0
	var limit: int = 0
	for position: int in count:
		limit += config.spawn_weights[position]
		if draw < limit:
			return window[position]
	return window[count - 1]


## TH13, D-15. True when two touching tiles have the same exponent and the
## pair fits (pair_fits): its result is at most max_exponent and its points
## keep score below 2^max_score_bits. A longer chain from a
## pair only adds to its sum, so a pair that does not fit is no move at all.
static func has_valid_move(cells: PackedInt64Array, score: BigNum, config: GameConfig) -> bool:
	if cells.size() != config.cell_count():
		return false
	for row: int in config.rows:
		for column: int in config.columns:
			var cell: Vector2i = Vector2i(column, row)
			var value: int = cells[index_of(cell, config.columns)]
			var fits: int = -1   # worked out once per cell, only when a neighbor matches
			for step: Vector2i in _PAIR_STEPS:
				if value <= 0 or _value(cells, cell + step, config) != value:
					continue
				if fits < 0:
					fits = 1 if pair_fits(value, score, config) else 0
				if fits == 1:
					return true
	return false


## D-04. True when next would join chain if the finger reached it now. An
## empty chain accepts any tile. A tile does not join when the chain with it
## would fail the fit test (condition 5): a merge result above max_exponent,
## or points that take score to 2^max_score_bits.
static func can_join(cells: PackedInt64Array, score: BigNum, chain: Array[Vector2i], next: Vector2i, config: GameConfig) -> bool:
	var value: int = _value(cells, next, config)
	if value <= 0:
		return false
	if chain.is_empty():
		return true
	var last: Vector2i = chain[chain.size() - 1]
	if not touching(last, next) or chain.has(next):
		return false
	var last_value: int = _value(cells, last, config)
	if chain.size() == 1:
		if value != last_value:
			return false
	elif value != last_value and value != last_value + 1:
		return false
	var values: PackedInt64Array = _chain_values(cells, chain, config)
	values.append(value)
	return _chain_fits(values, score, config)


## The full check before a commit (GDD 6.1): at least MIN_CHAIN_LENGTH and 2
## cells, all on the board and all different, each touching the one before,
## the second exponent equal to the first, every later exponent equal to the
## one before it or one more (double the tile), and the fit test (D-37).
static func is_valid_chain(cells: PackedInt64Array, score: BigNum, chain: Array[Vector2i], config: GameConfig) -> bool:
	if cells.size() != config.cell_count():
		return false
	if chain.size() < 2 or chain.size() < config.min_chain_length:
		return false
	var seen: Dictionary[Vector2i, bool] = {}
	var values: PackedInt64Array = PackedInt64Array()
	var previous_value: int = 0
	for position: int in chain.size():
		var cell: Vector2i = chain[position]
		var value: int = _value(cells, cell, config)
		if value <= 0 or seen.has(cell):
			return false
		seen[cell] = true
		if position == 1 and value != previous_value:
			return false
		if position > 1 and value != previous_value and value != previous_value + 1:
			return false
		if position > 0 and not touching(chain[position - 1], cell):
			return false
		values.append(value)
		previous_value = value
	return _chain_fits(values, score, config)


## TH14, D-40. Every tile that would join the chain if the finger moved onto
## it now, in index order. Empty for an empty chain.
static func joinable_cells(cells: PackedInt64Array, score: BigNum, chain: Array[Vector2i], config: GameConfig) -> Array[Vector2i]:
	var joinable: Array[Vector2i] = []
	if chain.is_empty():
		return joinable
	var last: Vector2i = chain[chain.size() - 1]
	for row: int in range(last.y - 1, last.y + 2):
		for column: int in range(last.x - 1, last.x + 2):
			var cell: Vector2i = Vector2i(column, row)
			if can_join(cells, score, chain, cell, config):
				joinable.append(cell)
	return joinable


## The chain after the finger reaches cell: a joinable cell is added (D-04), the previous cell backtracks (D-05),
## anything else leaves the chain unchanged. An empty chain starts on any tile. Returns a new array.
static func step_chain(cells: PackedInt64Array, score: BigNum, chain: Array[Vector2i], cell: Vector2i, config: GameConfig) -> Array[Vector2i]:
	var stepped: Array[Vector2i] = chain.duplicate()
	if stepped.size() >= 2 and cell == stepped[stepped.size() - 2]:
		stepped.pop_back()
	elif can_join(cells, score, stepped, cell, config):
		stepped.append(cell)
	return stepped


## The points of tiles with these exponents: the sum of 2^k. Every value must
## be positive and at most max_exponent. Internal to core: RunRules uses it.
## Worked out as small times 2^lowest, where small is the sum of
## 2^(k - lowest). A chain's exponents differ by at most its length, so small
## has only a few limbs and the cost is one cached power and one linear pass,
## even for tiles near the ceiling (SEC-06).
static func _points_of(values: PackedInt64Array) -> BigNum:
	if values.is_empty():
		return BigNum.zero()
	var lowest: int = values[0]
	for value: int in values:
		lowest = mini(lowest, value)
	var small: BigNum = BigNum.zero()
	for value: int in values:
		small = small.add(BigNum.pow2(value - lowest))
	return small._times(BigNum.pow2(lowest))


## The headroom below the score ceiling: 2^limit - 1 - score, the largest
## number of points that still fits, or null when the score is already at
## 2^limit or above. The last answer is kept, keyed by the score object and
## the limit. BigNum never changes, so the same object always gives the same
## headroom, and a move check over many pairs works it out once (SEC-06).
static var _room_score: BigNum = null
static var _room_limit: int = -1
static var _room: BigNum = null


static func _headroom(score: BigNum, limit: int) -> BigNum:
	if score != _room_score or limit != _room_limit:
		var below: BigNum = BigNum.pow2(limit).sub(score)   # null when score is above 2^limit
		_room = null if below == null or below.is_zero() else below.sub(BigNum.from_int(1))
		_room_score = score
		_room_limit = limit
	return _room


## The one fit test (D-37, SEC-01, section 17) for tiles with these
## exponents: every value from 1 to max_exponent, the merge result at most max_exponent,
## and score plus the points below 2^max_score_bits. A null score is a
## programming error: it is reported and nothing fits.
## The points P lie between 2^merge and 2^(merge + 1) - 1. So when the score
## and the points are both below 2^(max_score_bits - 1) the sum fits without
## working anything out. Otherwise the sum fits exactly when P is at most
## the headroom (see _headroom), and bit lengths decide that unless the
## headroom has merge + 1 bits too; only then are the points worked out and
## compared. Each path is exact, so every caller gets the same answer the
## full sum would give (SEC-06). Internal to core: RunRules relies on it
## through is_valid_chain.
static func _chain_fits(values: PackedInt64Array, score: BigNum, config: GameConfig) -> bool:
	for value: int in values:
		if value <= 0 or value > config.max_exponent:
			return false
	var merge: int = _sum_exponent(values)
	if merge > config.max_exponent:
		return false
	if score == null:
		push_error("CoreRules: the fit test needs the run's score")
		return false
	var limit: int = config.max_score_bits
	if score.bit_length() < limit and merge + 2 <= limit:
		return true
	var room: BigNum = _headroom(score, limit)
	if room == null:
		return false
	var room_bits: int = room.bit_length()
	if room_bits != merge + 1:
		return room_bits > merge + 1
	return _points_of(values).compare(room) <= 0


## The bit length minus 1 of the sum of 2^k over values, all positive: a
## binary counter where each value sets bit k and carries upward.
static func _sum_exponent(values: PackedInt64Array) -> int:
	var bits: Dictionary[int, bool] = {}
	var top: int = 0
	for value: int in values:
		var bit: int = value
		while bits.has(bit):
			bits.erase(bit)
			bit += 1
		bits[bit] = true
		top = maxi(top, bit)
	return top


## The exponent of a positive power of two from GameConfig (log2, rounded
## down for other values). 0 for values of 1 or less.
static func _exponent_of(value: int) -> int:
	var exponent: int = 0
	var rest: int = value
	while rest > 1:
		rest >>= 1
		exponent += 1
	return exponent


## The exponents on the chain's cells, in order. Off board cells give 0.
static func _chain_values(cells: PackedInt64Array, chain: Array[Vector2i], config: GameConfig) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in chain:
		values.append(_value(cells, cell, config))
	return values


## The exponent on cell, or 0 when the cell is off the board or the board is short.
static func _value(cells: PackedInt64Array, cell: Vector2i, config: GameConfig) -> int:
	if not in_bounds(cell, config):
		return 0
	var index: int = index_of(cell, config.columns)
	if index >= cells.size():
		return 0
	return cells[index]
