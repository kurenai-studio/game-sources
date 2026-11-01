extends RefCounted
## Test boards from GDD section 19.0 and small helpers for the core tests.
## Not a test file: the runner only loads files named test_*.gd.
## Every board function returns a new array, so tests never share one.
##
## Core boards hold exponents (docs/ARCHITECTURE.md section 17). These
## helpers let tests keep writing the GDD's tile values: the board builders
## and changed, placed and with_column take values (2, 4, 1024) and store
## exponents; at, values_of and column_of give values back. Values must be 0
## (empty) or a power of two up to 2^62. Tests past 2^62 write exponents
## straight into the board (board_all_exponent, changed_exponents).

const COLUMNS: int = 5
const ROWS: int = 8


## The exponent of a tile value: 2 is 1, 1024 is 10, 0 (empty) is 0. A value
## that is not 0 or a positive power of two is a mistake in the test.
static func e(value: int) -> int:
	if value == 0:
		return 0
	if value < 0 or (value & (value - 1)) != 0:
		push_error("core_fixtures.e: %d is not a tile value" % value)
		return 0
	var exponent: int = 0
	while (1 << exponent) != value:
		exponent += 1
	return exponent


## The exponents of tile values, in order.
static func ev(values: PackedInt64Array) -> PackedInt64Array:
	var exponents: PackedInt64Array = PackedInt64Array()
	for value: int in values:
		exponents.append(e(value))
	return exponents


## The tile value of an exponent up to 62; 0 stays 0.
static func v(exponent: int) -> int:
	if exponent < 0 or exponent > 62:
		push_error("core_fixtures.v: exponent %d does not fit in an int" % exponent)
		return 0
	return 0 if exponent == 0 else 1 << exponent


## The tile values of exponents up to 62, in order.
static func vv(exponents: PackedInt64Array) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	for exponent: int in exponents:
		values.append(v(exponent))
	return values


static func big(value: int) -> BigNum:
	return BigNum.from_int(value)


## Board D: no valid move, H = 16.
static func board_d() -> PackedInt64Array:
	return ev(PackedInt64Array([
		2, 4, 2, 4, 2,
		8, 16, 8, 16, 8,
		2, 4, 2, 4, 2,
		8, 16, 8, 16, 8,
		2, 4, 2, 4, 2,
		8, 16, 8, 16, 8,
		2, 4, 2, 4, 2,
		8, 16, 8, 16, 8,
	]))


## Board P: the example board of GDD 6.6, H = 32.
static func board_p() -> PackedInt64Array:
	return ev(PackedInt64Array([
		2, 4, 2, 4, 2,
		8, 16, 8, 16, 8,
		2, 4, 2, 4, 2,
		8, 16, 8, 16, 8,
		2, 4, 2, 4, 2,
		8, 4, 8, 16, 8,
		2, 2, 2, 4, 2,
		8, 8, 32, 8, 8,
	]))


## Board E: no valid move, H = 32, no 2s.
static func board_e() -> PackedInt64Array:
	return ev(PackedInt64Array([
		4, 16, 4, 16, 4,
		8, 32, 8, 32, 8,
		4, 16, 4, 16, 4,
		8, 32, 8, 32, 8,
		4, 16, 4, 16, 4,
		8, 32, 8, 32, 8,
		4, 16, 4, 16, 4,
		8, 32, 8, 32, 8,
	]))


## Bart's board on 2026-10-21, in exponents, row by row (mostly 2^56). His
## score then was 9,221,253,119,629,040,934.
static func bart_board() -> PackedInt64Array:
	var board: PackedInt64Array = PackedInt64Array([
		47, 50, 48, 50, 47,
		51, 52, 50, 51, 49,
		48, 53, 48, 52, 55,
		55, 55, 56, 56, 55,
	])
	for index: int in 20:
		board.append(56)
	return board


## Board A2 (value 2) or Board A4 (value 4): every cell holds value.
static func board_all(value: int) -> PackedInt64Array:
	return board_all_exponent(e(value))


## Every cell holds the tile 2^exponent.
static func board_all_exponent(exponent: int) -> PackedInt64Array:
	var board: PackedInt64Array = PackedInt64Array()
	board.resize(COLUMNS * ROWS)
	board.fill(exponent)
	return board


