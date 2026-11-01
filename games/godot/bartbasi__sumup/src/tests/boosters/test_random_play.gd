extends "res://tests/base_test.gd"
## Random play. AT-84 on the rules model (D-30: the score never goes below
## zero, refused calls change nothing, accepted boosters take exactly their
## charge: the cost, or 0 when they use a free booster, D-46), and random
## intents on GameSession checking its flow rules hold at every step.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")

var config: GameConfig


func before_each() -> void:
	config = GameConfig.new()


## A random chain that follows the joining rule, 2 to 5 tiles long, or an
## empty chain when the board has no valid move. It starts on the first
## touching equal pair found from a random cell, then grows through
## CoreRules.joinable_cells with the run's score. The first pair may not fit
## under the ceiling; the commit then refuses it.
func _random_chain(cells: PackedInt64Array, score: BigNum, pick: RandomNumberGenerator) -> Array[Vector2i]:
	var chain: Array[Vector2i] = []
	var columns: int = config.columns
	var size: int = cells.size()
	var offset: int = pick.randi_range(0, size - 1)
	for step: int in size:
		var index: int = (offset + step) % size
		var column: int = index % columns
		var value: int = cells[index]
		var partner: int = -1
		if column + 1 < columns and cells[index + 1] == value:
			partner = index + 1
		elif index + columns < size:
			if cells[index + columns] == value:
				partner = index + columns
			elif column > 0 and cells[index + columns - 1] == value:
				partner = index + columns - 1
			elif column + 1 < columns and cells[index + columns + 1] == value:
				partner = index + columns + 1
		if partner >= 0:
			chain = [CoreRules.cell_of(index, columns), CoreRules.cell_of(partner, columns)]
			if pick.randi_range(0, 1) == 0:
				chain.reverse()
			break
	if chain.is_empty():
		return chain
	var length: int = pick.randi_range(2, 5)
	while chain.size() < length:
		var options: Array[Vector2i] = CoreRules.joinable_cells(cells, score, chain, config)
		if options.is_empty():
			break
		chain.append(options[pick.randi_range(0, options.size() - 1)])
	return chain


## A random cell, now and then just off the board.
func _random_cell(pick: RandomNumberGenerator) -> Vector2i:
	if pick.randi_range(0, 9) == 0:
		return Vector2i(pick.randi_range(-1, config.columns), pick.randi_range(-1, config.rows))
	return Vector2i(pick.randi_range(0, config.columns - 1), pick.randi_range(0, config.rows - 1))


## Random targets: usually the right count for the booster, sometimes not.
func _random_targets(id: StringName, pick: RandomNumberGenerator) -> Array[Vector2i]:
	var count: int = BoosterRules.target_count(id)
	if pick.randi_range(0, 9) == 0:
		count = pick.randi_range(0, 2)
	var targets: Array[Vector2i] = []
	for position: int in count:
		targets.append(_random_cell(pick))
	return targets


## Every cell an exponent from 1 (the tile 2) to the ceiling, none below the
## window floor (D-38, D-39), the run highest tile and Best Tile at least H,
## the score below 2^max_score_bits (D-37).
func _board_problem(state: RunState, records: Records) -> String:
	if state.cells.size() != config.cell_count():
		return "the board has %d cells" % state.cells.size()
	var floor_value: int = CoreRules.window_floor(state.highest(), config)
	for value: int in state.cells:
		if value < 1 or value > config.max_exponent:
			return "a cell holds 2^%d" % value
		if value < floor_value:
			return "a 2^%d is below the floor 2^%d" % [value, floor_value]
	if state.run_highest < state.highest() or records.best_tile < state.run_highest:
		return "H %d, run highest %d, Best Tile %d" % [state.highest(), state.run_highest, records.best_tile]
	if state.score.bit_length() > config.max_score_bits:
		return "the score %s reached 2^%d" % [state.score.to_decimal(), config.max_score_bits]
	if records.best_score.compare(state.score) < 0:
		return "Best Score %s below the score %s" % [records.best_score.to_decimal(), state.score.to_decimal()]
	return ""


