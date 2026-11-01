extends "res://tests/base_test.gd"
## The ceiling for boosters (D-37, GDD 12.1, 13.1, 13.2, 13.5, 13.6, section
## 17 of docs/ARCHITECTURE.md): a booster is usable only when it can act on
## the board (NO_TARGET), a 2^65535 tile is never a Double target, the Shuffle
## fallback only pairs values that fit with the score after the charge, the
## session's highlight, move check and commit agree with the run's score, and
## the booster halves of AT-143, AT-144 and AT-167. Bart's position of
## 2026-10-21 plays a chain. The joining and move check halves are core tests.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")
const USABLE: BoosterStatus.Usability = BoosterStatus.Usability.USABLE
const CANNOT_AFFORD: BoosterStatus.Usability = BoosterStatus.Usability.CANNOT_AFFORD
const NO_SNAPSHOT: BoosterStatus.Usability = BoosterStatus.Usability.NO_SNAPSHOT
const NO_TARGET: BoosterStatus.Usability = BoosterStatus.Usability.NO_TARGET
const TOP: int = 65535            # MAX_EXPONENT
const SCORE_BITS: int = 65600     # MAX_SCORE_BITS
const BART_SCORE: String = "9221253119629040934"
const INT64_MAX: String = "9223372036854775807"

var config: GameConfig
var recorder: BF.Recorder


func before_each() -> void:
	config = GameConfig.new()
	recorder = BF.Recorder.new()


func _usabilities(state: RunState) -> Array[BoosterStatus.Usability]:
	var list: Array[BoosterStatus.Usability] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BoosterRules.usability(id, state, config))
	return list


func _reasons(session: GameSession) -> Array[BoosterStatus.Usability]:
	var list: Array[BoosterStatus.Usability] = []
	for status: BoosterStatus in session.booster_statuses():
		list.append(status.reason)
	return list


func _costs(state: RunState) -> Array[int]:
	var list: Array[int] = []
	for id: StringName in BoosterRules.ALL:
		list.append(BoosterRules.cost(id, state, config))
	return list


## The largest score allowed: 2^65600 minus 1.
func _top_score() -> BigNum:
	return BF.below_pow2(SCORE_BITS, 1)


func _big(text: String) -> BigNum:
	return BigNum.parse(text, 40)


## Board D with (0,7) and (1,7) at the given exponent.
func _pair_board(exponent: int) -> PackedInt64Array:
	return F.changed_exponents(F.board_d(), {Vector2i(0, 7): exponent, Vector2i(1, 7): exponent})


## Every exponent different except two twins_exponent tiles on (0,0) and
## (2,0), which do not touch. With small_twins, also two 2s on (0,2) and
## (2,2), which do not touch either. No valid move at any score.
func _twins_board(twins_exponent: int, small_twins: bool) -> PackedInt64Array:
	var board: PackedInt64Array = PackedInt64Array()
	var next: int = 2 if small_twins else 1
	for index: int in 40:
		if index == 0 or index == 2:
			board.append(twins_exponent)
		elif small_twins and (index == 10 or index == 12):
			board.append(1)
		else:
			board.append(next)
			next += 1
	return board


## Bart's run on 2026-10-21 (GDD 12.1 V11, AT-159, AT-160).
func _bart_state() -> RunState:
	return BF.none_held(RunState.create(F.bart_board(), _big(BART_SCORE), PackedInt64Array(), null, 56))


## Every cell touching the chain's last cell, on the board and not in it.
func _neighbors(chain: Array[Vector2i]) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var last: Vector2i = chain[chain.size() - 1]
	for row: int in range(last.y - 1, last.y + 2):
		for column: int in range(last.x - 1, last.x + 2):
			var cell: Vector2i = Vector2i(column, row)
			if cell != last and CoreRules.in_bounds(cell, config) and not chain.has(cell):
				cells.append(cell)
	return cells


## True when RunRules.commit_chain accepts the chain on a copy of the session's run.
func _commit_accepts(session: GameSession, chain: Array[Vector2i]) -> bool:
	var copy: RunState = session.state.copy()
	return RunRules.commit_chain(copy, session.records.copy(), chain, F.seeded(1), config).accepted


## For a chain: every neighbor the session highlights, added, commits; every
## other neighbor, added, is refused (D-37, D-40). Returns "" or the problem.
func _highlight_matches_commit(session: GameSession, chain: Array[Vector2i]) -> String:
	var joinable: Array[Vector2i] = session.joinable_cells(chain)
	for cell: Vector2i in _neighbors(chain):
		var longer: Array[Vector2i] = chain.duplicate()
		longer.append(cell)
		if _commit_accepts(session, longer) != joinable.has(cell):
			return "chain %s then %s: joinable %s, commit %s" % [chain, cell, joinable.has(cell), _commit_accepts(session, longer)]
	return ""


