extends McpTestSuite
## The clock: how ticks map to days and hours, and the pacing defaults.


func suite_name() -> String:
	return "sim_clock"


func test_default_pace_is_twenty_real_minutes_per_day() -> void:
	var config: SimConfig = SimFixture.load_config()
	assert_eq(config.real_seconds_per_game_day, 1200.0)
	assert_eq(config.seconds_per_tick(), 50.0)


func test_day_and_hour_from_tick() -> void:
	var config: SimConfig = SimFixture.load_config()
	assert_eq(config.day_of(0), 0)
	assert_eq(config.hour_of(0), 0)
	assert_eq(config.day_of(25), 1)
	assert_eq(config.hour_of(25), 1)
	assert_eq(config.hour_of(47), 23)
	assert_eq(config.day_of(48), 2)


func test_hour_scales_with_tick_resolution() -> void:
	var config: SimConfig = SimFixture.load_config().duplicate()
	config.ticks_per_day = 48
	assert_eq(config.hour_of(2), 1)
	assert_eq(config.tick_for_hour(6), 12)
	assert_eq(config.day_of(48), 1)


func test_sleeping_hours() -> void:
	var config: SimConfig = SimFixture.load_config()
	assert_true(config.is_sleeping_hour(23))
	assert_true(config.is_sleeping_hour(5))
	assert_false(config.is_sleeping_hour(6))
	assert_false(config.is_sleeping_hour(21))
