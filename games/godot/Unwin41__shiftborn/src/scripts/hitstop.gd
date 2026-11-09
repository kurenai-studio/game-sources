class_name Hitstop
extends Node
## Freezes the game for a few real-time milliseconds to sell a heavy hit.
## Slows [member Engine.time_scale] instead of pausing, so menus and the
## level-up pause are not affected.

const SLOW_SCALE := 0.05

## Bumped on every trigger so only the newest timer restores time.
var _serial: int = 0


func trigger(duration: float) -> void:
	_slow(duration, SLOW_SCALE, false)


## A longer, gentler slowdown that also lowers the pitch of all audio.
func slow_motion(duration: float, scale: float) -> void:
	_slow(duration, scale, true)


func _slow(duration: float, scale: float, slow_audio: bool) -> void:
	if not is_inside_tree() or duration <= 0.0:
		return
	_serial += 1
	var serial := _serial
	Engine.time_scale = scale
	AudioServer.playback_speed_scale = scale if slow_audio else 1.0
	# Process while paused, ignore time scale: real time.
	get_tree().create_timer(duration, true, false, true).timeout.connect(func() -> void:
		if serial == _serial:
			_restore())


func _restore() -> void:
	Engine.time_scale = 1.0
	AudioServer.playback_speed_scale = 1.0


func _exit_tree() -> void:
	_serial += 1
	_restore()