## A copy of board with the listed cells changed. changes maps Vector2i to a tile value.
static func changed(board: PackedInt64Array, changes: Dictionary) -> PackedInt64Array:
	var exponents: Dictionary = {}
	for cell: Vector2i in changes:
		var value: int = changes[cell]
		exponents[cell] = e(value)
	return changed_exponents(board, exponents)


## A copy of board with the listed cells changed. changes maps Vector2i to an exponent.
static func changed_exponents(board: PackedInt64Array, changes: Dictionary) -> PackedInt64Array:
	var result: PackedInt64Array = board.duplicate()
	for cell: Vector2i in changes:
		var exponent: int = changes[cell]
		result[cell.y * COLUMNS + cell.x] = exponent
	return result


## A copy of board with one column replaced, values listed top to bottom.
static func with_column(board: PackedInt64Array, column: int, values: PackedInt64Array) -> PackedInt64Array:
	var result: PackedInt64Array = board.duplicate()
	for row: int in ROWS:
		result[row * COLUMNS + column] = e(values[row])
	return result


## The values of one column, top to bottom.
static func column_of(board: PackedInt64Array, column: int) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	for row: int in ROWS:
		values.append(v(board[row * COLUMNS + column]))
	return values


## The tile value on cell.
static func at(board: PackedInt64Array, cell: Vector2i) -> int:
	return v(board[cell.y * COLUMNS + cell.x])


## The tile values on the chain's cells, in order.
static func values_of(board: PackedInt64Array, chain: Array[Vector2i]) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in chain:
		values.append(at(board, cell))
	return values


## A copy of board with values written along path, in order.
static func placed(board: PackedInt64Array, path: Array[Vector2i], values: PackedInt64Array) -> PackedInt64Array:
	var result: PackedInt64Array = board.duplicate()
	for position: int in path.size():
		var cell: Vector2i = path[position]
		result[cell.y * COLUMNS + cell.x] = e(values[position])
	return result


## The first count cells of a snake that runs row 0 left to right, row 1
## right to left, and so on down the board.
static func snake_from_top(count: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for row: int in ROWS:
		for step: int in COLUMNS:
			var column: int = step if row % 2 == 0 else COLUMNS - 1 - step
			if path.size() < count:
				path.append(Vector2i(column, row))
	return path


## The first count cells of a snake that runs row 7 left to right, row 6
## right to left, and so on up the board.
static func snake_from_bottom(count: int) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for climb: int in ROWS:
		var row: int = ROWS - 1 - climb
		for step: int in COLUMNS:
			var column: int = step if climb % 2 == 0 else COLUMNS - 1 - step
			if path.size() < count:
				path.append(Vector2i(column, row))
	return path


## Every touching pair of equal tiles, worked out by brute force without
## CoreRules. Pairs are flattened: [a0, b0, a1, b1, ...], a before b in index order.
@warning_ignore("integer_division")
static func equal_pairs(board: PackedInt64Array) -> Array[Vector2i]:
	var pairs: Array[Vector2i] = []
	for first: int in board.size():
		for second: int in range(first + 1, board.size()):
			var a: Vector2i = Vector2i(first % COLUMNS, first / COLUMNS)
			var b: Vector2i = Vector2i(second % COLUMNS, second / COLUMNS)
			if absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1 and board[first] == board[second] and board[first] > 0:
				pairs.append(a)
				pairs.append(b)
	return pairs


## A state on board (exponents) with a score that fits in an int.
static func state(board: PackedInt64Array, score: int) -> RunState:
	return RunState.create(board, big(score))


## Records with Best Score best_score and Best Tile the value best_tile.
static func records(best_score: int, best_tile: int) -> Records:
	var result: Records = Records.new()
	result.best_score = big(best_score)
	result.best_tile = e(best_tile)
	return result


static func seeded(seed_value: int) -> RunRandom:
	var rng: RunRandom = RunRandom.new()
	rng.set_seed(seed_value)
	return rng


## True when every tile value of board (exponents) is one of allowed (values).
static func all_in(board: PackedInt64Array, allowed: PackedInt64Array) -> bool:
	var exponents: PackedInt64Array = ev(allowed)
	for exponent: int in board:
		if not exponents.has(exponent):
			return false
	return true
