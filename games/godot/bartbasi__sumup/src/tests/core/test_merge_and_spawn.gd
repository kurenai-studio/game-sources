extends "res://tests/base_test.gd"
## Merge result (D-02, D-03), spawn window and floor (D-10), the weighted draw
## (TH9) and the move check (D-15), through CoreRules and RunRandom. Core
## works in exponents; the helpers below turn the GDD's tile values into
## exponents and back.

const F := preload("res://tests/core/core_fixtures.gd")

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


## merge_result for tile values, as a tile value.
func _merge(values: PackedInt64Array) -> int:
	return F.v(CoreRules.merge_result(F.ev(values)))


## The spawn window for H given as a tile value, as tile values.
func _window(h: int) -> PackedInt64Array:
	return F.vv(CoreRules.spawn_window(F.e(h), config))


## The exact merge result: (the BigNum sum of 2^k).bit_length() - 1 (section 17).
func _merge_by_big_sum(exponents: PackedInt64Array) -> int:
	var total: BigNum = BigNum.zero()
	for exponent: int in exponents:
		total = total.add(BigNum.pow2(exponent))
	return total.bit_length() - 1


# Merge result

## GDD 7.2, M1 to M10: chain values, result, points.
const MERGE_EXAMPLES: Array[Array] = [
	["M1", [2, 2], 4, 4],
	["M2", [2, 2, 2], 4, 6],
	["M3", [4, 4, 8], 16, 16],
	["M4", [2, 2, 2, 2, 2], 8, 10],
	["M5", [2, 2, 4, 8, 16, 32], 64, 64],
	["M6", [8, 8, 8, 16, 16, 32], 64, 88],
	["M7", [2, 2, 2, 2, 2, 2, 2, 2, 4, 4, 8], 32, 32],
	["M8", [2, 2, 4, 4, 4, 8, 8, 16], 32, 48],
	["M9", [512, 512, 1024, 1024], 2048, 3072],
	["M10", [64, 64, 64, 64], 256, 256],
]


func test_merge_result_worked_examples_m1_to_m10() -> void:
	for example: Array in MERGE_EXAMPLES:
		var values: PackedInt64Array = PackedInt64Array(example[1])
		assert_eq(_merge(values), example[2], "%s result" % example[0])


## GDD 7.2 M11 (2026-10-21): 2^62, 2^62 makes 2^63, past the old 64 bit limit.
func test_merge_result_m11_two_2_62_make_2_63() -> void:
	assert_eq(CoreRules.merge_result(PackedInt64Array([62, 62])), 63, "2^63")


func test_merge_result_needs_two_values() -> void:
	assert_eq(CoreRules.merge_result(PackedInt64Array()), 0, "no values")
	assert_eq(CoreRules.merge_result(PackedInt64Array([1])), 0, "one value")
	assert_eq(CoreRules.merge_result(PackedInt64Array([10])), 0, "one big value")


func test_merge_result_refuses_empty_and_negative_exponents() -> void:
	assert_eq(CoreRules.merge_result(PackedInt64Array([0, 0])), 0, "two empty cells")
	assert_eq(CoreRules.merge_result(PackedInt64Array([3, 0])), 0, "an empty cell in the chain")
	assert_eq(CoreRules.merge_result(PackedInt64Array([-1, -1])), 0, "negative exponents")


func test_merge_result_rounds_down_between_powers() -> void:
	assert_eq(_merge(PackedInt64Array([2, 2, 2, 2, 2, 2, 2])), 8, "14 rounds down to 8")
	assert_eq(_merge(PackedInt64Array([8, 8, 8, 8, 8, 8, 8, 8])), 64, "64 is already a power of two")
	assert_eq(_merge(PackedInt64Array([16, 16, 32, 32])), 64, "96 rounds down to 64")
	assert_eq(_merge(PackedInt64Array([16, 16, 32, 32, 32])), 128, "128 is already a power of two")
	assert_eq(_merge(PackedInt64Array([16, 16, 32, 32, 32, 32, 64])), 128, "224 rounds down to 128")


