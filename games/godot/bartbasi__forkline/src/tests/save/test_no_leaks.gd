# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Save objects are freed as soon as their last user lets go (QA p7).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")


func before_each() -> void:
	Fx.fresh()


func after_each() -> void:
	Fx.clean()


func test_store_game_data_and_loaded_saves_are_freed() -> void:
	var game: GameData = Fx.game()
	var store: SaveStore = SaveStore.new(Fx.WORK)
	assert_true(store.save_game(Fx.saved(SavedGame.LEVEL, Fx.battle_mid_wave(game, &"r1_l1", false, 120))), "the game saves")
	assert_true(store.save_game(Fx.saved_run(Fx.daily(game, "2026-10-23"))), "the daily saves")
	var record: DailyRecord = DailyRecord.new()
	record.record_finish("2026-10-23", {"won": true, "waves": 18, "lives": 4})
	assert_true(store.save_daily(record), "the daily record saves")
	assert_true(store.save_settings(Settings.from_data({"format": 1, "sound": false})), "settings save")
	assert_true(store.save_progress(Progress.from_data({})), "progress saves")
	var loaded: Array[SavedGame] = store.load_games(game)
	assert_eq(loaded.size(), 2, "the saved games load")
	var daily: DailyRecord = store.load_daily()
	var settings: Settings = store.load_settings()
	var progress: Progress = store.load_progress()
	assert_false(settings.sound_on, "the saved setting reads back")
	var refs: Dictionary[String, WeakRef] = {
		"game data": weakref(game),
		"catalog": weakref(game.catalog),
		"store": weakref(store),
		"settings": weakref(settings),
		"progress": weakref(progress),
		"saved game": weakref(loaded[0]),
		"saved battle": weakref(loaded[0].battle),
		"saved run": weakref(loaded[1].run if loaded[1].run != null else loaded[0].run),
		"run data": weakref(game.run),
		"daily record": weakref(daily),
	}
	game = null
	store = null
	settings = null
	progress = null
	record = null
	daily = null
	loaded.clear()
	for key: String in refs:
		assert_null(refs[key].get_ref(), key + " is freed")
