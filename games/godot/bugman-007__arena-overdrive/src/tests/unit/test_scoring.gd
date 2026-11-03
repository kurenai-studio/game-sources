extends GutTest

var scores: ScoreManager


func before_each() -> void:
	scores = ScoreManager.new()


func test_starts_empty() -> void:
	assert_eq(scores.score, 0)
	assert_eq(scores.combo, 0)
	assert_eq(scores.multiplier(), 1.0)


func test_first_kill_uses_combo_one() -> void:
	assert_eq(scores.add_kill(100), 105)


func test_combo_grows_multiplier_and_caps() -> void:
	for i in 100:
		scores.add_kill(10)
	assert_eq(scores.multiplier(), 1.0 + ScoreManager.MAX_COMBO_STEPS * 0.05)
	assert_eq(scores.max_combo, 100)


func test_combo_decays_after_window() -> void:
	scores.add_kill(10)
	scores.add_kill(10)
	scores.tick(ScoreManager.COMBO_WINDOW + 0.01)
	assert_eq(scores.combo, 0)
	assert_eq(scores.max_combo, 2, "max combo survives decay")


func test_combo_time_ratio() -> void:
	scores.add_kill(10)
	scores.tick(ScoreManager.COMBO_WINDOW / 2.0)
	assert_almost_eq(scores.combo_time_ratio(), 0.5, 0.01)


func test_bonus_and_signal() -> void:
	watch_signals(scores)
	scores.add_bonus(50)
	assert_eq(scores.score, 50)
	assert_signal_emitted_with_parameters(scores, "score_changed", [50])


func test_reset() -> void:
	scores.add_kill(10)
	scores.reset()
	assert_eq(scores.score, 0)
	assert_eq(scores.max_combo, 0)
