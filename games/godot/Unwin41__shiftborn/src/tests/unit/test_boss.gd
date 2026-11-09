extends TestCase


func test_resistance_alternates_every_swap_interval() -> void:
	var first := Boss.resisted_form_at(0.0)
	assert_eq(Boss.resisted_form_at(Boss.SWAP_INTERVAL * 0.5), first)
	assert_true(Boss.resisted_form_at(Boss.SWAP_INTERVAL + 0.01) != first, "should swap after one interval")
	assert_eq(Boss.resisted_form_at(Boss.SWAP_INTERVAL * 2.0 + 0.01), first)


func test_swap_warning_only_right_before_a_swap() -> void:
	assert_false(Boss.is_swap_warning(0.5))
	assert_true(Boss.is_swap_warning(Boss.SWAP_INTERVAL - Boss.SWAP_WARNING * 0.5))
	assert_false(Boss.is_swap_warning(Boss.SWAP_INTERVAL + 0.5))


func test_ring_directions_are_evenly_spaced() -> void:
	var directions := Boss.ring_directions(4, 0.0)
	assert_eq(directions.size(), 4)
	assert_true(directions[0].is_equal_approx(Vector2.RIGHT), "first shot points right")
	assert_true(directions[1].is_equal_approx(Vector2.DOWN), "second shot is a quarter turn later")


func test_boss_scene_is_a_tough_boss() -> void:
	var boss := preload("res://scenes/boss.tscn").instantiate() as Boss
	assert_true(boss.max_health >= 300.0, "boss needs a lot of health")
	assert_true(boss.body_radius >= 12.0, "boss should be much bigger than a grunt")
	boss.free()
