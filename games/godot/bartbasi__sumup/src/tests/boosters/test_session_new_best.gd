extends "res://tests/base_test.gd"
## The New best badge (GDD 12.3, 15.1, QA6-03): each run keeps the Best Score
## from when it began in state.best_at_start, so the badge survives closing
## and reopening the app. The session part of AT-145; the save file part is a
## save test (TH18).

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/boosters/booster_fixtures.gd")

var recorder: BF.Recorder


func before_each() -> void:
	recorder = BF.Recorder.new()


## A session over a copy of state, resumed with records and shown, recorder on.
func _session(state: RunState, records: Records, seed_value: int = 1) -> GameSession:
	var session: GameSession = BF.ready_session(state, records, seed_value)
	recorder.watch(session)
	return session


## The AT-145 run file: Board D1024, score 5,000, no snapshot, and the given
## Best Score when the run began (-1 for a file saved before the rule).
func _at_145_run(best_at_start: int) -> RunState:
	return BF.make(BF.board_d1024(), 5000, PackedInt64Array(), 0, 0, 5, 0, best_at_start)


func test_start_new_run_keeps_the_best_score_from_before_the_run() -> void:
	var session: GameSession = GameSession.new(null, null, F.records(777, 16))
	session.start_new_run()
	assert_eq(BF.n(session.state.best_at_start), 777, "the Best Score before the run")
	session.move_shown()
	session.start_new_run()
	assert_eq(BF.n(session.state.best_at_start), 777, "a second run starts from the record as it is then")


func test_resume_keeps_the_saved_best_at_start() -> void:
	var saved: RunState = _at_145_run(4000)
	var session: GameSession = GameSession.new(null, null, F.records(5000, 1024))
	session.resume(saved)
	assert_eq(BF.n(session.state.best_at_start), 4000, "the saved value is kept")
	assert_eq(BF.n(saved.best_at_start), 4000, "the saved object is not changed")


func test_resume_without_best_at_start_takes_the_loaded_best_score() -> void:
	var session: GameSession = GameSession.new(null, null, F.records(5000, 1024))
	session.resume(_at_145_run(-1))
	assert_eq(BF.n(session.state.best_at_start), 5000, "-1: the Best Score loaded with the run")
	var higher: GameSession = GameSession.new(null, null, F.records(3000, 1024))
	higher.resume(_at_145_run(-1))
	assert_eq(BF.n(higher.state.best_at_start), 3000, "the value loaded, from before the resume raises it to the run's score")
	assert_eq(BF.n(higher.records.best_score), 5000, "the resume then raises Best Score to the run's 5,000")


func test_at_145_new_best_survives_a_restart() -> void:
	var cases: Array[Array] = [
		[4000, true, "(a) the run raised the record from 4,000 to 5,000"],
		[5000, false, "(b) the run only equalled the record"],
		[-1, false, "(c) no starting Best Score in the file: the old behaviour"],
	]
	for each: Array in cases:
		recorder.clear()
		var session: GameSession = _session(_at_145_run(each[0]), F.records(5000, 1024))
		assert_true(session.is_offer_open(), "%s: the run resumes and the offer opens" % each[2])
		session.end_run()
		assert_eq(recorder.summaries.size(), 1, "%s: the run ended" % each[2])
		assert_eq(recorder.summaries[0].new_best_score, each[1], "%s: New best" % each[2])
		assert_eq(BF.n(recorder.summaries[0].best_score), 5000, "%s: Best Score 5,000" % each[2])


## The Play part of AT-145 on the session: a new Best Score, a booster that
## drops the score below it, a restart, then End run without passing it again.
func test_at_145_new_best_survives_a_restart_in_a_real_run() -> void:
	var board: PackedInt64Array = F.changed(F.board_e(), {Vector2i(4, 6): 1024, Vector2i(4, 7): 1024})
	var records: Records = F.records(11000, 1024)
	var session: GameSession = _session(BF.make(board, 10000, PackedInt64Array(), 0, 0, 5, 0, 11000), records, 145)
	session.rng.script_spawns(F.ev(PackedInt64Array([8, 4])))
	var chain: MoveResult = session.commit_chain(BF.targets([Vector2i(4, 6), Vector2i(4, 7)]))
	assert_eq(BF.n(session.state.score), 12048, "the chain makes 12,048")
	assert_true(chain.new_best_score, "a new Best Score")
	assert_eq(BF.n(records.best_score), 12048, "Best Score 12,048")
	assert_true(chain.offer_opens, "the board has no valid move after it")
	session.move_shown()
	session.press_booster(BoosterRules.HAMMER)
	var hammered: MoveResult = session.tap_cell(Vector2i(0, 0))
	assert_eq(BF.n(hammered.cost), 2048, "a Hammer for 2,048")
	assert_eq(BF.n(session.state.score), 10000, "drops the score below the record")
	assert_true(hammered.offer_opens, "and the offer opens again")
	session.move_shown()
	var saved: RunState = session.state.copy()
	var saved_records: Records = records.copy()
	recorder.clear()
	var reopened: GameSession = _session(saved, saved_records, 146)
	assert_true(reopened.is_offer_open(), "after the restart the offer opens")
	assert_eq(BF.n(reopened.state.best_at_start), 11000, "the run still began at 11,000")
	reopened.end_run()
	var summary: RunSummary = recorder.summaries[0]
	assert_eq(BF.n(summary.final_score), 10000, "final score 10,000")
	assert_eq(BF.n(summary.best_score), 12048, "Best Score 12,048")
	assert_true(summary.new_best_score, "the badge shows")


