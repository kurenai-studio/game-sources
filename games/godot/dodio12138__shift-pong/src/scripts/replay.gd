extends RefCounted
## Rolling recording of the last few seconds of play — ball, rackets, spin and
## sound events — so a rally can be replayed exactly (highlight and VAR replays).

const SECONDS := 9.0

var clock := 0.0         # game time recorded so far
var frames: Array = []   # [t, bp, bv, bw, paddle_player, paddle_ai, ball_live]
var events: Array = []   # [t, kind, pos, speed, detail]


func record(delta: float, bp: Vector3, bv: Vector3, bw: Vector3, pp: Vector3, pa: Vector3, live: bool) -> void:
	clock += delta
	frames.append([clock, bp, bv, bw, pp, pa, live])
	while frames.size() > 2 and frames[0][0] < clock - SECONDS:
		frames.pop_front()
	while not events.is_empty() and events[0][0] < clock - SECONDS:
		events.pop_front()


## A sound-making moment ("hit", "table", "net", "floor") to replay with the frames.
func event(kind: String, pos: Vector3, speed: float, detail := "") -> void:
	events.append([clock, kind, pos, speed, detail])


func earliest() -> float:
	return frames[0][0] if not frames.is_empty() else clock


## Recorded state at time `t`, interpolated between frames:
## [bp, bv, bw, paddle_player, paddle_ai, ball_live].
func sample(t: float) -> Array:
	if frames.is_empty():
		return []
	var lo := 0
	var hi := frames.size() - 1
	if t <= frames[0][0]:
		hi = 0
	elif t >= frames[hi][0]:
		lo = hi
	else:
		while hi - lo > 1:
			var mid := (lo + hi) / 2
			if frames[mid][0] <= t:
				lo = mid
			else:
				hi = mid
	var a: Array = frames[lo]
	var b: Array = frames[hi]
	var k: float = 0.0 if b[0] == a[0] else (t - a[0]) / (b[0] - a[0])
	return [a[1].lerp(b[1], k), a[2].lerp(b[2], k), a[3].lerp(b[3], k), a[4].lerp(b[4], k), a[5].lerp(b[5], k), a[6]]
