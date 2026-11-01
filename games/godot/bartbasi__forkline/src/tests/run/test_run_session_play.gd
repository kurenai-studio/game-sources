# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## RunSession played through: whole runs twice, results, and save and restore
## (docs/ARCHITECTURE.md 3.4, 5.5, 5.6). A restored run must play on exactly like the
## run that was never interrupted.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
const Player: GDScript = preload("res://tests/run/fixtures/run_player.gd")

const DAY: String = "2026-10-23"
const DAY_SEED: int = 20261023

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _player(seed_value: int, early: int = 0, safe: bool = false) -> RefCounted:
	var p: RefCounted = Player.new(seed_value, early, safe)
	p.rich = true
	return p


## The battle and the run through their saved shapes and the JSON parser, as a game file
## would bring them back, on freshly loaded data.
func _restore(s: RunSession) -> RunSession:
	var battle_text: String = JSON.stringify(s.battle.to_data())
	var run_text: String = JSON.stringify(s.to_data())
	var loaded: Battle = Battle.from_data(JSON.parse_string(battle_text), catalog)
	assert_not_null(loaded, "the battle loads")
	var back: RunSession = RunSession.from_data(JSON.parse_string(run_text), loaded, Fx.run_data())
	assert_not_null(back, "the run loads")
	return back


## Advances the player until check returns true (before the step) or the battle is over.
func _advance_until(p: RefCounted, s: RunSession, check: Callable) -> bool:
	var guard: int = 0
	while guard < 100000:
		if check.call(s):
			return true
		if not p.advance(s):
			return false
		guard += 1
	return false


# whole runs

func test_a_whole_run_played_twice_with_the_same_seed_and_picks_ends_in_equal_state() -> void:
	for run_seed: int in [1, 2, 12345, 20261023]:
		var states: Array[String] = []
		var picks: Array = []
		for attempt: int in 2:
			var s: RunSession = Player.session(run_seed, false, "", true)
			var p: RefCounted = _player(run_seed + 7)
			assert_true(p.play(s), "the run ends")
			states.append(Player.fingerprint(s))
			picks.append(s.picks)
		assert_eq(states[0], states[1], "seed %d" % run_seed)
		assert_eq(picks[0], picks[1])
		assert_true((picks[0] as Array).size() >= 10, "a long run, %d picks" % (picks[0] as Array).size())


func test_a_whole_run_with_early_calls_is_the_same_twice() -> void:
	for run_seed: int in [3, 99]:
		var states: Array[String] = []
		var waits: int = 0
		for attempt: int in 2:
			var s: RunSession = Player.session(run_seed, false, "", true)
			var p: RefCounted = _player(run_seed, 30)
			assert_true(p.play(s))
			states.append(Player.fingerprint(s))
			waits += p.waits
		assert_eq(states[0], states[1], "seed %d" % run_seed)
		assert_true(waits > 0, "calls were refused while a draft was owed")


func test_different_seeds_play_different_runs() -> void:
	var seen: Dictionary = {}
	for run_seed: int in 6:
		var s: RunSession = Player.session(run_seed, false, "", true)
		assert_true(_player(1).play(s))
		seen[Player.fingerprint(s)] = true
	assert_eq(seen.size(), 6)


func test_a_won_run_reports_its_result() -> void:
	var s: RunSession = Player.session(2, false, "", true)
	var p: RefCounted = _player(5, 0, true)
	assert_true(p.play(s))
	var result: Dictionary = s.result()
	assert_eq(s.battle.phase, Battle.Phase.WON)
	assert_true(result["won"])
	assert_eq(result["waves"], 18)
	assert_eq(result["reached"], 18)
	assert_true(result["lives"] > 0)
	assert_eq(result["lives"], s.battle.lives)
	assert_eq(result["risks"], 0, "the careful player took no risk card")
	var risky: RunSession = Player.session(2, false, "", true)
	var q: RefCounted = _player(5)
	assert_true(q.play(risky))
	var count: int = 0
	for id: StringName in risky.picks:
		if Fx.run_data().card(id)["kind"] == &"risk":
			count += 1
	assert_eq(risky.result()["risks"], count)
	assert_true(count > 0, "this player took risk cards")