# Usability: something to act on (13.1)

func test_usability_needs_something_to_act_on() -> void:
	var a4: RunState = F.state(F.board_all(4), 5000)
	assert_eq(_usabilities(a4), [USABLE, NO_TARGET, NO_TARGET, USABLE, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "Board A4: Swap and Shuffle have nothing to act on")
	var paid: RunState = BF.none_held(RunState.create(F.board_all_exponent(TOP), _top_score()))
	assert_eq(_usabilities(paid), [USABLE, NO_TARGET, NO_TARGET, NO_TARGET, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "all 2^65535 at the largest score: Hammer only, Double has no tile")
	var free: RunState = BF.holding_big(1, F.board_all_exponent(TOP), BigNum.zero(), TOP)
	assert_eq(_usabilities(free), [USABLE, NO_TARGET, NO_TARGET, NO_TARGET, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "all 2^65535 with a free booster: Hammer only")
	var one_below: RunState = BF.holding_big(1, F.changed_exponents(F.board_all_exponent(TOP), {Vector2i(4, 7): TOP - 1}), BigNum.zero(), TOP)
	assert_eq(_usabilities(one_below), [USABLE, USABLE, USABLE, USABLE, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "one 2^65534 tile is enough for Swap, Shuffle and Double")
	var undo: RunState = BF.holding_big(1, F.board_all_exponent(TOP), F.big(4), TOP, F.board_p(), F.big(4))
	assert_eq(BoosterRules.usability(BoosterRules.UNDO, undo, config), USABLE, "Undo can always act")


func test_affordability_is_checked_before_the_target() -> void:
	var state: RunState = BF.none_held(RunState.create(F.board_all_exponent(TOP), BigNum.zero()))
	assert_eq(_usabilities(state), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "a booster that is unaffordable and has no target reads CANNOT_AFFORD")


## D-37, 13.2: costs have no upper limit, and a cost is affordable exactly
## when the score covers it: 2^cost at most the score.
func test_a_cost_is_affordable_exactly_when_the_score_covers_it() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(2, 0): TOP})
	var state: RunState = BF.none_held(RunState.create(board, BigNum.pow2(TOP + 1)))
	assert_eq(_costs(state), [TOP, TOP, TOP, TOP + 1, TOP - 1] as Array[int], "costs 2^65535 and Double 2^65536")
	assert_eq(_usabilities(state), [USABLE, USABLE, USABLE, USABLE, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "a score of exactly 2^65536 covers Double")
	state.score = BigNum.pow2(TOP + 1).sub(F.big(1))
	assert_eq(_usabilities(state), [USABLE, USABLE, USABLE, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "one point less does not")
	state.score = BigNum.pow2(TOP + 1)
	var result: MoveResult = BoosterRules.apply(BoosterRules.DOUBLE, state, Records.new(), BF.targets([Vector2i(0, 0)]), F.seeded(1), config)
	assert_true(result.accepted, "Double accepted at exactly its cost")
	assert_true(result.cost.equals(BigNum.pow2(TOP + 1)), "charged 2^65536 exactly")
	assert_true(state.score.is_zero(), "score exactly 0")


func test_no_target_is_refused_as_a_bad_target_and_spends_nothing() -> void:
	var cases: Array[Array] = [
		[F.state(F.board_all(4), 5000), BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0)]],
		[F.state(F.board_all(4), 5000), BoosterRules.SHUFFLE, []],
		[BF.holding_big(1, F.board_all_exponent(TOP), BigNum.zero(), TOP), BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0)]],
		[BF.holding_big(1, F.board_all_exponent(TOP), BigNum.zero(), TOP), BoosterRules.SHUFFLE, []],
		[BF.holding_big(1, F.board_all_exponent(TOP), BigNum.zero(), TOP), BoosterRules.DOUBLE, [Vector2i(0, 0)]],
	]
	for each: Array in cases:
		var state: RunState = each[0]
		var id: StringName = each[1]
		var before: RunState = state.copy()
		var rng: RunRandom = F.seeded(1)
		var rng_before: int = rng.get_state()
		var result: MoveResult = BoosterRules.apply(id, state, Records.new(), BF.targets(each[2]), rng, config)
		var label: String = "%s on all 2^%d" % [id, state.cells[0]]
		assert_eq(result.refusal, &"bad_target", "%s: refused as a bad target" % label)
		assert_true(state.equals(before), "%s: nothing changed, no free booster used" % label)
		assert_eq(rng.get_state(), rng_before, "%s: no draw" % label)
		assert_eq(rng.shuffle_attempts, 0, "%s: no Shuffle attempt" % label)