func test_merge_result_large_values_stay_exact() -> void:
	assert_eq(_merge(PackedInt64Array([131072, 131072])), 262144, "128K pair")
	assert_eq(_merge(PackedInt64Array([131072, 131072, 262144, 262144])), 524288, "128K chain")
	assert_eq(CoreRules.merge_result(PackedInt64Array([60, 60])), 61, "2^60 pair")
	assert_eq(CoreRules.merge_result(PackedInt64Array([61, 61])), 62, "2^61 pair")
	assert_eq(CoreRules.merge_result(PackedInt64Array([60, 60, 61, 61])), 62, "6 x 2^60 rounds down to 2^62")


## Tiles past 2^62 merge like any other (D-37, 2026-10-21).
func test_merge_result_past_2_62() -> void:
	assert_eq(CoreRules.merge_result(PackedInt64Array([62, 62, 62, 62, 62])), 64, "5 x 2^62 is 2^64 + 2^62, rounds down to 2^64")
	assert_eq(CoreRules.merge_result(PackedInt64Array([63, 63])), 64, "2^63 pair")
	assert_eq(CoreRules.merge_result(PackedInt64Array([99, 99])), 100, "2^99 pair makes 2^100")
	assert_eq(CoreRules.merge_result(PackedInt64Array([99, 99, 100])), 101, "2^99, 2^99, 2^100 makes 2^101")
	assert_eq(CoreRules.merge_result(PackedInt64Array([98, 98, 98])), 99, "3 x 2^98 rounds down to 2^99")
	assert_eq(CoreRules.merge_result(PackedInt64Array([65534, 65534])), 65535, "a pair making the ceiling tile")
	assert_eq(CoreRules.merge_result(PackedInt64Array([65535, 65535])), 65536, "merge_result itself has no ceiling")


## Mixed chains: the result is the bit length of the exact BigNum sum minus 1.
func test_merge_result_mixed_chains_match_the_big_sum() -> void:
	var cases: Array[PackedInt64Array] = [
		PackedInt64Array([1, 1, 2, 2, 2, 3, 3, 4]),
		PackedInt64Array([50, 50, 51, 52, 52, 53]),
		PackedInt64Array([56, 56, 56, 57, 58, 58, 59, 60, 61, 62, 63]),
		PackedInt64Array([62, 62, 63, 63, 63, 64, 65, 66, 67]),
		PackedInt64Array([90, 90, 90, 90, 91, 92, 93, 94, 95, 96, 97, 98, 99, 100]),
	]
	for exponents: PackedInt64Array in cases:
		assert_eq(CoreRules.merge_result(exponents), _merge_by_big_sum(exponents), "%s" % exponents)


## AT-27 on exponents: for random valid chains, up to 40 tiles and up to
## 2^100, the result is the bit length of the exact sum minus 1, at most the
## sum, more than half the sum, and at least double the last tile.
func test_at_27_result_facts_for_random_chains() -> void:
	var checked: int = 0
	for seed_value: int in range(1, 3001):
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = seed_value
		var top: int = 20 if seed_value <= 2000 else 100
		var exponent: int = rng.randi_range(1, top - 39 if top > 40 else top)
		var exponents: PackedInt64Array = PackedInt64Array([exponent, exponent])
		var length: int = rng.randi_range(2, 40)
		while exponents.size() < length:
			if rng.randi_range(0, 1) == 1:
				exponent += 1
			exponents.append(exponent)
		var total: BigNum = BigNum.zero()
		for each: int in exponents:
			total = total.add(BigNum.pow2(each))
		var result: int = CoreRules.merge_result(exponents)
		var last: int = exponents[exponents.size() - 1]
		var power: BigNum = BigNum.pow2(result)
		var problem: bool = result != total.bit_length() - 1
		problem = problem or power.compare(total) > 0 or power.add(power).compare(total) <= 0 or result < last + 1
		if problem:
			fail("seed %d: exponents %s sum %s gave 2^%d" % [seed_value, exponents, total.to_decimal(), result])
			return
		checked += 1
	assert_eq(checked, 3000, "every chain checked")


