# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## RunSession: starting a run, owed drafts, eligibility, the draw and picks
## (docs/ARCHITECTURE.md 3.4, RULES 14.4). Saves and whole runs are in test_run_session_play.gd.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
const Player: GDScript = preload("res://tests/run/fixtures/run_player.gd")

const DAY: String = "2026-10-23"
const DAY_SEED: int = 20261023

var catalog: Catalog = null
var data: RunData = null


func before_each() -> void:
	catalog = Fx.catalog()
	data = Fx.run_data()


## A session on the fixtures with a pool of the given cards.
func _with_pool(run_seed: int, ids: Array[StringName]) -> RunSession:
	return RunSession.start(run_seed, "", false, ids, data, catalog)


## Shortcut for tests of the draw. Makes the draft that follows wave `draft` the open one,
## as if waves 1 to `draft` had been cleared and the picks so far were `fake_picks`. Only
## the numbers the draw reads are set, so a test that does this never starts a wave.
func _open(s: RunSession, draft: int, fake_picks: Array[StringName] = [], started: int = -1) -> void:
	var got: Array[StringName] = fake_picks
	if got.is_empty():
		for i: int in draft - 1:
			got.append(&"gold_purse")
	assert_eq(got.size(), draft - 1, "one pick for each draft before this one")
	s.picks = got
	s.battle.waves_started = draft if started < 0 else started


## A real wave 1, played on a fortified map, ending in a build phase with the first draft open.
func _after_wave_one(ids: Array[StringName], run_seed: int = 1) -> RunSession:
	var s: RunSession = _with_pool(run_seed, ids)
	var p: RefCounted = Player.new(9, 0, true)
	p.rich = true
	for i: int in 3:
		p.build_phase(s)
	assert_eq(s.start_next_wave(), Battle.DONE)
	var guard: int = 0
	while s.battle.phase == Battle.Phase.WAVE and guard < 20000:
		s.battle.step()
		guard += 1
	assert_eq(s.battle.phase, Battle.Phase.BUILD, "wave 1 was cleared")
	return s


## Every card offered by the draft that follows wave `draft`, over many seeds.
func _seen(draft: int, every_card: bool, seeds: int = 150) -> Dictionary:
	var seen: Dictionary = {}
	for run_seed: int in seeds:
		var s: RunSession = Player.session(run_seed, false, "", every_card)
		_open(s, draft)
		for id: StringName in s.offers():
			seen[id] = true
	return seen


func _kind(id: StringName) -> StringName:
	return data.card(id)["kind"]


# starting a run

func test_a_new_run_starts_in_a_build_phase_with_the_run_plan() -> void:
	var s: RunSession = Player.session(12345)
	assert_not_null(s)
	assert_eq(s.run_seed, 12345)
	assert_false(s.daily)
	assert_eq(s.day, "")
	assert_eq(s.pool, data.pool({}))
	assert_eq(s.picks, [])
	assert_eq(s.battle.phase, Battle.Phase.BUILD)
	assert_false(s.battle.relaxed)
	assert_eq(s.battle.level.id, &"run")
	assert_eq(s.battle.gold, 300)
	assert_eq(s.battle.lives, 20)
	assert_eq(s.battle.gates_in_hand, 1)
	assert_eq(s.battle.wave_count(), 18)
	assert_false(s.draft_open())
	assert_eq(s.offers(), [])
	assert_eq(s.risk_card(), &"")
	assert_eq(s.result(), {"won": false, "waves": 0, "lives": 20, "reached": 0, "risks": 0})


func test_relaxed_gives_more_lives_and_gold() -> void:
	var s: RunSession = Player.session(12345, true)
	assert_true(s.battle.relaxed)
	assert_eq(s.battle.lives, 40)
	assert_eq(s.battle.gold, 450)


func test_the_session_keeps_its_own_copy_of_the_pool() -> void:
	var ids: Array[StringName] = [&"gold_purse", &"spare_gate"]
	var s: RunSession = _with_pool(5, ids)
	ids.clear()
	assert_eq(s.pool, [&"gold_purse", &"spare_gate"])


func test_the_same_seed_gives_an_equal_run_and_other_seeds_differ() -> void:
	var seen: Dictionary = {}
	for run_seed: int in [0, 1, 77, 12345, 4294967295]:
		var first: String = Player.fingerprint(Player.session(run_seed))
		assert_eq(Player.fingerprint(Player.session(run_seed)), first, "seed %d" % run_seed)
		seen[first] = true
	assert_eq(seen.size(), 5)


func test_a_daily_belongs_to_its_day() -> void:
	var s: RunSession = Player.session(DAY_SEED, false, DAY, true)
	assert_not_null(s)
	assert_true(s.daily)
	assert_eq(s.day, DAY)
	assert_eq(s.run_seed, DAY_SEED)
	assert_eq(s.pool, data.card_ids(), "the daily uses every card")
	assert_false(s.battle.relaxed)
	assert_eq(Player.fingerprint(s), Player.fingerprint(Player.session(DAY_SEED, false, DAY, true)), "the same day, the same run")


func test_a_daily_that_breaks_the_rules_does_not_start() -> void:
	assert_null(Player.session(DAY_SEED, true, DAY, true), "a daily is never Relaxed")
	assert_null(Player.session(DAY_SEED + 1, false, DAY, true), "the seed is the day's")
	assert_null(Player.session(DAY_SEED, false, "2026-10-24", true), "a seed that is another day's")
	for bad: String in ["20261023", "2026-1-23", "2026-13-01", "2026-02-30", "2025-12-31", "2201-01-01", "abcd-ef-gh", "2026-10-23 ", " 2026-10-23", "2026-10-231"]:
		assert_null(Player.session(DAY_SEED, false, bad, true), "day '%s' is not a day key" % bad)
	assert_null(Player.session(20261301, false, "2026-13-01", true), "a seed that fits a bad day")
	assert_not_null(Player.session(DAY_SEED, false, "", true), "an empty day is a normal run")


