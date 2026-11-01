# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Hostile bytes in every save file: each falls back safely with no script error, and
## the next save works (docs/ARCHITECTURE.md 5.2, 5.4, 10).

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")

var game: GameData = null


func before_each() -> void:
	Fx.fresh()
	game = Fx.game()


func after_each() -> void:
	Fx.clean()


func _valid_game_text(mode: StringName) -> String:
	return JsonFile.to_text(_game_of(mode, 60).to_data())


## A saved game of the mode: a level played a while, or a new run or daily.
func _game_of(mode: StringName, ticks: int) -> SavedGame:
	if mode == SavedGame.RUN:
		return Fx.saved_run(Fx.session(game, ticks))
	if mode == SavedGame.DAILY:
		return Fx.saved_run(Fx.daily(game, "2026-10-23"))
	return Fx.saved(mode, Fx.battle_mid_wave(game, &"r1_l1" if ticks == 60 else &"r1_l2", false, ticks))


func test_hostile_settings_give_defaults() -> void:
	var cases: Dictionary = Fx.hostile_files("{\"format\":1,\"sound\":false}", SaveStore.SETTINGS_CAP)
	cases["sound as text"] = "{\"format\": 1, \"sound\": \"false\"}".to_ascii_buffer()
	cases["sound as number"] = "{\"format\": 1, \"sound\": 0}".to_ascii_buffer()
	cases["sound infinite"] = "{\"format\": 1, \"sound\": -1e999}".to_ascii_buffer()
	for name: String in cases:
		Fx.fresh()
		Fx.write_bytes("settings.json", cases[name])
		var store: SaveStore = SaveStore.new(Fx.WORK)
		assert_true(store.load_settings().sound_on, name)
		var off: Settings = Settings.new()
		off.sound_on = false
		assert_true(store.save_settings(off), "%s: the next save works" % name)
		assert_false(SaveStore.new(Fx.WORK).load_settings().sound_on, name)


func test_hostile_progress_gives_defaults() -> void:
	var cases: Dictionary = Fx.hostile_files("{\"format\":1,\"levels\":{\"r1_l1\":7},\"seen\":[],\"twists\":[],\"counters\":{}}", SaveStore.PROGRESS_CAP)
	cases["levels as list"] = "{\"format\": 1, \"levels\": [7, 7]}".to_ascii_buffer()
	cases["stars past range"] = "{\"format\": 1, \"levels\": {\"r1_l1\": 1e300}}".to_ascii_buffer()
	cases["counter infinite"] = "{\"format\": 1, \"counters\": {\"runs_won\": 1e999}}".to_ascii_buffer()
	cases["counter past ceiling"] = "{\"format\": 1, \"counters\": {\"runs_won\": 1000000001}}".to_ascii_buffer()
	cases["seen of objects"] = "{\"format\": 1, \"seen\": [{\"a\": 1}, [\"b\"], null, true]}".to_ascii_buffer()
	cases["key with a path"] = "{\"format\": 1, \"levels\": {\"../../x\": 7, \"res://a\": 7}}".to_ascii_buffer()
	for name: String in cases:
		Fx.fresh()
		Fx.write_bytes("progress.json", cases[name])
		var store: SaveStore = SaveStore.new(Fx.WORK)
		var loaded: Progress = store.load_progress()
		assert_eq(loaded.stars(), 0, name)
		assert_eq(loaded.seen.size(), 0, name)
		assert_eq(loaded.counters[&"runs_won"], 0, name)
		var progress: Progress = Progress.new()
		progress.record_level(&"r1_l1", 3)
		assert_true(store.save_progress(progress), "%s: the next save works" % name)
		assert_eq(SaveStore.new(Fx.WORK).load_progress().stars(), 2, name)


