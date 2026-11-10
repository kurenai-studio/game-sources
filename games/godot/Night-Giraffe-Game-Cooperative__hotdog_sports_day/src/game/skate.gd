class_name Skate
extends RefCounted
## One skateboarding run through the street course.
##
## The board rolls on at a steady speed in time with the music (one beat, so
## many metres), so everything on the course arrives on a beat. Between
## obstacles, tap BOUNCE on every beat to push: that keeps the flow up, and
## flow multiplies every trick. The obstacles:
##   cone    JUMP on its beat to ollie over it.
##   rail    JUMP on its first beat to jump on, hold JUMP along it, let go on
##           its last beat to jump off.
##   ramp    JUMP on its beat to launch: two beats of air. On the beat at the
##           top, BOUNCE for a kickflip or JUMP for a 360; tap BOUNCE as the
##           board lands, on the beat after.
## A missed cone or a bad landing is a bail: the hot dog tumbles, the flow
## drains and the combo starts again. Everyone gets the same course.

const SPEED := 2.6               ## metres a beat
const POINTS := {"ollie": 50.0, "kickflip": 110.0, "spin": 130.0, "land": 30.0, "grind": 40.0, "off": 50.0}
const GRADE_K := {"perfect": 1.0, "good": 0.75, "ok": 0.5}

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var cpu := false
var skill := 0.8
var rng := RandomNumberGenerator.new()
var go := 0.0
var state := "set"               ## set, ride, done
var course: Array = []           ## [{kind, at (beat from go), len}]
var x := 0.0                     ## metres along the course
var y := 0.0                     ## height of the board off the ground (metres)
var flow := 0.3                  ## 0..1, from pushes on the beat
var combo := 0                   ## tricks landed since the last bail
var score := 0.0
var pose := "roll"               ## roll, ollie, air, grind, bail
var pose_at := -10.0
var trick := ""                  ## kickflip, spin: the trick in the air
var trick_at := -10.0
var log: Array = []
var t := 0.0
var windows: Array = [0.05, 0.09, 0.13]
var length := 0                  ## beats in the course
var _judged := {}                ## beat index -> what was judged there
var _holding := false
var _feature: Dictionary = {}    ## the obstacle being ridden now
var _plan: Array = []
var _done_at := 0.0


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, course_seed := 1, seed := 1) -> void:
	info = Catalog.event("skateboard")
	beat = p_beat
	level = p_level
	windows = Catalog.windows(level)
	cpu = bool(entrant.get("cpu", false))
	skill = float(entrant.get("skill", 0.8))
	rng.seed = seed * 19 + 3
	b = Bouncer.new()
	b.name = String(entrant.get("name", "?"))
	b.cpu = cpu
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	course = make_course(course_seed)
	length = 0
	for f in course:
		length = maxi(length, int(f.at) + int(f.len) + 2)
	length = int(ceil(length / 4.0)) * 4 + 4
	if cpu:
		_plan_cpu()


## The course: eight obstacles with room to push between them.
static func make_course(seed: int) -> Array:
	var kinds := ["cone", "rail", "ramp", "cone", "ramp", "rail", "cone", "ramp"]
	var out: Array = []
	var at := 4                      # a bar of pushing first
	for i in kinds.size():
		var k: String = kinds[(i + seed) % kinds.size()] if i > 0 else "cone"
		var len := 0
		match k:
			"rail":
				len = 4 if (seed + i) % 2 == 0 else 6
			"ramp":
				len = 2
		out.append({"kind": k, "at": at, "len": len})
		at += len + 3 + ((seed * 7 + i * 3) % 2)
	return out


func beat_time(n: float) -> float:
	return go + n * beat.beat_len()


func now_beat(at: float) -> float:
	return (at - go) / beat.beat_len()


func _grade(err: float) -> String:
	var e := absf(err)
	return "perfect" if e <= float(windows[0]) else ("good" if e <= float(windows[1]) else ("ok" if e <= float(windows[2]) else ""))


## The obstacle that starts nearest beat n (within a beat), or {}.
func feature_at(n: float) -> Dictionary:
	for f in course:
		if absf(float(f.at) - n) < 0.6:
			return f
	return {}


