# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Saved runs and dailies: the run around the saved battle, checked all or nothing, and a
## restored run that plays on like one never saved (docs/ARCHITECTURE.md 3.4, 3.5, 5.5,
## 5.6, 6; RULES 14, 15). The run data is the real data in data/.

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")

const DAY: String = "2026-10-23"
const DAY_SEED: int = 20261023

var game: GameData = null
var store: SaveStore = null


func before_each() -> void:
	Fx.fresh()
	game = Fx.game()
	store = SaveStore.new(Fx.WORK)


func after_each() -> void:
	store = null
	Fx.clean()


## A run (day "") or daily played until check(session) is true.
func _played(run_seed: int, day: String, check: Callable) -> RunSession:
	var session: RunSession = Fx.session(game, run_seed, day)
	assert_not_null(session, "the run starts")
	assert_true(Fx.play_until(session, Fx.player(run_seed), check), "the run reaches the moment")
	return session


## A run with two cards picked and the draft after wave 3 open.
func _with_picks(run_seed: int = 12, day: String = "") -> RunSession:
	return _played(run_seed, day, func(s: RunSession) -> bool: return s.draft_open() and s.picks.size() == 2)


## Writes the data to its mode's file and loads every saved game with a new store.
func _load_written(data: Dictionary) -> Array[SavedGame]:
	var mode: StringName = StringName(String(data.get("mode", "run")))
	Fx.write_text(SaveStore.GAME_FILES.get(mode, "game_run.json"), JSON.stringify(data))
	return SaveStore.new(Fx.WORK).load_games(game)


## The data is refused through the store, and its file is deleted.
func _assert_refused(data: Dictionary, label: String) -> void:
	var file_name: String = SaveStore.GAME_FILES.get(StringName(String(data.get("mode", "run"))), "game_run.json")
	assert_eq(_load_written(data).size(), 0, label)
	assert_false(Fx.exists(file_name), "%s: deleted" % label)


## The saved game's data with one change to its run.
func _with_run(base: Dictionary, change: Dictionary) -> Dictionary:
	var data: Dictionary = base.duplicate(true)
	(data["run"] as Dictionary).merge(change, true)
	return data


# round trips

func test_a_run_with_picks_and_an_open_draft_round_trips() -> void:
	var session: RunSession = _with_picks()
	var offered: Array[StringName] = session.offers()
	assert_true(store.save_game(Fx.saved_run(session)))
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(loaded.size(), 1)
	var back: RunSession = loaded[0].run
	assert_not_null(back)
	assert_eq(loaded[0].mode, SavedGame.RUN)
	assert_eq(back.run_seed, session.run_seed)
	assert_eq(back.day, "")
	assert_false(back.daily)
	assert_eq(back.pool, session.pool)
	assert_eq(back.picks, session.picks)
	assert_true(back.draft_open(), "the draft is still open")
	assert_eq(back.offers(), offered, "with the same offers")
	assert_eq(Fx.run_text(back), Fx.run_text(session))


func test_a_daily_round_trips_with_its_day() -> void:
	var session: RunSession = _with_picks(DAY_SEED, DAY)
	assert_true(store.save_game(Fx.saved_run(session)))
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(loaded.size(), 1)
	assert_eq(loaded[0].mode, SavedGame.DAILY)
	assert_true(loaded[0].run.daily)
	assert_eq(loaded[0].run.day, DAY)
	assert_eq(loaded[0].run.run_seed, DAY_SEED)
	assert_eq(loaded[0].run.pool, game.run.card_ids(), "the daily uses every card")
	assert_eq(Fx.run_text(loaded[0].run), Fx.run_text(session))


func test_the_saved_run_is_plain_data_in_the_contract_shape() -> void:
	var data: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var run: Dictionary = data["run"]
	assert_eq(run.keys().size(), 6)
	for key: String in ["format", "seed", "day", "pool", "picks", "tier"]:  # tier since A12 (contract 14.7)
		assert_true(run.has(key), key)
	assert_eq(run["picks"].size(), 2)
	assert_eq(data["level_id"], "")
	assert_eq(data["twist"], false)
	var text: String = JsonFile.to_text(Fx.saved_run(_with_picks()).to_data())
	assert_false(text.is_empty(), "plain ASCII")
	assert_true(text.length() < SaveStore.GAME_CAP)


