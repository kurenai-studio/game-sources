class_name TapTiming
extends RefCounted
## Learns how late (or early) this screen's taps land, as you play.
##
## A tablet hears its own sound late (its speaker lags behind the music's
## clock) and feels a finger late (its screen lags too); together that can be
## a sixth of a second, which makes every tap a miss. So each tap in an event
## is placed on the bounce grid, and once enough of them agree on where they
## land (a circular mean, so taps either side of a landing don't cancel out),
## the calibration moves half the way there. A player who is simply all
## over the place agrees with nothing, and nothing moves. (Tuned on a
## simulation of young players' wobbly taps: unbiased, and settled within a
## couple of events from the Android first guess; see the decision log.)

const BATCH := 16                ## taps to look at before moving
const AGREE := 0.3               ## how alike they must be (0 none, 1 all the same)
const SHARE := 0.5               ## how much of the way to move each time
const LOW := -0.1
const HIGH := 0.35

var _s := 0.0
var _c := 0.0
var _n := 0


## A tap, as its distance from the nearest landing in slots (-0.5..0.5).
func add(err_slots: float) -> void:
	var a := err_slots * TAU
	_s += sin(a)
	_c += cos(a)
	_n += 1


func count() -> int:
	return _n


## How alike the taps are: 0 (all over the place) to 1 (all at one spot).
func agreement() -> float:
	return sqrt(_s * _s + _c * _c) / _n if _n > 0 else 0.0


## Where they land on average, in slots (late +).
func mean() -> float:
	return atan2(_s, _c) / TAU if _n > 0 else 0.0


## After a batch: the new calibration (or the old one, if the taps disagree).
## Resets for the next batch either way.
func settle(calibration: float, slot_len: float) -> float:
	var out := calibration
	if _n >= BATCH and agreement() >= AGREE:
		var off := mean() * slot_len
		if absf(off) > 0.012:
			out = clampf(calibration + off * SHARE, LOW, HIGH)
	if _n >= BATCH:
		_s = 0.0
		_c = 0.0
		_n = 0
	return out


## Where a tap at song time `at` falls from the nearest landing of a grid
## that starts at `origin` with landings every `slot_len`, in slots.
static func phase(at: float, origin: float, slot_len: float) -> float:
	var x := (at - origin) / slot_len
	return x - roundf(x)