## GDD 7.3: the preview while dragging M8 one tile at a time.
func test_preview_table_for_m8() -> void:
	var values: PackedInt64Array = PackedInt64Array([2, 2, 4, 4, 4, 8, 8, 16])
	var expected: PackedInt64Array = PackedInt64Array([0, 4, 8, 8, 16, 16, 32, 32])
	for length: int in range(1, values.size() + 1):
		assert_eq(_merge(values.slice(0, length)), expected[length - 1], "step %d" % length)
	assert_eq(_merge(values.slice(0, 7)), 32, "after the backtrack off the 16")


# Spawn window and floor

func test_at_34_spawn_window_by_highest_tile() -> void:
	var cases: Array[Array] = [
		[2, [2, 4, 8, 16]],
		[16, [2, 4, 8, 16]],
		[1024, [2, 4, 8, 16]],
		[2048, [4, 8, 16, 32]],
		[4096, [8, 16, 32, 64]],
		[131072, [256, 512, 1024, 2048]],
		[1048576, [2048, 4096, 8192, 16384]],
	]
	for case: Array in cases:
		var h: int = case[0]
		var expected: PackedInt64Array = PackedInt64Array(case[1])
		var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): h}) if h > 16 else F.board_all(h)
		assert_eq(CoreRules.highest(board), F.e(h), "H %d" % h)
		assert_eq(F.vv(CoreRules.spawn_window(CoreRules.highest(board), config)), expected, "window for H %d" % h)
	var empty: PackedInt64Array = PackedInt64Array()
	empty.resize(40)
	assert_eq(CoreRules.highest(empty), 0, "an empty board has no H")
	assert_eq(F.vv(CoreRules.spawn_window(CoreRules.highest(empty), config)), PackedInt64Array([2, 4, 8, 16]), "empty board")


func test_spawn_window_table_of_gdd_9_1() -> void:
	var h: int = 2048
	var bottom: int = 4
	while h <= 1 << 40:
		assert_eq(_window(h), PackedInt64Array([bottom, bottom * 2, bottom * 4, bottom * 8]), "window for H %d" % h)
		h *= 2
		bottom *= 2
	for low: int in [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024]:
		assert_eq(_window(low), PackedInt64Array([2, 4, 8, 16]), "starting window for H %d" % low)
	assert_eq(CoreRules.spawn_window(0, config), PackedInt64Array([1, 2, 3, 4]), "starting window for an empty board")


func test_window_floor_is_2_until_2048_then_h_over_512() -> void:
	for h: int in [0, 1, 4, 9, 10]:
		assert_eq(CoreRules.window_floor(h, config), 1, "floor 2 for H 2^%d" % h)
	for power: int in range(11, 200):
		assert_eq(CoreRules.window_floor(power, config), power - 9, "floor for H 2^%d is 2^%d" % [power, power - 9])


func test_spawn_window_past_2_62_and_at_the_ceiling() -> void:
	assert_eq(CoreRules.spawn_window(56, config), PackedInt64Array([47, 48, 49, 50]), "Bart's H 2^56: 2^47 to 2^50")
	assert_eq(CoreRules.spawn_window(63, config), PackedInt64Array([54, 55, 56, 57]), "H 2^63")
	assert_eq(CoreRules.spawn_window(100, config), PackedInt64Array([91, 92, 93, 94]), "H 2^100")
	assert_eq(CoreRules.spawn_window(65535, config), PackedInt64Array([65526, 65527, 65528, 65529]), "H at the ceiling")


## GDD 9.2, S1 to S4: the window that applies when spawning, from H after the move.
func test_window_timing_examples_s1_to_s4() -> void:
	assert_eq(_window(2048), PackedInt64Array([4, 8, 16, 32]), "S1")
	assert_eq(_window(1024), PackedInt64Array([2, 4, 8, 16]), "S2")
	assert_eq(_window(2048), PackedInt64Array([4, 8, 16, 32]), "S3")
	assert_eq(_window(131072), PackedInt64Array([256, 512, 1024, 2048]), "S4")


