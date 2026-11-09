extends TestCase
## Power pass: crits, enemy health scaling over the run, crit numbers.


func test_crit_when_the_roll_is_under_the_chance() -> void:
	assert_true(Player.is_crit(0.25, 0.1))
	assert_false(Player.is_crit(0.25, 0.3))
	assert_false(Player.is_crit(0.0, 0.0))


func test_crit_damage_is_multiplied() -> void:
	assert_almost_eq(Player.hit_damage(3.0, true), 3.0 * Player.CRIT_MULTIPLIER)
	assert_almost_eq(Player.hit_damage(3.0, false), 3.0)


func test_enemy_health_grows_over_the_run() -> void:
	assert_almost_eq(Run.health_scale(0.0), 1.0)
	assert_true(Run.health_scale(300.0) > Run.health_scale(60.0), "health should keep growing")
	assert_true(Run.health_scale(Run.BOSS_TIME) >= 3.0, "late enemies should be much tougher")


func test_crit_numbers_are_big_and_gold() -> void:
	var numbers := DamageNumbers.new()
	numbers.spawn(Vector2.ZERO, 4.0, false, true)
	assert_eq(numbers.color_of_newest(), DamageNumbers.CRIT_COLOR)
	assert_eq(numbers.size_of_newest(), DamageNumbers.CRIT_FONT_SIZE)
	numbers.spawn(Vector2.ZERO, 1.0)
	assert_eq(numbers.size_of_newest(), DamageNumbers.FONT_SIZE)
	numbers.free()


func test_first_level_comes_quickly() -> void:
	assert_true(Experience.xp_for_level(1) <= 3, "first level should need 3 kills or fewer")
