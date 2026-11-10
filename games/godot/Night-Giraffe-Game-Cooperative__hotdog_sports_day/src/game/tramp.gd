class_name Tramp
extends RefCounted
## One trampoline routine.
##
## A bounce on the trampoline takes two beats: the hot dog lands on one beat,
## is at the top of its flight on the next, and lands again on the one after.
## So the rhythm is steady and alternating: tap BOUNCE as you land (that keeps
## the height coming, like every other event), and on the beat at the top you
## may do a trick: BOUNCE for a somersault, JUMP for a twist. A trick takes the
## beat from the top down to the bed, so a late one lands crooked.
##
## Three warm-up bounces build height, then eight skills, then press JUMP as
## you land to stick it. Judges mark difficulty (the tricks), execution (how
## well every landing and trick was timed) and flight (how high).

const WARMUP := 3
const SKILLS := 8
const GRADE_VALUE := {"perfect": 1.0, "good": 0.8, "ok": 0.6, "off": 0.25}

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var driver: Rival
var go := 0.0
var state := "set"               ## set, warmup, routine, stick, done
var skills: Array = []           ## per skill: {kind, grade} (kind "plain" if no trick)
var trick_at := -1.0             ## when the current trick began
var trick_kind := ""
var flips := 0.0                 ## the body's turn from somersaults, degrees
var twist := 0.0
var stuck := ""                  ## the stick landing's grade
var heights: Array = []
var difficulty := 0.0
var execution := 10.0
var flight := 0.0
var score := 0.0
var marks: Array = []            ## five judges' execution cards, for show
var log: Array = []
var t := 0.0
var rng := RandomNumberGenerator.new()
var _deduct := 0.0
var _skill_slot := -1            ## the landing the current skill left from
var _done_at := 0.0


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, seed := 1) -> void:
	info = Catalog.event("trampoline")
	beat = p_beat
	level = p_level
	rng.seed = seed * 13 + 1
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = bool(entrant.get("cpu", false))
	b.skill = float(entrant.get("skill", 0.8))
	b.windows = Catalog.windows(level)
	if level == "easy":
		b.forgive()
	b.action_mode = "tap"
	b.steady = true
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	if b.cpu:
		driver = Rival.new(b, b.skill, seed)
		driver.think = func(_r: Rival, slot: int) -> bool: return slot == WARMUP + SKILLS + 1
		driver.tapper = func(when: float, action: bool) -> void: press(action, when)


## Which landing slot the routine is on (0 = the go).
func landings() -> int:
	return b.from_slot


func top_time() -> float:
	return b.slot_time(b.from_slot) + beat.beat_len()


func press(action: bool, at: float) -> String:
	if b.state != "run" or state == "set" or state == "done":
		return ""
	# nearer the top of the bounce than a landing? then it's a trick
	var top := top_time()
	var land := b.slot_time(b.to_slot) if absf(at - b.slot_time(b.to_slot)) < absf(at - b.slot_time(b.from_slot)) \
		else b.slot_time(b.from_slot)
	if absf(at - top) < absf(at - land):
		return _trick(action, at, top)
	var k: int = b.to_slot if absf(at - b.slot_time(b.to_slot)) < absf(at - b.slot_time(b.from_slot)) else b.from_slot
	var g := b.tap(at, false)
	if action and k == WARMUP + SKILLS + 1 and g != "fumble" and g != "":
		_stick(g)
	return g


func _trick(action: bool, at: float, top: float) -> String:
	if state != "routine" or trick_at >= 0.0 and trick_at > b.slot_time(b.from_slot):
		_deduct += 0.4
		log.append({"kind": "sloppy"})
		return "fumble"
	var e := absf(at - top)
	var w: Array = b.windows
	var grade := "perfect" if e <= float(w[0]) else ("good" if e <= float(w[1]) else ("ok" if e <= float(w[2]) else "off"))
	trick_at = at
	trick_kind = "twist" if action else "flip"
	log.append({"kind": trick_kind, "grade": grade})
	if skills.size() > 0:
		skills[-1] = {"kind": trick_kind, "grade": grade}
	b.mood = "push"
	return grade