func test_a_lost_run_reports_its_result() -> void:
	var s: RunSession = Player.session(2, false, "", true)
	var p: RefCounted = Player.new(5, 0, true)
	assert_true(p.play(s))
	assert_eq(s.battle.phase, Battle.Phase.LOST)
	var result: Dictionary = s.result()
	assert_false(result["won"])
	assert_eq(result["lives"], 0)
	assert_eq(result["waves"], s.battle.result()["waves_cleared"])
	assert_eq(result["reached"], s.battle.waves_started)
	assert_true(result["reached"] > result["waves"], "it was lost during a wave")


func test_a_daily_plays_and_keeps_its_day_through_a_save() -> void:
	var s: RunSession = Player.session(DAY_SEED, false, DAY, true)
	var p: RefCounted = _player(2)
	assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.battle.waves_started == 4 and x.battle.phase == Battle.Phase.WAVE))
	var back: RunSession = _restore(s)
	assert_true(back.daily)
	assert_eq(back.day, DAY)
	assert_eq(back.run_seed, DAY_SEED)
	assert_eq(back.to_data(), s.to_data())
	assert_eq(back.pool, s.pool)
	var q: RefCounted = p.fork()
	assert_true(p.play(s))
	assert_true(q.play(back))
	assert_eq(Player.fingerprint(back), Player.fingerprint(s))
	assert_eq(back.day, DAY, "a daily still belongs to its day after it ends")


# save and restore

func test_the_saved_run_is_the_seed_the_day_the_pool_and_the_picks() -> void:
	var s: RunSession = Player.session(12345)
	var data: Dictionary = s.to_data()
	assert_eq(data.keys().size(), 6)
	assert_eq(data["format"], 1)
	assert_eq(data["tier"], 0)
	assert_eq(data["seed"], 12345)
	assert_eq(data["day"], "")
	assert_eq(data["pool"], Fx.run_data().pool({}).map(func(id: StringName) -> String: return String(id)))
	assert_eq(data["picks"], [])
	for id: Variant in data["pool"]:
		assert_eq(typeof(id), TYPE_STRING)
	assert_true(JSON.stringify(data).to_ascii_buffer().size() == JSON.stringify(data).length(), "plain ASCII")


func test_save_and_restore_mid_wave_equals_an_uninterrupted_run() -> void:
	for run_seed: int in [4, 5]:
		var s: RunSession = Player.session(run_seed, false, "", true)
		var p: RefCounted = _player(run_seed)
		assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.battle.waves_started == 5 and x.battle.phase == Battle.Phase.WAVE and x.battle.enemies.size() >= 1))
		assert_eq(s.battle.phase, Battle.Phase.WAVE)
		var back: RunSession = _restore(s)
		assert_eq(Player.fingerprint(back), Player.fingerprint(s), "equal right after the restore")
		assert_eq(back.picks, s.picks)
		assert_eq(back.risk_card(), s.risk_card())
		var q: RefCounted = p.fork()
		assert_true(p.play(s))
		assert_true(q.play(back))
		assert_eq(Player.fingerprint(back), Player.fingerprint(s), "equal at the end, seed %d" % run_seed)
		assert_eq(back.result(), s.result())
		assert_eq(q.ticks, p.ticks)


func test_save_and_restore_with_a_draft_open_equals_an_uninterrupted_run() -> void:
	for run_seed: int in [6, 7, 8]:
		var s: RunSession = Player.session(run_seed, false, "", true)
		var p: RefCounted = _player(run_seed)
		assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open() and x.battle.waves_started == 6))
		assert_true(s.draft_open())
		var offered: Array[StringName] = s.offers()
		assert_true(offered.size() >= 1)
		var back: RunSession = _restore(s)
		assert_true(back.draft_open(), "the draft is still open")
		assert_eq(back.offers(), offered, "the same offers, as nothing but the picks and the battle is saved")
		assert_eq(back.start_next_wave(), &"draft_waiting")
		assert_eq(Player.fingerprint(back), Player.fingerprint(s))
		var q: RefCounted = p.fork()
		assert_true(p.play(s))
		assert_true(q.play(back))
		assert_eq(Player.fingerprint(back), Player.fingerprint(s), "equal at the end, seed %d" % run_seed)
		assert_eq(back.picks, s.picks)