# Double (13.6)

func test_a_double_on_the_ceiling_while_free_is_a_bad_target_that_keeps_the_free_booster() -> void:
	var state: RunState = BF.holding_big(1, _pair_board(TOP), BigNum.zero(), TOP)
	var before: RunState = state.copy()
	var result: MoveResult = BoosterRules.apply(BoosterRules.DOUBLE, state, Records.new(), BF.targets([Vector2i(0, 7)]), F.seeded(1), config)
	assert_eq(result.refusal, &"bad_target", "refused as a bad target")
	assert_false(result.free_used, "no free booster used")
	assert_true(state.equals(before), "nothing changed")
	assert_eq(CoreRules.free_held(state, config), 1, "1 free booster still held")


## The boosters part of AT-95 (d): no booster ever makes a tile above
## 2^65535, the exponent a save refuses. Double turns 2^65534 into exactly
## 2^65535, and refuses 2^65535.
func test_at_95_d_no_booster_makes_a_tile_above_the_ceiling() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(2, 0): TOP, Vector2i(4, 7): TOP - 1})
	var state: RunState = BF.none_held(RunState.create(board, BigNum.pow2(TOP + 2)))
	var refused: MoveResult = BoosterRules.apply(BoosterRules.DOUBLE, state, Records.new(), BF.targets([Vector2i(2, 0)]), F.seeded(1), config)
	assert_eq(refused.refusal, &"bad_target", "2^65535 cannot double")
	var result: MoveResult = BoosterRules.apply(BoosterRules.DOUBLE, state, Records.new(), BF.targets([Vector2i(4, 7)]), F.seeded(1), config)
	assert_true(result.accepted, "2^65534 doubles")
	assert_eq(result.result_value, TOP, "into exactly 2^65535")
	assert_eq(state.highest(), TOP, "no tile is above the ceiling")


func test_tiles_past_2_62_are_ordinary_double_targets() -> void:
	var board: PackedInt64Array = F.changed_exponents(F.board_d(), {Vector2i(2, 0): 62})
	var state: RunState = BF.none_held(RunState.create(board, BigNum.pow2(64)))
	var result: MoveResult = BoosterRules.apply(BoosterRules.DOUBLE, state, Records.new(), BF.targets([Vector2i(2, 0)]), F.seeded(1), config)
	assert_true(result.accepted, "a 2^62 tile doubles (13.6, since 2026-10-21)")
	assert_eq(result.result_value, 63, "into 2^63")
	assert_eq(state.highest(), 63, "which is now H; the small tiles cleared under it (D-38)")
	assert_true(state.score.equals(BigNum.pow2(64).sub(BigNum.pow2(63))), "charged 2B = 2^63 exactly")


# The Shuffle fallback (13.5)

func test_shuffle_fallback_skips_twins_whose_pair_does_not_fit() -> void:
	var board: PackedInt64Array = _twins_board(TOP, true)
	assert_false(CoreRules.has_valid_move(board, BigNum.zero(), config), "the setup has no move")
	var state: RunState = BF.none_held(RunState.create(board, BigNum.pow2(TOP)))
	var rng: RunRandom = F.seeded(1)
	rng.force_shuffle(board)
	var result: MoveResult = BoosterRules.apply(BoosterRules.SHUFFLE, state, Records.new(), BF.no_targets(), rng, config)
	assert_true(result.accepted, "accepted")
	assert_eq(rng.shuffle_attempts, 100, "every arrangement was tried")
	var expected: PackedInt64Array = F.changed_exponents(board, {Vector2i(1, 2): 1, Vector2i(2, 2): board[CoreRules.index_of(Vector2i(1, 2), F.COLUMNS)]})
	assert_eq(state.cells, expected, "P is the first 2 on (0,2), not the 2^65535 on (0,0): its twin moves to (1,2)")
	assert_true(result.has_valid_move, "so the board has a valid move")
	assert_true(state.score.is_zero(), "charged B = 2^65535")


