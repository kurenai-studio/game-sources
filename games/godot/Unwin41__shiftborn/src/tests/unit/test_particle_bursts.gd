extends TestCase
## Draw-based particle bursts: one node holds every particle.


func test_burst_adds_the_requested_count() -> void:
	var bursts := ParticleBursts.new()
	bursts.max_particles = 100
	bursts.burst(Vector2.ZERO, Color.RED, 8, 50.0)
	assert_eq(bursts.count(), 8)
	bursts.free()


func test_cap_drops_the_oldest_particles() -> void:
	var bursts := ParticleBursts.new()
	bursts.max_particles = 10
	bursts.burst(Vector2.ZERO, Color.RED, 8, 50.0)
	bursts.burst(Vector2.ZERO, Color.BLUE, 8, 50.0)
	assert_eq(bursts.count(), 10)
	bursts.free()


func test_particles_move_and_expire() -> void:
	var bursts := ParticleBursts.new()
	bursts.max_particles = 100
	bursts.burst(Vector2.ZERO, Color.RED, 4, 50.0, 0.5)
	bursts.advance(0.1)
	assert_true(bursts.position_of(0).length() > 0.0, "particles should fly outward")
	bursts.advance(0.5)
	assert_eq(bursts.count(), 0)
	bursts.free()


func test_ring_spreads_particles_evenly() -> void:
	var bursts := ParticleBursts.new()
	bursts.max_particles = 100
	bursts.ring(Vector2.ZERO, Color.WHITE, 4, 40.0)
	bursts.advance(0.05)
	var first := bursts.position_of(0).angle()
	var second := bursts.position_of(1).angle()
	assert_almost_eq(absf(angle_difference(first, second)), TAU / 4.0, 0.01)
	bursts.free()


func test_count_scale_is_lower_on_low_quality() -> void:
	assert_eq(ParticleBursts.scaled_count(10, false), 5)
	assert_eq(ParticleBursts.scaled_count(10, true), 10)
	assert_eq(ParticleBursts.scaled_count(1, false), 1)


func test_screen_fade_starts_clear_and_falls_back_without_autoload() -> void:
	var fade := ScreenFade.new()
	assert_almost_eq(fade.alpha(), 0.0)
	fade.free()