func test_start_refuses_bad_input() -> void:
	var ids: Array[StringName] = data.pool({})
	assert_null(RunSession.start(-1, "", false, ids, data, catalog))
	assert_null(RunSession.start(4294967296, "", false, ids, data, catalog))
	assert_null(RunSession.start(9223372036854775807, "", false, ids, data, catalog))
	assert_not_null(RunSession.start(0, "", false, ids, data, catalog))
	assert_not_null(RunSession.start(4294967295, "", false, ids, data, catalog))
	assert_null(RunSession.start(1, "", false, ids, null, catalog))
	assert_null(RunSession.start(1, "", false, ids, data, null))
	var none: Array[StringName] = []
	assert_null(RunSession.start(1, "", false, none, data, catalog), "an empty pool")
	var unknown: Array[StringName] = [&"gold_purse", &"no_such_card"]
	assert_null(RunSession.start(1, "", false, unknown, data, catalog))
	var repeated: Array[StringName] = [&"gold_purse", &"gold_purse"]
	assert_null(RunSession.start(1, "", false, repeated, data, catalog))
	var broken: RunData = Fx.run_data()
	broken.packs = []
	assert_null(RunSession.start(1, "", false, ids, broken, catalog), "the map cannot be built")


## A draft can never be empty: economy cards are always eligible, so the pool needs one that
## can be taken again.
func test_a_pool_needs_an_economy_card_that_can_be_taken_again() -> void:
	var bad_pools: Array = [
		[&"tower_bakery"],
		[&"sharp_pebbles", &"spare_gate"],
		[&"crowded_night", &"flock", &"tower_lullaby_bell"],
		[&"piggy_bank"],
		[&"piggy_bank", &"spare_gate", &"tower_bakery"],
	]
	for bad: Array in bad_pools:
		var ids: Array[StringName] = []
		ids.assign(bad)
		assert_null(RunSession.start(1, "", false, ids, data, catalog), "pool %s" % str(bad))
	var good_pools: Array = [[&"gold_purse"], [&"piggy_bank", &"gold_purse"], [&"tower_bakery", &"gold_purse", &"crowded_night"]]
	for good: Array in good_pools:
		var ids: Array[StringName] = []
		ids.assign(good)
		assert_not_null(RunSession.start(1, "", false, ids, data, catalog), "pool %s" % str(good))
	assert_not_null(RunSession.start(1, "", false, data.pool({}), data, catalog), "the base pool")
	assert_not_null(RunSession.start(1, "", false, data.card_ids(), data, catalog), "every card")


func test_card_gives_the_data_of_a_known_card_and_nothing_for_an_unknown_one() -> void:
	var s: RunSession = Player.session(1)
	assert_eq(s.card(&"gold_purse"), data.card(&"gold_purse"))
	assert_eq(s.card(&"gold_purse")["kind"], &"economy")
	assert_eq(s.card(&"tower_bakery")["tower"], &"bakery")
	assert_eq(s.card(&"no_such_card"), {})
	assert_eq(s.card(&""), {})
	# A card outside the pool is still a known card.
	var small: RunSession = _with_pool(1, [&"gold_purse"] as Array[StringName])
	assert_eq(small.card(&"spare_gate")["kind"], &"gate")
	# A change to the answer does not reach the run's data.
	var copy: Dictionary = s.card(&"gold_purse")
	copy["kind"] = &"risk"
	assert_eq(s.card(&"gold_purse")["kind"], &"economy")


# owed drafts

func test_no_draft_is_owed_before_a_wave_is_cleared() -> void:
	var s: RunSession = Player.session(1)
	assert_false(s.draft_open())
	assert_eq(s.start_next_wave(), Battle.DONE)
	assert_false(s.draft_open(), "during wave 1")
	assert_eq(s.offers(), [])
	assert_eq(s.battle.phase, Battle.Phase.WAVE)


func test_drafts_owed_counts_the_cleared_waves_less_the_picks() -> void:
	var s: RunSession = Player.session(1)
	assert_eq(s.drafts_owed(), 0, "a new run")
	s.start_next_wave()
	assert_eq(s.drafts_owed(), 0, "during wave 1")
	var done: RunSession = _after_wave_one(data.pool({}))
	assert_eq(done.drafts_owed(), 1, "wave 1 cleared")
	assert_true(done.draft_open())
	done.pick(done.offers()[0])
	assert_eq(done.drafts_owed(), 0, "the pick is made")
	# Shortcut states: drafts are owed for waves 1 to 17 only.
	s = Player.session(1)
	_open(s, 5)
	assert_eq(s.drafts_owed(), 1)
	s.battle.waves_started = 9
	assert_eq(s.drafts_owed(), 5, "waves 5 to 9 are owed")
	s.battle.waves_started = 18
	assert_eq(s.drafts_owed(), 13, "wave 18 owes no draft: 17 cleared less 4 picks")
	s.battle.waves_started = 0
	assert_eq(s.drafts_owed(), 0, "never below 0")


func test_a_cleared_wave_owes_a_draft_that_blocks_the_next_wave() -> void:
	var s: RunSession = _after_wave_one(data.pool({}))
	assert_true(s.draft_open())
	var offered: Array[StringName] = s.offers()
	assert_true(offered.size() >= 1 and offered.size() <= 3)
	assert_eq(s.start_next_wave(), &"draft_waiting", "a draft cannot be skipped")
	assert_eq(s.battle.phase, Battle.Phase.BUILD)
	assert_eq(s.battle.waves_started, 1, "no wave started")
	assert_eq(s.pick(offered[0]), Battle.DONE)
	assert_false(s.draft_open())
	assert_eq(s.offers(), [])
	assert_eq(s.start_next_wave(), Battle.DONE)
	assert_eq(s.battle.waves_started, 2)


