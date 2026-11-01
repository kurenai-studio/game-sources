extends GutTest
## Local progress: round trip, unlock order, and recovery from a damaged file.

const PATH := "user://test_progress.json"

var _campaign: Campaign


func before_each() -> void:
	_remove_all()
	var placement := {
		"worlds":
		[
			{
				"id": "w",
				"title": "W",
				"summary": "",
				"chapters": [{"id": "c", "title": "C", "levels": ["a", "b", "c"]}],
			}
		]
	}
	var loader := func(id: String) -> Variant: return _level(id)
	_campaign = Campaign.from_data(placement, loader)


func after_each() -> void:
	_remove_all()


func _remove_all() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func _level(id: String) -> Dictionary:
	return {
		"schemaVersion": 1,
		"levelId": id,
		"levelVersion": 1,
		"slug": id,
		"title": id,
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": []},
		"board": {"width": 3, "height": 3, "walls": []},
		"initialState": {"position": [0, 2], "direction": "north"},
		"availableCommands": ["MOVE_FORWARD"],
		"constraints": {"maxCommands": 4, "maxSteps": 10},
		"goal": {"type": "reach_tile", "position": [0, 0]},
		"hints": [],
	}


func _write(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func test_missing_file_starts_fresh() -> void:
	var store := ProgressStore.new(PATH)
	store.load_data()
	assert_true(store.started_fresh)
	assert_false(store.is_completed("a"))
	assert_eq(store.settings.theme(), "system")
	assert_false(store.settings.reduce_motion())


func test_save_and_load_round_trip() -> void:
	var store := ProgressStore.new(PATH)
	store.load_data()
	store.record_completion("a", 1, 5)
	store.set_last_level("a")
	store.settings.set_theme("dark")
	store.settings.set_reduce_motion(true)
	assert_true(store.save())
	var again := ProgressStore.new(PATH)
	again.load_data()
	assert_false(again.started_fresh)
	assert_true(again.is_completed("a"))
	assert_eq(again.best_commands("a", 1), 5)
	assert_eq(again.last_level(), "a")
	assert_eq(again.settings.theme(), "dark")
	assert_true(again.settings.reduce_motion())


func test_best_keeps_the_fewest_commands() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 6)
	store.record_completion("a", 1, 4)
	store.record_completion("a", 1, 9)
	assert_eq(store.best_commands("a", 1), 4)


func test_best_is_not_reinterpreted_for_another_level_version() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 4)
	assert_eq(store.best_commands("a", 2), 0)
	assert_true(store.is_completed("a"), "completion itself is kept")
	store.record_completion("a", 2, 7)
	assert_eq(store.best_commands("a", 2), 7)


func test_save_leaves_no_temporary_file() -> void:
	var store := ProgressStore.new(PATH)
	store.save()
	assert_true(FileAccess.file_exists(PATH))
	assert_false(FileAccess.file_exists(PATH + ".tmp"))


func test_second_save_keeps_the_previous_good_save_as_backup() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 3)
	store.save()
	store.record_completion("b", 1, 3)
	store.save()
	var backup := ProgressStore.new(PATH + ".bak")
	backup.load_data()
	assert_true(backup.is_completed("a"))
	assert_false(backup.is_completed("b"))


func test_corrupt_file_with_backup_recovers_the_backup() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 3)
	store.save()
	store.record_completion("b", 1, 3)
	store.save()
	_write(PATH, "{ this is not json")
	var again := ProgressStore.new(PATH)
	again.load_data()
	assert_true(again.recovered_from_backup)
	assert_true(again.is_completed("a"))
	assert_true(FileAccess.file_exists(PATH + ".corrupt"), "the bad file is kept for inspection")


func test_corrupt_file_without_backup_starts_fresh_and_keeps_the_bad_file() -> void:
	_write(PATH, "garbage")
	var store := ProgressStore.new(PATH)
	store.load_data()
	assert_true(store.started_fresh)
	assert_false(store.is_completed("a"))
	assert_true(FileAccess.file_exists(PATH + ".corrupt"))