func test_shuffle_fallback_with_only_twins_that_do_not_fit_changes_nothing() -> void:
	var board: PackedInt64Array = _twins_board(TOP, false)
	assert_false(CoreRules.has_valid_move(board, BigNum.zero(), config), "the setup has no move")
	var state: RunState = BF.none_held(RunState.create(board, BigNum.pow2(TOP)))
	var rng: RunRandom = F.seeded(1)
	rng.force_shuffle(board)
	var result: MoveResult = BoosterRules.apply(BoosterRules.SHUFFLE, state, Records.new(), BF.no_targets(), rng, config)
	assert_true(result.accepted, "Shuffle still runs and is charged")
	assert_eq(state.cells, board, "no value below the ceiling repeats, so the fallback leaves the last arrangement")
	assert_false(result.has_valid_move, "no valid move")
	assert_true(state.score.is_zero(), "charged B = 2^65535")


## 13.5: the fallback measures with the score after the Shuffle is paid. The
## two 2s pay 4 points: before the charge the score is 4 below the score
## ceiling, so they would not fit; after it they do.
func test_shuffle_fallback_measures_with_the_score_after_the_charge() -> void:
	var board: PackedInt64Array = PackedInt64Array()
	for exponent: int in range(2, 40):
		board.append(exponent)
	board.insert(0, 1)
	board.insert(2, 1)
	assert_eq(board.size(), 40, "40 cells")
	var state: RunState = BF.none_held(RunState.create(board, BF.below_pow2(SCORE_BITS, 4)))
	assert_false(CoreRules.pair_fits(1, state.score, config), "before the charge the pair of 2s would not fit")
	var rng: RunRandom = F.seeded(1)
	rng.force_shuffle(board)
	var result: MoveResult = BoosterRules.apply(BoosterRules.SHUFFLE, state, Records.new(), BF.no_targets(), rng, config)
	assert_true(result.accepted, "accepted")
	assert_true(state.score.equals(BF.below_pow2(SCORE_BITS, 4).sub(BigNum.pow2(39))), "charged B = 2^39")
	assert_eq(F.equal_pairs(state.cells), [Vector2i(0, 0), Vector2i(1, 0)] as Array[Vector2i], "the fallback put the two 2s side by side")
	assert_true(result.has_valid_move, "and that pair fits with the score after the charge")


## D-37: a score so large that every pair is blocked. No move, so the offer
## opens, and every booster that can act is affordable. The run is never
## stuck: Shuffle lowers the score and the small pairs fit again.
func test_a_score_that_blocks_every_pair_opens_the_offer_with_boosters_affordable() -> void:
	for seed_value: int in range(1, 11):
		var rng: RunRandom = F.seeded(seed_value)
		var fresh: RunState = RunRules.new_run(rng, Records.new(), config)
		var state: RunState = RunState.create(fresh.cells, _top_score(), BF.snapshot_board(), F.big(40))
		var problem: String = ""
		if CoreRules.has_valid_move(state.cells, state.score, config):
			problem = "a pair fits at 2^65600 minus 1"
		elif BoosterRules.outcome(state, config) != BoosterRules.Outcome.OFFER:
			problem = "the offer does not open"
		elif _usabilities(state) != ([USABLE, USABLE, USABLE, USABLE, USABLE] as Array[BoosterStatus.Usability]):
			problem = "usable %s" % [_usabilities(state)]
		elif BoosterRules.suggested_rescue(state, config) != BoosterRules.SHUFFLE:
			problem = "Shuffle is not marked"
		if problem.is_empty():
			var result: MoveResult = BoosterRules.apply(BoosterRules.SHUFFLE, state, Records.new(), BF.no_targets(), rng, config)
			if not result.accepted or not result.has_valid_move:
				problem = "Shuffle did not rescue"
			elif BoosterRules.outcome(state, config) != BoosterRules.Outcome.PLAY:
				problem = "play does not go on"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


# AT-143 and AT-144, the booster halves

