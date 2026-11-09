extends TestCase


func test_angle_inside_forward_sweep() -> void:
	assert_true(SpinningSword.angle_in_sweep(0.5, 0.2, 0.8))


func test_angle_outside_forward_sweep() -> void:
	assert_false(SpinningSword.angle_in_sweep(1.0, 0.2, 0.8))


func test_sweep_is_half_open() -> void:
	assert_true(SpinningSword.angle_in_sweep(0.2, 0.2, 0.8), "start is included")
	assert_false(SpinningSword.angle_in_sweep(0.8, 0.2, 0.8), "end is excluded")


func test_sweep_wraps_past_tau() -> void:
	# Sweep from 6.0 to 6.6 rad crosses 2*PI, so it covers angle 0.1.
	assert_true(SpinningSword.angle_in_sweep(0.1, 6.0, 6.6))
	assert_false(SpinningSword.angle_in_sweep(1.0, 6.0, 6.6))


func test_backward_sweep_matches_forward() -> void:
	assert_true(SpinningSword.angle_in_sweep(2.5, 3.0, 2.0))
	assert_false(SpinningSword.angle_in_sweep(3.5, 3.0, 2.0))


func test_negative_angles_from_vector_angle() -> void:
	# Vector2.angle() returns -PI..PI; -PI/2 equals 3PI/2.
	assert_true(SpinningSword.angle_in_sweep(-PI / 2.0, 4.0, 5.0))


func test_full_turn_covers_everything() -> void:
	for angle in [0.0, 1.0, 3.0, -2.0, 6.2]:
		assert_true(SpinningSword.angle_in_sweep(angle, 1.0, 1.0 + TAU), "angle %s" % angle)


func test_consecutive_sweeps_cover_each_angle_once() -> void:
	var steps := 18
	for probe in [0.0, 0.7, 2.0, 3.14, 5.9]:
		var hits := 0
		for i in steps:
			var from := 0.3 + TAU * i / steps
			var to := 0.3 + TAU * (i + 1) / steps
			if SpinningSword.angle_in_sweep(probe, from, to):
				hits += 1
		assert_eq(hits, 1, "probe %s" % probe)


func test_single_blade_hits_inside_sweep() -> void:
	assert_eq(SpinningSword.blades_in_sweep(0.5, 0.2, 0.8, 1), [0] as Array[int])
	assert_eq(SpinningSword.blades_in_sweep(2.0, 0.2, 0.8, 1), [] as Array[int])


func test_second_blade_sweeps_the_opposite_side() -> void:
	# Blade 1 sits PI behind blade 0, so it covers 0.2+PI .. 0.8+PI.
	assert_eq(SpinningSword.blades_in_sweep(0.5 + PI, 0.2, 0.8, 2), [1] as Array[int])


func test_full_turn_hits_once_per_blade() -> void:
	assert_eq(SpinningSword.blades_in_sweep(1.0, 0.0, TAU, 3), [0, 1, 2] as Array[int])


func test_grip_moves_out_so_the_tip_reaches_the_trail_edge() -> void:
	var sword := SpinningSword.new()
	sword.reach = 50.0
	assert_almost_eq(sword.grip_radius(), 50.0 - sword.texture.get_height())
	sword.reach = 10.0
	assert_almost_eq(sword.grip_radius(), SpinningSword.MIN_GRIP_RADIUS)
	sword.free()