func test_one_draft_after_each_wave_in_order() -> void:
	var s: RunSession = Player.session(3)
	var p: RefCounted = Player.new(4, 0, true)
	p.rich = true
	for wave: int in 6:
		p.build_phase(s)
		assert_eq(s.picks.size(), wave, "a pick for every wave cleared so far")
		assert_false(s.draft_open(), "no draft left in the build phase before wave %d" % (wave + 1))
		assert_eq(s.start_next_wave(), Battle.DONE)
		var guard: int = 0
		while s.battle.phase == Battle.Phase.WAVE and guard < 20000:
			s.battle.step()
			guard += 1
		assert_eq(s.battle.phase, Battle.Phase.BUILD)
		assert_true(s.draft_open(), "wave %d owes a draft" % (wave + 1))
		var offered: Array[StringName] = s.offers()
		assert_eq(s.pick(offered[0]), Battle.DONE)
		assert_eq(s.picks.size(), wave + 1)
		assert_false(s.draft_open(), "exactly one draft per wave")


## RULES 14.4: a wave cleared while another runs owes its draft at once, and from then on the
## next wave cannot be called. The drafts open one after another in the next build phase.
func test_an_early_call_with_a_wave_cleared_while_another_runs() -> void:
	var s: RunSession = Player.session(1)
	var p: RefCounted = Player.new(9, 0, true)
	p.rich = true
	for i: int in 3:
		p.build_phase(s)
	var b: Battle = s.battle
	assert_eq(s.start_next_wave(), Battle.DONE)
	var guard: int = 0
	while b.next_wave_info()["refusal"] != &"" and guard < 5000:
		b.step()
		guard += 1
	assert_eq(s.start_next_wave(), Battle.DONE, "wave 2 is called early; wave 1 is not cleared, so no draft is owed")
	assert_eq(b.running.size(), 2)
	assert_false(s.draft_open())
	guard = 0
	while b.running.size() == 2 and guard < 20000:
		b.step()
		guard += 1
	assert_eq(b.running.size(), 1, "one wave is cleared while the other still runs")
	assert_eq(b.phase, Battle.Phase.WAVE)
	assert_false(s.draft_open(), "a draft opens only in a build phase")
	assert_eq(s.offers(), [])
	assert_eq(s.start_next_wave(), &"draft_waiting", "Pick your card after this wave.")
	assert_eq(b.waves_started, 2, "the refused call started nothing")
	guard = 0
	while b.phase == Battle.Phase.WAVE and guard < 20000:
		b.step()
		guard += 1
	assert_eq(b.phase, Battle.Phase.BUILD)
	# Both waves are cleared: two drafts, one after the other, for waves 1 and 2.
	assert_true(s.draft_open())
	assert_eq(s.start_next_wave(), &"draft_waiting", "Pick a card first.")
	var first: Array[StringName] = s.offers()
	assert_eq(s.pick(first[0]), Battle.DONE)
	assert_true(s.draft_open(), "the second draft is next")
	assert_eq(s.start_next_wave(), &"draft_waiting")
	var second: Array[StringName] = s.offers()
	assert_ne(second, first, "the second draft has its own generator")
	assert_eq(s.pick(second[0]), Battle.DONE)
	assert_false(s.draft_open())
	assert_eq(s.picks.size(), 2)
	assert_eq(s.start_next_wave(), Battle.DONE)
	assert_eq(b.waves_started, 3)


func test_nothing_is_offered_and_no_wave_starts_once_the_battle_is_over() -> void:
	var s: RunSession = Player.session(1)
	var p: RefCounted = Player.new(5, 0, true)
	assert_true(p.play(s))
	assert_eq(s.battle.phase, Battle.Phase.LOST)
	assert_false(s.draft_open())
	assert_eq(s.offers(), [])
	assert_eq(s.start_next_wave(), &"over")
	assert_false(s.result()["won"])
	assert_eq(s.result()["lives"], 0)
	assert_true(s.result()["waves"] >= 1 and s.result()["reached"] > s.result()["waves"])


func test_after_a_win_no_draft_is_open_and_the_last_draft_never_opens_when_the_boss_is_called_early() -> void:
	var s: RunSession = Player.session(2)
	var p: RefCounted = Player.new(5, 0, true)
	p.rich = true
	assert_true(p.play(s))
	assert_eq(s.battle.phase, Battle.Phase.WON)
	assert_eq(s.picks.size(), 17, "a draft after each of waves 1 to 17")
	assert_false(s.draft_open())
	assert_eq(s.offers(), [])
	assert_eq(s.start_next_wave(), &"over")
	var early: RunSession = Player.session(3)
	var q: RefCounted = Player.new(5, 20, true)
	q.rich = true
	assert_true(q.play(early))
	assert_true(early.picks.size() <= 17)
	assert_false(early.draft_open())


# the risk rule

func test_no_risk_card_once_wave_17_has_started() -> void:
	# [draft, waves started]: the draft after wave 17, and the draft after wave 16 when wave 17
	# was called early, so it opens after wave 17 has started.
	for case: Array in [[17, 17], [16, 17], [10, 17]]:
		var seen: Dictionary = {}
		for run_seed: int in 200:
			var s: RunSession = Player.session(run_seed, false, "", true)
			_open(s, case[0], [] as Array[StringName], case[1])
			for id: StringName in s.offers():
				seen[id] = true
		for id: StringName in seen.keys():
			assert_ne(_kind(id), &"risk", "draft %d with %d waves started offered %s" % [case[0], case[1], id])
		assert_true(seen.size() > 5, "the test saw many cards")
	# The control: with only 16 waves started the draft after wave 16 may offer a risk card.
	var risky: bool = false
	for run_seed: int in 200:
		var s: RunSession = Player.session(run_seed, false, "", true)
		_open(s, 16)
		for id: StringName in s.offers():
			risky = risky or _kind(id) == &"risk"
	assert_true(risky, "with 16 waves started a risk card is offered for some seed, so the test above could fail")


