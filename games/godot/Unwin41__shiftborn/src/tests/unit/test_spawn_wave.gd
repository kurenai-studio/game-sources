extends TestCase


func _make(start: float, end: float, interval: float) -> SpawnWave:
	var wave := SpawnWave.new()
	wave.start_time = start
	wave.end_time = end
	wave.interval = interval
	return wave


func test_no_batches_before_start() -> void:
	assert_eq(_make(10.0, 20.0, 1.0).batches_due(9.99), 0)


func test_first_batch_fires_at_start() -> void:
	assert_eq(_make(10.0, 20.0, 1.0).batches_due(10.0), 1)


func test_batches_accumulate_by_interval() -> void:
	var wave := _make(0.0, 60.0, 2.0)
	assert_eq(wave.batches_due(1.9), 1)
	assert_eq(wave.batches_due(2.0), 2)
	assert_eq(wave.batches_due(9.0), 5)


func test_batches_stop_at_end_time_exclusive() -> void:
	var wave := _make(0.0, 10.0, 2.0)
	# Batches at 0, 2, 4, 6, 8. Not at 10.
	assert_eq(wave.batches_due(10.0), 5)
	assert_eq(wave.batches_due(500.0), 5)


func test_batch_count_is_robust_to_float_error() -> void:
	# 1.1 / 0.1 and 0.3 / 0.1 are not exact in floating point.
	var wave := _make(0.0, 1.1, 0.1)
	assert_eq(wave.batches_due(100.0), 11, "end is exclusive")
	assert_eq(wave.batches_due(0.3), 4, "batch at t=0.3 fires on time")


func test_is_active_window() -> void:
	var wave := _make(5.0, 15.0, 1.0)
	assert_false(wave.is_active(4.9))
	assert_true(wave.is_active(5.0))
	assert_false(wave.is_active(15.0))


func test_ring_position_is_on_radius() -> void:
	var center := Vector2(100, -50)
	for angle in [0.0, 1.0, PI, 5.5]:
		var point := HordeSpawner.ring_position(center, 300.0, angle)
		assert_almost_eq(point.distance_to(center), 300.0)
