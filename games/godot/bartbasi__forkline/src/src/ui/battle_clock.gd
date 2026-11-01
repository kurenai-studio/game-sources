# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name BattleClock
extends RefCounted
## Turns real time into whole sim ticks (docs/ARCHITECTURE.md 3.2, 3.6).
##
## Time is counted in whole microseconds, so the same frames always give the
## same ticks. A tick is 50 ms of game time (Sim.MS_PER_TICK). At 3x the clock
## hands out three times as many ticks.

const MAX_FRAME_SECONDS: float = 0.25
const MAX_TICKS_PER_FRAME: int = 6
const TICK_US: int = 50000
const MAX_FRAME_US: int = 250000

## 1, 2 or 3. Every level and run starts at 1. Any other value is refused.
var speed: int = 1:
	set(value):
		if value >= 1 and value <= 3:
			speed = value
## While paused no ticks are handed out and no time is kept.
var paused: bool = false

var _left_us: int = 0
## The part of a microsecond that rounding left over, so no time is lost.
var _fraction: float = 0.0


## Whole ticks to run for a frame of `delta` seconds. 0 while paused.
func advance(delta: float) -> int:
	if paused or delta <= 0.0:
		return 0
	var exact: float = minf(delta, MAX_FRAME_SECONDS) * 1000000.0 + _fraction
	# The small nudge keeps 60 frames of 1/60 s from landing a hair short.
	var frame_us: int = mini(int(exact + 0.001), MAX_FRAME_US)
	_fraction = exact - float(frame_us)
	_left_us += frame_us * speed
	@warning_ignore("integer_division")
	var ticks: int = _left_us / TICK_US
	_left_us -= ticks * TICK_US
	if ticks > MAX_TICKS_PER_FRAME:
		ticks = MAX_TICKS_PER_FRAME
		_left_us = 0
	return ticks


## How far the game is between the last tick and the next, 0 to 1.
func alpha() -> float:
	return float(_left_us) / float(TICK_US)


## Drops the leftover time (a build phase, a resume, a layout change).
func reset() -> void:
	_left_us = 0
	_fraction = 0.0