func test_save_and_restore_with_a_draft_owed_during_a_wave() -> void:
	var s: RunSession = Player.session(9, false, "", true)
	var p: RefCounted = _player(9, 15)
	var owed: Callable = func(x: RunSession) -> bool:
		return x.battle.phase == Battle.Phase.WAVE and mini(x.battle.waves_started, 17) - x.battle.running.size() > x.picks.size()
	assert_true(_advance_until(p, s, owed), "a wave was cleared while another ran")
	assert_false(s.draft_open())
	var back: RunSession = _restore(s)
	assert_false(back.draft_open())
	assert_eq(back.start_next_wave(), &"draft_waiting")
	assert_eq(s.start_next_wave(), &"draft_waiting")
	var q: RefCounted = p.fork()
	assert_true(p.play(s))
	assert_true(q.play(back))
	assert_eq(Player.fingerprint(back), Player.fingerprint(s))


## A run restored again and again, at a new moment each time, ends where the uninterrupted
## run ends: every field that matters is in the two saved shapes. Risk cards, kept card
## effects and waves called early are all in play.
func test_restoring_over_and_over_changes_nothing() -> void:
	for run_seed: int in [10, 11]:
		var whole: RunSession = Player.session(run_seed, false, "", true)
		var p: RefCounted = _player(run_seed, 40)
		assert_true(p.play(whole))
		var s: RunSession = Player.session(run_seed, false, "", true)
		var q: RefCounted = _player(run_seed, 40)
		var steps: int = 0
		var restores: int = 0
		while q.advance(s):
			steps += 1
			if steps % 97 == 0:
				var before: String = Player.fingerprint(s)
				s = _restore(s)
				assert_eq(Player.fingerprint(s), before, "equal after restore %d" % restores)
				restores += 1
		assert_true(restores > 20, "%d restores" % restores)
		assert_eq(Player.fingerprint(s), Player.fingerprint(whole), "seed %d" % run_seed)


func test_a_restored_run_can_start_the_next_wave_and_pick() -> void:
	var s: RunSession = Player.session(12, false, "", true)
	var p: RefCounted = _player(12)
	assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open() and x.battle.waves_started == 3))
	var back: RunSession = _restore(s)
	var card: StringName = back.offers()[0]
	assert_eq(back.pick(card), Battle.DONE)
	assert_eq(back.picks.size(), 3)
	assert_eq(back.start_next_wave(), Battle.DONE)
	assert_eq(back.battle.waves_started, 4)


# hostile run data

## A good saved run in the shape a file gives back (plain JSON values), its battle and the
## data, taken with a draft open and some picks made.
func _good() -> Array:
	var s: RunSession = Player.session(12, false, "", true)
	var p: RefCounted = _player(12)
	assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open() and x.battle.waves_started == 4))
	var run_data: Variant = JSON.parse_string(JSON.stringify(s.to_data()))
	var loaded: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(s.battle.to_data())), catalog)
	assert_eq((run_data as Dictionary)["picks"].size(), 3)
	return [run_data, loaded]


## Like _good(), but the pool holds only Gold Purse, an instant card, so the three picks keep
## no card effect and the picks can be changed freely without breaking the tie to the battle.
func _good_instant() -> Array:
	var data: RunData = Fx.run_data()
	var only: Array[StringName] = [&"gold_purse"]
	var s: RunSession = RunSession.start(12, "", false, only, data, catalog)
	var p: RefCounted = _player(12)
	assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open() and x.battle.waves_started == 4))
	assert_true(s.battle.card_effects.is_empty())
	var run_data: Variant = JSON.parse_string(JSON.stringify(s.to_data()))
	var loaded: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(s.battle.to_data())), catalog)
	assert_eq((run_data as Dictionary)["picks"].size(), 3)
	return [run_data, loaded]


func _refused(label: String, mutate: Callable) -> void:
	var good: Array = _good()
	var raw: Variant = good[0]
	var loaded: Battle = good[1]
	var changed: Variant = mutate.call(raw)
	if changed != null:
		raw = changed
	assert_null(RunSession.from_data(raw, loaded, Fx.run_data()), label)


func test_good_run_data_loads() -> void:
	var good: Array = _good()
	var back: RunSession = RunSession.from_data(good[0], good[1], Fx.run_data())
	assert_not_null(back)
	assert_eq(back.picks.size(), 3)
	assert_eq(back.run_seed, 12)
	assert_false(back.daily)