func test_saving_after_a_corrupt_load_does_not_destroy_a_good_backup() -> void:
	var good := ProgressStore.new(PATH)
	good.record_completion("a", 1, 3)
	good.save()
	good.save()
	_write(PATH, "garbage")
	var store := ProgressStore.new(PATH)
	store.load_data()
	store.save()
	var backup := ProgressStore.new(PATH + ".bak")
	backup.load_data()
	assert_true(backup.is_completed("a"))


func test_file_from_a_newer_version_is_not_used() -> void:
	_write(PATH, JSON.stringify({"version": ProgressStore.VERSION + 1, "completed": {}}))
	var store := ProgressStore.new(PATH)
	store.load_data()
	assert_true(store.started_fresh)


func test_bad_entries_are_dropped_one_by_one() -> void:
	var raw := {
		"version": 1,
		"completed":
		{
			"a": {"levelVersion": 1, "bestCommands": 4},
			"b": {"levelVersion": "x", "bestCommands": 4},
			"c": 7,
		},
		"lastLevel": 12,
		"settings": {"theme": "neon", "reduceMotion": "yes"},
	}
	_write(PATH, JSON.stringify(raw))
	var store := ProgressStore.new(PATH)
	store.load_data()
	assert_true(store.is_completed("a"))
	assert_false(store.is_completed("b"))
	assert_false(store.is_completed("c"))
	assert_eq(store.last_level(), "")
	assert_eq(store.settings.theme(), "system")
	assert_false(store.settings.reduce_motion())


func test_unknown_theme_is_ignored() -> void:
	var store := ProgressStore.new(PATH)
	store.settings.set_theme("neon")
	assert_eq(store.settings.theme(), "system")


func test_only_the_first_level_is_unlocked_at_the_start() -> void:
	var store := ProgressStore.new(PATH)
	assert_eq(store.level_state(_campaign, 0), "current")
	assert_eq(store.level_state(_campaign, 1), "locked")
	assert_eq(store.level_state(_campaign, 2), "locked")
	assert_true(store.is_unlocked(_campaign, 0))
	assert_false(store.is_unlocked(_campaign, 1))


func test_completing_a_level_unlocks_the_next_in_order() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 3)
	assert_eq(store.level_state(_campaign, 0), "done")
	assert_eq(store.level_state(_campaign, 1), "current")
	assert_eq(store.level_state(_campaign, 2), "locked")
	store.record_completion("b", 1, 3)
	assert_eq(store.level_state(_campaign, 2), "current")


func test_skipping_ahead_does_not_unlock_anything() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("c", 1, 3)
	assert_eq(store.level_state(_campaign, 0), "current")
	assert_eq(store.level_state(_campaign, 1), "locked")
	assert_eq(store.level_state(_campaign, 2), "done", "a solved level can be replayed")


func test_all_done_leaves_nothing_current() -> void:
	var store := ProgressStore.new(PATH)
	for id in ["a", "b", "c"]:
		store.record_completion(id, 1, 3)
	assert_eq(store.first_unfinished_index(_campaign), 3)
	assert_eq(store.level_to_play(_campaign), 2)


func test_level_to_play_prefers_the_last_played_unlocked_level() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 3)
	assert_eq(store.level_to_play(_campaign), 1)
	store.set_last_level("a")
	assert_eq(store.level_to_play(_campaign), 0)
	store.set_last_level("c")
	assert_eq(store.level_to_play(_campaign), 1, "a locked last level is not used")


func test_progress_for_a_removed_level_is_kept_and_ignored() -> void:
	var store := ProgressStore.new(PATH)
	store.record_completion("a", 1, 3)
	store.record_completion("removed-level", 1, 4)
	store.set_last_level("removed-level")
	assert_true(store.save())
	var again := ProgressStore.new(PATH)
	again.load_data()
	assert_true(again.is_completed("removed-level"), "kept in case the level returns")
	assert_eq(again.first_unfinished_index(_campaign), 1)
	assert_eq(again.level_state(_campaign, 0), "done")
	assert_eq(again.level_state(_campaign, 1), "current")
	assert_eq(again.level_state(_campaign, 2), "locked")
	assert_eq(again.level_to_play(_campaign), 1, "a last level that is gone falls back")
