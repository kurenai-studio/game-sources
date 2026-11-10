class_name SkiJump
extends RefCounted
## One ski jump.
##
## Down the in-run for two bars: tap BOUNCE on every beat to tuck tighter and
## go faster. The edge of the table comes on the next downbeat: JUMP on it to
## spring off. In the air, keep your balance: BOUNCE on every beat (a tap off
## the beat wobbles you and the air takes your lift). As the snow comes up,
## press JUMP as you touch down for a telemark landing.
##
## Distance points (60 at the K-point, 1.8 a metre either side) plus five
## judges' style marks out of 20 (the top and bottom dropped).

const K := 90.0                  ## the K-point (metres)
const HILL := 135.0              ## the hill size
const INRUN_BEATS := 8
const GRAVITY := 9.8
const LIFT := 3.4                ## how much a perfect V holds it up

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var driver: Rival
var cpu := false
var skill := 0.8
var rng := RandomNumberGenerator.new()
var go := 0.0
var state := "set"               ## set, inrun, flight, landed, done
var x := 0.0                     ## metres from the edge of the table (negative on the in-run)
var y := 0.0                     ## height (metres) relative to the table's edge
var vx := 0.0
var vy := 0.0
var balance := 0.7               ## 0..1: how well it holds the V in the air
var take_off := ""               ## the edge's grade
var landing := ""                ## telemark, two feet, fall
var distance := 0.0
var points := 0.0
var marks: Array = []
var log: Array = []
var t := 0.0
var windows: Array = [0.05, 0.09, 0.13]
var grace := 0.0                 ## extra wait before a beat counts as missed (a phone's press may still be on its way)
var _flight_beats := {}          ## beat index -> tapped
var _land_t := -1.0
var _touch_t := -1.0
var _done_at := 0.0
var _wobbles := 0
var _cpu_plan: Array = []


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, seed := 1) -> void:
	info = Catalog.event("ski_jump")
	beat = p_beat
	level = p_level
	windows = Catalog.windows(level)
	cpu = bool(entrant.get("cpu", false))
	skill = float(entrant.get("skill", 0.8))
	rng.seed = seed * 23 + 9
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = cpu
	b.windows = windows
	b.action_mode = "none"
	b.steady = true
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	if cpu:
		driver = Rival.new(b, skill, seed)
		_cpu_edge = clampf(rng.randfn(0.0, lerpf(0.09, 0.02, skill)), -0.12, 0.12)


var _cpu_edge := 0.0


## The landing hill's height below the table's edge at x (metres; negative is
## down): a knoll, then the steep landing slope, then the outrun flattening
## out. Worked out once, a metre at a time, and read off by interpolation.
static var _profile: PackedFloat32Array = PackedFloat32Array()


static func hill(xm: float) -> float:
	if xm <= 0.0:
		return 0.0
	if _profile.is_empty():
		var y_ := 0.0
		_profile.append(0.0)
		for p in 260:
			var ang := 0.0
			if p < 12:
				ang = lerpf(10.0, 30.0, p / 12.0)
			elif p < 110:
				ang = 35.0
			elif p < 150:
				ang = lerpf(35.0, 0.0, (p - 110.0) / 40.0)
			y_ -= tan(deg_to_rad(ang))
			_profile.append(y_)
	var i := clampi(int(floor(xm)), 0, _profile.size() - 2)
	var f := clampf(xm - i, 0.0, 1.0)
	return lerpf(_profile[i], _profile[i + 1], f) - 3.0


## The in-run: a steep straight ramp down to the table, x from -L to 0.
static func inrun(xm: float) -> float:
	return -xm * tan(deg_to_rad(35.0)) * 0.6 if xm < 0.0 else 0.0


func edge_time() -> float:
	return go + INRUN_BEATS * beat.beat_len()


func press(action: bool, at: float) -> String:
	match state:
		"inrun":
			if action:
				return _take_off(at)
			return b.tap(at, false)
		"flight":
			if action:
				# reaching for the landing: the first reach is the one that
				# counts (mashing it only unsettles the flight)
				if _land_t < 0.0:
					_land_t = at
					return ""
				balance = clampf(balance - 0.18, 0.0, 1.0)
				_wobbles += 1
				b.mood = "ouch"
				log.append({"kind": "wobble"})
				return "fumble"
			var n := roundf(beat.beat_at(at))
			var e := at - beat.time_of_beat(n)
			var g := "perfect" if absf(e) <= float(windows[0]) else ("good" if absf(e) <= float(windows[1]) else \
				("ok" if absf(e) <= float(windows[2]) else ""))
			if g == "" or _flight_beats.has(int(n)):
				balance = clampf(balance - 0.18, 0.0, 1.0)
				_wobbles += 1
				b.mood = "ouch"
				log.append({"kind": "wobble"})
				return "fumble"
			_flight_beats[int(n)] = g
			balance = clampf(balance + {"perfect": 0.12, "good": 0.06, "ok": 0.02}[g], 0.0, 1.0)
			b.mood = "fly"
			log.append({"kind": "balance", "grade": g})
			return g
		"landed":
			if action and _land_t < 0.0:
				_land_t = at
	return ""