func _stick(grade: String) -> void:
	stuck = grade
	state = "done"
	_done_at = t
	b.state = "down"
	b.y = 0.0
	b.mood = "joy"
	_judge()
	log.append({"kind": "stick", "grade": grade, "score": score})


func update(at: float, dt: float) -> void:
	t = at
	if state == "set":
		if at >= go:
			state = "warmup"
			b.start(go, beat.beat_len() * 2.0, beat.beat_len())
			b.vx = 0.0
		return
	if state == "done":
		b.update(at, dt)
		return
	if driver != null and b.state == "run":
		driver.update(at)
		_cpu_trick(at)
	var was := b.from_slot
	b.arc = lerpf(1.2, 4.6, b.spring)
	b.update(at, dt)
	b.x = 0.0
	if b.from_slot != was:
		_landed(at)
	# the body's turn through a trick: a full turn from the top down to the bed
	flips = 0.0
	twist = 0.0
	if trick_at >= 0.0:
		var p := clampf((at - trick_at) / beat.beat_len(), 0.0, 1.0)
		if trick_kind == "flip":
			flips = 360.0 * smoothstep(0.0, 1.0, p)
		elif p < 1.0:
			twist = p
	b.angle = flips if flips < 359.0 else 0.0


func _landed(at: float) -> void:
	var n := b.from_slot
	# a trick still turning as the hot dog lands is a crooked landing
	if trick_at >= 0.0 and at - trick_at < beat.beat_len() * 0.9:
		_deduct += 0.6
		log.append({"kind": "crooked"})
	trick_at = -1.0
	trick_kind = ""
	if n <= WARMUP:
		state = "warmup"
	elif n <= WARMUP + SKILLS:
		state = "routine"
		heights.append(lerpf(1.2, 4.6, b.spring))
		skills.append({"kind": "plain", "grade": ""})
		_skill_slot = n
	else:
		if state != "stick":
			state = "stick"
			log.append({"kind": "stick_now"})
		elif n > WARMUP + SKILLS + 1:
			# never stuck it: the routine ends anyway
			state = "done"
			_done_at = at
			b.state = "down"
			b.y = 0.0
			_judge()
			log.append({"kind": "stick", "grade": "", "score": score})


func _judge() -> void:
	difficulty = 0.0
	for s in skills:
		match String(s.kind):
			"flip":
				difficulty += 0.6 * float(GRADE_VALUE.get(s.grade, 0.25))
			"twist":
				difficulty += 0.5 * float(GRADE_VALUE.get(s.grade, 0.25))
	execution = 10.0 - _deduct
	for g in b.tapped.values():
		execution -= {"perfect": 0.0, "good": 0.1, "ok": 0.25}.get(g, 0.4)
	execution -= 0.5 * b.counts.miss + 0.3 * b.counts.fumble
	if stuck == "perfect":
		execution += 0.5
	execution = clampf(execution, 0.0, 10.0)
	var avg := 0.0
	for h in heights:
		avg += float(h)
	avg = avg / maxf(1.0, heights.size())
	flight = clampf((avg - 1.2) / 3.4 * 10.0, 0.0, 10.0)
	score = snappedf(difficulty * 4.0 + execution * 2.0 + flight * 1.0, 0.05)
	marks = []
	for j in 5:
		marks.append(clampf(roundf((execution + rng.randfn(0.0, 0.3)) * 2.0) / 2.0, 0.0, 10.0))


func _cpu_trick(at: float) -> void:
	if state != "routine" or trick_at > b.slot_time(b.from_slot):
		return
	var top := top_time()
	var key := b.from_slot
	if _planned.has(key):
		var when := float(_planned[key])
		if when >= 0.0 and at >= when:
			var action: bool = _planned_kind[key]
			_planned[key] = -1.0
			press(action, when)
		return
	if driver.rng.randf() < 0.45 + 0.5 * b.skill:
		_planned[key] = top + clampf(driver.rng.randfn(0.0, driver.sigma), -0.15, 0.15)
		_planned_kind[key] = driver.rng.randf() < 0.4
	else:
		_planned[key] = -1.0


var _planned := {}
var _planned_kind := {}


func finished() -> bool:
	return state == "done" and t - _done_at > 1.6