func test_hostile_run_data_gives_null() -> void:
	var good: Array = _good()
	assert_null(RunSession.from_data(good[0], null, Fx.run_data()), "no battle")
	assert_null(RunSession.from_data(good[0], good[1], null), "no run data")
	for junk: Variant in [null, 5, 1.5, "run", [], [1, 2], true]:
		assert_null(RunSession.from_data(junk, good[1], Fx.run_data()), "not an object: %s" % str(junk))
	_refused("empty object", func(r: Dictionary) -> Variant: return {})
	for key: String in ["format", "seed", "day", "pool", "picks"]:
		_refused("missing " + key, func(r: Dictionary) -> Variant: r.erase(key); return null)
	_refused("extra key", func(r: Dictionary) -> Variant: r["more"] = 1; return null)
	_refused("non string key", func(r: Dictionary) -> Variant: r[3] = 1; return null)
	_refused("format 2", func(r: Dictionary) -> Variant: r["format"] = 2; return null)
	_refused("format 0", func(r: Dictionary) -> Variant: r["format"] = 0; return null)
	_refused("format text", func(r: Dictionary) -> Variant: r["format"] = "1"; return null)
	_refused("format fraction", func(r: Dictionary) -> Variant: r["format"] = 1.5; return null)


func test_hostile_seeds_give_null() -> void:
	for bad: Variant in [-1, 4294967296, 1.5, "12", null, true, [12], {}, 1e30, -1e30, 9223372036854775807, INF, NAN]:
		_refused("seed %s" % str(bad), func(r: Dictionary) -> Variant: r["seed"] = bad; return null)


func test_hostile_days_give_null() -> void:
	# The good run is a normal run with seed 12, so any day other than "" is wrong for it.
	for bad: Variant in ["2026-10-23", "x", "20261023", 5, null, [], "2026-13-01", "2026-02-30", "2025-12-31", "a".repeat(11), "2026-10-23\n"]:
		_refused("day %s" % str(bad), func(r: Dictionary) -> Variant: r["day"] = bad; return null)
	# A day whose seed is not the seed, a daily saved with a Relaxed battle.
	var daily: RunSession = Player.session(DAY_SEED, false, DAY, true)
	var p: RefCounted = _player(1)
	assert_true(_advance_until(p, daily, func(x: RunSession) -> bool: return x.draft_open() and x.battle.waves_started == 2))
	var saved: Variant = JSON.parse_string(JSON.stringify(daily.to_data()))
	var loaded: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(daily.battle.to_data())), catalog)
	assert_not_null(RunSession.from_data(saved, loaded, Fx.run_data()), "the good daily loads")
	var wrong_day: Dictionary = (saved as Dictionary).duplicate(true)
	wrong_day["day"] = "2026-10-24"
	assert_null(RunSession.from_data(wrong_day, loaded, Fx.run_data()), "the seed is another day's")
	var no_day: Dictionary = (saved as Dictionary).duplicate(true)
	no_day["day"] = ""
	assert_not_null(RunSession.from_data(no_day, loaded, Fx.run_data()), "the same seed as a normal run is fine")
	var relaxed: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(Player.session(DAY_SEED, true, "", true).battle.to_data())), catalog)
	assert_null(RunSession.from_data(saved, relaxed, Fx.run_data()), "a daily is never Relaxed")


func test_hostile_pools_give_null() -> void:
	for bad: Variant in [[], null, "pool", {}, 5, [5], [""], ["Gold Purse"], ["no_such_card"], ["gold_purse", "gold_purse"], [["gold_purse"]], ["gold_purse", null], [1.5]]:
		_refused("pool %s" % str(bad), func(r: Dictionary) -> Variant: r["pool"] = bad; return null)
	_refused("pool of 257", func(r: Dictionary) -> Variant: r["pool"] = _many_ids(257); return null)
	_refused("a pick outside the pool", func(r: Dictionary) -> Variant: r["pool"] = ["gold_purse"]; return null)
	var good: Array = _good()
	var tiny: Dictionary = (good[0] as Dictionary).duplicate(true)
	tiny["pool"] = (good[0] as Dictionary)["picks"].duplicate()
	assert_not_null(RunSession.from_data(tiny, good[1], Fx.run_data()), "a pool of just the picks is a fine pool")