## D-37, AT-168: the move check says yes exactly when some touching equal
## pair would be accepted as a chain (tried on a copy), and when it says no
## the run is never left in play: the offer opens or the run ends.
func _move_check_problem(state: RunState, records: Records) -> String:
	var any_accepted: bool = false
	for index: int in state.cells.size():
		var cell: Vector2i = CoreRules.cell_of(index, config.columns)
		for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]:
			var other: Vector2i = cell + step
			if not CoreRules.in_bounds(other, config) or state.value_at(other) != state.value_at(cell):
				continue
			var pair: Array[Vector2i] = [cell, other]
			if RunRules.commit_chain(state.copy(), records.copy(), pair, F.seeded(1), config).accepted:
				any_accepted = true
				break
		if any_accepted:
			break
	var valid: bool = CoreRules.has_valid_move(state.cells, state.score, config)
	if valid != any_accepted:
		return "the move check says %s, the commit accepts a pair: %s" % [valid, any_accepted]
	if (BoosterRules.outcome(state, config) == BoosterRules.Outcome.PLAY) != valid:
		return "outcome() disagrees with the move check"
	return ""


## One random action on the rules model, checked (AT-84): a chain when valid
## and the roll allows it, else a booster with random targets whether or not
## it is usable. Returns the problem found, or "" when every check holds.
## tally counts "accepted", "refused" and "free" (accepted free boosters).
## result receives the move's result as its only element.
func _random_action(state: RunState, records: Records, rng: RunRandom, pick: RandomNumberGenerator, valid: bool, tally: Dictionary[String, int], result: Array[MoveResult]) -> String:
	var before: RunState = state.copy()
	var records_before: Records = records.copy()
	var rng_before: int = rng.get_state()
	var label: String = ""
	var moved: MoveResult = null
	var price: BigNum = BigNum.zero()
	var was_free: bool = false
	if valid and pick.randi_range(0, 2) == 0:
		label = "chain"
		moved = RunRules.commit_chain(state, records, _random_chain(state.cells, state.score, pick), rng, config)
	else:
		var id: StringName = BoosterRules.ALL[pick.randi_range(0, BoosterRules.ALL.size() - 1)]
		label = String(id)
		price = BoosterRules.charge(id, state, config)
		was_free = BoosterRules.is_free(state, config)
		if was_free and not price.is_zero():
			return "%s would charge %s while free" % [label, price.to_decimal()]
		moved = BoosterRules.apply(id, state, records, _random_targets(id, pick), rng, config)
	result.clear()
	result.append(moved)
	if state.score == null:
		return "the score went below zero"
	if CoreRules.free_held(state, config) < 0:
		return "free boosters held %d" % CoreRules.free_held(state, config)
	if not moved.accepted:
		tally["refused"] += 1
		if not state.equals(before) or rng.get_state() != rng_before:
			return "a refused %s changed the run" % label
		if not records.best_score.equals(records_before.best_score) or records.best_tile != records_before.best_tile:
			return "a refused %s changed the records" % label
		if not moved.cost.is_zero() or moved.free_used:
			return "a refused %s reports a charge" % label
		return ""
	if label == "chain":
		if not state.score.equals(before.score.add(moved.points)):
			return "a chain took the score from %s to %s, not adding its points %s" % [before.score.to_decimal(), state.score.to_decimal(), moved.points.to_decimal()]
		if state.free_used != before.free_used:
			return "a chain used a free booster"
	else:
		tally["accepted"] += 1
		var expected: BigNum = before.score.sub(price)
		if label == "undo":
			expected = before.score.sub(before.snapshot_points)
			expected = expected.sub(price) if expected != null else null
		if expected == null:
			return "%s was accepted though it would take the score below zero" % label
		if not moved.cost.equals(price) or not state.score.equals(expected):
			return "%s took the score from %s to %s at charge %s" % [label, before.score.to_decimal(), state.score.to_decimal(), price.to_decimal()]
		var used: int = 1 if was_free else 0
		if moved.free_used != was_free or state.free_used != before.free_used + used:
			return "%s used %d free boosters with %d held" % [label, state.free_used - before.free_used, CoreRules.free_held(before, config)]
		tally["free"] += used
	return _board_problem(state, records)


func _new_tally() -> Dictionary[String, int]:
	var tally: Dictionary[String, int] = {"accepted": 0, "refused": 0, "free": 0}
	return tally