func test_spawn_window_follows_config_overrides() -> void:
	config.spawn_top_min = 32
	assert_eq(F.vv(CoreRules.spawn_window(0, config)), PackedInt64Array([4, 8, 16, 32]), "SPAWN_TOP_MIN 32")
	config.spawn_top_divisor = 16
	assert_eq(_window(1024), PackedInt64Array([8, 16, 32, 64]), "SPAWN_TOP_DIVISOR 16")
	config.spawn_window_size = 3
	assert_eq(_window(1024), PackedInt64Array([16, 32, 64]), "SPAWN_WINDOW_SIZE 3")
	assert_eq(CoreRules.window_floor(F.e(1024), config), F.e(16), "floor follows")


# Weighted draw

func test_at_35_spawn_weights() -> void:
	var window: PackedInt64Array = CoreRules.spawn_window(F.e(1024), config)
	var draws: PackedInt64Array = PackedInt64Array([0, 39, 40, 69, 70, 89, 90, 99])
	var mapped: PackedInt64Array = PackedInt64Array()
	for draw: int in draws:
		mapped.append(CoreRules.draw_value(draw, window, config))
	assert_eq(F.vv(mapped), PackedInt64Array([2, 2, 4, 4, 8, 8, 16, 16]), "(a) draw numbers to values")
	var rng: RunRandom = F.seeded(35)
	var counts: Dictionary[int, int] = {2: 0, 4: 0, 8: 0, 16: 0}
	for draw: int in 100000:
		var value: int = F.v(rng.next_spawn(window, config))
		if not counts.has(value):
			fail("value %d is outside the window" % value)
			return
		counts[value] += 1
	var shares: Dictionary[int, float] = {2: 40.0, 4: 30.0, 8: 20.0, 16: 10.0}
	for value: int in shares:
		var share: float = counts[value] * 100.0 / 100000.0
		assert_near(share, shares[value], 1.0, "(b) share of %d" % value)


func test_draw_value_follows_weight_overrides() -> void:
	config.spawn_weights = PackedInt32Array([25, 25, 25, 25])
	var window: PackedInt64Array = F.ev(PackedInt64Array([2, 4, 8, 16]))
	assert_eq(CoreRules.draw_value(24, window, config), F.e(2), "first quarter")
	assert_eq(CoreRules.draw_value(25, window, config), F.e(4), "second quarter")
	assert_eq(CoreRules.draw_value(99, window, config), F.e(16), "last quarter")


# Move check

func test_at_45_move_check() -> void:
	assert_false(CoreRules.has_valid_move(F.board_d(), BigNum.zero(), config), "V1: Board D has none")
	assert_true(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(2, 0): 4}), BigNum.zero(), config), "V2: side by side")
	assert_true(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(1, 1): 2}), BigNum.zero(), config), "V3: diagonal")
	assert_true(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(0, 0): 8}), BigNum.zero(), config), "V4: one above the other")
	assert_false(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(0, 0): 4096, Vector2i(2, 0): 4096}), BigNum.zero(), config), "V5: two cells apart")
	assert_true(CoreRules.has_valid_move(F.changed_exponents(F.board_d(), {Vector2i(0, 7): 62, Vector2i(1, 7): 62}), BigNum.zero(), config), "V6: 2^62 + 2^62 is a move now (D-37, 2026-10-21)")
	assert_true(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(0, 7): 1 << 61, Vector2i(1, 7): 1 << 61}), BigNum.zero(), config), "V7: 2^61 + 2^61")
	assert_false(CoreRules.has_valid_move(F.changed_exponents(F.board_d(), {Vector2i(0, 7): 65535, Vector2i(1, 7): 65535}), BigNum.zero(), config), "a pair at the ceiling is no move")


func test_move_check_boards_e_and_d1024_have_none() -> void:
	assert_false(CoreRules.has_valid_move(F.board_e(), BigNum.zero(), config), "Board E")
	assert_false(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(2, 0): 1024}), BigNum.zero(), config), "Board D1024")
	assert_true(CoreRules.has_valid_move(F.board_p(), BigNum.zero(), config), "Board P")


