# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Saved games: one per mode, resumed at the exact moment, the Continue order, and
## invalid saves deleted (docs/ARCHITECTURE.md 3.5, 5.4, 5.5, 5.6, 6; RULES 4.10, 14.7).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")

var game: GameData = null
var store: SaveStore = null


func before_each() -> void:
	Fx.fresh()
	game = Fx.game()
	store = SaveStore.new(Fx.WORK)


func after_each() -> void:
	store = null
	Fx.clean()


func _find(list: Array[SavedGame], mode: StringName) -> SavedGame:
	for saved: SavedGame in list:
		if saved.mode == mode:
			return saved
	return null


func _modes(list: Array[SavedGame]) -> Array[StringName]:
	var out: Array[StringName] = []
	for saved: SavedGame in list:
		out.append(saved.mode)
	return out


## A run or daily played into a wave with creatures on the map.
func _run_mid_wave(run_seed: int, day: String, relaxed: bool, waves: int) -> RunSession:
	var session: RunSession = Fx.session(game, run_seed, day, relaxed)
	assert_not_null(session)
	var p: RefCounted = Fx.player(run_seed)
	assert_true(Fx.play_until(session, p, func(s: RunSession) -> bool:
		return s.battle.waves_started >= waves and s.battle.phase == Battle.Phase.WAVE and s.battle.enemies.size() >= 1))
	return session


func _saved_of(mode: StringName, battle: Battle, runs: Dictionary) -> SavedGame:
	if runs.has(mode):
		return Fx.saved_run(runs[mode])
	return Fx.saved(mode, battle)


func test_each_mode_resumes_to_an_identical_battle() -> void:
	var runs: Dictionary = {
		SavedGame.RUN: _run_mid_wave(77, "", true, 3),
		SavedGame.DAILY: _run_mid_wave(20261023, "2026-10-23", false, 4),
	}
	var battles: Dictionary = {
		SavedGame.LEVEL: Fx.battle_mid_wave(game, &"r1_l1", false, 150),
		SavedGame.RUN: (runs[SavedGame.RUN] as RunSession).battle,
		SavedGame.DAILY: (runs[SavedGame.DAILY] as RunSession).battle,
	}
	for mode: StringName in battles:
		var battle: Battle = battles[mode]
		assert_eq(battle.phase, Battle.Phase.WAVE, String(mode))
		assert_false(battle.enemies.is_empty(), "%s has creatures on the map" % mode)
		assert_true(store.save_game(_saved_of(mode, battle, runs)), String(mode))
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(loaded.size(), 3)
	for mode: StringName in battles:
		var original: Battle = battles[mode]
		var saved: SavedGame = _find(loaded, mode)
		assert_not_null(saved, String(mode))
		if saved == null:
			continue
		assert_eq(Fx.battle_text(saved.battle), Fx.battle_text(original), "%s resumes at the exact moment" % mode)
		assert_eq(saved.level_id, original.level.id if mode == SavedGame.LEVEL else &"")
		if mode == SavedGame.LEVEL:
			assert_null(saved.run)
		else:
			assert_not_null(saved.run, String(mode))
			assert_true(saved.run.battle == saved.battle, "the run is around the saved battle")
			assert_eq(JSON.stringify(saved.run.to_data()), JSON.stringify((runs[mode] as RunSession).to_data()))
		# Played on, the resumed battle stays the same as the one never saved.
		for i: int in 400:
			original.step()
			saved.battle.step()
		assert_eq(Fx.battle_text(saved.battle), Fx.battle_text(original), "%s plays on the same" % mode)


func test_build_phase_resumes_too() -> void:
	var battle: Battle = Battle.create(game.levels[&"r1_l2"], game.catalog, false, [])
	battle.place_tower(battle.level.spots[1], &"pumpkin_catapult")
	battle.place_gate(battle.level.sockets[0])
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, battle)))
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(loaded.size(), 1)
	assert_eq(Fx.battle_text(loaded[0].battle), Fx.battle_text(battle))
	assert_eq(loaded[0].battle.phase, Battle.Phase.BUILD)


func test_continue_picks_the_most_recent() -> void:
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 10))))
	assert_true(store.save_game(Fx.saved_run(Fx.daily(game, "2026-10-23"))))
	assert_true(store.save_game(Fx.saved_run(Fx.session(game, 5))))
	var next: SaveStore = SaveStore.new(Fx.WORK)
	var loaded: Array[SavedGame] = next.load_games(game)
	assert_eq(_modes(loaded), [SavedGame.RUN, SavedGame.DAILY, SavedGame.LEVEL] as Array[StringName])
	# Saving the level again makes it the most recent, in this launch and the next.
	var level_game: SavedGame = _find(loaded, SavedGame.LEVEL)
	level_game.battle.step()
	assert_true(next.save_game(level_game))
	assert_eq(_modes(SaveStore.new(Fx.WORK).load_games(game))[0], SavedGame.LEVEL)
	assert_true(level_game.order > _find(loaded, SavedGame.RUN).order)