func test_at_84_random_play_never_goes_below_zero() -> void:
	var tally: Dictionary[String, int] = _new_tally()
	var result: Array[MoveResult] = []
	for seed_value: int in range(1, 21):
		var rng: RunRandom = F.seeded(seed_value)
		var pick: RandomNumberGenerator = RandomNumberGenerator.new()
		pick.seed = seed_value * 7919
		var records: Records = Records.new()
		var state: RunState = RunRules.new_run(rng, records, config)
		# Every result reports the move check on the board it leaves, so the
		# board is not checked again here.
		var valid: bool = true
		for action: int in 10000:
			if not valid and BoosterRules.outcome(state, config) == BoosterRules.Outcome.END:
				state = RunRules.new_run(rng, records, config)
				valid = true
			var problem: String = _random_action(state, records, rng, pick, valid, tally, result)
			if not problem.is_empty():
				fail("seed %d, action %d: %s" % [seed_value, action, problem])
				return
			valid = result[0].has_valid_move
	assert_true(tally["accepted"] > 1000, "boosters were really used (%d)" % tally["accepted"])
	assert_true(tally["refused"] > 1000, "refusals were really tried (%d)" % tally["refused"])
	assert_true(tally["free"] > 0, "free boosters were really used (%d)" % tally["free"])


## AT-84 again from runs that hold free boosters (D-46): tight boards, a
## run highest tile from 8K to 2^40, a random count already used and a small
## score, so free boosters, the offer and refusals all come up often.
func test_random_play_with_free_boosters_held() -> void:
	var tally: Dictionary[String, int] = _new_tally()
	var result: Array[MoveResult] = []
	for seed_value: int in range(1, 41):
		var rng: RunRandom = F.seeded(seed_value)
		var pick: RandomNumberGenerator = RandomNumberGenerator.new()
		pick.seed = seed_value * 6271
		var records: Records = Records.new()
		var boards: Array[PackedInt64Array] = [F.board_d(), F.board_e(), BF.board_d1024(), F.board_p()]
		var board: PackedInt64Array = boards[pick.randi_range(0, boards.size() - 1)]
		var snapshot: PackedInt64Array = F.board_p() if pick.randi_range(0, 1) == 0 else PackedInt64Array()
		var run_highest: int = pick.randi_range(13, 40)
		var state: RunState = RunState.create(board, F.big(pick.randi_range(0, 3000)), snapshot, F.big(pick.randi_range(4, 64)), run_highest)
		state.free_used = pick.randi_range(0, CoreRules.free_earned(run_highest, config))
		records.update_from(state)
		records.best_tile = run_highest
		var valid: bool = CoreRules.has_valid_move(state.cells, state.score, config)
		for action: int in 400:
			if not valid and BoosterRules.outcome(state, config) == BoosterRules.Outcome.END:
				break
			var problem: String = _random_action(state, records, rng, pick, valid, tally, result)
			if not problem.is_empty():
				fail("seed %d, action %d: %s" % [seed_value, action, problem])
				return
			valid = result[0].has_valid_move
	assert_true(tally["free"] > 100, "free boosters were really used (%d)" % tally["free"])
	assert_true(tally["accepted"] > tally["free"], "paid boosters too (%d)" % (tally["accepted"] - tally["free"]))
	assert_true(tally["refused"] > 100, "refusals were really tried (%d)" % tally["refused"])


## AT-168 seeds. The GDD allows at least 10 in the automated test; QA runs
## 200 by hand. 500 actions each, as written.
const AT_168_SEEDS: int = 10
const AT_168_ACTIONS: int = 500
const NEIGHBORS: Array[Vector2i] = [
	Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0),
	Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1),
]


