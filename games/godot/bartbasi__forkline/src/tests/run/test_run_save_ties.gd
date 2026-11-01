# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## A saved run is tied to its picks (docs/ARCHITECTURE.md 5.6, security review N1): the battle's
## kept card effects must be the picks' effects, and a waiting or running risk card must be one
## that was picked. Real saves at every point still load and play on the same.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
const Player: GDScript = preload("res://tests/run/fixtures/run_player.gd")
const Golden: GDScript = preload("res://tests/run/fixtures/run_golden.gd")

const DAY: String = "2026-10-23"
const DAY_SEED: int = 20261023

var catalog: Catalog = null
var _data: RunData = null


func before_each() -> void:
	catalog = Fx.catalog()
	_data = Fx.run_data()


func _player(seed_value: int, early: int = 0) -> RefCounted:
	var p: RefCounted = Player.new(seed_value, early, false)
	p.rich = true
	return p


## The effects of a fixture card, in the file shape.
func _effects_of(id: String) -> Array:
	for item: Dictionary in Fx.cards()["cards"]:
		if item["id"] == id:
			return JSON.parse_string(JSON.stringify(item["effects"]))
	fail("no fixture card " + id)
	return []


## The run and the battle of a session as a save gives them back.
func _saved(s: RunSession) -> Array:
	var run_raw: Variant = JSON.parse_string(JSON.stringify(s.to_data()))
	var battle_raw: Variant = JSON.parse_string(JSON.stringify(s.battle.to_data()))
	return [run_raw, battle_raw]


## Loads the run from a (possibly changed) pair. Asserts the battle itself loads, so a
## refusal is the run's own.
func _load(pair: Array) -> RunSession:
	var loaded: Battle = Battle.from_data(pair[1], catalog)
	assert_not_null(loaded, "the changed battle loads, so only the run's tie can refuse it")
	if loaded == null:
		return null
	return RunSession.from_data(pair[0], loaded, _data)


func _advance_until(p: RefCounted, s: RunSession, check: Callable) -> bool:
	var guard: int = 0
	while guard < 100000:
		if check.call(s):
			return true
		if not p.advance(s):
			return false
		guard += 1
	return false


## A run of every card, in a build phase with the draft after wave `wave` open.
func _with_draft(run_seed: int, wave: int) -> RunSession:
	var s: RunSession = Player.session(run_seed, false, "", true)
	var p: RefCounted = _player(run_seed)
	assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open() and x.battle.waves_started == wave))
	return s


## A run with a risk card picked and waiting. Tries seeds until a draft offers one.
func _with_risk_waiting(first_seed: int) -> RunSession:
	for run_seed: int in range(first_seed, first_seed + 60):
		var s: RunSession = _with_draft(run_seed, 3)
		for id: StringName in s.offers():
			if s.card(id)["kind"] == &"risk":
				assert_eq(s.pick(id), Battle.DONE)
				assert_eq(s.risk_card(), id)
				return s
	fail("no seed offered a risk card")
	return null


# the review's repro and the kept effects

func test_the_reviews_repro_seven_huge_risk_effects_are_refused() -> void:
	var s: RunSession = Player.session(5, false, "", true)
	var pair: Array = _saved(s)
	var risk: Array = []
	for i: int in 7:
		risk.append({"type": "count_pct", "pct": 1000, "flyers": false, "last_wave": false})
	risk.append({"type": "reward_gold", "amount": 100})
	var huge: Dictionary = (pair[1] as Dictionary).duplicate(true)
	huge["risk"] = risk
	assert_null(Battle.from_data(huge, catalog), "the battle itself refuses the repro: a group passes MAX_ENEMIES")
	for effect: Dictionary in risk:
		if effect["type"] == "count_pct":
			effect["pct"] = 150
	(pair[1] as Dictionary)["risk"] = risk
	assert_null(_load(pair), "no risk card was picked")
	# The same save with the risk card removed loads.
	(pair[1] as Dictionary)["risk"] = []
	assert_not_null(_load(pair))