func test_at_143_a_nothing_usable_ends_the_run_at_once() -> void:
	var state: RunState = BF.none_held(RunState.create(_pair_board(TOP), BigNum.zero()))
	assert_eq([CoreRules.stars(state.run_highest, config), CoreRules.free_earned(state.run_highest, config)], [65525, 21841], "65,525 stars, 21,841 free boosters earned")
	assert_eq(CoreRules.free_held(state, config), 0, "all 21,841 used")
	assert_eq(_costs(state), [TOP, TOP, TOP, TOP + 1, TOP - 1] as Array[int], "Hammer, Swap and Shuffle cost 2^65535, Double 2^65536")
	assert_eq(_usabilities(state), [CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, CANNOT_AFFORD, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "nothing is usable")
	assert_eq(BoosterRules.outcome(state, config), BoosterRules.Outcome.END, "the move check ends the run")
	var session: GameSession = GameSession.new()
	recorder.watch(session)
	session.resume(state)
	var chain: Array[Vector2i] = [Vector2i(0, 7)]
	assert_true(session.joinable_cells(chain).is_empty(), "(1,7) is not joinable")
	assert_eq(session.preview_value([Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i]), 0, "no preview for the pair")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.ENDED, "the run ends at once; it does not stay in play")
	assert_eq(recorder.count("offer_changed"), 0, "no offer")
	assert_true(recorder.summaries[0].final_score.is_zero(), "final score 0")
	assert_true(recorder.summaries[0].no_moves_left, "no moves left")
	assert_eq(recorder.summaries[0].stars, 65525, "the summary carries the 65,525 stars")
	assert_eq(recorder.summaries[0].run_highest, TOP, "and the run highest tile 2^65535")


func test_at_143_b_a_free_booster_rescues() -> void:
	var session: GameSession = BF.ready_session(BF.holding_big(1, _pair_board(TOP), BigNum.zero(), TOP))
	recorder.watch(session)
	assert_eq(session.phase(), GameSession.Phase.OFFER, "the offer opens")
	assert_eq(BF.usable_ids(session), [&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName], "Hammer, Swap, Shuffle and Double are usable")
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "and free")
	assert_eq(BF.status_of(session, BoosterRules.UNDO).reason, NO_SNAPSHOT, "Undo is not")
	assert_eq(BF.suggested_id(session), BoosterRules.SHUFFLE, "Shuffle is marked")
	session.press_booster(BoosterRules.DOUBLE)
	var before: RunState = session.state.copy()
	recorder.clear()
	assert_true(null == session.tap_cell(Vector2i(0, 7)), "Double on (0,7) is refused as a bad target")
	assert_true(session.state.equals(before), "nothing changes")
	assert_eq(session.free_held(), 1, "1 free booster still held")
	assert_eq(session.targeting_booster(), BoosterRules.DOUBLE, "Double stays active")
	assert_eq(recorder.names, PackedStringArray(), "no signal")
	var result: MoveResult = session.tap_cell(Vector2i(2, 7))
	assert_true(result != null and result.accepted, "Double on (2,7) is accepted")
	assert_true(result.cost.is_zero(), "and charges 0")
	assert_true(result.free_used, "using the free booster")
	assert_eq(F.v(session.state.value_at(Vector2i(2, 7))), 16, "(2,7) = 16, touching (3,7) = 16")
	assert_true(result.has_valid_move, "so the board has a valid move")
	assert_eq(session.free_held(), 0, "0 held")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "play goes on")
	assert_false(session.is_offer_open(), "the offer closed")


func test_at_143_c_a_pair_that_makes_the_ceiling_commits() -> void:
	var state: RunState = BF.none_held(RunState.create(_pair_board(TOP - 1), BigNum.zero()))
	var session: GameSession = BF.ready_session(state)
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "a valid move")
	var start: Array[Vector2i] = [Vector2i(0, 7)]
	assert_eq(session.joinable_cells(start), [Vector2i(1, 7)] as Array[Vector2i], "(1,7) is joinable")
	var chain: Array[Vector2i] = [Vector2i(0, 7), Vector2i(1, 7)]
	assert_eq(session.preview_value(chain), TOP, "the preview is 2^65535")
	var result: MoveResult = session.commit_chain(chain)
	assert_true(result.accepted, "the commit is accepted")
	assert_eq(result.result_value, TOP, "(1,7) = 2^65535")
	assert_true(session.state.score.equals(BigNum.pow2(TOP)), "score exactly 2^65535")
	assert_eq(result.stars_earned, 1, "1 star earned")


