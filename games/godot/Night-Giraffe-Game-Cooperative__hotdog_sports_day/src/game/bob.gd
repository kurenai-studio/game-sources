class_name Bob
extends RefCounted
## One bobsleigh run. The bun is the sled.
##
## The push: a bar of bouncing behind the bun, tapping BOUNCE on the beat;
## every tap in time adds to the start speed. On the next downbeat, JUMP to
## hop in. Then the bends come, one every two beats, each banked high or low:
## lean with it on its beat (JUMP for a high bend, BOUNCE for a low one). A
## clean lean carries speed through; the wrong lean, or none, and the bun
## scrapes the wall. Lowest time wins; everyone gets the same track.

const LENGTH := 640.0            ## metres of ice
const PUSH_BEATS := 4
const BEND_EVERY := 2            ## beats between bends

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var driver: Rival
var cpu := false
var skill := 0.8
var rng := RandomNumberGenerator.new()
var go := 0.0
var state := "set"               ## set, push, run, finished, done
var bends: Array = []            ## [{at (beat from go), high, grade}]
var d := 0.0                     ## metres down the track
var v := 0.0                     ## speed, metres a second
var lean := 0.0                  ## -1 low .. +1 high, for the view
var hop := ""                    ## how well it hopped in
var time := 0.0                  ## the run's time, from the hop
var log: Array = []
var t := 0.0
var windows: Array = [0.05, 0.09, 0.13]
var grace := 0.0                 ## extra wait before a beat counts as missed (a phone's press may still be on its way)
var _start_t := 0.0
var _done_at := 0.0
var _plan: Array = []


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, track_seed := 1, seed := 1) -> void:
	info = Catalog.event("bobsleigh")
	beat = p_beat
	level = p_level
	windows = Catalog.windows(level)
	cpu = bool(entrant.get("cpu", false))
	skill = float(entrant.get("skill", 0.8))
	rng.seed = seed * 29 + 11
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = cpu
	b.bash = not cpu                   # players push on two RUN buttons
	b.windows = windows
	b.action_mode = "none"
	b.steady = true
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	bends = make_track(track_seed, PUSH_BEATS + 2)
	if cpu:
		driver = Rival.new(b, skill, seed)
		_plan_cpu()


## The bends: which way each is banked, from a seed.
static func make_track(seed: int, first: int) -> Array:
	var out: Array = []
	for k in 24:
		var high := ((seed * 31 + k * 17 + (k * k) % 7) % 5) >= 2
		out.append({"at": first + k * BEND_EVERY, "high": high, "grade": ""})
	return out


func hop_time() -> float:
	return go + PUSH_BEATS * beat.beat_len()


func bend_time(bd: Dictionary) -> float:
	return go + float(bd.at) * beat.beat_len()


func _grade(err: float) -> String:
	var e := absf(err)
	return "perfect" if e <= float(windows[0]) else ("good" if e <= float(windows[1]) else ("ok" if e <= float(windows[2]) else ""))


func press(action: bool, at: float) -> String:
	match state:
		"push":
			if action:
				return _hop(at)
			if b.bash:
				b.bash_other(at)
				return ""
			return b.tap(at, false)
		"run":
			# the nearest bend still to come (or just gone)
			var best: Dictionary = {}
			var err := INF
			for bd in bends:
				if bd.grade != "":
					continue
				var e := at - bend_time(bd)
				if absf(e) < absf(err):
					err = e
					best = bd
			var g := _grade(err)
			if best.is_empty() or g == "":
				v = maxf(14.0, v - 0.6)
				log.append({"kind": "wobble"})
				return "fumble"
			if bool(best.high) != action:
				_scrape(best, "wrong")
				return "wrong"
			best.grade = g
			v += {"perfect": 0.7, "good": 0.35, "ok": 0.0}[g]
			lean = 1.0 if action else -1.0
			b.mood = "happy" if g == "perfect" else "push"
			log.append({"kind": "bend", "grade": g, "high": action})
			return g
	return ""