## The same, in played runs: waves called early so wave 17 starts before the drafts of waves up
## to 16 are open.
func test_no_risk_card_in_played_runs_once_wave_17_has_started() -> void:
	var late: int = 0
	var risky: int = 0
	for run_seed: int in 12:
		var s: RunSession = Player.session(run_seed + 100, false, "", true)
		var p: RefCounted = Player.new(run_seed, 25, false)
		p.rich = true
		assert_true(p.play(s))
		late += p.late_drafts
		risky += p.risky_late
	assert_true(late > 0, "wave 17 was called early in some run, so a draft opened after it started")
	assert_eq(risky, 0, "and none of them offered a risk card")


func test_no_risk_card_while_another_is_waiting() -> void:
	var tested: int = 0
	for run_seed: int in 200:
		var s: RunSession = Player.session(run_seed, false, "", true)
		_open(s, 1)
		var risk_id: StringName = &""
		for id: StringName in s.offers():
			if _kind(id) == &"risk":
				risk_id = id
		if risk_id == &"":
			continue
		assert_eq(s.pick(risk_id), Battle.DONE)
		assert_eq(s.risk_card(), risk_id)
		s.battle.waves_started = 2
		assert_eq(s.picks.size(), 1)
		for id: StringName in s.offers():
			assert_ne(_kind(id), &"risk", "seed %d offered %s with %s waiting" % [run_seed, id, risk_id])
		tested += 1
	assert_true(tested > 10, "%d seeds offered a risk card in the first draft" % tested)


func test_a_draft_offers_at_most_one_risk_card() -> void:
	var heavy: RunData = Fx.run_data()
	heavy.weights = {&"tower": 0, &"perk": 0, &"gate": 0, &"economy": 0, &"risk": 100}
	var most: int = 0
	for run_seed: int in 80:
		var s: RunSession = RunSession.start(run_seed, "", false, heavy.card_ids(), heavy, catalog)
		_open(s, 2)
		var offered: Array[StringName] = s.offers()
		var risks: int = 0
		for id: StringName in offered:
			if heavy.card(id)["kind"] == &"risk":
				risks += 1
		most = maxi(most, risks)
	assert_eq(most, 1, "only risk cards have weight, and still one a draft")


# eligibility

func test_a_tower_card_only_while_its_tower_is_not_in_the_run() -> void:
	var first: Dictionary = _seen(1, false)
	for id: StringName in [&"tower_pumpkin_catapult", &"tower_lullaby_bell", &"tower_longbow_loft", &"tower_firework_tower", &"tower_bakery"]:
		assert_true(first.has(id), "%s is offered when its tower is not in the run" % id)
	for run_seed: int in 100:
		var s: RunSession = Player.session(run_seed)
		_open(s, 3, [&"tower_bakery", &"tower_lullaby_bell"])
		for id: StringName in s.offers():
			assert_ne(id, &"tower_bakery", "the Bakery is in the run")
			assert_ne(id, &"tower_lullaby_bell", "the Lullaby Bell is in the run")


func test_a_perk_only_while_its_tower_is_in_the_run() -> void:
	var first: Dictionary = _seen(1, true)
	assert_true(first.has(&"sharp_pebbles"))
	assert_false(first.has(&"twin_pebbles"), "an unlocked perk waits for the base perk (3.4)")
	for id: StringName in first.keys():
		if _kind(id) == &"perk":
			assert_eq(data.card(id)["tower"], &"sling_post", "%s needs a tower the run does not have" % id)
	var bell: Dictionary = {}
	for run_seed: int in 150:
		var s: RunSession = Player.session(run_seed, false, "", true)
		_open(s, 2, [&"tower_lullaby_bell"])
		for id: StringName in s.offers():
			bell[id] = true
	assert_true(bell.has(&"deep_lullaby"), "the Bell's perk joins once the Bell is in the run")
	assert_false(bell.has(&"warm_ovens"))


# the unlocked perk rule (RULES 14.4, 14.6)

## Every offer of the drafts after waves 1 to 17 with the given picks held, over many seeds.
func _offered_with(picked: Array[StringName], every_card: bool, ids: Array[StringName] = []) -> Dictionary:
	var seen: Dictionary = {}
	for run_seed: int in 200:
		var s: RunSession = Player.session(run_seed, false, "", every_card) if ids.is_empty() else _with_pool(run_seed, ids)
		var held: Array[StringName] = picked.duplicate()
		while held.size() < 8:
			held.append(&"gold_purse")
		_open(s, 9, held)
		for id: StringName in s.offers():
			seen[id] = true
	return seen


func test_an_unlocked_perk_is_never_offered_while_a_base_perk_is_eligible() -> void:
	# Only the Sling Post in the run: Sharp Pebbles is eligible, so Twin Pebbles waits.
	for draft: int in [1, 2, 5, 9, 17]:
		for run_seed: int in 150:
			var s: RunSession = Player.session(run_seed, false, "", true)
			_open(s, draft)
			assert_false(s.offers().has(&"twin_pebbles"), "seed %d, draft %d" % [run_seed, draft])
	# A tower card makes its base perk eligible: the unlocked perk waits again.
	var bell: Dictionary = _offered_with([&"sharp_pebbles", &"tower_lullaby_bell"], true)
	assert_true(bell.has(&"deep_lullaby"))
	assert_false(bell.has(&"twin_pebbles"), "Deep Lullaby is eligible, so Twin Pebbles waits")