func test_the_same_effects_as_kept_effects_are_refused() -> void:
	var s: RunSession = Player.session(5, false, "", true)
	var pair: Array = _saved(s)
	var kept: Array = []
	for i: int in 7:
		kept.append({"type": "bounty_pct", "pct": 150})
	(pair[1] as Dictionary)["effects"] = kept
	assert_null(_load(pair))


func test_changed_or_extra_or_missing_kept_effects_are_refused() -> void:
	var s: RunSession = _with_draft(6, 4)
	var seed_value: int = 6
	while not _has_perk(s) and seed_value < 60:
		seed_value += 1
		s = _with_draft(seed_value, 4)
	assert_true(_has_perk(s), "a run that took a perk or a risk-free numbered effect")
	assert_true(s.battle.card_effects.size() >= 1, "the run keeps effects")
	var good: Array = _saved(s)
	assert_not_null(_load(good.duplicate(true)), "the untouched save loads")
	var effects: Array = (good[1] as Dictionary)["effects"]
	var extra: Array = good.duplicate(true)
	(extra[1] as Dictionary)["effects"].append({"type": "bounty_pct", "pct": 120})
	assert_null(_load(extra), "an extra effect")
	var missing: Array = good.duplicate(true)
	(missing[1] as Dictionary)["effects"].pop_back()
	assert_null(_load(missing), "a missing effect")
	var none: Array = good.duplicate(true)
	(none[1] as Dictionary)["effects"] = []
	assert_null(_load(none), "no effects at all")
	var changed: Array = good.duplicate(true)
	var done: bool = false
	for effect: Dictionary in (changed[1] as Dictionary)["effects"]:
		for key: String in effect.keys():
			if typeof(effect[key]) == TYPE_FLOAT and not done:
				effect[key] = float(effect[key]) + 1.0
				done = true
	assert_true(done, "the run keeps an effect with a number")
	assert_null(_load(changed), "a changed number")
	var other_tower: Array = good.duplicate(true)
	var swapped_tower: bool = false
	for effect: Dictionary in (other_tower[1] as Dictionary)["effects"]:
		if effect["type"] == "add_tower" and not swapped_tower:
			effect["tower"] = "firework_tower" if effect["tower"] != "firework_tower" else "bakery"
			swapped_tower = true
	assert_true(swapped_tower)
	assert_null(_load(other_tower), "a changed tower")
	if effects.size() >= 2:
		var swapped: Array = good.duplicate(true)
		(swapped[1] as Dictionary)["effects"].reverse()
		assert_null(_load(swapped), "the same effects in another order")


func _has_perk(s: RunSession) -> bool:
	for effect: Dictionary in s.battle.card_effects:
		if effect["type"] == "tower_add":
			return true
	return false


func test_picks_that_give_other_effects_than_the_battle_holds_are_refused() -> void:
	var s: RunSession = _with_draft(6, 4)
	var good: Array = _saved(s)
	assert_true(s.battle.card_effects.size() >= 1)
	# Dropping every pick leaves the battle holding effects no pick gave.
	var no_picks: Array = good.duplicate(true)
	(no_picks[0] as Dictionary)["picks"] = []
	assert_null(_load(no_picks))
	# Swapping a pick for another card that keeps other effects.
	var swapped: Array = good.duplicate(true)
	(swapped[0] as Dictionary)["picks"] = ["sharp_pebbles", "deep_lullaby", "warm_ovens"]
	assert_null(_load(swapped))


# the waiting risk card

func test_a_real_waiting_risk_card_loads_and_plays_on() -> void:
	var s: RunSession = _with_risk_waiting(0)
	var back: RunSession = _load(_saved(s))
	assert_not_null(back)
	assert_eq(back.risk_card(), s.risk_card())
	assert_eq(back.start_next_wave(), Battle.DONE)
	assert_eq(s.start_next_wave(), Battle.DONE)
	assert_eq(Player.fingerprint(back), Player.fingerprint(s))


