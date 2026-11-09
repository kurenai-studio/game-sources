extends TestCase


func test_first_level_needs_base_xp() -> void:
	assert_eq(Experience.xp_for_level(1), Experience.BASE_XP)


func test_each_level_needs_more_xp_than_the_last() -> void:
	for level in range(1, 40):
		assert_true(Experience.xp_for_level(level + 1) >= Experience.xp_for_level(level), "level %d" % level)
	assert_true(Experience.xp_for_level(20) > Experience.xp_for_level(1) * 5, "curve too flat")


func test_starts_at_level_one_with_no_xp() -> void:
	var experience := Experience.new()
	assert_eq(experience.level, 1)
	assert_eq(experience.xp, 0)
	assert_almost_eq(experience.progress(), 0.0)


func test_add_below_threshold_gains_no_level() -> void:
	var experience := Experience.new()
	assert_eq(experience.add(Experience.BASE_XP - 1), 0)
	assert_eq(experience.level, 1)
	assert_eq(experience.xp, Experience.BASE_XP - 1)


func test_add_reaching_threshold_levels_up_and_keeps_leftover() -> void:
	var experience := Experience.new()
	assert_eq(experience.add(Experience.BASE_XP + 2), 1)
	assert_eq(experience.level, 2)
	assert_eq(experience.xp, 2)


func test_large_add_gains_several_levels() -> void:
	var experience := Experience.new()
	var needed := Experience.xp_for_level(1) + Experience.xp_for_level(2) + Experience.xp_for_level(3)
	assert_eq(experience.add(needed), 3)
	assert_eq(experience.level, 4)
	assert_eq(experience.xp, 0)


func test_add_ignores_zero_and_negative_amounts() -> void:
	var experience := Experience.new()
	assert_eq(experience.add(0), 0)
	assert_eq(experience.add(-5), 0)
	assert_eq(experience.xp, 0)


func test_leveled_up_signal_fires_once_per_level() -> void:
	var experience := Experience.new()
	var levels: Array[int] = []
	experience.leveled_up.connect(func(new_level: int) -> void: levels.append(new_level))
	experience.add(Experience.xp_for_level(1) + Experience.xp_for_level(2))
	assert_eq(levels, [2, 3] as Array[int])


func test_early_levels_are_not_a_card_every_few_kills() -> void:
	var total := 0
	for level in range(1, 5):
		total += Experience.xp_for_level(level)
	assert_true(total >= 40, "reaching level 5 takes only %d XP" % total)