## AT-168 (D-04, D-37, D-40) with the constants lowered (TH4): MAX_EXPONENT 8
## and MAX_SCORE_BITS 12, so tiles stop at 256 and the score stays below
## 4,096. Each seed starts from a random score from 0 to 4,095; even seeds
## start just below 4,095 so blocked boards come up. 500 actions per seed mix
## drags (up to 15 finger moves onto touching cells, with backtracks, then a
## lift) with all five boosters on random targets. The action right after an
## accepted booster is always a drag. At every finger position every touching
## tile not in the chain is tried on a copy: a highlighted tile joins and the
## commit accepts the chain with it, any other tile does not join and the
## commit refuses it. Every lift of 2 or more tiles is accepted. At every
## action the move check, outcome() and the commit agree, no tile passes 2^8,
## the score stays below 2^12 and never below zero, and a run with no move is
## never left in play.
func test_at_168_highlight_and_commit_agree_through_drags_and_boosters() -> void:
	config.max_exponent = 8
	config.max_score_bits = 12
	var tally: Dictionary[String, int] = _new_tally()
	var counts: Dictionary[String, int] = {
		"neighbors": 0, "highlighted": 0, "lifts": 0, "short_lifts": 0,
		"backtracks": 0, "after_booster": 0, "blocked": 0, "offers": 0, "ended": 0, "at_top": 0,
	}
	var result: Array[MoveResult] = []
	var scratch: RunRandom = F.seeded(1)
	var started: int = Time.get_ticks_msec()
	for seed_value: int in range(1, AT_168_SEEDS + 1):
		var rng: RunRandom = F.seeded(seed_value)
		var pick: RandomNumberGenerator = RandomNumberGenerator.new()
		pick.seed = seed_value * 3571
		var records: Records = Records.new()
		var fresh: RunState = RunRules.new_run(rng, records, config)
		var start: int = pick.randi_range(0, 4095) if seed_value % 2 == 1 else 4095 - pick.randi_range(0, 63)
		var state: RunState = RunState.create(fresh.cells, F.big(start))
		records.update_from(state)
		var valid: bool = CoreRules.has_valid_move(state.cells, state.score, config)
		var after_booster: bool = false
		for action: int in AT_168_ACTIONS:
			var problem: String = _move_check_problem(state, records)
			if state.highest() == config.max_exponent:
				counts["at_top"] += 1
			if problem.is_empty() and not valid:
				counts["blocked"] += 1
				if BoosterRules.outcome(state, config) == BoosterRules.Outcome.END:
					counts["ended"] += 1
					break
				counts["offers"] += 1
			if problem.is_empty():
				result.clear()
				if after_booster or pick.randi_range(0, 1) == 0:
					if after_booster:
						counts["after_booster"] += 1
					after_booster = false
					problem = _drag(state, records, rng, scratch, pick, counts, result)
				else:
					var accepted_before: int = tally["accepted"]
					# valid false makes _random_action call a booster, never a chain.
					problem = _random_action(state, records, rng, pick, false, tally, result)
					after_booster = tally["accepted"] > accepted_before
			valid = CoreRules.has_valid_move(state.cells, state.score, config)
			if problem.is_empty() and not result.is_empty() and result[0].accepted and result[0].has_valid_move != valid:
				problem = "the move result says has_valid_move %s, the move check says %s" % [result[0].has_valid_move, valid]
			if not problem.is_empty():
				fail("seed %d, action %d: %s" % [seed_value, action, problem])
				return
	print("    AT-168: %d ms, %d seeds, %d neighbor checks (%d highlighted), %d lifts, %d short lifts, %d backtracks, %d accepted boosters, %d drags right after one, %d offers, %d ended, %d blocked steps, %d steps at 2^8" % [
		Time.get_ticks_msec() - started, AT_168_SEEDS, counts["neighbors"], counts["highlighted"], counts["lifts"], counts["short_lifts"],
		counts["backtracks"], tally["accepted"], counts["after_booster"], counts["offers"], counts["ended"],
		counts["blocked"], counts["at_top"]])
	assert_true(counts["neighbors"] > 50000, "plenty of neighbors tried (%d)" % counts["neighbors"])
	assert_true(counts["highlighted"] > 5000, "plenty of highlighted tiles tried (%d)" % counts["highlighted"])
	assert_true(counts["lifts"] > 500, "plenty of lifts (%d)" % counts["lifts"])
	assert_true(counts["backtracks"] > 500, "plenty of backtracks (%d)" % counts["backtracks"])
	assert_true(tally["accepted"] > 200, "boosters were really used (%d)" % tally["accepted"])
	assert_true(counts["after_booster"] > 200, "drags right after a booster (%d)" % counts["after_booster"])
	assert_true(counts["blocked"] > 0, "boards with no move came up (%d)" % counts["blocked"])
	assert_true(counts["at_top"] > 0, "tiles reached the lowered ceiling (%d)" % counts["at_top"])