func test_an_unlocked_perk_is_offered_once_no_base_perk_is_eligible() -> void:
	var after_sharp: Dictionary = _offered_with([&"sharp_pebbles"], true)
	assert_true(after_sharp.has(&"twin_pebbles"), "Sharp Pebbles is taken")
	assert_false(after_sharp.has(&"sharp_pebbles"))
	# With the Bell too, it comes back after Deep Lullaby is taken.
	var both: Dictionary = _offered_with([&"sharp_pebbles", &"tower_lullaby_bell", &"deep_lullaby"], true)
	assert_true(both.has(&"twin_pebbles"))
	assert_false(both.has(&"deep_lullaby"))


func test_a_pool_without_a_base_perk_offers_the_unlocked_perk_at_once() -> void:
	var ids: Array[StringName] = [&"tower_bakery", &"twin_pebbles", &"gold_purse", &"spare_gate"]
	var seen: Dictionary = _offered_with([], false, ids)
	assert_true(seen.has(&"twin_pebbles"), "the pool has no base perk for the Sling Post")
	var first: Dictionary = {}
	for run_seed: int in 100:
		var s: RunSession = _with_pool(run_seed, ids)
		_open(s, 1)
		for id: StringName in s.offers():
			first[id] = true
	assert_true(first.has(&"twin_pebbles"), "from the first draft")


func test_an_unlocked_perk_in_the_pool_changes_no_draft_while_a_base_perk_is_eligible() -> void:
	var base: Array[StringName] = data.pool({})
	var with_twin: Array[StringName] = base.duplicate()
	with_twin.append(&"twin_pebbles")
	for run_seed: int in 60:
		for draft: int in [1, 2, 6]:
			var a: RunSession = _with_pool(run_seed, base)
			var b: RunSession = _with_pool(run_seed, with_twin)
			_open(a, draft)
			_open(b, draft)
			assert_eq(b.offers(), a.offers(), "seed %d, draft %d" % [run_seed, draft])


func test_a_once_card_is_gone_after_it_is_taken_and_others_come_back() -> void:
	var gone: Dictionary = {}
	var back: Dictionary = {}
	for run_seed: int in 150:
		var s: RunSession = Player.session(run_seed, false, "", true)
		_open(s, 4, [&"sharp_pebbles", &"spare_gate", &"gold_purse"])
		for id: StringName in s.offers():
			gone[id] = true
			if id == &"gold_purse" or id == &"spare_gate":
				back[id] = true
	assert_false(gone.has(&"sharp_pebbles"), "a once card is gone")
	assert_true(back.has(&"gold_purse") and back.has(&"spare_gate"), "cards that can be taken again and again come back")


func test_a_gate_card_only_while_the_run_has_fewer_than_three_gates_and_than_sockets() -> void:
	var with_room: bool = false
	var with_one: bool = false
	for run_seed: int in 100:
		var s: RunSession = Player.session(run_seed)
		_open(s, 2)
		# The fixture maps have 2 sockets, so give this map 4 to test the limit of 3 gates.
		var wide: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(3, 0)]
		var real: Array[Vector2i] = s.battle.level.sockets
		s.battle.level.sockets = wide
		s.battle.gates_in_hand = 2
		with_room = with_room or s.offers().has(&"spare_gate")
		s.battle.gates_in_hand = 3
		assert_false(s.offers().has(&"spare_gate"), "3 gates in hand: seed %d" % run_seed)
		s.battle.gates_in_hand = 0
		var placed: Array[GateState] = []
		for i: int in 3:
			var gate: GateState = GateState.new()
			gate.cell = wide[i]
			placed.append(gate)
		s.battle.gates = placed
		assert_false(s.offers().has(&"spare_gate"), "3 gates placed: seed %d" % run_seed)
		s.battle.gates_in_hand = 1
		assert_false(s.offers().has(&"spare_gate"), "2 placed and 1 in hand: seed %d" % run_seed)
		# The real map: 2 sockets. Two gates fill it, one gate leaves room.
		s.battle.level.sockets = real
		s.battle.gates = []
		s.battle.gates_in_hand = 2
		assert_false(s.offers().has(&"spare_gate"), "as many gates as sockets: seed %d" % run_seed)
		s.battle.gates_in_hand = 1
		with_one = with_one or s.offers().has(&"spare_gate")
	assert_true(with_room, "with room for another gate the card is offered for some seed")
	assert_true(with_one, "one gate on a map with two sockets leaves room")


func test_economy_cards_are_always_eligible() -> void:
	var seen: Dictionary = _seen(5, false)
	assert_true(seen.has(&"gold_purse"))
	var only: Array[StringName] = [&"gold_purse"]
	for run_seed: int in 20:
		var s: RunSession = _with_pool(run_seed, only)
		_open(s, 9)
		assert_eq(s.offers(), [&"gold_purse"], "a non once economy card alone is offered every draft")


func test_unlocked_cards_come_only_from_the_pool() -> void:
	var base: Dictionary = _seen(1, false, 200)
	for id: StringName in [&"twin_pebbles", &"piggy_bank", &"pip_parade"]:
		assert_false(base.has(id), "%s is not in the base pool" % id)
	var all: Dictionary = {}
	for run_seed: int in 300:
		var s: RunSession = Player.session(run_seed, false, "", true)
		_open(s, 9, [&"sharp_pebbles", &"gold_purse", &"gold_purse", &"gold_purse", &"gold_purse", &"gold_purse", &"gold_purse", &"gold_purse"] as Array[StringName])
		for id: StringName in s.offers():
			all[id] = true
	for id: StringName in [&"twin_pebbles", &"piggy_bank", &"pip_parade"]:
		assert_true(all.has(id), "%s is offered when the pool has it" % id)
	var unlocked: RunSession = RunSession.start(1, "", false, data.pool({"best_run_wave": 6}), data, catalog)
	assert_true(unlocked.pool.has(&"twin_pebbles"))