func _take_off(at: float) -> String:
	if state != "inrun":
		return ""
	var e := at - edge_time()
	var ae := absf(e)
	var g := "perfect" if ae <= float(windows[0]) else ("good" if ae <= float(windows[1]) else \
		("ok" if ae <= float(windows[2]) else ""))
	if g == "":
		if e < 0.0:
			return ""              # too early: nothing yet
		g = "late"
	take_off = g
	_launch()
	return g


func _launch() -> void:
	state = "flight"
	b.state = "done"              # off the edge: no more bouncing
	var power: float = {"perfect": 1.0, "good": 0.82, "ok": 0.62, "late": 0.3, "none": 0.15}.get(take_off, 0.3)
	var speed := 20.0 + 6.0 * b.spring
	vx = speed * cos(deg_to_rad(10.0))
	vy = -speed * sin(deg_to_rad(10.0)) + 3.4 * power
	x = 0.0
	y = 0.0
	balance = 0.3 + 0.3 * power
	b.mood = "fly"
	log.append({"kind": "take_off", "grade": take_off, "speed": speed})


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= go:
				state = "inrun"
				b.start(go, beat.beat_len(), beat.beat_len())
				b.vx = 0.0
		"inrun":
			if driver != null:
				driver.update(at)
				if at >= edge_time() + _cpu_edge:
					_take_off(edge_time() + _cpu_edge)
			b.update(at, dt)
			b.y = 0.0
			# slide down the in-run: from -50 m to the edge over the two bars
			var u := clampf((at - go) / (INRUN_BEATS * beat.beat_len()), 0.0, 1.0)
			x = lerpf(-50.0, 0.0, u * u * 0.6 + u * 0.4)
			y = inrun(x)
			if at > edge_time() + float(windows[2]) + grace and state == "inrun":
				take_off = "none"
				_launch()
		"flight":
			if cpu:
				_cpu_flight(at)
			# the beats in the air: one gone by untapped loses some lift
			var n := int(floor(beat.beat_at(at)))
			var prev := n - 1
			if beat.time_of_beat(prev) > edge_time() + 0.1 and not _flight_beats.has(prev) \
					and at > beat.time_of_beat(prev) + float(windows[2]) + grace:
				_flight_beats[prev] = "miss"
				balance = clampf(balance - 0.12, 0.0, 1.0)
			# lift from the V, gravity, a little drag
			vy -= (GRAVITY - LIFT * balance) * dt
			vx -= (0.35 + 0.4 * (1.0 - balance)) * dt
			x += vx * dt
			y += vy * dt
			if y <= hill(x):
				y = hill(x)
				_touch_t = at
				distance = x
				state = "landed"
				log.append({"kind": "touch", "distance": distance})
		"landed":
			if cpu and _land_t < 0.0:
				_land_t = _touch_t + rng.randfn(0.0, lerpf(0.12, 0.03, skill))
			x += vx * dt * 0.8
			vx = move_toward(vx, 0.0, 6.0 * dt)
			y = hill(x)
			if at - _touch_t > 0.35 and landing == "":
				_judge()
			if at - _touch_t > 2.4:
				state = "done"
				_done_at = at
		"done":
			pass


func _cpu_flight(at: float) -> void:
	var n := roundf(beat.beat_at(at))
	var when := beat.time_of_beat(n)
	if not _flight_beats.has(int(n)) and when > edge_time() + 0.1 and at >= when + _jit(int(n)):
		if rng.randf() > (1.0 - skill) * 0.15:
			press(false, when + _jit(int(n)))


var _jits := {}


func _jit(n: int) -> float:
	if not _jits.has(n):
		_jits[n] = clampf(rng.randfn(0.0, lerpf(0.09, 0.02, skill)), -0.1, 0.1)
	return _jits[n]


func _judge() -> void:
	var e := absf(_land_t - _touch_t) if _land_t >= 0.0 else 9.0
	if e <= 0.12:
		landing = "telemark"
	elif e <= 0.3:
		landing = "two feet"
	else:
		landing = "wobbly"
	if take_off == "none" or take_off == "late":
		landing = "wobbly" if landing == "telemark" else landing
	var base: float = {"telemark": 19.0, "two feet": 17.0, "wobbly": 14.5}[landing]
	base -= _wobbles * 0.5
	marks = []
	for j in 5:
		marks.append(clampf(roundf((base + rng.randfn(0.0, 0.4)) * 2.0) / 2.0, 0.0, 20.0))
	var sorted := marks.duplicate()
	sorted.sort()
	var style := float(sorted[1]) + float(sorted[2]) + float(sorted[3])
	points = maxf(0.0, 60.0 + (distance - K) * 1.8) + style
	b.mood = "joy" if landing == "telemark" else ("happy" if landing == "two feet" else "dizzy")
	log.append({"kind": "landing", "how": landing, "distance": distance, "points": points})


func finished() -> bool:
	return state == "done"
