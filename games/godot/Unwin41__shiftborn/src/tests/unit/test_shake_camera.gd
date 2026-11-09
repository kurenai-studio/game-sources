extends TestCase
## ShakeCamera is never added to the tree; step() is driven by hand.


func test_trauma_is_clamped_to_one() -> void:
	var camera := ShakeCamera.new()
	camera.add_trauma(0.7)
	camera.add_trauma(0.7)
	assert_almost_eq(camera.trauma, 1.0)
	camera.free()


func test_trauma_decays_to_zero_and_offset_resets() -> void:
	var camera := ShakeCamera.new()
	camera.add_trauma(1.0)
	camera.step(0.1)
	assert_almost_eq(camera.trauma, 1.0 - ShakeCamera.DECAY * 0.1)
	for i in 100:
		camera.step(0.1)
	assert_almost_eq(camera.trauma, 0.0)
	assert_eq(camera.offset, Vector2.ZERO)
	camera.free()


func test_offset_stays_within_max() -> void:
	var camera := ShakeCamera.new()
	for i in 50:
		camera.add_trauma(1.0)
		camera.step(0.016)
		assert_true(absf(camera.offset.x) <= ShakeCamera.MAX_OFFSET + 0.001, "x offset too large")
		assert_true(absf(camera.offset.y) <= ShakeCamera.MAX_OFFSET + 0.001, "y offset too large")
	camera.free()


func test_small_trauma_shakes_less_than_full() -> void:
	assert_true(ShakeCamera.shake_strength(0.5) < 0.5)
	assert_almost_eq(ShakeCamera.shake_strength(1.0), 1.0)
	assert_almost_eq(ShakeCamera.shake_strength(0.0), 0.0)
