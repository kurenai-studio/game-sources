extends "res://tests/test_case.gd"

const STEP := 0.04  # 2 steps = 80 ms, 3 steps = 120 ms; windows are 100 ms


func _timers() -> JumpTimers:
	var t := JumpTimers.new()
	t.coyote_time = 0.1
	t.buffer_time = 0.1
	return t


func _jump_after_leaving_floor(steps: int) -> bool:
	var t := _timers()
	t.update(STEP, true, false)
	for i in steps:
		t.update(STEP, false, false)
	t.update(0.0, false, true)
	return t.consume_jump()


func _jump_after_press_before_landing(steps: int) -> bool:
	var t := _timers()
	t.update(STEP, false, true)
	for i in steps:
		t.update(STEP, false, false)
	t.update(0.0, true, false)
	return t.consume_jump()


func test_coyote_window() -> void:
	check(_jump_after_leaving_floor(2), "jump 80 ms after leaving ledge must be accepted")
	check(not _jump_after_leaving_floor(3), "jump 120 ms after leaving ledge must be rejected")


func test_buffer_window() -> void:
	check(_jump_after_press_before_landing(2), "press 80 ms before landing must fire on landing")
	check(not _jump_after_press_before_landing(3), "press 120 ms before landing must not fire")


func test_jump_consumed_once() -> void:
	var t := _timers()
	t.update(STEP, true, true)
	check(t.consume_jump(), "first consume succeeds")
	check(not t.consume_jump(), "second consume fails (no double jump)")