func test_a_saved_pool_needs_an_economy_card_that_can_be_taken_again() -> void:
	var good: Array = _good_instant()
	# Cards that are not economy cards, or economy cards that are taken only once.
	for bad: Array in [["tower_bakery"], ["sharp_pebbles", "spare_gate"], ["piggy_bank"], ["piggy_bank", "spare_gate"], ["piggy_bank", "tower_bakery", "crowded_night"]]:
		var raw: Dictionary = (good[0] as Dictionary).duplicate(true)
		raw["pool"] = bad
		raw["picks"] = []
		assert_null(RunSession.from_data(raw, good[1], Fx.run_data()), "pool %s" % str(bad))
	var ok: Dictionary = (good[0] as Dictionary).duplicate(true)
	ok["pool"] = ["piggy_bank", "gold_purse"]
	ok["picks"] = []
	assert_not_null(RunSession.from_data(ok, good[1], Fx.run_data()), "one economy card that can be taken again is enough")


func _many_ids(count: int) -> Array:
	var out: Array = []
	for i: int in count:
		out.append("card_%d" % i)
	return out


func test_hostile_picks_give_null() -> void:
	for bad: Variant in [null, "picks", {}, 5, [5], [""], ["no_such_card"], [null], [["gold_purse"]], [1.5], ["Gold Purse"]]:
		_refused("picks %s" % str(bad), func(r: Dictionary) -> Variant: r["picks"] = bad; return null)
	_refused("a once card twice", func(r: Dictionary) -> Variant: r["picks"] = ["sharp_pebbles", "sharp_pebbles", "gold_purse"]; return null)
	_refused("more picks than cleared waves", func(r: Dictionary) -> Variant: r["picks"] = _repeat("gold_purse", 5); return null)
	_refused("18 picks", func(r: Dictionary) -> Variant: r["picks"] = _repeat("gold_purse", 18); return null)
	_refused("a card the pool lacks", func(r: Dictionary) -> Variant: r["pool"] = ["gold_purse", "spare_gate"]; r["picks"] = ["gold_purse", "tower_bakery"]; return null)
	var good: Array = _good_instant()
	var again: Dictionary = (good[0] as Dictionary).duplicate(true)
	again["picks"] = ["gold_purse", "gold_purse", "gold_purse"]
	assert_not_null(RunSession.from_data(again, good[1], Fx.run_data()), "a card that can be taken again, taken again")
	var fewer: Dictionary = (good[0] as Dictionary).duplicate(true)
	fewer["picks"] = []
	assert_not_null(RunSession.from_data(fewer, good[1], Fx.run_data()), "fewer picks than cleared waves is a draft still owed")


func _repeat(id: String, count: int) -> Array:
	var out: Array = []
	for i: int in count:
		out.append(id)
	return out


func test_a_pick_for_a_wave_not_yet_cleared_gives_null() -> void:
	# At the start nothing is cleared, so even one pick is too many.
	var fresh: RunSession = Player.session(5, false, "", true)
	var saved: Variant = JSON.parse_string(JSON.stringify(fresh.to_data()))
	var loaded: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(fresh.battle.to_data())), catalog)
	assert_not_null(RunSession.from_data(saved, loaded, Fx.run_data()))
	(saved as Dictionary)["picks"] = ["gold_purse"]
	assert_null(RunSession.from_data(saved, loaded, Fx.run_data()))
	# During wave 1, still nothing cleared.
	var playing: RunSession = Player.session(5, false, "", true)
	playing.start_next_wave()
	var wave: Variant = JSON.parse_string(JSON.stringify(playing.to_data()))
	var wave_battle: Battle = Battle.from_data(JSON.parse_string(JSON.stringify(playing.battle.to_data())), catalog)
	assert_not_null(RunSession.from_data(wave, wave_battle, Fx.run_data()))
	(wave as Dictionary)["picks"] = ["gold_purse"]
	assert_null(RunSession.from_data(wave, wave_battle, Fx.run_data()))


func test_a_failed_load_changes_nothing_in_the_inputs() -> void:
	var good: Array = _good()
	var run_data: Dictionary = good[0]
	var before: String = JSON.stringify(run_data)
	var battle_before: String = JSON.stringify((good[1] as Battle).to_data())
	run_data["seed"] = -5
	var copy: String = JSON.stringify(run_data)
	assert_null(RunSession.from_data(run_data, good[1], Fx.run_data()))
	assert_eq(JSON.stringify(run_data), copy)
	assert_eq(JSON.stringify((good[1] as Battle).to_data()), battle_before)
	assert_ne(copy, before)
