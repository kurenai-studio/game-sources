extends TestCase
## Run score, achievements and the saved progress (best score, unlocks).


func _stats() -> RunStats:
	var stats := RunStats.new()
	stats.kills = 100
	stats.seconds = 120.5
	stats.perfects = 3
	return stats


func test_score_adds_kills_time_perfects_and_the_win() -> void:
	var stats := _stats()
	assert_eq(stats.score(), 100 * RunStats.KILL_POINTS + 120 * RunStats.SECOND_POINTS + 3 * RunStats.PERFECT_POINTS)
	stats.won = true
	assert_eq(stats.score(), 100 * RunStats.KILL_POINTS + 120 * RunStats.SECOND_POINTS + 3 * RunStats.PERFECT_POINTS + RunStats.WIN_POINTS)


func test_score_breakdown_lists_each_part() -> void:
	var lines := _stats().breakdown()
	assert_eq(lines.size(), 3, "no win line for a loss")
	assert_true(lines[0].begins_with("KILLS"), "first line is kills: %s" % lines[0])


func test_ten_achievements_with_unique_ids() -> void:
	var ids := {}
	for entry in Achievements.LIST:
		assert_false(ids.has(entry.id), "duplicate %s" % entry.id)
		ids[entry.id] = true
		assert_true(entry.title != "" and entry.text != "", "%s needs text" % entry.id)
	assert_eq(ids.size(), 10)


func test_newly_unlocked_skips_what_is_already_owned() -> void:
	var stats := RunStats.new()
	stats.kills = 1
	stats.perfects = 1
	var fresh := Achievements.newly_unlocked(stats, [])
	assert_true(&"first_blood" in fresh and &"perfect" in fresh, "first kill and perfect unlock: %s" % [fresh])
	assert_false(&"flawless_five" in fresh, "one perfect is not five")
	var again := Achievements.newly_unlocked(stats, fresh)
	assert_eq(again.size(), 0)


func test_win_achievements_need_the_win() -> void:
	var stats := RunStats.new()
	stats.health_share = 0.9
	assert_false(&"untouchable" in Achievements.newly_unlocked(stats, []), "untouchable needs a win")
	stats.won = true
	var unlocked := Achievements.newly_unlocked(stats, [])
	assert_true(&"demon_slayer" in unlocked and &"untouchable" in unlocked, "win at 90%% HP: %s" % [unlocked])


func test_progress_keeps_the_best_score_and_unlocks() -> void:
	var path := "user://test_progress.cfg"
	var progress := Progress.new()
	assert_true(progress.submit_score(500), "first score is a best")
	assert_false(progress.submit_score(400), "lower score is not a best")
	progress.unlock(&"perfect")
	progress.save_to(path)
	var loaded := Progress.new()
	loaded.load_from(path)
	assert_eq(loaded.best_score, 500)
	assert_true(loaded.is_unlocked(&"perfect"), "unlock should load back")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_results_screen_shows_score_and_new_best() -> void:
	var screen := ResultsScreen.new()
	var none: Array[Upgrade] = []
	var no_levels: Array[int] = []
	screen.open(true, 60.0, 10, 3, none, no_levels)
	screen.show_score(1234, PackedStringArray(["KILLS 10 x 10   100"]), true)
	assert_eq(screen.score_text(), "SCORE 1234")
	assert_true(screen.is_new_best_shown(), "new best should show")
	screen.free()


func test_achievements_page_lists_every_achievement() -> void:
	var page := AchievementsPanel.new()
	assert_eq(page.row_count(), Achievements.LIST.size())
	page.free()