# playing on

func test_a_restored_run_plays_on_equal_to_an_unbroken_run() -> void:
	var moments: Dictionary = {
		"mid wave": func(s: RunSession) -> bool: return s.battle.waves_started >= 5 and s.battle.phase == Battle.Phase.WAVE and s.battle.enemies.size() >= 1,
		"draft open": func(s: RunSession) -> bool: return s.draft_open() and s.battle.waves_started == 7,
		"build phase after a pick": func(s: RunSession) -> bool: return s.draft_open() and s.picks.size() == 3,
	}
	var run_seed: int = 40
	for name: String in moments:
		run_seed += 1
		Fx.fresh()
		store = SaveStore.new(Fx.WORK)
		var session: RunSession = Fx.session(game, run_seed)
		var p: RefCounted = Fx.player(run_seed)
		assert_true(Fx.play_until(session, p, moments[name]), name)
		if name == "build phase after a pick":
			assert_eq(session.pick(session.offers()[0]), Battle.DONE)
			assert_eq(session.battle.phase, Battle.Phase.BUILD)
		assert_true(store.save_game(Fx.saved_run(session)), name)
		var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(Fx.game())
		assert_eq(loaded.size(), 1, name)
		if loaded.is_empty():
			continue
		var back: RunSession = loaded[0].run
		assert_eq(Fx.run_text(back), Fx.run_text(session), "%s: equal right after the restore" % name)
		var q: RefCounted = p.fork()
		assert_true(p.play(session), "%s: the run ends" % name)
		assert_true(q.play(back), "%s: the restored run ends" % name)
		assert_eq(Fx.run_text(back), Fx.run_text(session), "%s: equal at the end" % name)
		assert_eq(back.result(), session.result(), name)
		assert_eq(back.picks, session.picks, name)


func test_saving_and_loading_again_and_again_changes_nothing() -> void:
	var session: RunSession = Fx.session(game, 55)
	var twin: RunSession = Fx.session(game, 55)
	var p: RefCounted = Fx.player(55)
	var q: RefCounted = Fx.player(55)
	var current: RunSession = twin
	for turn: int in 6:
		for i: int in 150:
			p.advance(session)
			q.advance(current)
		if current.battle.phase != Battle.Phase.BUILD and current.battle.phase != Battle.Phase.WAVE:
			break
		assert_true(store.save_game(Fx.saved_run(current)), "round %d" % turn)
		store = SaveStore.new(Fx.WORK)
		var loaded: Array[SavedGame] = store.load_games(game)
		assert_eq(loaded.size(), 1, "round %d" % turn)
		current = loaded[0].run
		assert_eq(Fx.run_text(current), Fx.run_text(session), "round %d" % turn)


# the daily and the clock

func test_a_daily_resumed_after_midnight_keeps_its_day() -> void:
	# The daily of 2026-10-23 is saved mid-wave late that night and resumed on 2026-10-24.
	var session: RunSession = _played(DAY_SEED, DAY, func(s: RunSession) -> bool:
		return s.battle.waves_started >= 4 and s.battle.phase == Battle.Phase.WAVE)
	assert_true(store.save_game(Fx.saved_run(session)))
	var next_launch: SaveStore = SaveStore.new(Fx.WORK)
	var loaded: Array[SavedGame] = next_launch.load_games(game)
	assert_eq(loaded.size(), 1)
	var back: RunSession = loaded[0].run
	assert_eq(back.day, DAY, "the daily still belongs to the day it started")
	assert_eq(back.run_seed, DAY_SEED, "and plays that day's seed")
	# Saved again on the new day, it still keeps its day.
	assert_true(next_launch.save_game(loaded[0]))
	back = SaveStore.new(Fx.WORK).load_games(game)[0].run
	assert_eq(back.day, DAY)
	assert_true(Fx.player(3).play(back), "the daily ends")
	var record: DailyRecord = DailyRecord.new()
	record.record_finish("2026-10-22", {"won": false, "waves": 5, "lives": 0})
	var result: Dictionary = back.result()
	record.record_finish(back.day, result)
	assert_eq(record.day, DAY, "the result counts for the day the daily started")
	assert_eq(record.best, {"won": result["won"], "waves": result["waves"], "lives": result["lives"]})
	assert_eq(record.streak, 2, "and keeps the streak going")
	assert_eq(record.streak_day, DAY)
	assert_eq(Daily.shown_streak(record.streak, record.streak_day, "2026-10-24"), 2, "still shown the next day")
	record.record_finish("2026-10-24", {"won": false, "waves": 1, "lives": 0})
	assert_eq(record.day, "2026-10-24", "today's own daily then takes over")
	assert_eq(record.streak, 3)


