class_name High
extends RefCounted
## One attempt at the high jump (or the springboard vault), at one height.
##
## The run-in is a set number of bounces, ending on a spot just before the bar
## (x = 0 is the bar). A player taps RUN, RUN for spring and presses JUMP as
## near the spot as they can, the moment they press it (game/aim.gd); held, a
## needle climbs from 40 degrees: let go in the green. The computer plants on
## its last bounce and lets go at its own angle. Up in the air, a tap of JUMP arches it
## flat (a Fosbury flop, for a sausage) for half a second: arched, its lowest
## point is much nearer its middle, so it can slide over a bar it would knock
## upright. Clearing is decided as its middle passes over the bar.

# The high jump's numbers; the vault's come from data/events.json ("shape").
var SPOT := -1.4                 ## the take-off spot, before the bar
var STEP := 2.0                  ## ground covered each bounce of the run-in
var GRAVITY := 8.5
var LAUNCH := Vector2(3.4, 2.6)  ## launch speed: base + gain * spring
var AIM := Vector3(40.0, 30.0, 88.0)   ## the aim: start, degrees a beat, top
const MIDDLE := 0.9              ## the middle of a hot dog, above its bottom
const ARCH_LOW := 0.28           ## arched: its lowest point below its middle
const ARCH_FOR := 0.5            ## seconds an arch lasts
const LATE_ARCH := 0.2           ## an arch this soon after crossing still counts
var MAT_FROM := 0.3              ## the landing mat begins this far past the bar
var MAT_H := 0.7                 ## and is this tall
var id := "high_jump"

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var bar := 1.5
var b: Bouncer
var driver: Rival
var go := 0.0
var approach := 7
var state := "set"               ## set, run, air, landed, done
var cleared := false
var knocked := false
var balked := false
var arched_at := -10.0
var arch_grade := ""
var apex_time := 0.0
var log: Array = []
var t := 0.0
var cpu_angle := 70.0
var cpu_arch := 0.0              ## seconds after launch the computer arches
var _decided := false
var _cross_t := -1.0             ## when its middle passed over the bar
var _low_up := 0.0
var _low_arched := 0.0
var _landed_at := 0.0
var _launch_t := 0.0
var band := "gentle"             ## a player's age band: how the aim goes (game/aim.gd)
var aim_target := 68.0           ## the best angle to let go at
var aim_green := 7.0


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, height: float, now: float, seed := 1,
		p_id := "high_jump") -> void:
	id = p_id
	info = Catalog.event(id)
	var shape: Dictionary = info.get("shape", {})
	SPOT = float(shape.get("spot", SPOT))
	STEP = float(shape.get("step", STEP))
	GRAVITY = float(shape.get("gravity", GRAVITY))
	var l: Array = shape.get("launch", [LAUNCH.x, LAUNCH.y])
	LAUNCH = Vector2(float(l[0]), float(l[1]))
	var a: Array = shape.get("aim", [AIM.x, AIM.y, AIM.z])
	AIM = Vector3(float(a[0]), float(a[1]), float(a[2]))
	var m: Array = shape.get("mat", [MAT_FROM, MAT_H])
	MAT_FROM = float(m[0])
	MAT_H = float(m[1])
	beat = p_beat
	level = p_level
	bar = height
	approach = int(info.get("approach", 7))
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = bool(entrant.get("cpu", false))
	b.skill = float(entrant.get("skill", 0.8))
	b.bash = not b.cpu                 # players run in on two RUN buttons
	band = String(entrant.get("band", "gentle"))
	aim_green = Aim.green(band)
	if not b.cpu:
		b.aim_speed = Aim.speed(band)
	b.windows = Catalog.windows(level)
	if level == "easy":
		b.forgive()
	b.action_mode = "hold"
	b.steady = true
	b.x = SPOT - STEP * approach
	cpu_angle = float(info.get("shape", {}).get("cpu_angle", 68.0))
	aim_target = cpu_angle
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	if b.cpu:
		driver = Rival.new(b, b.skill, seed)
		driver.think = func(_r: Rival, slot: int) -> bool: return slot >= approach
		cpu_angle = float(info.get("shape", {}).get("cpu_angle", 68.0)) + driver.rng.randfn(0.0, lerpf(8.0, 1.5, b.skill))
		cpu_arch = driver.rng.randfn(0.0, lerpf(0.16, 0.03, b.skill))


func press(action: bool, at: float) -> String:
	if state == "run" and b.state == "run":
		if b.bash and not action:
			b.bash_other(at)
			return ""
		if action and not b.cpu:
			return _take_off_now(at)
		return b.tap(at, action)
	if state == "air" and action and arched_at < 0.0:
		_arch(at)
		return arch_grade
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
	return b.bash and (state == "set" or ((state == "run") and b.state == "run"))