func test_modes_stay_separate() -> void:
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 10))))
	assert_true(store.save_game(Fx.saved_run(Fx.session(game, 9))))
	assert_true(store.save_game(Fx.saved_run(Fx.daily(game, "2026-11-02"))))
	assert_true(Fx.exists("game_level.json"))
	assert_true(Fx.exists("game_run.json"))
	assert_true(Fx.exists("game_daily.json"))
	# A second level replaces only the level's game.
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l4", false, 10))))
	store.delete_game(SavedGame.RUN)
	assert_false(Fx.exists("game_run.json"))
	assert_false(Fx.exists("game_run.json.bak"))
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(_modes(loaded), [SavedGame.LEVEL, SavedGame.DAILY] as Array[StringName])
	assert_eq(_find(loaded, SavedGame.LEVEL).level_id, &"r1_l4")


func test_games_that_cannot_be_saved_are_refused() -> void:
	assert_false(store.save_game(null))
	var empty: SavedGame = SavedGame.new()
	assert_false(store.save_game(empty), "no battle")
	var run: RunSession = Fx.session(game, 3)
	var daily: RunSession = Fx.daily(game, "2026-10-23")
	assert_false(store.save_game(Fx.saved(SavedGame.RUN, run.battle)), "a run without its run")
	assert_false(store.save_game(Fx.saved(SavedGame.DAILY, daily.battle)), "a daily without its run")
	var level_with_run: SavedGame = Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 5))
	level_with_run.run = run
	assert_false(store.save_game(level_with_run), "a campaign level with a run")
	var other_battle: SavedGame = Fx.saved_run(run)
	other_battle.battle = Fx.session(game, 3).battle
	assert_false(store.save_game(other_battle), "a run around another battle")
	var daily_as_run: SavedGame = Fx.saved_run(daily)
	daily_as_run.mode = SavedGame.RUN
	assert_false(store.save_game(daily_as_run), "a daily in the run's file")
	var run_as_daily: SavedGame = Fx.saved_run(run)
	run_as_daily.mode = SavedGame.DAILY
	assert_false(store.save_game(run_as_daily), "a run in the daily's file")
	var odd: SavedGame = Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 5))
	odd.mode = &"arena"
	assert_false(store.save_game(odd), "unknown mode")
	var lost: Battle = Fx.battle_mid_wave(game, &"r1_l1", false, 0)
	lost.lives = 1
	for i: int in 100000:
		if lost.phase == Battle.Phase.WON or lost.phase == Battle.Phase.LOST:
			break
		if lost.phase == Battle.Phase.BUILD:
			lost.start_next_wave()
		else:
			lost.step()
	assert_true(lost.phase == Battle.Phase.WON or lost.phase == Battle.Phase.LOST)
	assert_false(store.save_game(Fx.saved(SavedGame.LEVEL, lost)), "a finished battle is not saved")
	assert_eq(DirAccess.get_files_at(Fx.WORK).size(), 0)


func test_tmp_wins_for_a_saved_game() -> void:
	var older: Battle = Fx.battle_mid_wave(game, &"r1_l1", false, 20)
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, older)))
	var newer: SavedGame = Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 90))
	newer.order = 50
	Fx.write_text("game_level.json.tmp", JsonFile.to_text(newer.to_data()))
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(loaded[0].battle.tick, newer.battle.tick)
	assert_false(Fx.exists("game_level.json.tmp"))


func test_bak_is_used_when_the_saved_game_is_bad() -> void:
	var first: Battle = Fx.battle_mid_wave(game, &"r1_l1", false, 20)
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, first)))
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 40))))
	var text: String = Fx.read_text("game_level.json")
	Fx.write_text("game_level.json", text.left(text.length() / 3))
	Fx.write_text("game_level.json.tmp", "{\"format\": 1}")
	var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(loaded.size(), 1)
	assert_eq(Fx.battle_text(loaded[0].battle), Fx.battle_text(first), "one save behind")
	assert_false(Fx.exists("game_level.json.tmp"), "a bad .tmp is deleted")


func test_no_valid_copy_deletes_all_three() -> void:
	Fx.write_text("game_run.json", "{\"format\": 1, \"mode\": \"run\"")
	Fx.write_text("game_run.json.bak", "[]")
	Fx.write_text("game_run.json.tmp", "")
	assert_eq(store.load_games(game).size(), 0)
	assert_false(Fx.exists("game_run.json"))
	assert_false(Fx.exists("game_run.json.bak"))
	assert_false(Fx.exists("game_run.json.tmp"))