func test_the_first_card_is_a_tower_card_while_the_run_has_fewer_than_three_towers() -> void:
	for run_seed: int in 120:
		var s: RunSession = Player.session(run_seed)
		_open(s, 1)
		assert_eq(_kind(s.offers()[0]), &"tower", "seed %d, one tower in the run" % run_seed)
		_open(s, 3, [&"tower_bakery", &"tower_lullaby_bell"] as Array[StringName])
		var three: Array[StringName] = s.offers()
		assert_eq(three.size(), 3)
	var not_first: bool = false
	for run_seed: int in 120:
		var s: RunSession = Player.session(run_seed)
		_open(s, 3, [&"tower_bakery", &"tower_lullaby_bell"] as Array[StringName])
		not_first = not_first or _kind(s.offers()[0]) != &"tower"
	assert_true(not_first, "with 3 towers the first card is drawn like the others")


func test_the_first_card_is_a_tower_card_even_if_towers_have_no_weight() -> void:
	var no_towers: RunData = Fx.run_data()
	no_towers.weights = {&"tower": 0, &"perk": 10, &"gate": 10, &"economy": 10, &"risk": 10}
	for run_seed: int in 30:
		var s: RunSession = RunSession.start(run_seed, "", false, no_towers.pool({}), no_towers, catalog)
		_open(s, 1)
		var offered: Array[StringName] = s.offers()
		assert_eq(no_towers.card(offered[0])["kind"], &"tower")
		for id: StringName in offered.slice(1):
			assert_ne(no_towers.card(id)["kind"], &"tower", "a type of weight 0 is left out of the type draw")


func test_a_weight_of_zero_leaves_a_type_out_and_cards_never_repeat_in_a_draft() -> void:
	var no_risk: RunData = Fx.run_data()
	no_risk.weights = {&"tower": 30, &"perk": 25, &"gate": 10, &"economy": 20, &"risk": 0}
	for run_seed: int in 100:
		var s: RunSession = RunSession.start(run_seed, "", false, no_risk.card_ids(), no_risk, catalog)
		_open(s, 6)
		var offered: Array[StringName] = s.offers()
		var seen: Dictionary = {}
		for id: StringName in offered:
			assert_false(seen.has(id), "%s twice in one draft" % id)
			seen[id] = true
			assert_ne(no_risk.card(id)["kind"], &"risk")


func test_a_draft_offers_fewer_than_three_when_fewer_are_eligible() -> void:
	var two: Array[StringName] = [&"tower_bakery", &"gold_purse"]
	var s: RunSession = _with_pool(1, two)
	_open(s, 1)
	assert_eq(s.offers(), [&"tower_bakery", &"gold_purse"])
	var one: Array[StringName] = [&"sharp_pebbles", &"gold_purse"]
	var t: RunSession = _with_pool(1, one)
	_open(t, 1)
	assert_eq(t.offers().size(), 2)
	_open(t, 2, [&"sharp_pebbles"] as Array[StringName])
	assert_eq(t.offers(), [&"gold_purse"], "the once card is gone")


# the draw

## The offers for fixed seeds, as the draws of the contract give them. They depend on the
## fixtures and on the engine's generator. A change here is a change to every run a player
## has saved with a draft open, so look before updating them. Each row is the draft after
## waves 1, 2, 9 and 17, with gold_purse as every earlier pick.
func test_offers_are_pinned_for_fixed_seeds() -> void:
	var base: Dictionary = {
		0: [[&"tower_bakery", &"spare_gate", &"tower_lullaby_bell"], [&"tower_bakery", &"tower_longbow_loft", &"tower_pumpkin_catapult"], [&"tower_longbow_loft", &"sharp_pebbles", &"tower_lullaby_bell"], [&"tower_bakery", &"gold_purse", &"spare_gate"]],
		1: [[&"tower_pumpkin_catapult", &"sharp_pebbles", &"flock"], [&"tower_firework_tower", &"gold_purse", &"tower_pumpkin_catapult"], [&"tower_bakery", &"gold_purse", &"tower_longbow_loft"], [&"tower_bakery", &"sharp_pebbles", &"tower_lullaby_bell"]],
		2: [[&"tower_bakery", &"spare_gate", &"crowded_night"], [&"tower_lullaby_bell", &"sharp_pebbles", &"gold_purse"], [&"tower_lullaby_bell", &"tower_firework_tower", &"sharp_pebbles"], [&"tower_pumpkin_catapult", &"tower_bakery", &"sharp_pebbles"]],
		12345: [[&"tower_lullaby_bell", &"spare_gate", &"sharp_pebbles"], [&"tower_bakery", &"crowded_night", &"sharp_pebbles"], [&"tower_firework_tower", &"gold_purse", &"tower_longbow_loft"], [&"tower_lullaby_bell", &"tower_pumpkin_catapult", &"spare_gate"]],
		20261023: [[&"tower_firework_tower", &"spare_gate", &"sharp_pebbles"], [&"tower_bakery", &"tower_longbow_loft", &"crowded_night"], [&"tower_firework_tower", &"tower_longbow_loft", &"sharp_pebbles"], [&"tower_longbow_loft", &"tower_firework_tower", &"tower_bakery"]],
	}
	var every: Dictionary = {
		0: [[&"tower_bakery", &"spare_gate", &"tower_lullaby_bell"], [&"tower_bakery", &"tower_longbow_loft", &"tower_pumpkin_catapult"], [&"tower_longbow_loft", &"sharp_pebbles", &"tower_lullaby_bell"], [&"tower_bakery", &"piggy_bank", &"sharp_pebbles"]],
		1: [[&"tower_pumpkin_catapult", &"sharp_pebbles", &"pip_parade"], [&"tower_firework_tower", &"gold_purse", &"tower_lullaby_bell"], [&"tower_bakery", &"piggy_bank", &"pip_parade"], [&"tower_bakery", &"sharp_pebbles", &"tower_lullaby_bell"]],
		2: [[&"tower_bakery", &"spare_gate", &"crowded_night"], [&"tower_lullaby_bell", &"sharp_pebbles", &"gold_purse"], [&"tower_lullaby_bell", &"tower_firework_tower", &"sharp_pebbles"], [&"tower_pumpkin_catapult", &"tower_bakery", &"sharp_pebbles"]],
		12345: [[&"tower_lullaby_bell", &"spare_gate", &"sharp_pebbles"], [&"tower_bakery", &"crowded_night", &"sharp_pebbles"], [&"tower_firework_tower", &"piggy_bank", &"gold_purse"], [&"tower_lullaby_bell", &"tower_pumpkin_catapult", &"spare_gate"]],
		20261023: [[&"tower_firework_tower", &"spare_gate", &"sharp_pebbles"], [&"tower_bakery", &"tower_longbow_loft", &"pip_parade"], [&"tower_firework_tower", &"tower_longbow_loft", &"sharp_pebbles"], [&"tower_longbow_loft", &"tower_firework_tower", &"tower_bakery"]],
	}
	var drafts: Array[int] = [1, 2, 9, 17]
	for every_card: bool in [false, true]:
		var table: Dictionary = every if every_card else base
		for run_seed: int in table.keys():
			for i: int in drafts.size():
				var s: RunSession = Player.session(run_seed, false, "", every_card)
				_open(s, drafts[i])
				assert_eq(s.offers(), table[run_seed][i], "seed %d, draft after wave %d, %s" % [run_seed, drafts[i], "every card" if every_card else "base cards"])