## One drag for AT-168: the finger lands on a random tile (half the time one
## the highlight would extend from), makes 1 to 15 moves onto touching cells
## (half of them aimed at a highlighted tile when there is one, and a quarter
## back onto the previous tile once the chain has 2), and lifts. The aiming
## only makes chains long enough for the board to reach the ceiling. The highlight is checked at every finger
## position, the last one included. A lift of 2 or more tiles must be
## accepted. result receives the commit's result, if there was one.
func _drag(state: RunState, records: Records, rng: RunRandom, scratch: RunRandom, pick: RandomNumberGenerator, counts: Dictionary[String, int], result: Array[MoveResult]) -> String:
	var chain: Array[Vector2i] = []
	var landing: Vector2i = Vector2i(pick.randi_range(0, config.columns - 1), pick.randi_range(0, config.rows - 1))
	if pick.randi_range(0, 1) == 0:
		landing = _tile_with_a_partner(state, pick, landing)
	chain = CoreRules.step_chain(state.cells, state.score, chain, landing, config)
	if chain.size() != 1:
		return "the finger landed on %s and the chain is %s" % [landing, chain]
	var moves: int = pick.randi_range(1, 15)
	for move: int in moves + 1:
		var problem: String = _highlight_problem(state, records, chain, scratch, counts)
		if not problem.is_empty():
			return "drag after %d finger moves, chain %s: %s" % [move, chain, problem]
		if move == moves:
			break
		var target: Vector2i = chain[chain.size() - 1] + NEIGHBORS[pick.randi_range(0, NEIGHBORS.size() - 1)]
		var shown: Array[Vector2i] = CoreRules.joinable_cells(state.cells, state.score, chain, config)
		if not shown.is_empty() and pick.randi_range(0, 1) == 0:
			target = shown[pick.randi_range(0, shown.size() - 1)]
		if chain.size() >= 2 and pick.randi_range(0, 3) == 0:
			target = chain[chain.size() - 2]
			counts["backtracks"] += 1
		chain = CoreRules.step_chain(state.cells, state.score, chain, target, config)
	if chain.size() < 2:
		counts["short_lifts"] += 1
		return ""
	var score_before: BigNum = state.score
	var moved: MoveResult = RunRules.commit_chain(state, records, chain, rng, config)
	result.append(moved)
	if not moved.accepted:
		return "the lift of %s, built only from highlighted tiles, was refused" % [chain]
	counts["lifts"] += 1
	if not state.score.equals(score_before.add(moved.points)):
		return "a chain took the score from %s to %s, not adding its points %s" % [score_before.to_decimal(), state.score.to_decimal(), moved.points.to_decimal()]
	return _board_problem(state, records)


## The first tile from a random index on that has something highlighted
## once the finger lands on it, or fallback when no tile has.
func _tile_with_a_partner(state: RunState, pick: RandomNumberGenerator, fallback: Vector2i) -> Vector2i:
	var size: int = state.cells.size()
	var offset: int = pick.randi_range(0, size - 1)
	for step: int in size:
		var cell: Vector2i = CoreRules.cell_of((offset + step) % size, config.columns)
		var alone: Array[Vector2i] = [cell]
		if not CoreRules.joinable_cells(state.cells, state.score, alone, config).is_empty():
			return cell
	return fallback


## AT-168 at one finger position: the highlight (CoreRules.joinable_cells,
## what GameSession.joinable_cells hands the board) holds only touching tiles
## not in the chain, and every touching tile not in the chain is tried on a
## copy. Highlighted: the finger adds it and the commit accepts the chain with
## it. Not highlighted: the finger leaves the chain as it is and the commit
## refuses the chain with it.
func _highlight_problem(state: RunState, records: Records, chain: Array[Vector2i], scratch: RunRandom, counts: Dictionary[String, int]) -> String:
	var shown: Array[Vector2i] = CoreRules.joinable_cells(state.cells, state.score, chain, config)
	var last: Vector2i = chain[chain.size() - 1]
	for cell: Vector2i in shown:
		if not CoreRules.in_bounds(cell, config) or not CoreRules.touching(last, cell) or chain.has(cell):
			return "the highlight shows %s, not a touching tile outside the chain" % [cell]
	for step: Vector2i in NEIGHBORS:
		var cell: Vector2i = last + step
		if not CoreRules.in_bounds(cell, config) or chain.has(cell):
			continue
		counts["neighbors"] += 1
		var longer: Array[Vector2i] = chain.duplicate()
		longer.append(cell)
		var accepted: bool = RunRules.commit_chain(state.copy(), records.copy(), longer, scratch, config).accepted
		var stepped: Array[Vector2i] = CoreRules.step_chain(state.cells, state.score, chain, cell, config)
		if shown.has(cell):
			counts["highlighted"] += 1
			if not accepted:
				return "%s is highlighted but the commit refuses the chain with it" % [cell]
			if stepped != longer:
				return "%s is highlighted but does not join when the finger reaches it" % [cell]
		else:
			if accepted:
				return "%s is not highlighted but the commit accepts the chain with it" % [cell]
			if stepped != chain:
				return "%s is not highlighted but joins when the finger reaches it" % [cell]
	return ""