func test_a_waiting_risk_card_that_is_not_the_last_one_picked_is_refused() -> void:
	var s: RunSession = _with_risk_waiting(0)
	var other: String = "flock" if s.risk_card() == &"crowded_night" else "crowded_night"
	var pair: Array = _saved(s)
	(pair[1] as Dictionary)["risk"] = _effects_of(other)
	assert_null(_load(pair), "another real risk card")
	var bigger: Array = _saved(s)
	var changed: bool = false
	for effect: Dictionary in (bigger[1] as Dictionary)["risk"]:
		if effect["type"] == "reward_gold":
			effect["amount"] = float(effect["amount"]) + 1.0
			changed = true
	assert_true(changed)
	assert_null(_load(bigger), "a changed number")
	var extra: Array = _saved(s)
	((extra[1] as Dictionary)["risk"] as Array).append({"type": "reward_gold", "amount": 5})
	assert_null(_load(extra), "an extra effect")


func test_a_waiting_risk_card_with_no_risk_pick_is_refused() -> void:
	var s: RunSession = _with_risk_waiting(0)
	var risk_id: String = String(s.risk_card())
	var pair: Array = _saved(s)
	var picks: Array = (pair[0] as Dictionary)["picks"]
	picks.erase(risk_id)
	assert_null(_load(pair), "the pick that gave the waiting card is gone")
	# Picks that name another risk card.
	var other: String = "flock" if risk_id == "crowded_night" else "crowded_night"
	var swapped: Array = _saved(s)
	var list: Array = (swapped[0] as Dictionary)["picks"]
	list[list.rfind(risk_id)] = other
	assert_null(_load(swapped), "the picked card is not the waiting one")


func test_a_waiting_risk_card_is_refused_in_a_wave_and_at_the_boss_wave() -> void:
	var s: RunSession = _with_risk_waiting(0)
	var in_wave: Array = _saved(s)
	# A running wave cannot have a risk card still waiting: the battle itself may refuse the
	# pair, in which case there is no save to load.
	(in_wave[1] as Dictionary)["phase"] = "wave"
	var loaded: Battle = Battle.from_data(in_wave[1], catalog)
	if loaded != null:
		assert_null(RunSession.from_data(in_wave[0], loaded, Fx.run_data()))
	# A waiting card with 17 waves started (or more) was picked after the cutoff.
	var late: RunSession = _with_risk_waiting(0)
	late.battle.waves_started = RunSession.RISK_CUTOFF
	late.battle.running = []
	var pair: Array = _saved(late)
	var late_battle: Battle = Battle.from_data(pair[1], catalog)
	if late_battle != null:
		assert_null(RunSession.from_data(pair[0], late_battle, Fx.run_data()), "picked after wave 17 started")


# the risk card a running wave took

func test_a_running_waves_risk_card_must_be_a_picked_one() -> void:
	# A run in wave 1 with no risk card picked: any risk entry is made up.
	var s: RunSession = Player.session(5, false, "", true)
	assert_eq(s.start_next_wave(), Battle.DONE)
	var pair: Array = _saved(s)
	assert_not_null(_load(pair.duplicate(true)))
	var huge: Array = []
	for i: int in 7:
		huge.append({"type": "count_pct", "pct": 1000, "flyers": false, "last_wave": false})
	var forged: Array = pair.duplicate(true)
	(forged[1] as Dictionary)["wave_risk"] = [{"wave": 0, "effects": huge}]
	assert_null(Battle.from_data(forged[1], catalog), "the battle itself refuses it: a group passes MAX_ENEMIES")
	for effect: Dictionary in huge:
		effect["pct"] = 150
	assert_null(_load(forged), "made up")
	var real_card: Array = pair.duplicate(true)
	(real_card[1] as Dictionary)["wave_risk"] = [{"wave": 0, "effects": _effects_of("crowded_night")}]
	assert_null(_load(real_card), "a real risk card that was never picked")


