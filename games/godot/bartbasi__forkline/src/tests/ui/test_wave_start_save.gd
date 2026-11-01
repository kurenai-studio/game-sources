# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Starting a wave is a save point (docs/ARCHITECTURE.md 5.1 and 6; QA 2026-10-27, m1). A kill
## right after a wave starts, with no leave and no pause, brings the game back inside that
## wave with the build locked in, in a level, a run and the daily. The resumed wave plays out
## the same as one that was never killed. No running scene tree.

const Fx: GDScript = preload("res://tests/ui/flow_fixtures.gd")
const TAG: String = "wavesave"
const DAY: Dictionary = {"year": 2026, "month": 10, "day": 27}

var apps: Array[App] = []


func before_each() -> void:
	apps.clear()
	Fx.wipe(TAG)


func after_each() -> void:
	for made: App in apps:
		made.free()
	Fx.wipe(TAG)


func _app(fresh: bool = true) -> App:
	var made: App = Fx.run_app(TAG, fresh, DAY)
	apps.append(made)
	return made


## The app is dropped as a kill does it: no leave, no pause, no notification.
func _kill(made: App) -> void:
	apps.erase(made)
	made.free()


func _saved_on_disk() -> Array[SavedGame]:
	return SaveStore.new(Fx.dir(TAG)).load_games(Fx.BattleFixtures.game())


func _start(made: App, mode: StringName) -> BattleScreen:
	made.open_mode()
	if mode == SavedGame.LEVEL:
		made.campaign_requested.emit()
		(made.current_screen() as LevelSelect).level_chosen.emit(&"r1_l1")
		(made.current_screen() as LevelCard).play_requested.emit(false)
	else:
		if mode == SavedGame.RUN:
			made.roguelite_requested.emit()
		else:
			made.daily_requested.emit()
		(made.current_screen() as RunCard).start_button.tapped.emit()
	var screen: BattleScreen = made.battle_screen()
	assert_not_null(screen, "the game starts")
	return screen


## Builds one tower, then starts the wave from the HUD. Lives are raised first so the
## wave plays out whatever the build.
func _start_wave(screen: BattleScreen) -> void:
	var b: Battle = screen.battle
	Fx.build(screen, b.level.spots[0], b.level.towers[0])
	b.lives = 500
	screen.hud.call_button.tapped.emit()
	assert_eq(b.phase, Battle.Phase.WAVE, "the wave has started")


## Continue on the mode screen of a second app run on the same saves.
func _resume(mode: StringName) -> BattleScreen:
	var again: App = _app(false)
	again.open_mode()
	var card: ModeScreen = again.current_screen() as ModeScreen
	assert_not_null(card.continue_button, "a saved game is waiting")
	card.continue_button.tapped.emit()
	var screen: BattleScreen = again.battle_screen()
	assert_not_null(screen, "Continue resumes the %s" % mode)
	return screen


func _modes() -> Array[StringName]:
	return [SavedGame.LEVEL, SavedGame.RUN, SavedGame.DAILY]


func test_a_kill_right_after_a_wave_starts_resumes_inside_that_wave() -> void:
	for mode: StringName in _modes():
		var made: App = _app()
		var screen: BattleScreen = _start(made, mode)
		_start_wave(screen)
		var tick: int = screen.battle.tick
		var towers: int = screen.battle.towers.size()
		_kill(made)
		var games: Array[SavedGame] = _saved_on_disk()
		assert_eq(games.size(), 1, "%s: one saved game" % mode)
		assert_eq(games[0].mode, mode)
		assert_eq(games[0].battle.phase, Battle.Phase.WAVE, "%s: saved in the wave, not the build phase" % mode)
		assert_eq(games[0].battle.waves_started, 1, "%s: wave 1 has started" % mode)
		var resumed: BattleScreen = _resume(mode)
		assert_eq(resumed.battle.phase, Battle.Phase.WAVE, "%s: resumes in the wave" % mode)
		assert_eq(resumed.battle.waves_started, 1)
		assert_eq(resumed.battle.tick, tick, "%s: the exact moment" % mode)
		assert_eq(resumed.battle.towers.size(), towers, "%s: the build stays" % mode)
		assert_true(resumed.is_paused(), "%s: resumed paused" % mode)
		_free_all()


