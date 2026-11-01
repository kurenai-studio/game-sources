extends "res://tests/base_test.gd"
## Free boosters on the rules model (GDD 13.9, D-46): is_free and charge
## (TH3), usability measured against the charge, apply charging 0 and using
## exactly one free booster, refusals that use nothing, Undo never giving one
## back, and the worked examples FB2, FB4, FB6, FB7, FB9, FB10 and FB12.
## Session examples (FB1, FB3, FB5, FB8, FB11) are in
## test_session_free_boosters.gd.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const USABLE: BoosterStatus.Usability = BoosterStatus.Usability.USABLE
const CANNOT_AFFORD: BoosterStatus.Usability = BoosterStatus.Usability.CANNOT_AFFORD
const NO_SNAPSHOT: BoosterStatus.Usability = BoosterStatus.Usability.NO_SNAPSHOT
const TOP: int = 65535

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _apply(id: StringName, state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	return BoosterRules.apply(id, state, records, BF.targets(cells), rng, config)


func _commit(state: RunState, records: Records, cells: Array, rng: RunRandom) -> MoveResult:
	return RunRules.commit_chain(state, records, BF.targets(cells), rng, config)


func _held(state: RunState) -> int:
	return CoreRules.free_held(state, config)


func _stars(state: RunState) -> int:
	return CoreRules.stars(state.run_highest, config)


func _usabilities(state: RunState) -> Array[BoosterStatus.Usability]:
	var list: Array[BoosterStatus.Usability] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BoosterRules.usability(id, state, config))
	return list


func _charges(state: RunState) -> Array[int]:
	var list: Array[int] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BF.n(BoosterRules.charge(id, state, config)))
	return list


func _costs(state: RunState) -> Array[int]:
	var list: Array[int] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BF.price(id, state, config))
	return list


## Targets each booster can use on Board D style boards.
func _targets_for(id: StringName) -> Array:
	match id:
		BoosterRules.HAMMER, BoosterRules.DOUBLE:
			return [Vector2i(4, 7)]
		BoosterRules.SWAP:
			return [Vector2i(0, 0), Vector2i(1, 0)]
	return []


## The AT-127 setup (FB1): Board D with (0,7) = 4096 and (1,7) = 4096.
func _fb1_board() -> PackedInt64Array:
	return F.changed(F.board_d(), {Vector2i(0, 7): 4096, Vector2i(1, 7): 4096})


## The state right after AT-127: the 4096 pair committed from score 50,000.
func _after_fb1(records: Records, rng: RunRandom) -> RunState:
	var state: RunState = F.state(_fb1_board(), 50000)
	var result: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_true(result.accepted, "the FB1 chain commits")
	assert_eq(BF.n(state.score), 58192, "FB1: score 58,192")
	assert_eq(_held(state), 1, "FB1: 1 free booster held")
	return state


# is_free and charge (TH3)

func test_is_free_and_charge() -> void:
	var held: RunState = BF.holding(1, F.board_d(), 5000, 8192)
	assert_true(BoosterRules.is_free(held, config), "1 held: free")
	assert_eq(_charges(held), [0, 0, 0, 0, 0] as Array[int], "every booster charges 0 while free, Undo included")
	assert_eq(_costs(held), [128, 128, 128, 256, 64] as Array[int], "the cost still holds the price (AT-56)")
	var two: RunState = BF.holding(2, F.board_d(), 5000, 65536)
	assert_true(BoosterRules.is_free(two, config), "2 held: free")
	var none: RunState = BF.holding(0, F.board_d(), 5000, 8192)
	assert_false(BoosterRules.is_free(none, config), "earned and used: not free")
	assert_eq(_charges(none), _costs(none), "the charge is the cost")
	var never: RunState = F.state(F.board_d(), 5000)
	assert_false(BoosterRules.is_free(never, config), "no free booster earned yet")
	assert_eq(_charges(never), [128, 128, 128, 256, 64] as Array[int], "charges are the costs")


func test_a_negative_count_held_is_not_free() -> void:
	var bad: RunState = BF.holding(-1, F.board_d(), 5000, 8192)
	assert_eq(CoreRules.free_held(bad, config), -1, "a bad state holds minus 1")
	assert_false(BoosterRules.is_free(bad, config), "which is not free")
	assert_eq(_charges(bad), _costs(bad), "so the full cost is charged")
	var result: MoveResult = _apply(BoosterRules.HAMMER, bad, Records.new(), [Vector2i(0, 0)], F.seeded(1))
	assert_eq(BF.n(result.cost), 128, "a Hammer is paid")
	assert_false(result.free_used, "and uses nothing")
	assert_eq(bad.free_used, 2, "free_used is not touched")


