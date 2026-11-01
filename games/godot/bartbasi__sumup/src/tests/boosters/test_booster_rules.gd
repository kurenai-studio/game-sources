extends "res://tests/base_test.gd"
## BoosterRules queries: costs (D-20, D-21), usability (13.1, D-28, D-30),
## targets (D-24), the suggested rescue (D-42), the move check outcome (D-19),
## and refusals that change nothing (TH11). Costs are exponents and scores
## BigNum (docs/ARCHITECTURE.md section 17); the ceiling cases are in
## test_booster_fit.gd. Setups hold no free booster unless they
## say so (GDD section 19); free boosters are in test_free_boosters.gd.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const USABLE: BoosterStatus.Usability = BoosterStatus.Usability.USABLE
const CANNOT_AFFORD: BoosterStatus.Usability = BoosterStatus.Usability.CANNOT_AFFORD
const NO_SNAPSHOT: BoosterStatus.Usability = BoosterStatus.Usability.NO_SNAPSHOT

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


func _costs(state: RunState) -> Array[int]:
	var list: Array[int] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BF.price(id, state, config))
	return list


func _usabilities(state: RunState) -> Array[BoosterStatus.Usability]:
	var list: Array[BoosterStatus.Usability] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BoosterRules.usability(id, state, config))
	return list


## Plausible targets for each booster on Board D style boards.
func _targets_for(id: StringName) -> Array[Vector2i]:
	match id:
		BoosterRules.HAMMER, BoosterRules.DOUBLE:
			return BF.targets([Vector2i(4, 7)])
		BoosterRules.SWAP:
			return BF.targets([Vector2i(0, 0), Vector2i(1, 0)])
	return BF.no_targets()


# Constants and ids

func test_booster_ids_in_bar_order() -> void:
	assert_eq(BoosterRules.ALL, [&"hammer", &"swap", &"shuffle", &"double", &"undo"] as Array[StringName], "bar order")
	assert_eq(BoosterRules.HAMMER, &"hammer", "hammer")
	assert_eq(BoosterRules.SWAP, &"swap", "swap")
	assert_eq(BoosterRules.SHUFFLE, &"shuffle", "shuffle")
	assert_eq(BoosterRules.DOUBLE, &"double", "double")
	assert_eq(BoosterRules.UNDO, &"undo", "undo")


func test_target_counts() -> void:
	assert_eq(BoosterRules.target_count(BoosterRules.HAMMER), 1, "Hammer needs one tile")
	assert_eq(BoosterRules.target_count(BoosterRules.SWAP), 2, "Swap needs two tiles")
	assert_eq(BoosterRules.target_count(BoosterRules.SHUFFLE), 0, "Shuffle has no target")
	assert_eq(BoosterRules.target_count(BoosterRules.DOUBLE), 1, "Double needs one tile")
	assert_eq(BoosterRules.target_count(BoosterRules.UNDO), 0, "Undo has no target")
	assert_eq(BoosterRules.target_count(&"rocket"), 0, "an unknown id has none")


# Costs (D-20)

func test_at_56_cost_table() -> void:
	# H, B, then Hammer, Swap, Shuffle, Double, Undo, all as exponents. The
	# last two rows were added on 2026-10-21 (2^56 and the ceiling 2^65535).
	var rows: Array[Array] = [
		[4, 7, [7, 7, 7, 8, 6]],
		[7, 7, [7, 7, 7, 8, 6]],
		[8, 8, [8, 8, 8, 9, 7]],
		[12, 12, [12, 12, 12, 13, 11]],
		[17, 17, [17, 17, 17, 18, 16]],
		[56, 56, [56, 56, 56, 57, 55]],
		[65535, 65535, [65535, 65535, 65535, 65536, 65534]],
	]
	for row: Array in rows:
		var h: int = row[0]
		var board: PackedInt64Array = F.board_d() if h == 4 else F.changed_exponents(F.board_d(), {Vector2i(2, 0): h})
		var state: RunState = F.state(board, 0)
		assert_eq(state.highest(), h, "H = 2^%d" % h)
		assert_eq(BoosterRules.cost_basis(board, config), row[1], "B for H = 2^%d" % h)
		var costs: Array[int] = []
		for id: StringName in BoosterRules.ALL:
			costs.append(BoosterRules.cost(id, state, config))
		var expected: Array[int] = []
		expected.assign(row[2])
		assert_eq(costs, expected, "costs for H = 2^%d" % h)