func test_tampered_fields_make_the_game_invalid() -> void:
	var battle: Battle = Fx.battle_mid_wave(game, &"r1_l1", false, 120)
	var base: Dictionary = Fx.saved(SavedGame.LEVEL, battle).to_data()
	base["order"] = 3
	var cases: Dictionary = {
		"format 2": {"format": 2},
		"format text": {"format": "1"},
		"mode unknown": {"mode": "arena"},
		"mode of another file": {"mode": "run", "level_id": ""},
		"order past ceiling": {"order": 1e13},
		"order negative": {"order": -1},
		"order infinite": {"order": INF},
		"order fraction": {"order": 2.5},
		"level unknown": {"level_id": "r9_l9"},
		"level path": {"level_id": "../stats/rules"},
		"level other than battle": {"level_id": "r1_l2"},
		"twist without a Twist": {"twist": true},
		"twist as number": {"twist": 1},
		"run not null": {"run": {}},
		"battle missing": {"battle": null},
		"battle as text": {"battle": "res://src/sim/battle.gd"},
		"extra key": {"cheat": true},
	}
	var battle_cases: Dictionary = {
		"gold past ceiling": {"gold": 1e10},
		"gold infinite": {"gold": INF},
		"lives zero": {"lives": 0},
		"tick negative": {"tick": -5},
		"phase won": {"phase": "won"},
		"enemies wrong type": {"enemies": {"a": 1}},
		"level broken": {"level": {"format": 1}},
	}
	for name: String in battle_cases:
		var changed: Dictionary = base["battle"].duplicate(true)
		changed.merge(battle_cases[name], true)
		cases[name] = {"battle": changed}
	for name: String in cases:
		var data: Dictionary = base.duplicate(true)
		data.merge(cases[name], true)
		if name == "extra key":
			data["cheat"] = true
		var text: String = JSON.stringify(data)
		Fx.write_text("game_level.json", text)
		var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
		assert_eq(loaded.size(), 0, name)
		assert_false(Fx.exists("game_level.json"), "%s: deleted" % name)
	# The untouched data is valid, so each refusal above came from its one change.
	Fx.write_text("game_level.json", JSON.stringify(base))
	assert_eq(SaveStore.new(Fx.WORK).load_games(game).size(), 1)


func test_daily_is_always_normal() -> void:
	var data: Dictionary = Fx.through_json(Fx.saved_run(Fx.daily(game, "2026-10-23")).to_data())
	assert_not_null(SavedGame.from_data(data, game), "the Normal daily loads")
	data["battle"]["relaxed"] = true
	assert_null(SavedGame.from_data(data, game), "a Relaxed daily")
	var relaxed_run: Dictionary = Fx.through_json(Fx.saved_run(Fx.session(game, 4, "", true)).to_data())
	assert_not_null(SavedGame.from_data(relaxed_run, game), "a Relaxed run loads")


func test_game_in_the_wrong_file_is_deleted() -> void:
	var data: Dictionary = Fx.saved_run(Fx.session(game, 11)).to_data()
	Fx.write_text("game_daily.json", JSON.stringify(data))
	assert_eq(store.load_games(game).size(), 0)
	assert_false(Fx.exists("game_daily.json"))


func test_needs_valid_game_data() -> void:
	var data: Dictionary = Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 10)).to_data()
	assert_null(SavedGame.from_data(data, null))
	assert_null(SavedGame.from_data(data, GameData.new()))


## r1_l1 with a Twist added, as a level file would give it.
func _twist_game() -> GameData:
	var data: Dictionary = game.levels[&"r1_l1"].to_data()
	data["twist"] = {"name": "Thin Purse", "text": "Start with half the gold.",
		"effects": [{"type": "start_gold_pct", "pct": 50}, {"type": "speed_pct", "pct": 120}]}
	var twisted: LevelData = LevelData.from_data(JSON.parse_string(JSON.stringify(data)), game.catalog)
	assert_not_null(twisted)
	game.levels[&"r1_l1"] = twisted
	return game


func test_a_twist_game_must_hold_its_levels_twist_rules_13() -> void:
	var twisted: GameData = _twist_game()
	var level: LevelData = twisted.levels[&"r1_l1"]
	var battle: Battle = Battle.create(level, twisted.catalog, false, level.twist_effects)
	battle.place_tower(level.spots[0], level.towers[0])
	battle.start_next_wave()
	for i: int in 40:
		battle.step()
	var saved: SavedGame = Fx.saved(SavedGame.LEVEL, battle)
	saved.twist = true
	var data: Dictionary = JSON.parse_string(JSON.stringify(saved.to_data()))
	assert_not_null(SavedGame.from_data(data, twisted), "the Twist game loads")
	var plain: Dictionary = data.duplicate(true)
	plain["twist"] = false
	assert_null(SavedGame.from_data(plain, twisted), "a Twist battle saved as the plain level")
	var other: Dictionary = data.duplicate(true)
	other["battle"]["twist"] = [{"type": "start_gold_pct", "pct": 50}]
	assert_null(SavedGame.from_data(other, twisted), "Twist effects that are not the level's")
	var plain_battle: Dictionary = Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(twisted, &"r1_l1", false, 40)).to_data()
	var claimed: Dictionary = JSON.parse_string(JSON.stringify(plain_battle))
	claimed["twist"] = true
	assert_null(SavedGame.from_data(claimed, twisted), "a plain battle claiming the Twist")