## A RUN button. In the run-up (and waiting for it) it's a step: the two RUN
## buttons tapped in turn, as fast as you can, build the speed. Otherwise
## it's BOUNCE.
func run(side: int, at: float) -> String:
	if run_up():
		b.bash_tap(at, side)
		return ""
	return press(false, at)


## Whether RUN taps are building speed now.
func run_up() -> bool:
	return b.bash and (state == "set" or ((state == "push") and b.state == "run"))


func _hop(at: float) -> String:
	if state != "push":
		return ""
	var e := at - hop_time()
	var g := _grade(e)
	if g == "":
		if e < 0.0:
			return ""
		g = "late"
	hop = g
	_go()
	return g


func _go() -> void:
	state = "run"
	b.state = "done"              # in the sled: no more bouncing
	_start_t = hop_time()
	var bonus: float = {"perfect": 1.5, "good": 0.8, "ok": 0.2, "late": -1.0, "none": -2.0}.get(hop, 0.0)
	v = 17.0 + 9.0 * b.spring + bonus
	b.mood = "fly"
	log.append({"kind": "hop_in", "grade": hop, "speed": v})


func _scrape(bd: Dictionary, why: String) -> void:
	bd.grade = why
	v = maxf(14.0, v - 3.2)
	lean = 0.0
	b.mood = "ouch"
	log.append({"kind": "scrape", "why": why})


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= go:
				state = "push"
				b.start(go, beat.bounce_len(), beat.beat_len())
				b.vx = 0.0
		"push":
			if driver != null:
				driver.update(at)
				if at >= hop_time() + _cpu_hop:
					_hop(hop_time() + _cpu_hop)
			b.update(at, dt)
			d = lerpf(0.0, 8.0, clampf((at - go) / (hop_time() - go), 0.0, 1.0)) * (0.5 + 0.5 * b.spring)
			if at > hop_time() + float(windows[2]) + grace and state == "push":
				hop = "none"
				_go()
		"run":
			if cpu:
				_cpu(at)
			# bends gone by untouched scrape the wall
			for bd in bends:
				if bd.grade == "" and at > bend_time(bd) + float(windows[2]) + grace:
					_scrape(bd, "miss")
			v = minf(40.0, v + 0.18 * dt)
			d += v * dt
			lean = move_toward(lean, 0.0, dt * 2.5)
			if d >= LENGTH:
				time = at - _start_t - (d - LENGTH) / v
				state = "finished"
				_done_at = at
				b.mood = "joy"
				log.append({"kind": "finish", "time": time})
		"finished":
			v = move_toward(v, 0.0, 12.0 * dt)
			d += v * dt
			if at - _done_at > 1.8:
				state = "done"


var _cpu_hop := 0.0


func _plan_cpu() -> void:
	_cpu_hop = clampf(rng.randfn(0.0, lerpf(0.09, 0.02, skill)), -0.12, 0.12)
	var sigma := lerpf(0.1, 0.02, skill)
	_plan = []
	for bd in bends:
		if rng.randf() < (1.0 - skill) * 0.12:
			continue
		var high: bool = bd.high
		if rng.randf() < (1.0 - skill) * 0.1:
			high = not high
		_plan.append({"t": bend_time(bd) + rng.randfn(0.0, sigma), "action": high})


func _cpu(at: float) -> void:
	while not _plan.is_empty() and at >= float(_plan[0].t):
		var p: Dictionary = _plan.pop_front()
		press(bool(p.action), float(p.t))


## The next few bends, for the view's cue cards.
func coming(at: float, ahead := 6.0) -> Array:
	var out: Array = []
	for bd in bends:
		var dt_ := bend_time(bd) - at
		if dt_ > -0.4 and dt_ < ahead * beat.beat_len():
			out.append({"in": dt_, "high": bd.high, "grade": bd.grade})
	return out


func result() -> float:
	return time if state == "finished" or state == "done" else 99.0


func finished() -> bool:
	return state == "done"