## AT-56 in plain values for the first five rows.
func test_at_56_cost_table_in_values() -> void:
	var rows: Array[Array] = [
		[16, 128, [128, 128, 128, 256, 64]],
		[128, 128, [128, 128, 128, 256, 64]],
		[256, 256, [256, 256, 256, 512, 128]],
		[4096, 4096, [4096, 4096, 4096, 8192, 2048]],
		[131072, 131072, [131072, 131072, 131072, 262144, 65536]],
	]
	for row: Array in rows:
		var h: int = row[0]
		var board: PackedInt64Array = F.board_d() if h == 16 else F.changed(F.board_d(), {Vector2i(2, 0): h})
		var state: RunState = F.state(board, 0)
		assert_eq(F.v(BoosterRules.cost_basis(board, config)), row[1], "B for H = %d" % h)
		var expected: Array[int] = []
		expected.assign(row[2])
		assert_eq(_costs(state), expected, "costs for H = %d" % h)


func test_cost_basis_of_an_empty_board_is_the_minimum() -> void:
	assert_eq(BoosterRules.cost_basis(PackedInt64Array(), config), 7, "B is never below 128 (2^7)")


## Costs have no upper limit (D-37): every cost is B's exponent plus its
## shift, from H = 2 up to the ceiling, and charge() is exactly 2^cost.
func test_costs_follow_h_up_to_the_ceiling() -> void:
	var shifts: Dictionary[StringName, int] = {&"hammer": 0, &"swap": 0, &"shuffle": 0, &"double": 1, &"undo": -1}
	for h: int in [1, 7, 8, 30, 62, 63, 64, 1000, 65534, 65535]:
		var state: RunState = BF.none_held(F.state(F.changed_exponents(F.board_d(), {Vector2i(2, 0): h}), 0))
		var basis: int = maxi(h, 7)
		for id: StringName in BoosterRules.ALL:
			var cost: int = BoosterRules.cost(id, state, config)
			if cost != basis + shifts[id] or not BoosterRules.charge(id, state, config).equals(BigNum.pow2(cost)):
				fail("%s costs 2^%d at H = 2^%d" % [id, cost, h])
				return


func test_unknown_booster_costs_nothing_and_is_never_usable() -> void:
	var state: RunState = F.state(F.board_p(), 5000)
	assert_eq(BoosterRules.cost(&"rocket", state, config), 0, "an unknown id has cost 0")
	assert_eq(BoosterRules.usability(&"rocket", state, config), CANNOT_AFFORD, "and is never usable")


func test_costs_follow_config_overrides() -> void:
	config.cost_basis_min = 256
	config.cost_shift = {&"hammer": 1, &"swap": 0, &"shuffle": 2, &"double": 3, &"undo": -2}
	var state: RunState = F.state(F.board_d(), 0)
	assert_eq(BoosterRules.cost_basis(state.cells, config), 8, "COST_BASIS_MIN override (256 is 2^8)")
	assert_eq(_costs(state), [512, 256, 1024, 2048, 64] as Array[int], "every cost follows its shift")


func test_at_60_costs_follow_h_at_once() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 7): 1024, Vector2i(1, 7): 1024}), 0)
	assert_eq(BF.price(BoosterRules.HAMMER, state, config), 1024, "Hammer 1,024 before")
	assert_eq(BF.price(BoosterRules.DOUBLE, state, config), 2048, "Double 2,048 before")
	var chain: Array[Vector2i] = BF.targets([Vector2i(0, 7), Vector2i(1, 7)])
	var result: MoveResult = RunRules.commit_chain(state, Records.new(), chain, F.seeded(60), config)
	assert_true(result.accepted, "the commit is accepted")
	assert_eq(_costs(state), [2048, 2048, 2048, 4096, 1024] as Array[int], "Hammer, Swap, Shuffle 2,048, Double 4,096, Undo 1,024 after")


