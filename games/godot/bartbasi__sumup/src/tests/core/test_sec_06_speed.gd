extends "res://tests/base_test.gd"
## SEC-06 (docs/reviews/security-2026-10-21.md): on a hand edited save with
## tiles near 2^65535 and a score near 2^65600, chain steps, the commit and
## the move check took seconds. These tests time the reviewer's worst cases
## and check that the quick fit test and the quick points give exactly the
## answers of the full sums, near and far from both ceilings, so SEC-01's
## agreement between joining, the highlight, the move check and the commit
## still holds.
##
## Each timed case starts with an empty pow2 cache and builds the first huge
## power once (BigNum tests time that on its own), as loading such a save
## does. Every call is then held to 100 ms, a generous bound: on the
## development PC they take a few milliseconds.

const F := preload("res://tests/core/core_fixtures.gd")
const CALL_LIMIT_US: int = 100000

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


## Empties the pow2 cache and the headroom memo, then builds 2^65535 once.
func _fresh_start() -> void:
	BigNum._pow2_cache.clear()
	CoreRules._room_score = null
	CoreRules._room_limit = -1
	CoreRules._room = null
	BigNum.pow2(65535)


## The reviewer's ladder: a snake through all 40 cells holding 65490, 65490,
## 65491 and so on up to 65528.
func _ladder() -> PackedInt64Array:
	var board: PackedInt64Array = PackedInt64Array()
	board.resize(config.cell_count())
	var path: Array[Vector2i] = F.snake_from_top(40)
	for position: int in path.size():
		board[CoreRules.index_of(path[position], config.columns)] = 65490 + maxi(0, position - 1)
	return board


## 20 upright pairs, each a different exponent from 65516 to 65535, so no
## two pairs touch with the same value.
func _pairs() -> PackedInt64Array:
	var board: PackedInt64Array = PackedInt64Array()
	board.resize(config.cell_count())
	for column: int in config.columns:
		for pair: int in 4:
			var value: int = 65516 + column * 4 + pair
			board[CoreRules.index_of(Vector2i(column, pair * 2), config.columns)] = value
			board[CoreRules.index_of(Vector2i(column, pair * 2 + 1), config.columns)] = value
	return board


## 2^bits minus amount.
func _below_pow2(bits: int, amount: int) -> BigNum:
	return BigNum.pow2(bits).sub(BigNum.from_int(amount))


## The exponents on the chain's cells (F.values_of gives plain values).
func _values_on(board: PackedInt64Array, chain: Array[Vector2i]) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in chain:
		values.append(board[CoreRules.index_of(cell, config.columns)])
	return values


## The points worked out the slow, plain way: one pow2 per tile, added up.
func _plain_points(values: PackedInt64Array) -> BigNum:
	var total: BigNum = BigNum.zero()
	for value: int in values:
		total = total.add(BigNum.pow2(value))
	return total


## The fit test worked out the plain way, from the full sum, with compare
## only (no bit length estimates).
func _plain_fits(values: PackedInt64Array, score: BigNum, rules: GameConfig) -> bool:
	for value: int in values:
		if value <= 0 or value > rules.max_exponent:
			return false
	var points: BigNum = _plain_points(values)
	if points.compare(BigNum.pow2(rules.max_exponent + 1)) >= 0:
		return false
	return score.add(points).compare(BigNum.pow2(rules.max_score_bits)) < 0


## Drags the whole ladder as the board does (step_chain, then
## joinable_cells, at every step), times every call, then checks the full
## chain and commits it, timing those too.
func _drag_and_commit_the_ladder(score: BigNum, label: String) -> void:
	_fresh_start()
	var board: PackedInt64Array = _ladder()
	var chain: Array[Vector2i] = []
	var slowest: int = 0
	for cell: Vector2i in F.snake_from_top(40):
		var start: int = Time.get_ticks_usec()
		chain = CoreRules.step_chain(board, score, chain, cell, config)
		slowest = maxi(slowest, Time.get_ticks_usec() - start)
		start = Time.get_ticks_usec()
		CoreRules.joinable_cells(board, score, chain, config)
		slowest = maxi(slowest, Time.get_ticks_usec() - start)
	assert_eq(chain.size(), 40, "%s: the whole ladder joins" % label)
	assert_true(slowest < CALL_LIMIT_US, "%s: the slowest drag call took %d us" % [label, slowest])

	var begin: int = Time.get_ticks_usec()
	var valid: bool = CoreRules.is_valid_chain(board, score, chain, config)
	var took: int = Time.get_ticks_usec() - begin
	assert_true(valid, "%s: the full chain is valid" % label)
	assert_true(took < CALL_LIMIT_US, "%s: is_valid_chain took %d us" % [label, took])

	var state: RunState = RunState.create(board, score)
	var rng: RunRandom = F.seeded(6)
	begin = Time.get_ticks_usec()
	var result: MoveResult = RunRules.commit_chain(state, F.records(0, 1), chain, rng, config)
	took = Time.get_ticks_usec() - begin
	assert_true(took < CALL_LIMIT_US, "%s: commit_chain took %d us" % [label, took])
	assert_true(result.accepted, "%s: the commit is accepted" % label)
	var points: BigNum = _plain_points(_values_on(board, chain))
	assert_eq(result.result_value, 65529, "%s: the result is 2^65529" % label)
	assert_true(result.points.equals(points), "%s: the points are the exact sum" % label)
	assert_true(state.score.equals(score.add(points)), "%s: the score rose by the points" % label)

	begin = Time.get_ticks_usec()
	var move: bool = CoreRules.has_valid_move(state.cells, state.score, config)
	took = Time.get_ticks_usec() - begin
	assert_eq(move, result.has_valid_move, "%s: the move check agrees with the result" % label)
	assert_true(took < CALL_LIMIT_US, "%s: has_valid_move took %d us" % [label, took])