func test_a_campaign_game_holds_no_cards_and_a_run_no_twist_rules_13_and_14() -> void:
	var battle: Battle = Fx.battle_mid_wave(game, &"r1_l1", false, 40)
	assert_eq(battle.add_effects([{"type": "bounty_pct", "pct": 200}] as Array[Dictionary], false), Battle.DONE)
	var as_level: Dictionary = JSON.parse_string(JSON.stringify(Fx.saved(SavedGame.LEVEL, battle).to_data()))
	assert_null(SavedGame.from_data(as_level, game), "a campaign level with a card")
	var run: RunSession = Fx.run_after_pick(game, &"fat_bounties")
	assert_not_null(run, "a run picks Fat Bounties")
	if run == null:
		return
	assert_false(run.battle.card_effects.is_empty(), "the run keeps a card")
	var as_run: Dictionary = Fx.through_json(Fx.saved_run(run).to_data())
	assert_not_null(SavedGame.from_data(as_run, game), "a run takes cards")
	var twisted: Dictionary = as_run.duplicate(true)
	twisted["battle"]["twist"] = [{"type": "no_selling"}]
	assert_null(SavedGame.from_data(twisted, game), "a run has no Twist")


## Starts the next wave and plays 40 ticks of it.
func _into_wave(battle: Battle) -> void:
	battle.start_next_wave()
	for i: int in 40:
		battle.step()
	assert_eq(battle.phase, Battle.Phase.WAVE)


## 1-1 after the effects of a card the campaign never offers.
func _after_card(card_id: StringName) -> Battle:
	var card: Dictionary = game.run.card(card_id)
	var effects: Array[Dictionary] = []
	for effect: Dictionary in card["effects"]:
		effects.append(effect)
	var battle: Battle = Battle.create(game.levels[&"r1_l1"], game.catalog, false, [])
	battle.place_tower(battle.level.spots[0], battle.level.towers[0])
	assert_eq(battle.add_effects(effects, card["kind"] == &"risk"), Battle.DONE, String(card_id))
	_into_wave(battle)
	return battle


func test_a_campaign_game_holds_nothing_only_cards_give_contract_2_8() -> void:
	# Only risk cards make a wave take a risk card or open every gate, and only cards add
	# gates. Each of these loads as a run that picked the card and is refused as a
	# campaign level.
	var cases: Array = [
		["a wave that took a risk card", &"thick_hides", "wave_risk"],
		["gates standing open", &"gateless_night", "gates_open"],
		["gates added by a card", &"spare_gate", "gates_added"],
	]
	for item: Array in cases:
		var run: RunSession = Fx.run_after_pick(game, item[1])
		assert_not_null(run, "a run picks %s" % item[1])
		if run == null:
			continue
		assert_eq(run.start_next_wave(), Battle.DONE, "%s: the next wave starts" % item[0])
		_into_wave(run.battle)
		var as_run: Dictionary = Fx.through_json(Fx.saved_run(run).to_data())
		var in_run: Dictionary = as_run["battle"]
		var key: String = item[2]
		assert_true(in_run[key] is Array and not (in_run[key] as Array).is_empty() or in_run[key] is bool and in_run[key] or in_run[key] is float and in_run[key] > 0, "%s shows in the run's %s" % [item[0], key])
		assert_not_null(SavedGame.from_data(as_run, game), "%s loads as a run" % item[0])
		var battle: Battle = _after_card(item[1])
		var as_level: Dictionary = JSON.parse_string(JSON.stringify(Fx.saved(SavedGame.LEVEL, battle).to_data()))
		var inner: Dictionary = as_level["battle"]
		assert_true(inner[key] is Array and not (inner[key] as Array).is_empty() or inner[key] is bool and inner[key] or inner[key] is float and inner[key] > 0, "%s shows in %s" % [item[0], key])
		assert_true((inner["effects"] as Array).is_empty() and (inner["risk"] as Array).is_empty(), "%s keeps no card" % item[0])
		assert_null(SavedGame.from_data(as_level, game), "%s is refused as a campaign level" % item[0])
	var plain: Battle = Fx.battle_mid_wave(game, &"r1_l1", false, 40)
	assert_not_null(SavedGame.from_data(JSON.parse_string(JSON.stringify(Fx.saved(SavedGame.LEVEL, plain).to_data())), game), "a plain level loads")