## The draw order of 3.4, replayed by hand for the first draft of the base pool: slot 1 is a
## tower card (one tower in the run), drawn by randi_range over the tower cards; slots 2 and 3
## draw a type by weight among the types with a card left, then a card of it.
func test_the_draw_follows_the_order_of_the_contract() -> void:
	var towers: Array[StringName] = [&"tower_pumpkin_catapult", &"tower_lullaby_bell", &"tower_longbow_loft", &"tower_firework_tower", &"tower_bakery"]
	var perks: Array[StringName] = [&"sharp_pebbles"]
	var gates: Array[StringName] = [&"spare_gate"]
	var economy: Array[StringName] = [&"gold_purse"]
	var risks: Array[StringName] = [&"crowded_night", &"flock"]
	var weights: Array[int] = [30, 25, 10, 20, 15]
	for run_seed: int in [0, 1, 5, 99, 4242, 20261024]:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = RunSeeds.derive(run_seed, "draft", 1)
		var lists: Array = [towers.duplicate(), perks.duplicate(), gates.duplicate(), economy.duplicate(), risks.duplicate()]
		var want: Array[StringName] = []
		var first: Array = lists[0]
		var tower_card: StringName = first.pop_at(rng.randi_range(0, first.size() - 1))
		want.append(tower_card)
		var risk_done: bool = false
		for slot: int in 2:
			var total: int = 0
			for k: int in 5:
				if not (lists[k] as Array).is_empty() and not (k == 4 and risk_done):
					total += weights[k]
			var roll: int = rng.randi_range(1, total)
			var running: int = 0
			for k: int in 5:
				if (lists[k] as Array).is_empty() or (k == 4 and risk_done):
					continue
				running += weights[k]
				if roll <= running:
					var chosen: Array = lists[k]
					want.append(chosen.pop_at(rng.randi_range(0, chosen.size() - 1)))
					risk_done = risk_done or k == 4
					break
		var s: RunSession = Player.session(run_seed)
		_open(s, 1)
		assert_eq(s.offers(), want, "seed %d" % run_seed)


func test_offers_are_the_same_every_time_they_are_asked_for() -> void:
	var s: RunSession = Player.session(31)
	_open(s, 4)
	var first: Array[StringName] = s.offers()
	assert_eq(s.offers(), first)
	assert_eq(s.offers(), first)
	var other: RunSession = Player.session(31)
	_open(other, 4)
	assert_eq(other.offers(), first, "a second session with the same state")


## RULES 14.4: earlier picks never change which random numbers a later draft gets. Two picks
## that leave the same cards eligible give the same draft.
func test_earlier_picks_do_not_change_a_later_drafts_generator() -> void:
	for run_seed: int in 60:
		var a: RunSession = Player.session(run_seed, false, "", true)
		_open(a, 4, [&"gold_purse", &"gold_purse", &"gold_purse"] as Array[StringName])
		var b: RunSession = Player.session(run_seed, false, "", true)
		_open(b, 4, [&"gold_purse", &"gold_purse", &"gold_purse"] as Array[StringName])
		var c: RunSession = Player.session(run_seed, false, "", true)
		_open(c, 4, [&"spare_gate", &"gold_purse", &"spare_gate"] as Array[StringName])
		assert_eq(a.offers(), b.offers())
		assert_eq(c.offers().size(), a.offers().size())
	# A draft depends on its wave number: the same state at another number draws differently.
	var differ: bool = false
	for run_seed: int in 30:
		var x: RunSession = Player.session(run_seed)
		_open(x, 2)
		var y: RunSession = Player.session(run_seed)
		_open(y, 3)
		differ = differ or x.offers() != y.offers()
	assert_true(differ)


# picking

func test_a_card_that_is_not_offered_is_refused() -> void:
	var s: RunSession = Player.session(1)
	assert_eq(s.pick(&"gold_purse"), &"not_offered", "no draft is open")
	_open(s, 1)
	var offered: Array[StringName] = s.offers()
	for id: StringName in [&"gold_purse", &"spare_gate", &"sharp_pebbles", &"tower_bakery", &"crowded_night", &"no_such_card", &""]:
		if offered.has(id):
			continue
		assert_eq(s.pick(id), &"not_offered", String(id))
	assert_eq(s.picks, [])
	assert_eq(s.offers(), offered, "a refusal changes nothing")


