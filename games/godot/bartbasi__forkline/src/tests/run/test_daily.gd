# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Daily: the best result and the streak (docs/design/RULES.md 15, ARCHITECTURE 3.4).


func _result(won: bool, waves: int, lives: int) -> Dictionary:
	return {"won": won, "waves": waves, "lives": lives}


func test_a_win_beats_a_loss() -> void:
	assert_true(Daily.is_better(_result(true, 18, 1), _result(false, 17, 20)))
	assert_false(Daily.is_better(_result(false, 17, 20), _result(true, 18, 1)))


func test_between_wins_more_lives_is_better() -> void:
	assert_true(Daily.is_better(_result(true, 18, 12), _result(true, 18, 11)))
	assert_false(Daily.is_better(_result(true, 18, 11), _result(true, 18, 12)))


func test_between_losses_more_waves_is_better() -> void:
	assert_true(Daily.is_better(_result(false, 9, 0), _result(false, 8, 0)))
	assert_false(Daily.is_better(_result(false, 8, 0), _result(false, 9, 0)))


func test_a_tie_keeps_the_earlier_result() -> void:
	assert_false(Daily.is_better(_result(true, 18, 5), _result(true, 18, 5)))
	assert_false(Daily.is_better(_result(false, 7, 0), _result(false, 7, 0)))


func test_lives_do_not_matter_between_losses_and_waves_do_not_matter_between_wins() -> void:
	assert_false(Daily.is_better(_result(false, 7, 9), _result(false, 7, 0)), "an abandoned run with lives left")
	assert_false(Daily.is_better(_result(true, 18, 3), _result(true, 18, 3)))
	assert_true(Daily.is_better(_result(false, 8, 0), _result(false, 7, 9)))
	assert_false(Daily.is_better(_result(true, 17, 4), _result(true, 18, 4)), "waves are not compared between wins")


func test_any_result_beats_no_result_and_nothing_beats_with_nothing() -> void:
	assert_true(Daily.is_better(_result(false, 0, 0), {}))
	assert_false(Daily.is_better({}, _result(false, 5, 0)))
	assert_false(Daily.is_better({}, {}))


func test_hostile_result_values_count_as_zero() -> void:
	var junk: Dictionary = {"won": "yes", "waves": "many", "lives": null}
	assert_false(Daily.is_better(junk, _result(false, 0, 0)))
	assert_true(Daily.is_better(_result(false, 1, 0), junk))
	assert_false(Daily.is_better({"won": true, "lives": 1.5}, _result(true, 18, 0)))


func test_the_day_after_adds_one_and_moves_the_day() -> void:
	var out: Dictionary = Daily.streak_after(3, "2026-10-23", "2026-10-24")
	assert_eq(out["streak"], 4)
	assert_eq(out["day"], "2026-10-24")
	out = Daily.streak_after(1, "2026-10-31", "2026-11-01")
	assert_eq(out["streak"], 2)
	out = Daily.streak_after(9, "2026-12-31", "2027-01-01")
	assert_eq(out["streak"], 10)
	assert_eq(out["day"], "2027-01-01")


func test_the_same_day_or_an_earlier_day_changes_nothing() -> void:
	var same: Dictionary = Daily.streak_after(3, "2026-10-24", "2026-10-24")
	assert_eq(same["streak"], 3)
	assert_eq(same["day"], "2026-10-24")
	var earlier: Dictionary = Daily.streak_after(3, "2026-10-24", "2026-10-20")
	assert_eq(earlier["streak"], 3)
	assert_eq(earlier["day"], "2026-10-24", "a phone whose date moved backward")
	var yesterday: Dictionary = Daily.streak_after(3, "2026-10-24", "2026-10-23")
	assert_eq(yesterday["streak"], 3)
	assert_eq(yesterday["day"], "2026-10-24")


func test_a_gap_or_no_last_day_starts_again_at_one() -> void:
	var gap: Dictionary = Daily.streak_after(8, "2026-10-20", "2026-10-22")
	assert_eq(gap["streak"], 1)
	assert_eq(gap["day"], "2026-10-22")
	var first: Dictionary = Daily.streak_after(0, "", "2026-10-22")
	assert_eq(first["streak"], 1)
	assert_eq(first["day"], "2026-10-22")
	var junk: Dictionary = Daily.streak_after(5, "garbage", "2026-10-22")
	assert_eq(junk["streak"], 1)
	assert_eq(junk["day"], "2026-10-22")


func test_a_day_that_is_not_a_day_key_changes_nothing() -> void:
	var out: Dictionary = Daily.streak_after(4, "2026-10-23", "")
	assert_eq(out["streak"], 4)
	assert_eq(out["day"], "2026-10-23")
	out = Daily.streak_after(4, "2026-10-23", "2026-02-31")
	assert_eq(out["day"], "2026-10-23")


func test_the_streak_stops_at_its_ceiling() -> void:
	var out: Dictionary = Daily.streak_after(Daily.STREAK_MAX, "2026-10-23", "2026-10-24")
	assert_eq(out["streak"], Daily.STREAK_MAX)
	out = Daily.streak_after(-5, "2026-10-23", "2026-10-24")
	assert_eq(out["streak"], 1, "a negative streak counts as 0")


func test_a_week_of_days_builds_a_streak() -> void:
	var streak: int = 0
	var last: String = ""
	for day: String in ["2026-10-25", "2026-10-26", "2026-10-27", "2026-10-28", "2026-10-29", "2026-10-30", "2026-10-31"]:
		var out: Dictionary = Daily.streak_after(streak, last, day)
		streak = out["streak"]
		last = out["day"]
	assert_eq(streak, 7)
	assert_eq(last, "2026-10-31")


func test_the_shown_streak_is_the_saved_one_for_today_or_yesterday() -> void:
	assert_eq(Daily.shown_streak(5, "2026-10-24", "2026-10-24"), 5, "played today")
	assert_eq(Daily.shown_streak(5, "2026-10-23", "2026-10-24"), 5, "played yesterday")
	assert_eq(Daily.shown_streak(5, "2026-10-22", "2026-10-24"), 0, "missed a day")
	assert_eq(Daily.shown_streak(5, "2026-09-01", "2026-10-24"), 0)
	assert_eq(Daily.shown_streak(5, "2026-10-30", "2026-10-24"), 0, "the phone date moved backward")
	assert_eq(Daily.shown_streak(5, "2026-12-31", "2027-01-01"), 5, "across a year")
	assert_eq(Daily.shown_streak(0, "2026-10-24", "2026-10-24"), 0)


func test_the_shown_streak_is_zero_for_bad_days() -> void:
	assert_eq(Daily.shown_streak(5, "", "2026-10-24"), 0)
	assert_eq(Daily.shown_streak(5, "2026-10-24", ""), 0)
	assert_eq(Daily.shown_streak(5, "junk", "junk"), 0)
	assert_eq(Daily.shown_streak(-3, "2026-10-24", "2026-10-24"), 0)
	assert_eq(Daily.shown_streak(999999999, "2026-10-24", "2026-10-24"), Daily.STREAK_MAX)