## Random intents on GameSession, checking after each one that the flow state
## is consistent (flow rules 1 to 8) and the signals came in the right order.
func test_random_session_intents_keep_the_flow_rules() -> void:
	var visits: Dictionary[GameSession.Phase, int] = {}
	var offer_targeting: int = 0
	for seed_value: int in range(1, 11):
		var pick: RandomNumberGenerator = RandomNumberGenerator.new()
		pick.seed = seed_value * 104729
		var session: GameSession = GameSession.new()
		var recorder: BF.Recorder = BF.Recorder.new()
		recorder.watch(session)
		session.rng.force_start_board(RunRules.new_run(F.seeded(seed_value), Records.new(), config).cells)
		_restart(session, pick, seed_value)
		for intent: int in 1500:
			var before: RunState = session.state.copy()
			var signal_count: int = recorder.names.size()
			var roll: int = pick.randi_range(0, 99)
			var result: MoveResult = null
			var label: String = ""
			if session.phase() == GameSession.Phase.ENDED or (intent > 0 and intent % 100 == 0):
				label = "restart"
				_restart(session, pick, seed_value * 1000 + intent)
			elif roll < 30:
				label = "move_shown"
				session.move_shown()
			elif roll < 45:
				label = "commit_chain"
				session.begin_drag()
				result = session.commit_chain(_random_chain(session.state.cells, session.state.score, pick))
			elif roll < 50:
				label = "drag"
				session.begin_drag()
				if pick.randi_range(0, 1) == 0:
					session.end_drag()
			elif roll < 70:
				var id: StringName = BoosterRules.ALL[pick.randi_range(0, BoosterRules.ALL.size() - 1)]
				label = "press %s" % id
				result = session.press_booster(id)
			elif roll < 90:
				label = "tap"
				result = session.tap_cell(_random_cell(pick))
			elif roll < 97:
				label = "cancel_targeting"
				session.cancel_targeting()
			else:
				label = "end_run"
				session.end_run()
			var problem: String = _session_problem(session, recorder, signal_count, before, result)
			if problem.is_empty() and label != "restart" and not _same(session.state.best_at_start, before.best_at_start):
				problem = "best_at_start changed without a new run or resume"
			if not problem.is_empty():
				fail("seed %d, intent %d (%s): %s" % [seed_value, intent, label, problem])
				return
			visits[session.phase()] = visits.get(session.phase(), 0) + 1
			if session.phase() == GameSession.Phase.TARGETING and session.is_offer_open():
				offer_targeting += 1
	for phase: GameSession.Phase in [GameSession.Phase.PLAYING, GameSession.Phase.TARGETING, GameSession.Phase.OFFER, GameSession.Phase.ENDED]:
		assert_true(visits.get(phase, 0) > 0, "phase %d was reached" % phase)
	assert_true(offer_targeting > 0, "targeting from the offer was reached")