## GDD 13.2 price changes: buying a booster does not change prices, a merge
## that raises H raises them, hammering the only highest tile lowers them.
func test_price_changes_during_a_run() -> void:
	var mid: RunState = F.state(F.changed(F.board_d(), {Vector2i(2, 0): 4096}), 75000)
	var rng: RunRandom = F.seeded(13)
	var shuffled: MoveResult = BoosterRules.apply(BoosterRules.SHUFFLE, mid, Records.new(), BF.no_targets(), rng, config)
	assert_true(shuffled.accepted, "Shuffle accepted")
	assert_eq(BF.n(mid.score), 70904, "score 70,904")
	assert_eq(_costs(mid), [4096, 4096, 4096, 8192, 2048] as Array[int], "prices stay at the 4,096 level")

	var late: RunState = F.state(F.changed(F.board_d(), {Vector2i(2, 0): 4096, Vector2i(4, 7): 1024}), 10000)
	assert_eq(BF.price(BoosterRules.HAMMER, late, config), 4096, "Hammer costs 4,096 before")
	var hammered: MoveResult = BoosterRules.apply(BoosterRules.HAMMER, late, Records.new(), BF.targets([Vector2i(2, 0)]), rng, config)
	assert_eq(BF.n(hammered.cost), 4096, "the 4,096 was charged")
	assert_eq(BF.price(BoosterRules.HAMMER, late, config), 1024, "Hammer costs 1,024 right after")


# Usability (13.1, D-28, D-30)

## Board P since 2026-10-13 (QA Q1): it has a valid move, so the bar can be
## tapped at every score. The costs are the same as on Board D.
func test_at_57_unaffordable_boosters_are_disabled() -> void:
	var state: RunState = F.state(F.board_p(), 127)
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.PLAY, "Board P has a valid move")
	assert_eq(_usabilities(state), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "at 127 all five are disabled")
	state.score = F.big(128)
	assert_eq(_usabilities(state), [USABLE, USABLE, USABLE, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "at 128 Hammer, Swap and Shuffle")
	state.score = F.big(256)
	assert_eq(_usabilities(state), [USABLE, USABLE, USABLE, USABLE, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "at 256 Double too, Undo still has no snapshot")


func test_z1_score_below_the_cost_is_refused() -> void:
	var state: RunState = F.state(F.board_d(), 100)
	var before: RunState = state.copy()
	assert_eq(BoosterRules.usability(BoosterRules.HAMMER, state, config), CANNOT_AFFORD, "Hammer disabled")
	var result: MoveResult = BoosterRules.apply(BoosterRules.HAMMER, state, Records.new(), BF.targets([Vector2i(0, 0)]), F.seeded(1), config)
	assert_false(result.accepted, "a forced call is refused")
	assert_eq(result.refusal, &"cannot_afford", "refusal")
	assert_true(state.equals(before), "score stays 100, board unchanged")


func test_z2_score_exactly_the_cost() -> void:
	var state: RunState = F.state(F.board_d(), 128)
	assert_eq(BoosterRules.usability(BoosterRules.HAMMER, state, config), USABLE, "Hammer usable at exactly its cost")
	var result: MoveResult = BoosterRules.apply(BoosterRules.HAMMER, state, Records.new(), BF.targets([Vector2i(3, 3)]), F.seeded(2), config)
	assert_true(result.accepted, "accepted")
	assert_eq(BF.n(state.score), 0, "score 0")
	for id: StringName in BoosterRules.ALL:
		assert_ne(BoosterRules.usability(id, state, config), USABLE, "%s disabled at 0" % id)


func test_at_58_spending_down_to_exactly_zero() -> void:
	var state: RunState = F.state(F.board_d(), 128)
	var result: MoveResult = BoosterRules.apply(BoosterRules.HAMMER, state, Records.new(), BF.targets([Vector2i(0, 0)]), F.seeded(58), config)
	assert_true(result.accepted, "Hammer accepted")
	assert_eq(BF.n(result.cost), 128, "cost 128")
	assert_eq(BF.n(state.score), 0, "score 0")
	assert_eq(_usabilities(state), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "all five disabled")


func test_zero_score_disables_everything_and_refuses_everything() -> void:
	var state: RunState = BF.make(F.board_p(), 0, F.board_d(), 4)
	var before: RunState = state.copy()
	for id: StringName in BoosterRules.ALL:
		assert_ne(BoosterRules.usability(id, state, config), USABLE, "%s disabled at score 0" % id)
		var result: MoveResult = BoosterRules.apply(id, state, Records.new(), _targets_for(id), F.seeded(3), config)
		assert_eq(result.refusal, &"cannot_afford", "%s refused as unaffordable" % id)
	assert_true(state.equals(before), "nothing changed")


func test_every_booster_is_usable_at_exactly_its_cost() -> void:
	for id: StringName in BoosterRules.ALL:
		var state: RunState = F.state(BF.board_d1024(), 0)
		var price: int = BF.price(id, state, config)
		if id == BoosterRules.UNDO:
			state = BF.make(BF.board_d1024(), price + 40, BF.snapshot_board(), 40)
		else:
			state.score = F.big(price)
		assert_eq(BoosterRules.usability(id, state, config), USABLE, "%s usable at exactly its cost" % id)
		var below: RunState = state.copy()
		below.score = below.score.sub(F.big(1))
		assert_eq(BoosterRules.usability(id, below, config), CANNOT_AFFORD, "%s not usable one point below" % id)
		var result: MoveResult = BoosterRules.apply(id, state, Records.new(), _targets_for(id), F.seeded(4), config)
		assert_true(result.accepted, "%s accepted at exactly its cost" % id)
		assert_eq(BF.n(state.score), 0, "%s leaves exactly 0" % id)


func test_undo_usability_needs_a_snapshot_and_the_score_without_its_points() -> void:
	var state: RunState = F.state(F.board_p(), 5000)
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, state, config), NO_SNAPSHOT, "no snapshot")
	state = BF.make(F.board_p(), 126, F.board_d(), 96)
	assert_eq(BF.price(BoosterRules.UNDO, state, config), 64, "cost 64")
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, state, config), CANNOT_AFFORD, "126 minus 96 is 30, below 64")
	state.score = F.big(160)
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, state, config), USABLE, "160 minus 96 is exactly 64")
	state.score = F.big(159)
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, state, config), CANNOT_AFFORD, "159 minus 96 is 63")