func test_mode_daily_needs_a_day_and_mode_run_none() -> void:
	var daily: Dictionary = Fx.through_json(Fx.saved_run(Fx.daily(game, DAY)).to_data())
	var as_run: Dictionary = daily.duplicate(true)
	as_run["mode"] = "run"
	_assert_refused(as_run, "a daily in the run's file")
	var run: Dictionary = Fx.through_json(Fx.saved_run(Fx.session(game, DAY_SEED)).to_data())
	var as_daily: Dictionary = run.duplicate(true)
	as_daily["mode"] = "daily"
	_assert_refused(as_daily, "a run in the daily's file, even with a daily's seed")
	assert_eq(_load_written(daily).size(), 1, "the daily itself loads")
	assert_eq(_load_written(run).size(), 2, "and the run too")


# hostile run fields

func test_hostile_seeds_are_refused() -> void:
	var base: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var cases: Dictionary = {
		"negative": -1, "past 2^32 - 1": 4294967296.0, "huge": 1e300, "fraction": 12.5,
		"text": "12", "null": null, "bool": true, "list": [12], "object": {"seed": 12},
	}
	for name: String in cases:
		_assert_refused(_with_run(base, {"seed": cases[name]}), "seed %s" % name)
	_assert_refused(_with_run(base, {"seed": INF}), "seed infinite")
	var text: String = JSON.stringify(_with_run(base, {"seed": "SEED"})).replace("\"SEED\"", "1e999")
	assert_true(text.contains(":1e999"))
	Fx.write_text("game_run.json", text)
	assert_eq(SaveStore.new(Fx.WORK).load_games(game).size(), 0, "seed 1e999 in the file")
	assert_eq(_load_written(_with_run(base, {"seed": 4294967295.0})).size(), 1, "the highest seed loads")


func test_hostile_days_are_refused() -> void:
	var run: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var daily: Dictionary = Fx.through_json(Fx.saved_run(_with_picks(DAY_SEED, DAY)).to_data())
	_assert_refused(_with_run(run, {"day": DAY}), "a day that is not the seed's")
	var cases: Dictionary = {
		"empty on a daily": "", "the next day": "2026-10-24", "not a date": "2026-02-30",
		"before 2026": "2025-12-31", "after 2200": "2201-01-01", "no dashes": "20261023",
		"number": 20261023, "path": "../2026-10-23", "long": DAY + " ", "null": null, "list": [DAY],
	}
	for name: String in cases:
		_assert_refused(_with_run(daily, {"day": cases[name]}), "day %s" % name)
	assert_eq(_load_written(daily).size(), 1, "the untouched daily loads")


func test_hostile_pools_are_refused() -> void:
	var base: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var pool: Array = base["run"]["pool"]
	var repeats: Array = pool.duplicate()
	repeats.append(pool[0])
	var unknown: Array = pool.duplicate()
	unknown.append("golden_goose")
	var too_long: Array = []
	for i: int in 257:
		too_long.append("card_%d" % i)
	var cases: Dictionary = {
		"empty": [], "repeats": repeats, "an unknown card": unknown, "257 entries": too_long,
		"text": "spare_gate", "numbers": [1, 2], "a path": ["../stats/rules"], "a null": [null],
		"objects": [{"id": "spare_gate"}], "null": null,
	}
	for name: String in cases:
		_assert_refused(_with_run(base, {"pool": cases[name]}), "pool %s" % name)
	var without_picks: Array = []
	for id: Variant in pool:
		if not (base["run"]["picks"] as Array).has(id):
			without_picks.append(id)
	_assert_refused(_with_run(base, {"pool": without_picks}), "a pool without the picked cards")
	assert_eq(_load_written(base).size(), 1, "the untouched run loads")