func test_the_resumed_wave_plays_out_the_same() -> void:
	for mode: StringName in _modes():
		var made: App = _app()
		var screen: BattleScreen = _start(made, mode)
		_start_wave(screen)
		var before: String = JSON.stringify(screen.battle.to_data())
		# The wave goes on without a kill (stepping the battle writes no save), noted at 40
		# ticks and at its end. Then the app is killed with the start of the wave on disk.
		Fx.BattleFixtures.steps(screen.battle, 40)
		var plain_40: String = JSON.stringify(screen.battle.to_data())
		Fx.BattleFixtures.finish_wave(screen.battle)
		var plain_end: String = JSON.stringify(screen.battle.to_data())
		var plain_phase: Battle.Phase = screen.battle.phase
		var plain_run: String = JSON.stringify(screen.run.to_data()) if screen.run != null else ""
		_kill(made)
		var resumed: BattleScreen = _resume(mode)
		var copy: Battle = resumed.battle
		assert_eq(JSON.stringify(copy.to_data()), before, "%s: the save is the moment of the start" % mode)
		Fx.BattleFixtures.steps(copy, 40)
		assert_eq(JSON.stringify(copy.to_data()), plain_40, "%s: same after 40 ticks" % mode)
		Fx.BattleFixtures.finish_wave(copy)
		assert_eq(copy.phase, plain_phase, "%s: same phase at the end" % mode)
		assert_eq(JSON.stringify(copy.to_data()), plain_end, "%s: same wave, same end" % mode)
		if mode != SavedGame.LEVEL:
			assert_eq(JSON.stringify(resumed.run.to_data()), plain_run, "%s: same run" % mode)
		_free_all()


func test_an_early_call_saves_too_and_a_kill_keeps_both_waves() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made, SavedGame.LEVEL)
	_start_wave(screen)
	Fx.BattleFixtures.steps(screen.battle, 95)  # wave 1 has spawned all four, so a call is allowed
	assert_eq(screen.battle.phase, Battle.Phase.WAVE)
	screen.hud.call_button.tapped.emit()
	assert_eq(screen.battle.waves_started, 2, "the early call started wave 2")
	var after: String = JSON.stringify(screen.battle.to_data())
	_kill(made)
	var games: Array[SavedGame] = _saved_on_disk()
	assert_eq(games[0].battle.waves_started, 2, "the save holds the early call")
	assert_eq(JSON.stringify(games[0].battle.to_data()), after, "and the exact moment of it")


func test_a_wave_start_asks_for_one_save() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made, SavedGame.LEVEL)
	var saves: Array[int] = [0]
	screen.save_requested.connect(func() -> void: saves[0] += 1)
	var b: Battle = screen.battle
	Fx.build(screen, b.level.spots[0], b.level.towers[0])
	assert_eq(saves[0], 0, "building asks for nothing")
	screen.hud.call_button.tapped.emit()
	assert_eq(saves[0], 1, "one save for the wave start")
	Fx.BattleFixtures.steps(b, 20)
	screen.frame(0.05)
	assert_eq(saves[0], 1, "and none while it runs")


func test_a_refused_call_does_not_save() -> void:
	var made: App = _app()
	var screen: BattleScreen = _start(made, SavedGame.RUN)
	var saves: Array[int] = [0]
	screen.save_requested.connect(func() -> void: saves[0] += 1)
	# The run owes no card before wave 1, so force a refusal another way: no waves left.
	screen.battle.waves_started = screen.battle.wave_count()
	screen.hud.call_button.tapped.emit()
	assert_eq(saves[0], 0, "a refused call saves nothing")


func _free_all() -> void:
	for made: App in apps:
		made.free()
	apps.clear()
	Fx.wipe(TAG)