func test_at_144_a_an_all_ceiling_board_with_a_free_booster_cannot_loop() -> void:
	var session: GameSession = BF.ready_session(BF.holding_big(1, F.board_all_exponent(TOP), BigNum.zero(), TOP))
	recorder.watch(session)
	session.rng.script_spawns(PackedInt64Array([TOP - 9]))
	assert_eq(session.phase(), GameSession.Phase.OFFER, "no valid move: the offer opens")
	assert_true(session.is_offer_open(), "End run is offered")
	assert_eq(BF.usable_ids(session), [BoosterRules.HAMMER] as Array[StringName], "only Hammer is usable")
	assert_eq(BF.free_ids(session), BoosterRules.ALL, "and free")
	assert_eq(_reasons(session), [USABLE, NO_TARGET, NO_TARGET, NO_TARGET, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "Swap and Shuffle: every tile equal; Double: no tile below 2^65535; Undo: no snapshot")
	assert_eq(BF.suggested_id(session), &"", "nothing is marked")
	var before: RunState = session.state.copy()
	var rng_before: int = session.rng.get_state()
	var calls: Array[Array] = [
		[BoosterRules.SWAP, [Vector2i(0, 0), Vector2i(1, 0)]],
		[BoosterRules.SHUFFLE, []],
		[BoosterRules.DOUBLE, [Vector2i(0, 0)]],
	]
	for each: Array in calls:
		var refused: MoveResult = BoosterRules.apply(each[0], session.state, session.records, BF.targets(each[1]), session.rng, session.config)
		assert_eq(refused.refusal, &"bad_target", "%s is refused as a bad target" % each[0])
	assert_true(session.state.equals(before), "the calls change nothing")
	assert_eq(session.rng.get_state(), rng_before, "and draw nothing")
	assert_eq(session.free_held(), 1, "1 free booster still held")
	session.press_booster(BoosterRules.HAMMER)
	var result: MoveResult = session.tap_cell(Vector2i(0, 0))
	assert_true(result != null and result.accepted, "the Hammer is accepted")
	assert_true(result.cost.is_zero(), "and charges 0")
	assert_eq(session.state.value_at(Vector2i(0, 0)), TOP - 9, "(0,0) = 2^65526")
	assert_true(session.state.score.is_zero(), "score 0")
	assert_eq(session.free_held(), 0, "0 held")
	assert_false(result.has_valid_move, "still no valid move")
	assert_true(result.run_ends, "and nothing usable")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.ENDED, "the run ends at once")
	assert_true(recorder.summaries[0].final_score.is_zero(), "final score 0")


func test_at_144_b_an_all_ceiling_board_at_the_largest_score() -> void:
	var session: GameSession = BF.ready_session(BF.none_held(RunState.create(F.board_all_exponent(TOP), _top_score())))
	recorder.watch(session)
	session.rng.script_spawns(PackedInt64Array([TOP - 9, TOP - 9]))
	assert_eq(session.phase(), GameSession.Phase.OFFER, "the offer opens")
	assert_eq(BF.usable_ids(session), [BoosterRules.HAMMER] as Array[StringName], "only Hammer is usable")
	assert_eq(BF.status_of(session, BoosterRules.HAMMER).cost, TOP, "at a cost of 2^65535")
	assert_true(BF.free_ids(session).is_empty(), "nothing is free")
	assert_eq(_reasons(session), [USABLE, NO_TARGET, NO_TARGET, NO_TARGET, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "Swap and Shuffle: every tile equal; Double: no target; Undo: no snapshot")
	session.press_booster(BoosterRules.HAMMER)
	var first: MoveResult = session.tap_cell(Vector2i(0, 0))
	assert_true(first.cost.equals(BigNum.pow2(TOP)), "charged 2^65535")
	assert_true(session.state.score.equals(_top_score().sub(BigNum.pow2(TOP))), "score 2^65600 minus 1 minus 2^65535")
	assert_eq(session.state.value_at(Vector2i(0, 0)), TOP - 9, "(0,0) = 2^65526")
	assert_false(first.has_valid_move, "still no valid move")
	assert_true(first.offer_opens, "the offer opens again")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.OFFER, "the offer is open")
	assert_eq(BF.usable_ids(session), [&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName], "now Hammer, Swap, Shuffle and Double: two values, and 2^65526 is a Double target")
	assert_eq(BF.suggested_id(session), BoosterRules.SHUFFLE, "Shuffle is marked")
	session.press_booster(BoosterRules.HAMMER)
	var second: MoveResult = session.tap_cell(Vector2i(1, 0))
	assert_true(session.state.score.equals(_top_score().sub(BigNum.pow2(TOP + 1))), "score 2^65600 minus 1 minus 2^65536")
	assert_eq(session.state.value_at(Vector2i(1, 0)), TOP - 9, "(1,0) = 2^65526, touching (0,0)")
	assert_true(second.has_valid_move, "that pair fits, so the board has a valid move")
	session.move_shown()
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "the offer closes and play goes on")
	var chain: Array[Vector2i] = [Vector2i(0, 0)]
	assert_eq(session.joinable_cells(chain), [Vector2i(1, 0)] as Array[Vector2i], "(1,0) is joinable from (0,0)")
	var problem: String = _highlight_matches_commit(session, chain)
	assert_true(problem.is_empty(), "the highlight agrees with the commit: %s" % problem)