## Starts the next run: half the time a new run, half the time a resumed
## tight board (Board D or E with a few cells changed, a small score and
## sometimes a snapshot), so the offer and the end of a run come up often.
## A third of the resumed runs reached 8K, so they hold one free booster.
func _restart(session: GameSession, pick: RandomNumberGenerator, seed_value: int) -> void:
	if pick.randi_range(0, 1) == 0:
		session.start_new_run()
	else:
		var board: PackedInt64Array = F.board_d() if pick.randi_range(0, 1) == 0 else F.board_e()
		var values: PackedInt64Array = F.ev(PackedInt64Array([2, 4, 8, 16, 32, 64, 512, 1024]))
		for change: int in pick.randi_range(0, 3):
			var cell: Vector2i = Vector2i(pick.randi_range(0, config.columns - 1), pick.randi_range(0, config.rows - 1))
			board[CoreRules.index_of(cell, config.columns)] = values[pick.randi_range(0, values.size() - 1)]
		var snapshot: PackedInt64Array = F.board_p() if pick.randi_range(0, 1) == 0 else PackedInt64Array()
		var run_highest: int = 13 if pick.randi_range(0, 2) == 0 else 0
		session.resume(RunState.create(board, F.big(pick.randi_range(0, 1500)), snapshot, F.big(pick.randi_range(4, 64)), run_highest))
	session.rng.set_seed(seed_value)


func _session_problem(session: GameSession, recorder: BF.Recorder, signal_count: int, before: RunState, result: MoveResult) -> String:
	var phase: GameSession.Phase = session.phase()
	if session.state.score == null:
		return "the score went below zero"
	if session.free_held() < 0:
		return "free boosters held %d" % session.free_held()
	if session.state.best_at_start == null:
		return "best_at_start unknown, which SaveCodec refuses to write"
	for status: BoosterStatus in session.booster_statuses():
		if status.free != (session.free_held() > 0):
			return "%s reads free %s with %d held" % [status.id, status.free, session.free_held()]
	if session.is_run_in_progress() != (phase == GameSession.Phase.PLAYING or phase == GameSession.Phase.TARGETING or phase == GameSession.Phase.OFFER):
		return "is_run_in_progress disagrees with the phase"
	if session.is_offer_open() and phase != GameSession.Phase.OFFER and phase != GameSession.Phase.TARGETING:
		return "the offer is open in phase %d" % phase
	if phase == GameSession.Phase.OFFER and not session.is_offer_open():
		return "phase OFFER with the offer closed"
	if (session.targeting_booster() != &"") != (phase == GameSession.Phase.TARGETING):
		return "targeting %s in phase %d" % [session.targeting_booster(), phase]
	if session.swap_first() != BF.NO_CELL and session.targeting_booster() != BoosterRules.SWAP:
		return "a Swap selection without Swap targeting"
	if session.is_waiting_for_view() and phase != GameSession.Phase.PLAYING and phase != GameSession.Phase.OFFER:
		return "waiting in phase %d" % phase
	if session.is_dragging() and (phase != GameSession.Phase.PLAYING or session.is_waiting_for_view()):
		return "a drag outside play"
	if not session.is_waiting_for_view():
		var valid: bool = CoreRules.has_valid_move(session.state.cells, session.state.score, session.config)
		if phase == GameSession.Phase.PLAYING and not valid:
			return "PLAYING with no valid move after the move check"
		if phase == GameSession.Phase.OFFER and (valid or BoosterRules.outcome(session.state, session.config) != BoosterRules.Outcome.OFFER):
			return "OFFER that the move check would not open"
	if result != null and not result.accepted and result.kind != MoveResult.Kind.CHAIN:
		return "a booster intent returned a refused result"
	if result != null and not result.accepted and not session.state.equals(before):
		return "a refused move changed the run"
	var names: PackedStringArray = recorder.names
	for position: int in range(signal_count, names.size()):
		if names[position] == "move_resolved":
			if position + 2 >= names.size() or names[position + 1] != "status_changed" or names[position + 2] != "save_requested":
				return "move_resolved not followed by status_changed and save_requested"
		if names[position] == "save_requested" and phase == GameSession.Phase.ENDED:
			return "save_requested in a run that ended"
	var last_end: int = -1
	var last_start: int = -1
	for position: int in names.size():
		if names[position] == "run_ended":
			last_end = position
		elif names[position] == "run_started":
			last_start = position
	if last_end > last_start:
		for position: int in range(last_end + 1, names.size()):
			if names[position] == "save_requested":
				return "save_requested after run_ended"
	return ""


## Two BigNum values that are equal, or both null.
func _same(a: BigNum, b: BigNum) -> bool:
	if a == null or b == null:
		return a == null and b == null
	return a.equals(b)