## Plant here and now, graded by how near the take-off spot it was.
func _take_off_now(at: float) -> String:
	var g := Aim.line_grade(b.x - SPOT, b.x > SPOT + 0.6)
	b.take_off_now(at, g, "hold")
	return g


## The aim while JUMP is held, for the dial.
func aim(at: float) -> Dictionary:
	return {"angle": b.hold_angle(at, AIM.y, AIM.x, AIM.z), "start": AIM.x, "top": AIM.z,
		"lo": aim_target - aim_green, "hi": aim_target + aim_green}


func release(at: float) -> void:
	if b.state != "hold" or state != "run":
		return
	var deg := b.hold_angle(at, AIM.y, AIM.x, AIM.z)
	var bonus: float = {"perfect": 0.03, "good": 0.015}.get(b.hold_grade, 0.0)
	var v := (LAUNCH.x + LAUNCH.y * b.spring) * (1.0 + bonus)
	b.launch(v, deg)
	b.vx = v * cos(deg_to_rad(deg))
	state = "air"
	_launch_t = at
	apex_time = at + b.vy / GRAVITY
	arched_at = -1.0
	log.append({"kind": "launch", "angle": deg, "speed": v})


func _arch(at: float) -> void:
	arched_at = at
	var err := at - apex_time
	var e := absf(err)
	arch_grade = "perfect" if e < 0.07 else ("good" if e < 0.14 else ("ok" if e < 0.24 else "late" if err > 0 else "early"))
	b.mood = "push"
	log.append({"kind": "arch", "grade": arch_grade})


func arched(at: float) -> bool:
	return arched_at >= 0.0 and at >= arched_at and at < arched_at + ARCH_FOR


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= go:
				state = "run"
				b.start(go, beat.bounce_len(), beat.beat_len())
				b.vx = STEP / beat.bounce_len()
		"run":
			if driver != null and b.state == "run":
				driver.update(at)
			b.update(at, dt)
			if b.state == "hold":
				var deg := b.hold_angle(at, AIM.y, AIM.x, AIM.z)
				if b.cpu and deg >= cpu_angle:
					release(at)
				elif not b.cpu and Aim.helps(band) and deg >= aim_target:
					release(at)            # (5-7: it lets go for them, at the best angle)
				elif deg >= AIM.z - 0.1:
					release(at)
			elif b.state == "run" and not b.cpu and Aim.helps(band) and b.x > SPOT + 0.25:
				_take_off_now(at)          # (5-7: past the spot? it goes anyway, a little late)
			elif b.state == "run" and b.x > SPOT + 0.8:
				# ran in under the bar without taking off
				balked = true
				knocked = true
				b.state = "down"
				b.mood = "dizzy"
				state = "landed"
				_landed_at = at
				log.append({"kind": "balk"})
		"air":
			if (b.cpu or Aim.helps(band)) and arched_at < 0.0 and at >= apex_time + cpu_arch:
				_arch(at)
			var px := b.x
			b.update(at, dt, GRAVITY)
			var flop := arched(at)
			b.angle = lerpf(b.angle, 90.0 if flop else 20.0, clampf(dt * 14.0, 0.0, 1.0))
			if _cross_t < 0.0 and px < 0.0 and b.x >= 0.0:
				# its middle is over the bar: how low is it, upright and arched?
				_cross_t = at
				_low_up = b.y
				_low_arched = b.y + MIDDLE - ARCH_LOW
			# the hips are still over the bar a moment after the middle passes,
			# so an arch just after the crossing still counts
			if not _decided and _cross_t >= 0.0 and (flop or at >= _cross_t + LATE_ARCH):
				_decided = true
				var arched_over := arched_at >= 0.0 and arched_at <= _cross_t + LATE_ARCH \
					and arched_at + ARCH_FOR >= _cross_t
				var low := _low_arched if arched_over else _low_up
				cleared = low >= bar
				knocked = not cleared
				log.append({"kind": "clear" if cleared else "knock", "low": low})
				if knocked:
					b.mood = "ouch"
			var ground := MAT_H if b.x > MAT_FROM else 0.0
			if not _decided and b.y <= ground and b.vy < 0.0:
				# came down before the bar
				_decided = true
				knocked = true
				log.append({"kind": "knock", "low": 0.0})
			if b.y <= ground and b.vy < 0.0:
				b.y = ground
				b.floor_y = ground
				b.state = "down"
				b.vx *= 0.3
				b.angle = 90.0
				state = "landed"
				_landed_at = at
				b.mood = "joy" if cleared else "sad"
				log.append({"kind": "mat", "cleared": cleared})
		"landed":
			b.update(at, dt)
			if at - _landed_at > 1.3:
				state = "done"


func finished() -> bool:
	return state == "done"