func test_charge_at_the_ceiling() -> void:
	var held: RunState = BF.holding_big(1, F.changed_exponents(F.board_d(), {Vector2i(2, 0): TOP}), BigNum.zero(), TOP)
	assert_eq(BoosterRules.cost(BoosterRules.DOUBLE, held, config), TOP + 1, "Double costs 2^65536, the largest cost (13.2)")
	assert_true(BoosterRules.charge(BoosterRules.DOUBLE, held, config).is_zero(), "free: charge 0")
	assert_eq(BoosterRules.usability(BoosterRules.DOUBLE, held, config), USABLE, "and usable while free, on a tile it can double")
	held.free_used += 1
	assert_true(BoosterRules.charge(BoosterRules.DOUBLE, held, config).equals(BigNum.pow2(TOP + 1)), "paid: charge 2^65536 exactly")


# Usability against the charge (13.9 Affordability)

func test_every_booster_is_affordable_while_free() -> void:
	var state: RunState = BF.holding(1, F.board_d(), 0, 8192)
	assert_eq(_usabilities(state), [USABLE, USABLE, USABLE, USABLE, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "score 0: every booster but Undo (no snapshot)")
	var with_snapshot: RunState = BF.holding(1, F.board_d(), 40, 8192, F.board_p(), 40)
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, with_snapshot, config), USABLE, "Undo free at score minus points exactly 0")
	with_snapshot.score = F.big(39)
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, with_snapshot, config), CANNOT_AFFORD, "but not below 0 (FB4, D-28)")
	assert_eq(_usabilities(BF.holding(0, F.board_d(), 0, 8192)), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "with nothing held, score 0 affords nothing")


func test_every_booster_can_be_used_free() -> void:
	for id: StringName in BoosterRules.ALL:
		var state: RunState = BF.holding(1, BF.board_d1024(), 40, 8192, BF.snapshot_board(), 40)
		var paid: RunState = BF.holding(0, BF.board_d1024(), 40, 8192, BF.snapshot_board(), 40)
		var refused: MoveResult = _apply(id, paid, Records.new(), _targets_for(id), F.seeded(5))
		assert_eq(refused.refusal, &"cannot_afford", "%s: unaffordable at score 40 with nothing held" % id)
		var result: MoveResult = _apply(id, state, Records.new(), _targets_for(id), F.seeded(5))
		assert_true(result.accepted, "%s: usable with a free booster held" % id)
		assert_eq(BF.n(result.cost), 0, "%s: charges 0" % id)
		assert_true(result.free_used, "%s: reports the free booster used" % id)
		assert_eq(state.free_used, 1, "%s: one free booster used" % id)
		assert_eq(_held(state), 0, "%s: none held after" % id)
		var expected: int = 0 if id == BoosterRules.UNDO else 40
		assert_eq(BF.n(state.score), expected, "%s: the score loses nothing but Undo's chain points" % id)


func test_z1_and_z3_with_a_free_booster_held() -> void:
	var z1: RunState = BF.holding(1, F.board_d(), 100, 8192)
	assert_eq(BoosterRules.usability(BoosterRules.HAMMER, z1, config), USABLE, "Z1: Hammer is usable and free at score 100")
	var result: MoveResult = _apply(BoosterRules.HAMMER, z1, Records.new(), [Vector2i(0, 0)], F.seeded(1))
	assert_eq(BF.n(result.cost), 0, "Z1: charged 0")
	assert_eq(BF.n(z1.score), 100, "Z1: score stays 100")
	var z3: RunState = BF.holding(1, F.board_d(), 0, 8192)
	assert_eq(BoosterRules.outcome(z3, config), BoosterRules.Outcome.OFFER, "Z3: the offer opens instead of the run ending")
	assert_eq(BoosterRules.suggested_rescue(z3, config), BoosterRules.SHUFFLE, "Z3: with Shuffle marked")


# Worked examples