func _in_feature(n: float) -> Dictionary:
	for f in course:
		if n >= float(f.at) - 0.5 and n <= float(f.at) + float(f.len) + 0.5:
			return f
	return {}


func press(action: bool, at: float) -> String:
	if state != "ride":
		return ""
	var n := roundf(now_beat(at))
	var err := at - beat_time(n)
	var g := _grade(err)
	var f := _in_feature(n)
	if action:
		_holding = true
		if g == "":
			_flow(-0.12)
			log.append({"kind": "wobble"})
			return "fumble"
		var start := feature_at(n)
		if not start.is_empty() and int(start.at) == int(n) and not _judged.has(int(n)):
			_judged[int(n)] = true
			_take(start, g, at)
			return g
		# a trick in the air: JUMP on the beat at the top is a 360
		if not _feature.is_empty() and _feature.kind == "ramp" and int(n) == int(_feature.at) + 1 and trick == "":
			_trick("spin", g, at)
			return g
		# a JUMP with nothing to jump: the board clatters, and the flow drops
		_flow(-0.06)
		log.append({"kind": "wobble"})
		return "fumble"
	# BOUNCE: a push, a kickflip at the top of a ramp, or a landing
	if g == "":
		_flow(-0.12)
		log.append({"kind": "wobble"})
		return "fumble"
	if not _feature.is_empty() and _feature.kind == "ramp":
		if int(n) == int(_feature.at) + 1 and trick == "":
			_trick("kickflip", g, at)
			return g
		if int(n) == int(_feature.at) + 2 and not _judged.has(int(n)):
			_judged[int(n)] = true
			_land(g)
			return g
	if not f.is_empty() and f.kind == "rail" and pose == "grind":
		return ""
	if not feature_at(n).is_empty():
		return ""                  # an obstacle's beat is for JUMP, not a push
	if _judged.has(int(n)):
		_flow(-0.06)
		return "fumble"
	_judged[int(n)] = true
	_flow({"perfect": 0.1, "good": 0.05, "ok": 0.02}[g])
	b.mood = "happy" if g == "perfect" else "push"
	pose_at = at
	log.append({"kind": "push", "grade": g})
	return g


func release(at: float) -> void:
	_holding = false
	if state != "ride" or _feature.is_empty() or _feature.kind != "rail" or pose != "grind":
		return
	var end := float(_feature.at) + float(_feature.len)
	var n := now_beat(at)
	var g := _grade(at - beat_time(end))
	var beats := clampf(n - float(_feature.at), 0.0, float(_feature.len))
	_points(POINTS.grind * beats, "")
	if g != "":
		_points(POINTS.off * GRADE_K[g], g)
		log.append({"kind": "off", "grade": g, "beats": beats})
		combo += 1
	else:
		log.append({"kind": "off", "grade": "early" if n < end else "late", "beats": beats})
	pose = "ollie"
	pose_at = at
	_feature = {}


func _take(f: Dictionary, g: String, at: float) -> void:
	_feature = f
	pose_at = at
	match String(f.kind):
		"cone":
			pose = "ollie"
			_points(POINTS.ollie * GRADE_K[g], g)
			combo += 1
			log.append({"kind": "ollie", "grade": g})
			_feature = {}
		"rail":
			pose = "grind"
			log.append({"kind": "grind", "grade": g})
		"ramp":
			pose = "air"
			trick = ""
			log.append({"kind": "launch", "grade": g})
	b.mood = "fly"


func _trick(kind: String, g: String, at: float) -> void:
	trick = kind
	trick_at = at
	_points(POINTS[kind] * GRADE_K[g], g)
	log.append({"kind": kind, "grade": g})


func _land(g: String) -> void:
	_points(POINTS.land * GRADE_K[g], g)
	combo += 1
	pose = "roll"
	pose_at = t
	trick = ""
	_feature = {}
	b.mood = "joy" if g == "perfect" else "happy"
	log.append({"kind": "landed", "grade": g})