func test_a_real_running_wave_risk_card_loads_and_a_changed_one_is_refused() -> void:
	var s: RunSession = _with_risk_waiting(0)
	assert_eq(s.start_next_wave(), Battle.DONE)
	var taken: Array = s.battle.to_data()["wave_risk"]
	assert_eq(taken.size(), 1, "the wave took the card")
	var back: RunSession = _load(_saved(s))
	assert_not_null(back)
	assert_eq(Player.fingerprint(back), Player.fingerprint(s))
	var other: String = "flock" if s.picks.has(&"crowded_night") else "crowded_night"
	var changed: Array = _saved(s)
	(changed[1] as Dictionary)["wave_risk"][0]["effects"] = _effects_of(other)
	assert_null(_load(changed), "another card than the picked one")


# real saves load at every point

## Plays a run with its own choices at every draft (a risk card when one is offered, else a
## card that is taken once, else the first), saving and restoring at many points. Returns
## how often each kind of point came up, and the end state.
func _drive(run_seed: int, day: String, restoring: bool) -> Dictionary:
	var s: RunSession = RunSession.start(run_seed, day, false, _data.card_ids(), _data, catalog)
	var p: RefCounted = _player(run_seed)
	var seen: Dictionary = {"draft": 0, "risk_waiting": 0, "wave_risk": 0, "once": 0, "mid_wave": 0, "risk_picked": 0}
	var steps: int = 0
	while steps < 200000:
		if s.draft_open():
			if restoring:
				s = _restore(s)
				seen["draft"] += 1
			var offered: Array[StringName] = s.offers()
			var choice: StringName = offered[0]
			for id: StringName in offered:
				if s.card(id)["kind"] == &"risk":
					choice = id
					break
				if s.card(id)["once"] and s.card(choice)["kind"] != &"risk":
					choice = id
			assert_eq(s.pick(choice), Battle.DONE)
			if s.card(choice)["kind"] == &"risk":
				seen["risk_picked"] += 1
			if restoring:
				s = _restore(s)
				if s.card(choice)["kind"] == &"risk":
					assert_eq(s.risk_card(), choice)
					seen["risk_waiting"] += 1
				if s.card(choice)["once"]:
					seen["once"] += 1
		if not p.advance(s):
			break
		steps += 1
		if restoring and s.battle.phase == Battle.Phase.WAVE:
			if not (s.battle.to_data()["wave_risk"] as Array).is_empty() and steps % 40 == 0:
				s = _restore(s)
				seen["wave_risk"] += 1
			elif steps % 400 == 0:
				s = _restore(s)
				seen["mid_wave"] += 1
	seen["fingerprint"] = Player.fingerprint(s)
	return seen


func _restore(s: RunSession) -> RunSession:
	var pair: Array = _saved(s)
	var back: RunSession = _load(pair)
	assert_not_null(back, "a real save loads")
	if back == null:
		return s
	assert_eq(Player.fingerprint(back), Player.fingerprint(s), "the same state right after the load")
	return back


func test_real_saves_at_every_point_load_and_play_on_the_same() -> void:
	var totals: Dictionary = {"draft": 0, "risk_waiting": 0, "wave_risk": 0, "once": 0, "mid_wave": 0, "risk_picked": 0}
	for run_seed: int in [1, 2, 3, 4, 5, 6]:
		var whole: Dictionary = _drive(run_seed, "", false)
		var cut: Dictionary = _drive(run_seed, "", true)
		assert_eq(cut["fingerprint"], whole["fingerprint"], "seed %d" % run_seed)
		for key: String in totals.keys():
			totals[key] += int(cut[key])
	for key: String in totals.keys():
		assert_true(totals[key] > 0, "the points of kind %s came up" % key)


func test_real_daily_saves_load_and_play_on_the_same() -> void:
	var whole: Dictionary = _drive(DAY_SEED, DAY, false)
	var cut: Dictionary = _drive(DAY_SEED, DAY, true)
	assert_eq(cut["fingerprint"], whole["fingerprint"])
	assert_true(cut["draft"] > 0)
	assert_true(cut["once"] > 0)


