class_name Jump
extends RefCounted
## One attempt at the long jump or the hop, skip and jump.
##
## The hot dog bounces up the runway on the beat; a player's speed comes from
## tapping the two RUN buttons in turn (the computer's from bouncing on the beat). The board's front edge is at
## x = 0: taking off past it is a foul. In the long jump, holding JUMP as it
## lands plants it, squashed, while the aim comes up 45 degrees a beat; letting
## go launches it. In the hop, skip and jump, a tap of JUMP on a landing is a
## hop (a big bounce), the next a skip, and then the hold and launch.
##
## A player takes off the Track & Field way (game/aim.gd): JUMP (or HOP) as
## close to the board as they can, the moment they press it. The mark is
## measured from the board, so an early take-off loses distance, and past the
## board is a foul (not at ages 5-7: there it's measured from the take-off).
## Holding JUMP, a needle climbs: let go in the green. The computer takes off
## near the board too, and lets go at its own angle.

const BASE_SLOT := 1.0 / 2.9     ## the bounce length hops are measured against

var id := "long_jump"
var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var driver: Rival
var go := 0.0
var phases: Array = ["jump"]
var phase_i := 0                 ## which phase the next action starts
var take_off := 0.0              ## where the first phase left the ground
var foul := ""                   ## why it doesn't count ("" if it does)
var mark := 0.0
var state := "set"               ## set, run, air, landed, done
var log: Array = []
var t := 0.0
var gravity := 13.0
var pit_from := 1.0              ## sand begins this far past the board
var cpu_angle := 45.0            ## where the computer means to let go
var _phase_slot := -1            ## the landing the last hop/skip touched down on
var _landed_at := 0.0
var band := "gentle"             ## a player's age band: how the aim goes (game/aim.gd)
var aim_target := 43.0           ## the best angle to let go at
var aim_green := 7.0             ## either side of it is the green
var _cpu_x := -0.3               ## where the computer takes off
const IDEAL := -0.15             ## the best take-off: just short of the board


func setup(p_id: String, p_beat: Beat, entrant: Dictionary, p_level: String, now: float, seed := 1) -> void:
	id = p_id
	info = Catalog.event(id)
	beat = p_beat
	level = p_level
	phases = info.get("phases", ["jump"])
	gravity = float(info.get("gravity", 13.0))
	pit_from = 1.0 if phases.size() == 1 else 9.0
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = bool(entrant.get("cpu", false))
	b.skill = float(entrant.get("skill", 0.8))
	b.bash = not b.cpu                 # players run up on two RUN buttons, at every age
	band = String(entrant.get("band", "gentle"))
	aim_green = Aim.green(band)
	if not b.cpu:
		b.aim_speed = Aim.speed(band)
	b.windows = Catalog.windows(level)
	if level == "easy":
		b.forgive()
	b.x = -float(info.get("run_up", 34.0))
	b.action_mode = _mode()
	b.listeners.append(_heard)
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	if b.cpu:
		driver = Rival.new(b, b.skill, seed)
		driver.think = _cpu_think
		cpu_angle = 45.0 + driver.rng.randfn(0.0, lerpf(9.0, 2.0, b.skill))
		# it takes off near the board; now and then a little over it
		_cpu_x = IDEAL - absf(driver.rng.randfn(0.0, lerpf(0.9, 0.15, b.skill)))
		if driver.rng.randf() < lerpf(0.12, 0.02, b.skill):
			_cpu_x = driver.rng.randf_range(0.05, 0.4)


func _mode() -> String:
	if phase_i >= phases.size():
		return "tap"
	return "hold" if phases[phase_i] == "jump" else "big"


func press(action: bool, at: float) -> String:
	if state == "set":
		return ""
	if state != "run":
		return ""
	if b.state == "run":
		if b.bash and not action:
			b.bash_other(at)
			return ""
		if action and phase_i == 0 and not b.cpu:
			return _take_off_now(at)
		if action and phase_i > 0 and not b.cpu:
			return _next_phase(at)
		return b.tap(at, action)
	return ""


## The triple jump's SKIP and JUMP: pressed any time in the air before the
## landing, it happens as the hot dog lands (graded by how close to the
## landing it was pressed); a moment after landing still counts.
func _next_phase(at: float) -> String:
	var since := at - b.slot_time(b.from_slot)
	if b.from_slot >= _phase_slot and since <= float(b.windows[2]) + b.grace and not b.tapped.has(b.from_slot):
		return b.tap(at, true)             # (just landed: now)
	if b.to_slot < _phase_slot or b.pending != "":
		return ""
	var early := b.slot_time(b.to_slot) - at
	var g := "perfect" if early <= 0.15 else ("good" if early <= 0.35 else "ok")
	b.queue_action(at, g)
	return g


## Take off here and now (JUMP, or the triple jump's HOP), graded by how near
## the board it was.
func _take_off_now(at: float) -> String:
	var g := Aim.line_grade(b.x - IDEAL, b.x > 0.0)
	b.take_off_now(at, g, _mode())
	return g


## The aim while JUMP is held, for the dial: the angle now, where it starts and
## stops, and the green.
func aim(at: float) -> Dictionary:
	return {"angle": b.hold_angle(at), "start": 0.0, "top": 88.0, "lo": aim_target - aim_green,
		"hi": aim_target + aim_green}


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


