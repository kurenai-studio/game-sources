# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## S8's old save: a mid-wave game_level.json made by the build before the expansion still
## loads and plays on the same (docs/ARCHITECTURE.md 14.7, 14.13).

const Old: GDScript = preload("res://tests/sim/fixtures/old_save.gd")


func _expected() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(Old.DIR + "played_on.json"))


func test_old_save_loads_as_a_saved_game_with_todays_data() -> void:
	var game: GameData = GameData.load_from()
	assert_true(game.problems.is_empty(), "the bundled data is valid")
	var saved: SavedGame = SavedGame.from_data(Old.save_data(), game)
	assert_not_null(saved, "the old game_level.json loads")
	if saved == null:
		return
	assert_eq(saved.level_id, &"r4_l4")
	assert_eq(saved.battle.phase, Battle.Phase.WAVE, "saved mid-wave")
	var breaking: bool = false
	for enemy: EnemyState in saved.battle.enemies:
		breaking = breaking or enemy.breaking > 0
	assert_true(breaking, "a gate breaker is breaking")
	# It plays on to an end with today's data, whatever that end is.
	var got: Dictionary = Old.play_on(saved.battle)
	assert_true(int(got["phase"]) == Battle.Phase.WON or int(got["phase"]) == Battle.Phase.LOST, "it plays to an end")


func test_old_save_plays_on_the_same_as_the_build_that_made_it() -> void:
	var data: Dictionary = Old.save_data()
	var b: Battle = Battle.from_data(data["battle"], Old.old_catalog())
	assert_not_null(b, "the old battle loads with the old stats")
	if b == null:
		return
	var got: Dictionary = Old.play_on(b)
	var want: Dictionary = _expected()
	assert_eq(int(got["phase"]), int(want["phase"]))
	assert_eq(int(got["tick"]), int(want["tick"]))
	var got_points: Array = got["checkpoints"]
	var want_points: Array = want["checkpoints"]
	assert_eq(got_points.size(), want_points.size(), "as many checkpoints")
	for i: int in mini(got_points.size(), want_points.size()):
		var g: Dictionary = got_points[i]
		var w: Dictionary = want_points[i]
		assert_eq(int(g["tick"]), int(w["tick"]))
		assert_eq(g["state"], w["state"], "the state up to tick %d" % int(w["tick"]))
		assert_eq(g["events"], w["events"], "the events up to tick %d" % int(w["tick"]))
	var result: Dictionary = got["result"]
	var want_result: Dictionary = want["result"]
	assert_eq(result["won"], want_result["won"])
	for key: String in ["stars", "lives_left", "waves_cleared"]:
		assert_eq(int(result[key]), int(want_result[key]), key)