func test_sec_06_ladder_near_the_ceiling_with_score_2_65599() -> void:
	_drag_and_commit_the_ladder(BigNum.pow2(65599), "score 2^65599")


func test_sec_06_ladder_near_the_ceiling_with_score_0() -> void:
	_drag_and_commit_the_ladder(BigNum.zero(), "score 0")


## The ladder with a score just low enough for the whole chain: every step
## goes through the exact comparison, and one more point refuses the last tile.
func test_sec_06_ladder_at_the_exact_score_edge() -> void:
	var points: BigNum = _plain_points(_values_on(_ladder(), F.snake_from_top(40)))
	var edge: BigNum = BigNum.pow2(65600).sub(points).sub(BigNum.from_int(1))
	_drag_and_commit_the_ladder(edge, "score at the edge")
	var over: BigNum = edge.add(BigNum.from_int(1))
	var chain: Array[Vector2i] = []
	for cell: Vector2i in F.snake_from_top(40):
		chain = CoreRules.step_chain(_ladder(), over, chain, cell, config)
	assert_eq(chain.size(), 39, "one point more and the last tile does not join")


func _time_the_pairs(score: BigNum, expected: bool, label: String) -> void:
	_fresh_start()
	var board: PackedInt64Array = _pairs()
	var begin: int = Time.get_ticks_usec()
	var move: bool = CoreRules.has_valid_move(board, score, config)
	var took: int = Time.get_ticks_usec() - begin
	assert_eq(move, expected, "%s: has a move" % label)
	assert_true(took < CALL_LIMIT_US, "%s: has_valid_move took %d us" % [label, took])
	var slowest: int = 0
	for index: int in board.size():
		var chain: Array[Vector2i] = [CoreRules.cell_of(index, config.columns)]
		begin = Time.get_ticks_usec()
		var joinable: Array[Vector2i] = CoreRules.joinable_cells(board, score, chain, config)
		slowest = maxi(slowest, Time.get_ticks_usec() - begin)
		var exponent: int = board[index]
		var fits: bool = _plain_fits(PackedInt64Array([exponent, exponent]), score, config)
		assert_eq(joinable.size(), 1 if fits else 0, "%s: the highlight from a %d tile" % [label, exponent])
	assert_true(slowest < CALL_LIMIT_US, "%s: the slowest highlight took %d us" % [label, slowest])


func test_sec_06_twenty_pairs_near_the_ceiling_with_the_largest_score() -> void:
	_time_the_pairs(_below_pow2(65600, 1), false, "score 2^65600 - 1")


func test_sec_06_twenty_pairs_near_the_ceiling_with_score_0() -> void:
	_time_the_pairs(BigNum.zero(), true, "score 0")


## A score whose headroom is just the size of one pair: only the pairs at
## that exponent and below fit.
func test_sec_06_twenty_pairs_with_room_for_one_size() -> void:
	_time_the_pairs(BigNum.pow2(65600).sub(BigNum.pow2(65525)), true, "room for 2^65525")


# The quick paths give the exact answers

## A random chain: a pair, then each exponent equal to the one before or one
## more, starting at base.
func _random_chain(rng: RandomNumberGenerator, base: int) -> PackedInt64Array:
	var values: PackedInt64Array = PackedInt64Array([base, base])
	for step: int in rng.randi_range(0, 10):
		values.append(values[values.size() - 1] + rng.randi_range(0, 1))
	return values