## Letting go of JUMP during the hold launches the hot dog.
func release(at: float) -> void:
	if b.state != "hold" or state != "run":
		return
	var deg := b.hold_angle(at)
	var bonus: float = {"perfect": 0.03, "good": 0.015}.get(b.hold_grade, 0.0)
	var v := b.vx * (1.0 + bonus)
	b.launch(v, deg)
	state = "air"
	log.append({"kind": "launch", "angle": deg, "speed": v})


func update(at: float, dt: float) -> void:
	t = at
	if state == "set":
		if at >= go:
			state = "run"
			b.start(go, beat.bounce_len(), beat.beat_len())
		return
	if driver != null and b.state == "run":
		driver.update(at)
	b.update(at, dt, gravity)
	if state == "run":
		# 5-7: a hop or skip that comes down without SKIP or JUMP pressed does it anyway
		if phase_i > 0 and phase_i < phases.size() and b.state == "run" and not b.cpu and Aim.helps(band) 				and b.to_slot >= _phase_slot and b.pending == "" and at >= b.slot_time(b.to_slot) - 0.05:
			b.queue_action(at, "ok")
		# a hop or skip that lands with no action on that landing is the end of it
		if phase_i > 0 and phase_i < phases.size() and b.state == "run" and _phase_slot >= 0:
			if b.from_slot >= _phase_slot and at > b.slot_time(_phase_slot) + float(b.windows[2]) + b.grace:
				_fail("no " + String(phases[phase_i]))
		if b.state == "hold":
			var deg := b.hold_angle(at)
			if b.cpu and deg >= cpu_angle:
				release(at)
			elif not b.cpu and Aim.helps(band) and deg >= aim_target:
				release(at)                # (5-7: it lets go for them, at the best angle)
			elif deg >= 87.9:
				release(at)
		if phase_i == 0 and b.state == "run":
			if b.cpu and b.x >= _cpu_x:
				_take_off_now(at)
			elif not b.cpu and Aim.helps(band) and b.x > 0.3:
				_take_off_now(at)          # (5-7: missed the board? it goes anyway)
			elif b.x > pit_from:
				_fail("no jump")
	elif state == "air":
		b.angle = 90.0 - rad_to_deg(atan2(b.vy, maxf(b.vx, 0.01)))
		if b.y <= 0.0 and b.vy < 0.0:
			_touch_down(at)
	elif state == "landed":
		if at - _landed_at > 1.6:
			state = "done"


func _heard(e: Dictionary) -> void:
	if e.kind == "big" or e.kind == "hold":
		_phase_begins(e.kind)


func _phase_begins(kind: String) -> void:
	if state != "run" or phase_i >= phases.size():
		return
	if phase_i == 0:
		take_off = float(b.landed_x.get(b.from_slot, b.x))
		if take_off > 0.0 and not (not b.cpu and Aim.helps(band)):
			foul = "foul"
			log.append({"kind": "foul", "x": take_off})
	var p: String = phases[phase_i]
	log.append({"kind": p, "grade": b.tapped.get(b.from_slot, "ok")})
	if p != "jump":
		# a hop or skip: some speed is spent, none comes back
		var keep: Dictionary = info.get("hop_keep", {})
		b.vx *= float(keep.get(String(b.tapped.get(b.from_slot, "ok")), 0.8))
		b.steady = true
		b.stride_scale = BASE_SLOT / beat.bounce_len()
		_phase_slot = b.to_slot
	phase_i += 1
	b.action_mode = _mode()


func _fail(why: String) -> void:
	if foul == "":
		foul = why
	log.append({"kind": "foul", "why": why})
	b.state = "down"
	b.mood = "dizzy"
	state = "landed"
	_landed_at = t


func _touch_down(at: float) -> void:
	b.y = 0.0
	b.state = "down"
	b.vx *= 0.35
	# measured from the board (from the take-off, if it was past the board and let off)
	mark = maxf(0.0, b.x - maxf(take_off, 0.0))
	state = "landed"
	_landed_at = at
	var good := foul == "" and mark >= float(info.get("qualify", {}).get(level, 0.0))
	b.mood = "joy" if good else ("sad" if foul != "" else "happy")
	b.angle = 70.0
	log.append({"kind": "land", "mark": mark, "foul": foul})


## Is the landing on `slot` the one to hop, skip or plant on? (The assist
## shows it; the computer goes by it.)
func wants_action(slot: int) -> bool:
	if phase_i >= phases.size() or state != "run":
		return false
	if phase_i > 0:
		return slot >= _phase_slot
	var here := b.predict_x(b.slot_time(slot))
	var next := b.predict_x(b.slot_time(slot + 1))
	return here <= -0.05 and next > -0.05


## The computer's choice at each landing: hop, skip or plant?
func _cpu_think(r: Rival, slot: int) -> bool:
	if phase_i >= phases.size():
		return false
	if phase_i > 0:
		# after a hop the next landing is always the skip, then the jump
		return slot >= _phase_slot
	return false                       # (it takes off at its spot by the board: update())


func finished() -> bool:
	return state == "done"


func result() -> float:
	return -1.0 if foul != "" else mark
