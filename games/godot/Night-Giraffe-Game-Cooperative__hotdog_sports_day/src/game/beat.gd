class_name Beat
extends RefCounted
## The beat everything bounces to.
##
## A track's beat grid is its tempo (bpm) and where its first downbeat falls
## (offset, seconds into the file). Athletes bounce `sub` times a beat, chosen
## so a bounce comes about three times a second whatever the tempo: that's a
## comfortable rhythm for a thumb, and the same for every track.
##
## Times here are song times: seconds into the track as it is heard.

var bpm := 90.0
var offset := 0.0          ## song time of beat 0
var sub := 2               ## bounces per beat
var beats_per_bar := 4

const BOUNCE_HZ := 2.9     ## the bounce rate the sub is picked to come near


func _init(p_bpm := 90.0, p_offset := 0.0) -> void:
	bpm = p_bpm
	offset = p_offset
	sub = pick_sub(bpm)


static func pick_sub(tempo: float) -> int:
	var best := 1
	var err := INF
	for s in [1, 2, 3, 4]:
		var e := absf(tempo / 60.0 * s - BOUNCE_HZ)
		if e < err:
			err = e
			best = s
	return best


func beat_len() -> float:
	return 60.0 / bpm


func bounce_len() -> float:
	return beat_len() / sub


func bar_len() -> float:
	return beat_len() * beats_per_bar


## Beats since beat 0 at song time t (fractional).
func beat_at(t: float) -> float:
	return (t - offset) / beat_len()


func time_of_beat(b: float) -> float:
	return offset + b * beat_len()


## The first whole bar starting at or after song time t.
func next_bar(t: float) -> float:
	var b := ceilf(beat_at(t) / beats_per_bar - 0.0001) * beats_per_bar
	return time_of_beat(b)


## Song time of the nearest bounce slot to t, counted from `origin`
## (the race's go), and its index.
func nearest_slot(t: float, origin: float) -> Vector2:
	var k := roundf((t - origin) / bounce_len())
	return Vector2(origin + k * bounce_len(), k)