func test_move_check_finds_each_direction_alone() -> void:
	var pairs: Array[Array] = [
		["right", Vector2i(1, 2), Vector2i(2, 2)],
		["below", Vector2i(3, 4), Vector2i(3, 5)],
		["lower right", Vector2i(0, 6), Vector2i(1, 7)],
		["lower left", Vector2i(1, 0), Vector2i(0, 1)],
		["corner diagonal", Vector2i(4, 7), Vector2i(3, 6)],
		["top right corner", Vector2i(4, 0), Vector2i(3, 1)],
	]
	for pair: Array in pairs:
		var a: Vector2i = pair[1]
		var b: Vector2i = pair[2]
		var board: PackedInt64Array = F.changed(F.board_d(), {a: 64, b: 64})
		assert_eq(F.equal_pairs(board).size(), 2, "%s: exactly one pair on the board" % pair[0])
		assert_true(CoreRules.has_valid_move(board, BigNum.zero(), config), "%s: found" % pair[0])


func test_move_check_ignores_row_wrap() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(4, 0): 64, Vector2i(0, 1): 64})
	assert_true(F.equal_pairs(board).is_empty(), "the two 64s do not touch")
	assert_false(CoreRules.has_valid_move(board, BigNum.zero(), config), "no move across the row wrap")
	var bottom_wrap: PackedInt64Array = F.changed(F.board_d(), {Vector2i(4, 6): 64, Vector2i(0, 7): 64})
	assert_false(CoreRules.has_valid_move(bottom_wrap, BigNum.zero(), config), "no move across the wrap near the bottom")


func test_move_check_full_boards_and_large_values() -> void:
	assert_true(CoreRules.has_valid_move(F.board_all(2), BigNum.zero(), config), "Board A2")
	assert_true(CoreRules.has_valid_move(F.board_all(4), BigNum.zero(), config), "Board A4")
	assert_true(CoreRules.has_valid_move(F.changed(F.board_d(), {Vector2i(0, 7): 131072, Vector2i(1, 7): 131072}), BigNum.zero(), config), "a 128K pair")
	assert_true(CoreRules.has_valid_move(F.changed_exponents(F.board_d(), {Vector2i(2, 3): 61, Vector2i(3, 4): 61}), BigNum.zero(), config), "a 2^61 pair")
	assert_true(CoreRules.has_valid_move(F.changed_exponents(F.board_d(), {Vector2i(2, 3): 62, Vector2i(3, 4): 62}), BigNum.zero(), config), "a 2^62 pair")
	assert_true(CoreRules.has_valid_move(F.changed_exponents(F.board_d(), {Vector2i(2, 3): 100, Vector2i(3, 4): 100}), BigNum.zero(), config), "a 2^100 pair")
	assert_false(CoreRules.has_valid_move(F.changed_exponents(F.board_d(), {Vector2i(2, 3): 62, Vector2i(3, 4): 61}), BigNum.zero(), config), "2^62 next to 2^61")
	assert_true(CoreRules.has_valid_move(F.bart_board(), BigNum.zero(), config), "Bart's board")


func test_move_check_never_pairs_empty_cells() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 0): 0, Vector2i(1, 0): 0})
	assert_false(CoreRules.has_valid_move(board, BigNum.zero(), config), "two empty cells are not a pair")
	assert_false(CoreRules.has_valid_move(PackedInt64Array([1, 1]), BigNum.zero(), config), "a board of the wrong size has no move")
	var negative: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(0, 0): -3, Vector2i(1, 0): -3})
	assert_false(CoreRules.has_valid_move(negative, BigNum.zero(), config), "negative exponents are no tiles")


func test_highest_of_boards() -> void:
	assert_eq(CoreRules.highest(F.board_d()), F.e(16), "Board D")
	assert_eq(CoreRules.highest(F.board_p()), F.e(32), "Board P")
	assert_eq(CoreRules.highest(F.board_e()), F.e(32), "Board E")
	assert_eq(CoreRules.highest(F.changed_exponents(F.board_d(), {Vector2i(4, 7): 62})), 62, "2^62")
	assert_eq(CoreRules.highest(F.changed_exponents(F.board_d(), {Vector2i(4, 7): 65535})), 65535, "the ceiling")
	assert_eq(CoreRules.highest(F.bart_board()), 56, "Bart's board")
	assert_eq(CoreRules.highest(PackedInt64Array()), 0, "no cells")