## The real cards, run plan, segments and packs: saves of played runs load and play on the same.
func test_real_data_saves_load_and_play_on_the_same() -> void:
	var files: Dictionary = {}
	var paths: Array[String] = ["runs/run.json", "cards/cards.json", "segments/index.json", "segments/packs.json"]
	for rel: String in paths:
		var got: Dictionary = JsonFile.read("res://data/" + rel, 262144)
		assert_eq(got["status"], JsonFile.OK_STATUS, rel)
		files[rel] = got["data"]
	for id: Variant in files["segments/index.json"]["segments"]:
		var rel: String = "segments/%s.json" % id
		var got: Dictionary = JsonFile.read("res://data/" + rel, 16384)
		assert_eq(got["status"], JsonFile.OK_STATUS, rel)
		files[rel] = got["data"]
	catalog = Golden.catalog()  # the real stats, which the real run.json (tier 1 and all) names
	_data = RunData.from_data(files, catalog)
	assert_not_null(_data)
	if _data == null:
		return
	var risks: int = 0
	var drafts: int = 0
	for run_seed: int in [1, 2, 3, 4]:
		var whole: Dictionary = _drive(run_seed, "", false)
		var cut: Dictionary = _drive(run_seed, "", true)
		assert_eq(cut["fingerprint"], whole["fingerprint"], "seed %d" % run_seed)
		risks += int(cut["risk_waiting"])
		drafts += int(cut["draft"])
	assert_true(drafts >= 20, "%d drafts were saved and loaded" % drafts)
	assert_true(risks > 0, "a real risk card was saved while waiting")


## The three changed unlockable perks (G5) tie to their picks in a saved run: it loads, and a
## save with another number for the perk's effect is refused.
func test_a_saved_run_with_a_changed_unlockable_perk_loads_and_a_changed_number_is_refused() -> void:
	var files: Dictionary = {}
	var paths: Array[String] = ["runs/run.json", "cards/cards.json", "segments/index.json", "segments/packs.json"]
	for rel: String in paths:
		files[rel] = JsonFile.read("res://data/" + rel, 262144)["data"]
	for id: Variant in files["segments/index.json"]["segments"]:
		var rel: String = "segments/%s.json" % id
		files[rel] = JsonFile.read("res://data/" + rel, 16384)["data"]
	catalog = Golden.catalog()  # the real stats, which the real run.json (tier 1 and all) names
	_data = RunData.from_data(files, catalog)
	assert_not_null(_data)
	if _data == null:
		return
	var cases: Array = [
		[&"tower_lullaby_bell", &"frost_chime", "reach", -25.0],
		[&"tower_longbow_loft", &"volley", "damage", 85.0],
		[&"tower_firework_tower", &"long_fuse", "reload_ms", 250.0],
	]
	for item: Array in cases:
		var tower_card: StringName = item[0]
		var perk: StringName = item[1]
		var pool: Array[StringName] = [tower_card, perk, &"gold_purse"]
		var s: RunSession = RunSession.start(7, "", false, pool, _data, catalog)
		assert_not_null(s)
		var p: RefCounted = _player(7)
		assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open()))
		assert_true(s.offers().has(tower_card), "the first draft offers the tower card")
		assert_eq(s.pick(tower_card), Battle.DONE)
		assert_true(_advance_until(p, s, func(x: RunSession) -> bool: return x.draft_open()))
		assert_true(s.offers().has(perk), "%s is offered with no base perk in the pool" % perk)
		assert_eq(s.pick(perk), Battle.DONE)
		var pair: Array = _saved(s)
		assert_not_null(_load(pair.duplicate(true)), "%s: the save loads" % perk)
		var found: bool = false
		var changed: Array = pair.duplicate(true)
		for effect: Dictionary in (changed[1] as Dictionary)["effects"]:
			for key: String in ["amount", "pct"]:
				if effect.get("stat", "") == item[2] and effect.has(key) and absf(float(effect[key]) - float(item[3])) < 0.01:
					effect[key] = float(effect[key]) + 1.0
					found = true
		assert_true(found, "%s keeps the new number %s in the battle" % [perk, item[3]])
		assert_null(_load(changed), "%s: a changed number is refused" % perk)