# AT-167, the score ceiling through the session

func test_at_167_a_the_score_blocks_the_only_pair() -> void:
	for seed_value: int in range(1, 21):
		var state: RunState = RunState.create(_pair_board(10), BF.below_pow2(SCORE_BITS, 2048))
		var copy: RunState = state.copy()
		var refused: MoveResult = RunRules.commit_chain(copy, Records.new(), BF.targets([Vector2i(0, 7), Vector2i(1, 7)]), F.seeded(seed_value), config)
		var session: GameSession = BF.ready_session(state, null, seed_value)
		var start: Array[Vector2i] = [Vector2i(0, 7)]
		var problem: String = ""
		if CoreRules.has_valid_move(state.cells, state.score, config):
			problem = "a valid move"
		elif not session.joinable_cells(start).is_empty():
			problem = "(1,7) is joinable"
		elif refused.accepted or not copy.equals(state):
			problem = "the commit was not refused cleanly"
		elif session.phase() != GameSession.Phase.OFFER:
			problem = "the offer did not open"
		elif BF.usable_ids(session) != ([&"hammer", &"swap", &"shuffle", &"double"] as Array[StringName]):
			problem = "usable %s" % [BF.usable_ids(session)]
		elif BF.status_of(session, BoosterRules.UNDO).reason != NO_SNAPSHOT or BF.suggested_id(session) != BoosterRules.SHUFFLE:
			problem = "Undo or the mark"
		if problem.is_empty():
			var result: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
			if result == null or not session.state.score.equals(BF.below_pow2(SCORE_BITS, 3072)):
				problem = "Shuffle score"
			elif not result.has_valid_move:
				problem = "no valid move after the Shuffle"
			else:
				session.move_shown()
				if session.phase() != GameSession.Phase.PLAYING:
					problem = "the offer did not close"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


func test_at_167_b_a_chain_that_reaches_the_largest_score() -> void:
	for seed_value: int in range(1, 21):
		var state: RunState = RunState.create(_pair_board(10), BF.below_pow2(SCORE_BITS, 2049))
		var session: GameSession = BF.ready_session(state, null, seed_value)
		var start: Array[Vector2i] = [Vector2i(0, 7)]
		var problem: String = ""
		if session.phase() != GameSession.Phase.PLAYING:
			problem = "no valid move at the start"
		elif session.joinable_cells(start) != ([Vector2i(1, 7)] as Array[Vector2i]):
			problem = "(1,7) is not joinable"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return
		var chain: MoveResult = session.commit_chain([Vector2i(0, 7), Vector2i(1, 7)] as Array[Vector2i])
		if not chain.accepted or not session.state.score.equals(_top_score()):
			problem = "the commit"
		elif session.state.value_at(Vector2i(1, 7)) != 11 or chain.cleared_small.size() != 12:
			problem = "(1,7) = 2048 and twelve 2s clear"
		elif chain.has_valid_move or not chain.offer_opens:
			problem = "a valid move at 2^65600 minus 1"
		else:
			for index: int in 40:
				var one: Array[Vector2i] = [CoreRules.cell_of(index, F.COLUMNS)]
				if not session.joinable_cells(one).is_empty():
					problem = "a tile is highlighted from %s" % one[0]
		if problem.is_empty():
			session.move_shown()
			if session.phase() != GameSession.Phase.OFFER:
				problem = "the offer did not open"
			elif BF.usable_ids(session) != BoosterRules.ALL or BF.suggested_id(session) != BoosterRules.SHUFFLE:
				problem = "usable %s, marked %s" % [BF.usable_ids(session), BF.suggested_id(session)]
		if problem.is_empty():
			var shuffled: MoveResult = session.press_booster(BoosterRules.SHUFFLE)
			if shuffled == null or not session.state.score.equals(BF.below_pow2(SCORE_BITS, 2049)):
				problem = "Shuffle score"
			elif not shuffled.has_valid_move:
				problem = "no valid move after the Shuffle"
			else:
				session.move_shown()
				if session.phase() != GameSession.Phase.PLAYING:
					problem = "the offer did not close"
		if not problem.is_empty():
			fail("seed %d: %s" % [seed_value, problem])
			return


# Bart's position (2026-10-21)