func test_hostile_daily_record_gives_defaults() -> void:
	var good: String = "{\"best\":{\"lives\":3,\"waves\":18,\"won\":true},\"day\":\"2026-10-23\",\"format\":1,\"streak\":4,\"streak_day\":\"2026-10-23\"}"
	var cases: Dictionary = Fx.hostile_files(good, SaveStore.DAILY_CAP)
	cases["streak infinite"] = "{\"format\": 1, \"streak\": 1e999}".to_ascii_buffer()
	cases["streak past ceiling"] = "{\"format\": 1, \"streak\": 100001}".to_ascii_buffer()
	cases["day with a path"] = "{\"format\": 1, \"day\": \"../../x\", \"best\": {\"won\": true, \"waves\": 1, \"lives\": 1}}".to_ascii_buffer()
	cases["best of objects"] = "{\"format\": 1, \"day\": \"2026-10-23\", \"best\": {\"won\": {}, \"waves\": [], \"lives\": null}}".to_ascii_buffer()
	for name: String in cases:
		Fx.fresh()
		Fx.write_bytes("daily.json", cases[name])
		var store: SaveStore = SaveStore.new(Fx.WORK)
		var loaded: DailyRecord = store.load_daily()
		assert_eq(loaded.day, "", name)
		assert_eq(loaded.best, {}, name)
		assert_eq(loaded.streak, 0, name)
		var record: DailyRecord = DailyRecord.new()
		record.record_finish("2026-10-24", {"won": false, "waves": 7, "lives": 0})
		assert_true(store.save_daily(record), "%s: the next save works" % name)
		assert_eq(SaveStore.new(Fx.WORK).load_daily().best, {"won": false, "waves": 7, "lives": 0}, name)


func test_hostile_saved_games_are_deleted() -> void:
	for mode: StringName in SavedGame.MODES:
		var file_name: String = SaveStore.GAME_FILES[mode]
		var cases: Dictionary = Fx.hostile_files(_valid_game_text(mode), SaveStore.GAME_CAP)
		for name: String in cases:
			Fx.fresh()
			Fx.write_bytes(file_name, cases[name])
			var store: SaveStore = SaveStore.new(Fx.WORK)
			assert_eq(store.load_games(game).size(), 0, "%s %s" % [mode, name])
			assert_false(Fx.exists(file_name), "%s %s: deleted" % [mode, name])
			assert_true(store.save_game(_game_of(mode, 30)), "%s %s: the next save works" % [mode, name])
			var loaded: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
			assert_eq(loaded.size(), 1, "%s %s" % [mode, name])


func test_hostile_tmp_never_beats_a_good_file() -> void:
	# "huge" is over both caps, so it is refused for both files.
	var cases: Dictionary = Fx.hostile_files("{\"format\":1,\"sound\":true}", SaveStore.PROGRESS_CAP)
	for name: String in cases:
		Fx.fresh()
		Fx.write_text("settings.json", "{\"format\":1,\"sound\":false}")
		Fx.write_text("progress.json", "{\"format\":1,\"levels\":{\"r1_l1\":7}}")
		Fx.write_bytes("settings.json.tmp", cases[name])
		Fx.write_bytes("progress.json.tmp", cases[name])
		var parsed: Dictionary = JsonFile.read(Fx.path("settings.json.tmp"), SaveStore.SETTINGS_CAP)
		# A .tmp that parses to an object with this build's format is valid and wins; its bad
		# fields fall back to defaults. Anything else is passed over and deleted.
		var tmp_wins: bool = parsed["status"] == JsonFile.OK_STATUS and typeof(parsed["data"]) == TYPE_DICTIONARY 				and DataCheck.is_whole((parsed["data"] as Dictionary).get("format", null)) and int(parsed["data"]["format"]) == 1
		var store: SaveStore = SaveStore.new(Fx.WORK)
		assert_eq(store.load_settings().sound_on, tmp_wins, name)
		assert_eq(store.load_progress().stars(), 0 if tmp_wins else 3, name)
		assert_false(Fx.exists("settings.json.tmp"), "%s: the .tmp is gone" % name)
		assert_false(Fx.exists("progress.json.tmp"), "%s: the .tmp is gone" % name)


func test_hostile_bak_is_passed_over() -> void:
	var cases: Dictionary = Fx.hostile_files("{\"format\":1}", SaveStore.PROGRESS_CAP)
	for name: String in cases:
		Fx.fresh()
		Fx.write_bytes("progress.json.bak", cases[name])
		Fx.write_bytes("game_level.json.bak", cases[name])
		var store: SaveStore = SaveStore.new(Fx.WORK)
		assert_eq(store.load_progress().stars(), 0, name)
		assert_eq(store.load_games(game).size(), 0, name)
		assert_false(Fx.exists("game_level.json.bak"), "%s: deleted" % name)
		assert_true(store.save_progress(Progress.new()), name)
