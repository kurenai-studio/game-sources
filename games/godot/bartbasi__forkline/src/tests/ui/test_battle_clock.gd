# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## BattleClock: real time to whole ticks (docs/ARCHITECTURE.md 3.2, 3.6).

var clock: BattleClock


func before_each() -> void:
	clock = BattleClock.new()


func _ticks_over(seconds: float, fps: float) -> int:
	var total: int = 0
	var frames: int = roundi(seconds * fps)
	for i: int in frames:
		total += clock.advance(1.0 / fps)
	return total


func test_it_starts_at_1x_and_running() -> void:
	assert_eq(clock.speed, 1)
	assert_false(clock.paused)


func test_one_second_is_twenty_ticks_at_1x() -> void:
	assert_eq(_ticks_over(1.0, 60.0), 20)
	clock.reset()
	assert_eq(_ticks_over(1.0, 144.0), 20)
	clock.reset()
	assert_eq(_ticks_over(1.0, 30.0), 20)


func test_2x_and_3x_hand_out_twice_and_three_times_the_ticks() -> void:
	clock.speed = 2
	assert_eq(_ticks_over(1.0, 60.0), 40)
	clock.reset()
	clock.speed = 3
	assert_eq(_ticks_over(1.0, 60.0), 60)


func test_a_bad_speed_is_refused() -> void:
	clock.speed = 2
	clock.speed = 0
	assert_eq(clock.speed, 2)
	clock.speed = 4
	assert_eq(clock.speed, 2)
	clock.speed = -1
	assert_eq(clock.speed, 2)


func test_paused_gives_no_ticks_and_keeps_no_time() -> void:
	clock.paused = true
	assert_eq(clock.advance(1.0), 0)
	clock.paused = false
	assert_eq(clock.advance(0.01), 0, "the paused second must not come back")
	assert_eq(clock.advance(0.04), 1)


func test_a_long_frame_never_bursts() -> void:
	# A return from the background: 5 seconds in one frame counts as 0.25 s.
	assert_eq(clock.advance(5.0), 5)
	clock.speed = 3
	assert_eq(clock.advance(5.0), BattleClock.MAX_TICKS_PER_FRAME)


func test_the_burst_cap_drops_the_rest() -> void:
	clock.speed = 3
	var first: int = clock.advance(0.25)
	assert_eq(first, BattleClock.MAX_TICKS_PER_FRAME)
	assert_near(clock.alpha(), 0.0, 0.0001)
	assert_eq(clock.advance(0.0), 0)


func test_leftover_time_carries_into_the_next_frame() -> void:
	assert_eq(clock.advance(0.03), 0)
	assert_near(clock.alpha(), 0.6, 0.001)
	assert_eq(clock.advance(0.03), 1)
	assert_near(clock.alpha(), 0.2, 0.001)


func test_reset_drops_the_leftover() -> void:
	clock.advance(0.04)
	clock.reset()
	assert_near(clock.alpha(), 0.0, 0.0001)
	assert_eq(clock.advance(0.01), 0)


func test_a_zero_or_negative_frame_gives_nothing() -> void:
	assert_eq(clock.advance(0.0), 0)
	assert_eq(clock.advance(-1.0), 0)


func test_the_same_frames_always_give_the_same_ticks() -> void:
	var a: BattleClock = BattleClock.new()
	var b: BattleClock = BattleClock.new()
	var seen_a: Array[int] = []
	var seen_b: Array[int] = []
	for i: int in 200:
		var delta: float = 0.001 * float(1 + (i * 7) % 40)
		seen_a.append(a.advance(delta))
		seen_b.append(b.advance(delta))
	assert_eq(seen_a, seen_b)