func test_hostile_picks_are_refused() -> void:
	var base: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var picks: Array = base["run"]["picks"]
	var too_many: Array = picks.duplicate()
	too_many.append_array(["gold_purse", "gold_purse"])
	var eighteen: Array = []
	for i: int in 18:
		eighteen.append("gold_purse")
	var cases: Dictionary = {
		"a card not in the pool": picks + ["golden_goose"],
		"more picks than cleared waves": too_many,
		"18 picks": eighteen,
		"a once card twice": ["sharp_pebbles", "sharp_pebbles"],
		"text": "gold_purse", "numbers": [3], "a path": ["../x"], "null": null,
	}
	for name: String in cases:
		_assert_refused(_with_run(base, {"picks": cases[name]}), "picks %s" % name)
	# Three cleared waves allow three picks, and a card that is not once may come again.
	# The picks are real, so the battle's card effects match them (5.6).
	var three: RunSession = _three_picks_with_a_repeat()
	assert_not_null(three, "a run picks a card that is not once twice in three picks")
	if three == null:
		return
	assert_eq(int(three.battle.to_data()["record"]["waves_cleared"]), 3, "three waves cleared")
	assert_eq(three.picks.size(), 3)
	assert_eq(_load_written(Fx.through_json(Fx.saved_run(three).to_data())).size(), 1, "three picks after three cleared waves")


## A run whose three picks, after three cleared waves, take a card that is not once
## twice. Tries seeds in order, so it always finds the same run.
func _three_picks_with_a_repeat() -> RunSession:
	var choose: Callable = func(s: RunSession, offers: Array[StringName]) -> StringName:
		for id: StringName in offers:
			if s.picks.has(id) and not s.card(id)["once"]:
				return id
		return &"gold_purse" if offers.has(&"gold_purse") else &""
	for run_seed: int in range(1, 200):
		var s: RunSession = Fx.run_with(game, run_seed, choose, func(at: RunSession) -> bool: return at.picks.size() == 3)
		if s == null:
			continue
		for id: StringName in s.picks:
			if s.picks.count(id) > 1:
				return s
	return null


func test_hostile_run_shapes_are_refused() -> void:
	var base: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var shapes: Dictionary = {
		"run null": null, "run text": "run", "run list": [], "run empty": {},
	}
	for name: String in shapes:
		var data: Dictionary = base.duplicate(true)
		data["run"] = shapes[name]
		_assert_refused(data, name)
	_assert_refused(_with_run(base, {"format": 2}), "format 2")
	_assert_refused(_with_run(base, {"format": "1"}), "format as text")
	_assert_refused(_with_run(base, {"cheat": true}), "an extra key")
	var missing: Dictionary = base.duplicate(true)
	(missing["run"] as Dictionary).erase("picks")
	_assert_refused(missing, "a missing key")
	var with_level: Dictionary = base.duplicate(true)
	with_level["level_id"] = "r1_l1"
	_assert_refused(with_level, "a run naming a campaign level")
	var twisted: Dictionary = base.duplicate(true)
	twisted["twist"] = true
	_assert_refused(twisted, "a run claiming a Twist")


func test_a_campaign_level_holds_no_run() -> void:
	var level: SavedGame = Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 40))
	var data: Dictionary = Fx.through_json(level.to_data())
	assert_eq(_load_written(data).size(), 1, "the plain level loads")
	data["run"] = Fx.through_json(Fx.session(game, 3).to_data())
	_assert_refused(data, "a campaign level with a run")


func test_runs_need_run_data() -> void:
	var data: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	assert_not_null(SavedGame.from_data(data, game))
	game.run = null
	assert_null(SavedGame.from_data(data, game), "no run data, no run")


func test_a_failed_load_leaves_the_input_alone() -> void:
	var base: Dictionary = Fx.through_json(Fx.saved_run(_with_picks()).to_data())
	var bad: Dictionary = _with_run(base, {"picks": ["sharp_pebbles", "sharp_pebbles"]})
	var before: String = JSON.stringify(bad)
	assert_null(SavedGame.from_data(bad, game))
	assert_eq(JSON.stringify(bad), before)