## Scores around every edge that matters for these points: the exact edge
## (2^limit - points, give or take 2), the bounds of the points' size, half
## the limit, zero, the largest score, a random one and some beyond the limit.
func _scores_around(rng: RandomNumberGenerator, points: BigNum, limit: int) -> Array[BigNum]:
	var top: BigNum = BigNum.pow2(limit)
	var scores: Array[BigNum] = [BigNum.zero(), top.sub(BigNum.from_int(1)), top, top.add(BigNum.from_int(1)), BigNum.pow2(limit - 1)]
	var bits: int = points.bit_length()
	for base: BigNum in [points, BigNum.pow2(bits - 1), BigNum.pow2(bits)]:
		if top.compare(base) >= 0:
			var edge: BigNum = top.sub(base)
			for delta: int in [0, 1, 2]:
				scores.append(edge.add(BigNum.from_int(delta)))
				var less: BigNum = edge.sub(BigNum.from_int(delta))
				if less != null:
					scores.append(less)
	scores.append(BigNum.pow2(rng.randi_range(0, limit - 1)).add(BigNum.from_int(rng.randi_range(0, 1000))))
	return scores


func _check_chains(rng: RandomNumberGenerator, rules: GameConfig, bases: Vector2i, trials: int, label: String) -> int:
	var checked: int = 0
	for trial: int in trials:
		var values: PackedInt64Array = _random_chain(rng, rng.randi_range(bases.x, bases.y))
		assert_true(CoreRules._points_of(values).equals(_plain_points(values)), "%s: points of %s" % [label, values])
		var board: PackedInt64Array = PackedInt64Array()
		board.resize(rules.cell_count())
		var path: Array[Vector2i] = F.snake_from_top(values.size())
		for position: int in values.size():
			board[CoreRules.index_of(path[position], rules.columns)] = values[position]
		for score: BigNum in _scores_around(rng, _plain_points(values), rules.max_score_bits):
			var expected: bool = _plain_fits(values, score, rules)
			var got: bool = CoreRules._chain_fits(values, score, rules)
			var valid: bool = CoreRules.is_valid_chain(board, score, path, rules)
			if got != expected or valid != expected:
				fail("%s: %s with a score of %d bits: expected %s, fit test %s, full check %s" % [label, values, score.bit_length(), expected, got, valid])
				return checked
			checked += 1
	return checked


## Default limits: tiles low, middling, around 2^30000 and near 2^65535.
func test_sec_06_fit_test_matches_the_full_sum_with_the_game_limits() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6006
	var checked: int = 0
	checked += _check_chains(rng, config, Vector2i(1, 60), 12, "low")
	checked += _check_chains(rng, config, Vector2i(60, 3000), 8, "middle")
	checked += _check_chains(rng, config, Vector2i(30000, 30100), 6, "2^30000")
	checked += _check_chains(rng, config, Vector2i(65480, 65535), 16, "near the ceiling")
	assert_true(checked > 500, "%d cases checked" % checked)


## Small limits, so every edge is near and the numbers are cheap: many more
## random cases, and limits in both orders against one score object (the
## headroom memo must follow the limit).
func test_sec_06_fit_test_matches_the_full_sum_with_small_limits() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6007
	var small: GameConfig = GameConfig.new()
	small.max_exponent = 18
	small.max_score_bits = 24
	var middle: GameConfig = GameConfig.new()
	middle.max_exponent = 64
	middle.max_score_bits = 70
	var checked: int = _check_chains(rng, small, Vector2i(1, 18), 150, "limit 24")
	checked += _check_chains(rng, middle, Vector2i(40, 64), 150, "limit 70")
	assert_true(checked > 3000, "%d cases checked" % checked)
	var score: BigNum = BigNum.pow2(24).sub(BigNum.pow2(18))
	for repeat: int in 3:
		assert_true(CoreRules._chain_fits(PackedInt64Array([16, 16]), score, small), "2^24 - 2^18 + 2^17 fits under 2^24")
		assert_false(CoreRules._chain_fits(PackedInt64Array([17, 17]), score, small), "2^24 - 2^18 + 2^18 does not")
		assert_true(CoreRules._chain_fits(PackedInt64Array([40, 40]), score, middle), "the same score under 2^70")


## Points of any exponents, not only chains: wide spans and repeats.
func test_sec_06_points_match_the_plain_sum() -> void:
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([1]), PackedInt64Array([3, 5000, 65535]), PackedInt64Array([65535, 65535]),
		PackedInt64Array([62, 62, 63, 64]), PackedInt64Array([100, 1]), PackedInt64Array([7, 7, 7, 7, 7, 7, 7]),
	]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 6008
	for trial: int in 20:
		var values: PackedInt64Array = PackedInt64Array()
		for count: int in rng.randi_range(1, 8):
			values.append(rng.randi_range(1, 2000))
		cases.append(values)
	for values: PackedInt64Array in cases:
		assert_true(CoreRules._points_of(values).equals(_plain_points(values)), "points of %s" % values)
	assert_true(CoreRules._points_of(PackedInt64Array()).is_zero(), "no tiles, no points")