func test_at_59_the_rules_model_refuses_what_is_not_usable() -> void:
	var state: RunState = F.state(F.board_d(), 100)
	var records: Records = F.records(500, 16)
	var rng: RunRandom = F.seeded(59)
	var before: RunState = state.copy()
	var rng_before: int = rng.get_state()
	var expected: Dictionary[StringName, StringName] = {
		&"hammer": &"cannot_afford", &"swap": &"cannot_afford", &"shuffle": &"cannot_afford",
		&"double": &"cannot_afford", &"undo": &"no_snapshot",
	}
	for id: StringName in BoosterRules.ALL:
		var result: MoveResult = BoosterRules.apply(id, state, records, _targets_for(id), rng, config)
		assert_false(result.accepted, "%s refused" % id)
		assert_eq(result.refusal, expected[id], "%s refusal" % id)
		assert_eq(result.booster_id, id, "%s result names the booster" % id)
		assert_eq(BF.n(result.cost), 0, "%s charged nothing" % id)
		assert_eq(result.cells_after, result.cells_before, "%s result shows no change" % id)
	assert_true(state.equals(before), "board, score and snapshot unchanged")
	assert_eq(rng.get_state(), rng_before, "the random generator was not used")
	assert_eq(rng.shuffle_attempts, 0, "no Shuffle attempt was counted")
	assert_eq(BF.n(records.best_score), 500, "Best Score unchanged")
	assert_eq(F.v(records.best_tile), 16, "Best Tile unchanged")


# Bad targets