func test_at_128_the_next_booster_is_free_automatically_one_at_a_time() -> void:
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(128)
	var state: RunState = _after_fb1(records, rng)
	assert_true(BoosterRules.is_free(state, config), "every booster is free")
	var first: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(4, 0)], rng)
	assert_true(first.accepted, "the first Hammer is accepted")
	assert_eq(BF.n(first.cost), 0, "and charges 0")
	assert_true(first.free_used, "reported as using a free booster")
	assert_eq(BF.n(state.score), 58192, "score 58,192")
	assert_eq(_held(state), 0, "0 free boosters held")
	assert_false(BoosterRules.is_free(state, config), "every booster no longer free")
	assert_eq(BF.n(BoosterRules.charge(BoosterRules.HAMMER, state, config)), 8192, "the costs show again: Hammer 8K")
	var second: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(4, 0)], rng)
	assert_true(second.accepted, "the second Hammer is accepted")
	assert_eq(BF.n(second.cost), 8192, "and charges 8,192")
	assert_false(second.free_used, "it is paid")
	assert_eq(BF.n(state.score), 50000, "score 50,000")


func test_at_130_a_free_undo_still_follows_d_28() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(1, 7): 8, Vector2i(2, 7): 16})
	var state: RunState = F.state(board, 8160)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(130)
	_commit(state, records, [Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)], rng)
	assert_eq(BF.n(state.score), 8192, "after the commit: score 8,192")
	var doubled: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [Vector2i(2, 0)], rng)
	assert_eq(BF.n(doubled.cost), 8192, "the Double costs 8,192")
	assert_false(doubled.free_used, "and is paid")
	assert_eq(BF.n(state.score), 0, "score 0")
	assert_eq(_stars(state), 3, "3 stars")
	assert_eq(_held(state), 1, "1 free booster held")
	assert_eq(BF.n(BoosterRules.charge(BoosterRules.UNDO, state, config)), 0, "Undo would be free")
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, state, config), CANNOT_AFFORD, "but 0 minus the chain's 32 points is below 0")
	var before: RunState = state.copy()
	var rng_before: int = rng.get_state()
	var undone: MoveResult = _apply(BoosterRules.UNDO, state, records, [], rng)
	assert_false(undone.accepted, "the call is refused")
	assert_eq(undone.refusal, &"cannot_afford", "as unaffordable")
	assert_false(undone.free_used, "using nothing")
	assert_true(state.equals(before), "score 0, board unchanged")
	assert_eq(rng.get_state(), rng_before, "the generator was not used")
	assert_eq(_held(state), 1, "still 1 free booster held")
	for id: StringName in [BoosterRules.HAMMER, BoosterRules.SWAP, BoosterRules.SHUFFLE, BoosterRules.DOUBLE]:
		assert_eq(BoosterRules.usability(id, state, config), USABLE, "%s is usable for free" % id)


func test_at_132_a_free_booster_used_on_undo_stays_used() -> void:
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(132)
	var state: RunState = _after_fb1(records, rng)
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, state, config), USABLE, "Undo usable: 58,192 minus 8,192 is at least 0")
	var undone: MoveResult = _apply(BoosterRules.UNDO, state, records, [], rng)
	assert_true(undone.accepted, "Undo is accepted")
	assert_eq(BF.n(undone.cost), 0, "charges 0")
	assert_true(undone.free_used, "and uses the free booster")
	assert_eq(state.cells, _fb1_board(), "the board equals the AT-127 setup")
	assert_eq(BF.n(state.score), 50000, "score 50,000")
	assert_eq(F.v(state.run_highest), 8192, "the run highest tile stays 8192")
	assert_eq(_stars(state), 3, "still 3 stars")
	assert_eq(_held(state), 0, "0 free boosters held")
	var again: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(BF.n(state.score), 58192, "the same chain again: score 58,192")
	assert_eq(_stars(state), 3, "3 stars")
	assert_eq(again.stars_earned, 0, "0 stars earned")
	assert_eq(again.free_earned, 0, "0 free boosters earned")
	assert_eq(_held(state), 0, "0 held")


func test_undo_never_gives_a_free_booster_back() -> void:
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(13)
	var state: RunState = _after_fb1(records, rng)
	var hammered: MoveResult = _apply(BoosterRules.HAMMER, state, records, [Vector2i(4, 0)], rng)
	assert_true(hammered.free_used, "the Hammer used the free booster")
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 4096, "Undo costs 4,096 from the current board")
	var undone: MoveResult = _apply(BoosterRules.UNDO, state, records, [], rng)
	assert_true(undone.accepted, "Undo is accepted")
	assert_false(undone.free_used, "and paid")
	assert_eq(BF.n(undone.cost), 4096, "charged 4,096")
	assert_eq(state.cells, _fb1_board(), "the board from before the chain, the hammered tile back too")
	assert_eq(BF.n(state.score), 58192 - 8192 - 4096, "the Undo cost is spent, the free Hammer stays free")
	assert_eq(state.free_used, 1, "the free booster stays used: free_used is not part of the snapshot")
	assert_eq(_held(state), 0, "none held")