func test_a_battle_refusal_is_returned_and_the_pick_is_not_kept() -> void:
	var ids: Array[StringName] = [&"tower_bakery", &"gold_purse"]
	var s: RunSession = _with_pool(1, ids)
	_open(s, 1)
	var full: Array[Dictionary] = []
	for i: int in Modifiers.MAX_KEPT:
		full.append({"type": "bounty_pct", "pct": 100})
	s.battle.card_effects = full
	assert_eq(s.pick(&"tower_bakery"), &"bad_effect", "the battle holds no more kept card effects")
	assert_eq(s.picks, [])
	assert_true(s.draft_open())
	assert_eq(s.pick(&"gold_purse"), Battle.DONE, "an instant card keeps no effect")
	assert_eq(s.picks, [&"gold_purse"])


func test_picking_a_tower_card_adds_the_tower() -> void:
	var ids: Array[StringName] = [&"tower_bakery", &"gold_purse"]
	var s: RunSession = _after_wave_one(ids)
	assert_eq(s.offers(), [&"tower_bakery", &"gold_purse"])
	var spot: Vector2i = s.battle.level.spots[0]
	s.battle.sell_tower(spot)
	var before: Array[StringName] = []
	for option: Dictionary in s.battle.build_options(spot):
		before.append(option["tower"])
	assert_false(before.has(&"bakery"))
	assert_eq(s.pick(&"tower_bakery"), Battle.DONE)
	var after: Array[StringName] = []
	for option: Dictionary in s.battle.build_options(spot):
		after.append(option["tower"])
	assert_true(after.has(&"bakery"))
	assert_eq(s.picks, [&"tower_bakery"])
	assert_false(s.draft_open())


func test_picking_gold_lives_and_gates() -> void:
	var purse: RunSession = _after_wave_one([&"gold_purse"] as Array[StringName])
	var gold: int = purse.battle.gold
	assert_eq(purse.pick(&"gold_purse"), Battle.DONE)
	assert_eq(purse.battle.gold, gold + 110, "100 gold plus 10 for the wave cleared")
	var extra: Dictionary = Fx.files_from_json()
	extra["cards/cards.json"]["cards"].append({
		"id": "tea_break", "kind": "economy", "name": "Tea Break", "text": "Gain 5 lives.",
		"once": false, "unlock": {}, "effects": [{"type": "add_lives", "amount": 5}],
	})
	data = RunData.from_data(extra, catalog)
	assert_not_null(data)
	var tea: RunSession = _after_wave_one([&"tea_break"] as Array[StringName])
	var start_lives: int = tea.battle.start_lives
	tea.battle.lives = start_lives   # the test player is rich and has far more lives than a real run
	assert_eq(tea.pick(&"tea_break"), Battle.DONE)
	assert_eq(tea.battle.lives, start_lives, "Tea Break never lifts lives above the start")
	var hurt: RunSession = _after_wave_one([&"tea_break"] as Array[StringName])
	hurt.battle.lives = start_lives - 3
	assert_eq(hurt.pick(&"tea_break"), Battle.DONE)
	assert_eq(hurt.battle.lives, start_lives, "it repairs lost lives up to the start")
	var half: RunSession = _after_wave_one([&"tea_break"] as Array[StringName])
	half.battle.lives = start_lives - 10
	assert_eq(half.pick(&"tea_break"), Battle.DONE)
	assert_eq(half.battle.lives, start_lives - 5, "and gives the full 5 when that stays under the start")
	var gate: RunSession = _after_wave_one([&"spare_gate", &"gold_purse"] as Array[StringName])
	var in_hand: int = gate.battle.gates_in_hand
	assert_eq(gate.pick(&"spare_gate"), Battle.DONE)
	assert_eq(gate.battle.gates_in_hand, in_hand + 1)
	assert_eq(gate.pick(&"spare_gate"), &"not_offered", "the draft is done")


func test_a_risk_card_waits_for_the_next_wave_and_changes_it_only() -> void:
	var s: RunSession = _after_wave_one([&"crowded_night", &"gold_purse"] as Array[StringName])
	var plain: int = 0
	for row: Dictionary in s.battle.wave_preview(1):
		plain += int(row["count"])
	assert_eq(s.risk_card(), &"")
	assert_eq(s.pick(&"crowded_night"), Battle.DONE)
	assert_eq(s.risk_card(), &"crowded_night")
	assert_false(s.battle.risk_waiting.is_empty())
	var crowded: int = 0
	for row: Dictionary in s.battle.wave_preview(1):
		crowded += int(row["count"])
	assert_true(crowded > plain, "the preview of the next wave shows the risk card")
	assert_eq(s.start_next_wave(), Battle.DONE)
	assert_eq(s.risk_card(), &"", "the card is spent when its wave starts")
	assert_eq(s.result()["risks"], 1)
	var after: int = 0
	for row: Dictionary in s.battle.wave_preview(2):
		after += int(row["count"])
	assert_true(after > 0)


func test_a_flock_adds_a_group_to_the_next_wave() -> void:
	var s: RunSession = _after_wave_one([&"flock", &"gold_purse"] as Array[StringName])
	var rows: int = s.battle.wave_preview(1).size()
	assert_eq(s.pick(&"flock"), Battle.DONE)
	var preview: Array[Dictionary] = s.battle.wave_preview(1)
	assert_eq(preview.size(), rows + 1)
	assert_eq(preview.back()["enemy"], &"flitter")
	assert_eq(preview.back()["count"], 8)