func test_bart_position_joinable_cells_for_a_50_are_what_commit_accepts() -> void:
	var session: GameSession = BF.ready_session(_bart_state())
	assert_eq(session.phase(), GameSession.Phase.PLAYING, "the move check finds a valid move (V11)")
	var fifties: Array[Vector2i] = [Vector2i(1, 0), Vector2i(3, 0), Vector2i(2, 1)]
	for cell: Vector2i in fifties:
		assert_eq(session.state.value_at(cell), 50, "%s holds 2^50" % cell)
	var start: Array[Vector2i] = [Vector2i(1, 0)]
	assert_eq(session.joinable_cells(start), [Vector2i(2, 1)] as Array[Vector2i], "from (1,0) only (2,1) joins")
	var middle: Array[Vector2i] = [Vector2i(2, 1)]
	assert_eq(session.joinable_cells(middle), [Vector2i(1, 0), Vector2i(3, 0)] as Array[Vector2i], "from (2,1) both other 50s join")
	var chains: Array[Array] = [
		[Vector2i(1, 0)], [Vector2i(3, 0)], [Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 1)], [Vector2i(3, 0), Vector2i(2, 1)],
		[Vector2i(1, 0), Vector2i(2, 1), Vector2i(3, 0)],
	]
	for each: Array in chains:
		var chain: Array[Vector2i] = []
		chain.assign(each)
		var problem: String = _highlight_matches_commit(session, chain)
		assert_true(problem.is_empty(), "the highlight agrees with the commit: %s" % problem)
	var two: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 1)]
	assert_eq(session.joinable_cells(two), [Vector2i(3, 0), Vector2i(3, 1)] as Array[Vector2i], "then the third 50 or the touching 2^51")


func test_bart_position_a_chain_commits_through_the_session() -> void:
	var session: GameSession = BF.ready_session(_bart_state())
	recorder.watch(session)
	var chain: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 1)]
	assert_true(session.begin_drag(), "a drag opens")
	assert_eq(session.preview_value(chain), 51, "the preview shows 2^51")
	var result: MoveResult = session.commit_chain(chain)
	assert_true(result.accepted, "the chain commits")
	assert_true(result.points.equals(BigNum.pow2(51)), "2^51 points")
	var expected: BigNum = _big(BART_SCORE).add(BigNum.pow2(51))
	assert_true(session.state.score.equals(expected), "the score is the old score plus 2^51 exactly")
	assert_eq(session.state.score.to_decimal(), "9223504919442726182", "9,223,504,919,442,726,182")
	assert_true(session.state.score.compare(_big(INT64_MAX)) > 0, "above 2^63 minus 1")
	assert_true(session.records.best_score.equals(expected), "Best Score follows it live (D-16)")
	assert_eq(recorder.names, PackedStringArray(["move_resolved", "status_changed", "save_requested"]), "resolved and saved at once")
	session.move_shown()
	assert_true(session.is_run_in_progress(), "the run plays on")


func test_bart_position_booster_costs_at_2_56_tiles() -> void:
	var state: RunState = _bart_state()
	assert_eq(_costs(state), [56, 56, 56, 57, 55] as Array[int], "Hammer, Swap, Shuffle 2^56 (64Q), Double 2^57 (128Q), Undo 2^55 (32Q)")
	assert_eq(_usabilities(state), [USABLE, USABLE, USABLE, USABLE, NO_SNAPSHOT] as Array[BoosterStatus.Usability], "every booster is affordable at his score")
	var session: GameSession = BF.ready_session(state)
	assert_eq(BF.status_of(session, BoosterRules.DOUBLE).cost, 57, "the bar shows Double at 2^57")
	session.press_booster(BoosterRules.HAMMER)
	var hammered: MoveResult = session.tap_cell(Vector2i(0, 7))
	assert_true(hammered.accepted, "Hammer accepted")
	assert_true(hammered.cost.equals(BigNum.pow2(56)), "charged 2^56 exactly")
	var after_hammer: BigNum = _big(BART_SCORE).sub(BigNum.pow2(56))
	assert_true(session.state.score.equals(after_hammer), "score minus 2^56 exactly")
	session.move_shown()
	session.press_booster(BoosterRules.DOUBLE)
	var doubled: MoveResult = session.tap_cell(Vector2i(4, 7))
	assert_true(doubled.accepted, "Double accepted on a 2^56")
	assert_true(doubled.cost.equals(BigNum.pow2(57)), "charged 2^57 exactly")
	assert_eq(doubled.result_value, 57, "the tile becomes 2^57")
	assert_true(session.state.score.equals(after_hammer.sub(BigNum.pow2(57))), "score minus 2^57 exactly")
	session.move_shown()
	assert_eq(BoosterRules.cost(BoosterRules.HAMMER, session.state, config), 57, "H is 2^57, so Hammer now costs 2^57")