func test_a_run_that_never_beat_the_record_gets_no_badge() -> void:
	var session: GameSession = _session(_at_145_run(9000), F.records(9000, 1024))
	session.end_run()
	assert_false(recorder.summaries[0].new_best_score, "5,000 never beat 9,000")


func test_undo_and_the_other_boosters_never_touch_best_at_start() -> void:
	var config: GameConfig = GameConfig.new()
	var board: PackedInt64Array = F.changed(F.board_d(), {Vector2i(2, 0): 512, Vector2i(1, 7): 8, Vector2i(2, 7): 16})
	var state: RunState = BF.make(board, 3000, PackedInt64Array(), 0, 0, 5, 0, 2500)
	var records: Records = F.records(2500, 512)
	var rng: RunRandom = F.seeded(3)
	RunRules.commit_chain(state, records, BF.targets([Vector2i(0, 7), Vector2i(1, 7), Vector2i(2, 7)]), rng, config)
	var steps: Array[Array] = [
		[BoosterRules.HAMMER, [Vector2i(4, 0)]],
		[BoosterRules.SWAP, [Vector2i(3, 0), Vector2i(3, 1)]],
		[BoosterRules.SHUFFLE, []],
		[BoosterRules.UNDO, []],
	]
	for step: Array in steps:
		var result: MoveResult = BoosterRules.apply(step[0], state, records, BF.targets(step[1]), rng, config)
		assert_true(result.accepted, "%s accepted" % step[0])
		assert_eq(BF.n(state.best_at_start), 2500, "%s leaves best_at_start alone" % step[0])
	assert_eq(state.cells, board, "the Undo went back to before the chain")


# The safety net (docs/ARCHITECTURE.md section 10): SaveCodec refuses to write
# a state whose best_at_start is unknown (null, -1 before section 17), and a
# refused save during play would lose the run. So the session's state never
# holds null.

## Fails unless the session's state holds expected, which is never null.
func _assert_set(session: GameSession, expected: int, label: String) -> void:
	assert_not_null(session.state.best_at_start, "%s: never unknown" % label)
	assert_eq(BF.n(session.state.best_at_start), expected, "%s: best_at_start" % label)


## A cell whose value differs from the value on first, for Swap's second tap.
func _other_value(session: GameSession, first: Vector2i) -> Vector2i:
	for index: int in session.state.cells.size():
		var cell: Vector2i = CoreRules.cell_of(index, session.config.columns)
		if session.state.value_at(cell) != session.state.value_at(first):
			return cell
	return BF.NO_CELL


## A booster through the session: the tap on it, then the tile taps.
func _use(session: GameSession, id: StringName, taps: Array[Vector2i]) -> MoveResult:
	var result: MoveResult = session.press_booster(id)
	for cell: Vector2i in taps:
		result = session.tap_cell(cell)
	return result


func test_the_session_state_never_holds_best_at_start_minus_1() -> void:
	_assert_set(GameSession.new(), 0, "a new session's empty state")
	var fresh: GameSession = GameSession.new(null, null, F.records(777, 16))
	_assert_set(fresh, 777, "before any run")
	fresh.start_new_run()
	_assert_set(fresh, 777, "after start_new_run()")
	var empty: GameSession = GameSession.new()
	empty.start_new_run()
	_assert_set(empty, 0, "after start_new_run() with no records yet")
	var format_1: GameSession = GameSession.new(null, null, F.records(5000, 1024))
	format_1.resume(_at_145_run(-1))
	_assert_set(format_1, 5000, "after resume() of a -1 state (format 1): the loaded Best Score")
	var no_records: GameSession = GameSession.new()
	no_records.resume(_at_145_run(-1))
	_assert_set(no_records, 0, "after resume() of a -1 state with no records yet")
	var format_2: GameSession = GameSession.new(null, null, F.records(5000, 1024))
	format_2.resume(_at_145_run(4000))
	_assert_set(format_2, 4000, "after resume() of a real value: kept")


func test_no_move_ever_sets_best_at_start_to_minus_1() -> void:
	var session: GameSession = BF.ready_session(BF.make(F.board_p(), 50000), F.records(60000, 32), 7)
	_assert_set(session, 60000, "after the resume of a -1 state")
	var chain: MoveResult = session.commit_chain(BF.targets([Vector2i(1, 6), Vector2i(2, 6), Vector2i(3, 6), Vector2i(2, 5)]))
	assert_true(chain.accepted, "the chain commits")
	_assert_set(session, 60000, "after a chain")
	session.move_shown()
	for id: StringName in BoosterRules.ALL:
		var taps: Array[Vector2i] = []
		if id == BoosterRules.HAMMER or id == BoosterRules.DOUBLE:
			taps = [Vector2i(0, 0)]
		elif id == BoosterRules.SWAP:
			taps = [Vector2i(0, 0), _other_value(session, Vector2i(0, 0))]
		var result: MoveResult = _use(session, id, taps)
		assert_true(result != null and result.accepted, "%s applies" % id)
		_assert_set(session, 60000, "after %s" % id)
		session.move_shown()
		_assert_set(session, 60000, "after %s is shown" % id)
	assert_eq(session.state.cells, F.board_p(), "the Undo restored the board from before the chain")
	assert_false(session.state.has_snapshot(), "and cleared the snapshot, but not best_at_start")