func _bail(why: String) -> void:
	pose = "bail"
	pose_at = t
	combo = 0
	trick = ""
	_feature = {}
	_flow(-0.3)
	b.mood = "dizzy"
	log.append({"kind": "bail", "why": why})


func _flow(d: float) -> void:
	flow = clampf(flow + d, 0.0, 1.0)


func _points(p: float, _g: String) -> void:
	var mult := 1.0 + flow + minf(combo, 10) * 0.1
	score += p * mult


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= go:
				state = "ride"
		"ride":
			if cpu:
				_cpu(at)
			var n := now_beat(at)
			x = n * SPEED
			# flow fades unless it's kept up
			_flow(-0.035 * dt / beat.beat_len())
			# obstacles gone by without being taken
			for f in course:
				var start := int(f.at)
				if n > start + 0.5 and not _judged.has(start):
					_judged[start] = true
					if f.kind == "cone":
						_bail("cone")
					else:
						log.append({"kind": "skipped", "what": f.kind})
						combo = 0
			if not _feature.is_empty():
				var f2: Dictionary = _feature
				var start2 := float(f2.at)
				if f2.kind == "ramp" and n > start2 + 2.5 and not _judged.has(int(start2) + 2):
					_judged[int(start2) + 2] = true
					_bail("landing")
				if f2.kind == "rail" and pose == "grind":
					if not _holding:
						release(at)
					elif n > start2 + float(f2.len) + 0.5:
						# held on past the end: falls off the end of the rail
						_bail("rail")
			# the board's height
			var p := at - pose_at
			match pose:
				"ollie":
					y = maxf(0.0, 1.0 * 4.0 * (p / beat.beat_len()) * (1.0 - p / beat.beat_len())) if p < beat.beat_len() else 0.0
					if p >= beat.beat_len():
						pose = "roll"
				"air":
					var u := clampf(p / (beat.beat_len() * 2.0), 0.0, 1.0)
					y = 2.6 * 4.0 * u * (1.0 - u) + 0.6 * (1.0 - u)
				"grind":
					y = 0.75
				"bail":
					y = 0.0
					if p > beat.beat_len() * 1.5:
						pose = "roll"
						b.mood = "push"
				_:
					y = 0.0
			b.y = y
			if n > length:
				state = "done"
				_done_at = at
				b.mood = "joy"
				log.append({"kind": "done", "score": score})
		"done":
			x += SPEED / beat.beat_len() * dt * 0.5


func _plan_cpu() -> void:
	_plan = []
	var sigma := lerpf(0.1, 0.02, skill)
	var busy := {}
	for f in course:
		var a := int(f.at)
		for k in range(a, a + int(f.len) + 1):
			busy[k] = true
		if rng.randf() < (1.0 - skill) * 0.15:
			continue
		match String(f.kind):
			"cone":
				_plan.append({"at": a, "action": true, "down": true})
			"rail":
				_plan.append({"at": a, "action": true, "down": true})
				_plan.append({"at": a + int(f.len), "action": true, "down": false})
			"ramp":
				_plan.append({"at": a, "action": true, "down": true})
				_plan.append({"at": a, "action": true, "down": false, "dt": 0.1})
				if rng.randf() < 0.45 + 0.5 * skill:
					_plan.append({"at": a + 1, "action": rng.randf() < 0.45, "down": true})
					_plan.append({"at": a + 1, "action": true, "down": false, "dt": 0.1})
				_plan.append({"at": a + 2, "action": false, "down": true})
	for n in 64:
		if not busy.has(n) and rng.randf() < 0.55 + 0.45 * skill:
			_plan.append({"at": n, "action": false, "down": true})
	for p in _plan:
		p["t"] = beat_time(float(p.at)) + float(p.get("dt", 0.0)) + rng.randfn(0.0, sigma)
	_plan.sort_custom(func(a, c): return float(a.t) < float(c.t))


func _cpu(at: float) -> void:
	while not _plan.is_empty() and at >= float(_plan[0].t):
		var p: Dictionary = _plan.pop_front()
		if bool(p.down):
			press(bool(p.action), float(p.t))
		else:
			release(float(p.t))


func finished() -> bool:
	return state == "done" and t - _done_at > 1.6