func test_bad_targets_are_refused_and_change_nothing() -> void:
	var cases: Array[Array] = [
		[BoosterRules.HAMMER, []],
		[BoosterRules.HAMMER, [Vector2i(0, 0), Vector2i(1, 0)]],
		[BoosterRules.HAMMER, [Vector2i(5, 0)]],
		[BoosterRules.HAMMER, [Vector2i(0, 8)]],
		[BoosterRules.HAMMER, [Vector2i(-1, 3)]],
		[BoosterRules.DOUBLE, []],
		[BoosterRules.DOUBLE, [Vector2i(2, -1)]],
		[BoosterRules.SWAP, [Vector2i(0, 0)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(0, 0)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(2, 0)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(5, 7)]],
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]],
		[BoosterRules.SHUFFLE, [Vector2i(0, 0)]],
		[BoosterRules.UNDO, [Vector2i(0, 0)]],
		[&"rocket", []],
		[&"", []],
	]
	for each: Array in cases:
		var id: StringName = each[0]
		var state: RunState = BF.make(F.board_d(), 50000, F.board_p(), 16)
		var before: RunState = state.copy()
		var records: Records = F.records(50000, 16)
		var rng: RunRandom = F.seeded(9)
		var rng_before: int = rng.get_state()
		var result: MoveResult = BoosterRules.apply(id, state, records, BF.targets(each[1]), rng, config)
		var label: String = "%s %s" % [id, each[1]]
		assert_false(result.accepted, "%s refused" % label)
		assert_eq(result.refusal, &"bad_target", "%s refusal" % label)
		assert_true(state.equals(before), "%s changed nothing" % label)
		assert_eq(rng.get_state(), rng_before, "%s left the generator alone" % label)
		assert_eq(BF.n(records.best_score), 50000, "%s left the records alone" % label)


func test_a_board_that_does_not_match_the_config_is_refused() -> void:
	var state: RunState = F.state(PackedInt64Array([1, 2, 3]), 5000)
	var result: MoveResult = BoosterRules.apply(BoosterRules.SHUFFLE, state, Records.new(), BF.no_targets(), F.seeded(1), config)
	assert_eq(result.refusal, &"bad_target", "refused")
	assert_eq(state.cells, PackedInt64Array([1, 2, 3]), "unchanged")


func test_swap_of_two_equal_tiles_is_refused() -> void:
	var state: RunState = F.state(F.changed(F.board_d(), {Vector2i(0, 0): 32, Vector2i(4, 7): 32}), 5000)
	var before: RunState = state.copy()
	assert_false(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(4, 7)), "a 32 cannot pick another 32")
	var result: MoveResult = BoosterRules.apply(BoosterRules.SWAP, state, Records.new(), BF.targets([Vector2i(0, 0), Vector2i(4, 7)]), F.seeded(1), config)
	assert_eq(result.refusal, &"bad_target", "refused: equal values would change nothing but still cost points")
	assert_true(state.equals(before), "nothing charged, nothing moved")


func test_can_pick_second() -> void:
	var state: RunState = F.state(F.board_p(), 0)
	assert_true(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(1, 0)), "2 then 4, touching")
	assert_true(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(2, 7)), "2 then 32, far apart (D-24: anywhere)")
	assert_false(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(2, 0)), "2 then 2: equal values")
	assert_false(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(0, 0)), "the same cell")
	assert_false(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(5, 0)), "off the board right")
	assert_false(BoosterRules.can_pick_second(state, Vector2i(0, 0), Vector2i(0, 8)), "off the board below")
	assert_false(BoosterRules.can_pick_second(state, Vector2i(-1, 0), Vector2i(0, 0)), "first cell off the board")


# The suggested rescue (D-42) and the move check outcome (D-19)

func test_sr1_to_sr4_suggested_rescue() -> void:
	var sr1: RunState = BF.make(BF.board_d1024(), 5000, BF.snapshot_board(), 40)
	assert_eq(_usabilities(sr1), [USABLE, USABLE, USABLE, USABLE, USABLE] as Array[BoosterStatus.Usability], "SR1: all five usable (GO1)")
	assert_eq(BoosterRules.suggested_rescue(sr1, config), BoosterRules.SHUFFLE, "SR1: Shuffle")
	var sr2: RunState = BF.make(BF.board_d1024(), 600, BF.snapshot_board(), 40)
	assert_eq(_usabilities(sr2), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, USABLE] as Array[BoosterStatus.Usability], "SR2: Undo only (GO2)")
	assert_eq(BoosterRules.suggested_rescue(sr2, config), BoosterRules.UNDO, "SR2: Undo")
	var sr3: RunState = F.state(BF.board_d1024(), 1500)
	assert_eq(_usabilities(sr3), [USABLE, USABLE, USABLE, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "SR3: Hammer, Swap, Shuffle (GO4)")
	assert_eq(BoosterRules.suggested_rescue(sr3, config), BoosterRules.SHUFFLE, "SR3: Shuffle")
	var sr4: RunState = BF.make(BF.board_d1024(), 300, BF.snapshot_board(), 40)
	assert_eq(_usabilities(sr4), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD] as Array[BoosterStatus.Usability], "SR4: none (GO3)")
	assert_eq(BoosterRules.suggested_rescue(sr4, config), &"", "SR4: nothing marked")
	assert_eq(BoosterRules.outcome(sr4, config), BoosterRules.Outcome.END, "SR4: no offer, the run ends")