func test_at_133_two_free_boosters_held() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(0, 7): 32768, Vector2i(1, 7): 32768})
	var state: RunState = F.state(board, 1000000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(133)
	assert_eq([_stars(state), _held(state)], [5, 1], "5 stars, 1 earned, none used, so 1 held")
	var chain: MoveResult = _commit(state, records, [Vector2i(0, 7), Vector2i(1, 7)], rng)
	assert_eq(chain.free_earned, 1, "the 65536 earns the second free booster")
	assert_eq([BF.n(state.score), _stars(state), _held(state)], [1065536, 6, 2], "after the commit")
	var shuffled: MoveResult = _apply(BoosterRules.SHUFFLE, state, records, [], rng)
	assert_true(shuffled.free_used and shuffled.cost.is_zero(), "Shuffle is free")
	assert_eq([BF.n(state.score), _stars(state), _held(state)], [1065536, 6, 1], "after Shuffle")
	var top: Vector2i = BF.find(state.cells, 65536)
	var other: Vector2i = Vector2i(0, 0) if top != Vector2i(0, 0) else Vector2i(1, 0)
	var doubled: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [other], rng)
	assert_true(doubled.free_used and doubled.cost.is_zero(), "Double is free")
	assert_eq([BF.n(state.score), _stars(state), _held(state)], [1065536, 6, 0], "after Double")
	top = BF.find(state.cells, 65536)
	other = Vector2i(0, 0) if top != Vector2i(0, 0) else Vector2i(1, 0)
	var hammered: MoveResult = _apply(BoosterRules.HAMMER, state, records, [other], rng)
	assert_false(hammered.free_used, "Hammer is paid")
	assert_eq(BF.n(hammered.cost), 65536, "at 65,536")
	assert_eq([BF.n(state.score), _stars(state), _held(state)], [1000000, 6, 0], "after Hammer")


func test_at_134_a_double_that_earns_a_free_booster_is_itself_paid() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(0, 0): 32})
	var state: RunState = F.state(board, 30000)
	var records: Records = F.records(0, 4096)
	var rng: RunRandom = F.seeded(134)
	var doubled: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [Vector2i(2, 0)], rng)
	assert_false(doubled.free_used, "the Double is paid")
	assert_eq(BF.n(doubled.cost), 8192, "at 8,192")
	assert_eq(BF.n(state.score), 21808, "score 21,808")
	assert_eq(_stars(state), 3, "3 stars")
	assert_eq(_held(state), 1, "1 free booster held")
	var shuffled: MoveResult = _apply(BoosterRules.SHUFFLE, state, records, [], rng)
	assert_true(shuffled.accepted, "Shuffle is accepted")
	assert_eq(BF.n(shuffled.cost), 0, "and charges 0")
	assert_true(shuffled.free_used, "using the free booster")
	assert_eq(BF.n(state.score), 21808, "score 21,808")
	assert_eq(_held(state), 0, "0 held")


func test_at_136_a_free_booster_never_touches_score_or_best_score() -> void:
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 8192})
	var state: RunState = BF.holding(1, board, 1000, 8192)
	var records: Records = F.records(1000, 8192)
	var result: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [Vector2i(2, 0)], F.seeded(136))
	assert_true(result.accepted, "the Double is accepted")
	assert_eq(BF.n(result.cost), 0, "and charges 0")
	assert_true(result.free_used, "using the free booster")
	assert_eq(BF.n(state.score), 1000, "score 1,000")
	assert_eq(BF.n(records.best_score), 1000, "Best Score 1,000")
	assert_false(result.new_best_score, "no new Best Score")
	assert_eq(F.v(result.result_value), 16384, "the tile becomes 16384")
	assert_eq(F.v(records.best_tile), 16384, "Best Tile 16384")
	assert_true(result.new_best_tile, "a new Best Tile")
	assert_eq(F.v(state.run_highest), 16384, "run highest tile 16384")
	assert_eq(_stars(state), 4, "4 stars")
	assert_eq(_held(state), 0, "0 free boosters held")


