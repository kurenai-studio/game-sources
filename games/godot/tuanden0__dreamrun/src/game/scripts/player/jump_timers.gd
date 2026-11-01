## Coyote time + jump buffer as pure logic driven by an explicit delta, so it is testable without physics.
class_name JumpTimers
extends RefCounted

var coyote_time := 0.1
var buffer_time := 0.1

var _coyote_left := 0.0
var _buffer_left := 0.0


func update(delta: float, on_floor: bool, jump_pressed: bool) -> void:
	_coyote_left = coyote_time if on_floor else maxf(_coyote_left - delta, 0.0)
	_buffer_left = buffer_time if jump_pressed else maxf(_buffer_left - delta, 0.0)


## True once when a buffered press meets a grounded (or just-left-ground) body; consumes both timers.
func consume_jump() -> bool:
	if _coyote_left <= 0.0 or _buffer_left <= 0.0:
		return false
	_coyote_left = 0.0
	_buffer_left = 0.0
	return true