func test_at_109_the_suggested_rescue() -> void:
	var a: RunState = BF.make(BF.board_d1024(), 5000, BF.snapshot_board(), 40)
	assert_eq(BoosterRules.suggested_rescue(a, config), BoosterRules.SHUFFLE, "(a) Shuffle")
	var b: RunState = BF.make(BF.board_d1024(), 600, BF.snapshot_board(), 40)
	assert_eq(BoosterRules.suggested_rescue(b, config), BoosterRules.UNDO, "(b) Undo")
	var c: RunState = F.state(BF.board_d1024(), 1500)
	assert_eq(BoosterRules.suggested_rescue(c, config), BoosterRules.SHUFFLE, "(c) Shuffle")
	config.cost_shift = {&"hammer": 0, &"swap": 0, &"shuffle": 2, &"double": 1, &"undo": 2}
	var d: RunState = BF.make(BF.board_d1024(), 1500, BF.snapshot_board(), 40)
	assert_eq(_usabilities(d), [USABLE, USABLE, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD] as Array[BoosterStatus.Usability], "(d) Hammer and Swap usable, the rest not")
	assert_eq(BoosterRules.suggested_rescue(d, config), &"", "(d) nothing marked")
	assert_eq(BoosterRules.outcome(d, config), BoosterRules.Outcome.OFFER, "(d) the offer still opens")


func test_outcome_play_offer_end() -> void:
	assert_eq(BoosterRules.outcome(F.state(F.board_p(), 0), config), BoosterRules.Outcome.PLAY, "a valid move means play, whatever the score")
	assert_eq(BoosterRules.outcome(F.state(F.board_d(), 128), config), BoosterRules.Outcome.OFFER, "no move, something usable: offer")
	assert_eq(BoosterRules.outcome(F.state(F.board_d(), 127), config), BoosterRules.Outcome.END, "no move, nothing usable: end")
	var undo_only: RunState = BF.make(F.board_d(), 104, F.board_p(), 40)
	assert_eq(BoosterRules.outcome(undo_only, config), BoosterRules.Outcome.OFFER, "Undo alone keeps the run going (104 minus 40 is 64)")


func test_z3_zero_score_and_no_moves_ends_the_run() -> void:
	var state: RunState = F.state(F.board_d(), 0)
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.END, "nothing usable, the run ends at once")
	assert_eq(BoosterRules.suggested_rescue(state, config), &"", "no rescue")


func test_go1_to_go3_and_go6_outcomes() -> void:
	var go1: RunState = BF.make(BF.board_d1024(), 5000, BF.snapshot_board(), 40)
	assert_eq(BoosterRules.outcome(go1, config), BoosterRules.Outcome.OFFER, "GO1 offer")
	var go2: RunState = BF.make(BF.board_d1024(), 600, BF.snapshot_board(), 40)
	assert_eq(BoosterRules.outcome(go2, config), BoosterRules.Outcome.OFFER, "GO2 offer: 600 minus 40 is 560, at least 512")
	var go3: RunState = BF.make(BF.board_d1024(), 300, BF.snapshot_board(), 40)
	assert_eq(BoosterRules.outcome(go3, config), BoosterRules.Outcome.END, "GO3 ends: 300 minus 40 is 260, below 512")
	var go6: RunState = F.state(BF.board_d1024(), 476)
	assert_eq(BoosterRules.outcome(go6, config), BoosterRules.Outcome.END, "GO6 ends: every cost is at least 512")