## FB12, Bart's phone run, on the rules model: Doubles on the highest tile
## from 4K to 128K. The free boosters come at 8K and 64K, and each goes to the
## first booster used after it is earned.
func test_fb12_each_free_booster_goes_to_the_next_booster() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(2, 0): 4096}), 10000000)
	var records: Records = Records.new()
	var rng: RunRandom = F.seeded(12)
	var expected: Array[Array] = [
		# [free used, cost, stars after, held after]
		[false, 8192, 3, 1],
		[true, 0, 4, 0],
		[false, 32768, 5, 0],
		[false, 65536, 6, 1],
		[true, 0, 7, 0],
	]
	for step: int in expected.size():
		var top: int = F.v(state.highest())
		var result: MoveResult = _apply(BoosterRules.DOUBLE, state, records, [BF.find(state.cells, top)], rng)
		var row: Array = expected[step]
		assert_true(result.accepted, "Double %d on %d accepted" % [step + 1, top])
		assert_eq([result.free_used, BF.n(result.cost), _stars(state), _held(state)], row, "Double %d on %d" % [step + 1, top])
	assert_eq(F.v(state.run_highest), 131072, "the run reached 128K")
	assert_eq(CoreRules.free_earned(state.run_highest, config), 2, "2 free boosters earned")
	assert_eq(state.free_used, 2, "both used")
	assert_eq(BF.n(state.score), 10000000 - 8192 - 32768 - 65536, "only the paid Doubles took points")


# A refused call uses nothing (D-46)

func test_a_refused_call_spends_nothing() -> void:
	var cases: Array[Array] = [
		[BoosterRules.HAMMER, []],
		[BoosterRules.HAMMER, [Vector2i(5, 0)]],
		[BoosterRules.HAMMER, [Vector2i(0, 0), Vector2i(1, 0)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(2, 0)]],
		[BoosterRules.SWAP, [Vector2i(0, 0)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(0, 0)]],
		[BoosterRules.DOUBLE, []],
		[BoosterRules.DOUBLE, [Vector2i(-1, 0)]],
		[BoosterRules.SHUFFLE, [Vector2i(0, 0)]],
		[BoosterRules.UNDO, [Vector2i(0, 0)]],
		[&"rocket", []],
	]
	for each: Array in cases:
		var state: RunState = BF.holding(1, F.board_d(), 50000, 8192, F.board_p(), 16)
		_assert_refused_and_kept(state, each[0], each[1], "%s %s" % [each[0], each[1]])
	_assert_refused_and_kept(BF.holding(1, F.board_d(), 5000, 8192), BoosterRules.UNDO, [], "Undo with no snapshot")
	_assert_refused_and_kept(BF.holding(1, F.board_d(), 10, 8192, F.board_p(), 16), BoosterRules.UNDO, [], "Undo below the chain's points (FB4)")
	_assert_refused_and_kept(BF.holding_big(1, F.changed_exponents(F.board_d(), {Vector2i(2, 0): TOP}), BigNum.zero(), TOP), BoosterRules.DOUBLE, [Vector2i(2, 0)], "Double on 2^65535")
	_assert_refused_and_kept(BF.holding(1, F.board_all(4), 0, 8192), BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0)], "Swap on an all equal board")
	_assert_refused_and_kept(BF.holding(1, F.board_all(4), 0, 8192), BoosterRules.SHUFFLE, [], "Shuffle on an all equal board")


func _assert_refused_and_kept(state: RunState, id: StringName, cells: Array, label: String) -> void:
	var before: RunState = state.copy()
	var records: Records = F.records(50000, 8192)
	var rng: RunRandom = F.seeded(9)
	var rng_before: int = rng.get_state()
	var result: MoveResult = _apply(id, state, records, cells, rng)
	assert_false(result.accepted, "%s: refused" % label)
	assert_eq(BF.n(result.cost), 0, "%s: charges nothing" % label)
	assert_false(result.free_used, "%s: uses no free booster" % label)
	assert_true(state.equals(before), "%s: changes nothing, free_used included" % label)
	assert_eq(_held(state), CoreRules.free_held(before, config), "%s: the free booster is still held" % label)
	assert_eq(rng.get_state(), rng_before, "%s: the generator was not used" % label)
	assert_eq([BF.n(records.best_score), F.v(records.best_tile)], [50000, 8192], "%s: the records are untouched" % label)
