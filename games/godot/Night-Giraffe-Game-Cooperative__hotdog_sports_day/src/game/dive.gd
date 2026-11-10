class_name Dive
extends RefCounted
## One dive off the springboard.
##
## The hot dog stands on the end of the board, high over the pool, and bounces
## on it to the beat: every tap in time puts more spring in the board. JUMP on a
## landing takes off. In the air every beat is a chance for a trick: BOUNCE on
## the beat is a somersault, JUMP on the beat a twist; a trick takes a beat.
## Through it all the hot dog turns, slowly, head first for the water: it must
## have finished its last trick before it gets there, or it goes in crooked.
##
## Five judges mark it out of ten; the top and bottom marks are dropped and the
## middle three, times the dive's difficulty, are its score.

const BOARD_H := 5.0             ## metres from the board to the water
const GRAVITY := 6.5
const MAX_BOUNCES := 16          ## bounce longer than this on the board and it's a balk

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var driver: Rival
var go := 0.0
var state := "set"               ## set, board, air, water, done
var tricks: Array = []           ## [{kind, at, grade}]
var trick_end := -1.0            ## when the current trick finishes
var turn := 0.0                  ## the slow turn toward head-first, degrees
var flips := 0.0                 ## extra degrees from somersaults
var twist := 0.0                 ## 0..1 through a twist (the view flips the sprite)
var marks: Array = []            ## the five judges
var difficulty := 1.2
var score := 0.0
var entry := 0.0                 ## how far from straight it went in, degrees
var splash := 0.0                ## 0 = a whisper, 1 = a belly flop
var log: Array = []
var t := 0.0
var rng := RandomNumberGenerator.new()
var _launch_t := 0.0
var _flight := 1.0               ## expected seconds in the air
var _water_t := 0.0
var _cpu_plan: Array = []        ## beats (after launch) the computer tricks on, and which


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, seed := 1) -> void:
	info = Catalog.event("dive")
	beat = p_beat
	level = p_level
	rng.seed = seed * 7 + 3
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = bool(entrant.get("cpu", false))
	b.skill = float(entrant.get("skill", 0.8))
	b.windows = Catalog.windows(level)
	if level == "easy":
		b.forgive()
	b.action_mode = "hold"
	b.steady = true
	b.x = 0.0
	b.y = 0.0
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	if b.cpu:
		driver = Rival.new(b, b.skill, seed)
		var bounces := 4 + driver.rng.randi_range(0, 3)
		driver.think = func(_r: Rival, slot: int) -> bool: return slot >= bounces


## Height above the water of the hot dog's bottom.
func height() -> float:
	return BOARD_H + b.y


func press(action: bool, at: float) -> String:
	if state == "board" and b.state == "run":
		var g := b.tap(at, action)
		return g
	if state == "air":
		return _trick("twist" if action else "flip", at)
	return ""


func _trick(kind: String, at: float) -> String:
	if at < trick_end - 0.05:
		log.append({"kind": "sloppy"})
		tricks.append({"kind": "sloppy", "at": at, "grade": "fumble"})
		return "fumble"
	var k := roundf((at - _launch_t) / beat.beat_len())
	var err := at - (_launch_t + k * beat.beat_len())
	var e := absf(err)
	var w: Array = b.windows
	var grade := "perfect" if e <= float(w[0]) else ("good" if e <= float(w[1]) else ("ok" if e <= float(w[2]) else "off"))
	tricks.append({"kind": kind, "at": at, "grade": grade})
	trick_end = at + beat.beat_len()
	log.append({"kind": kind, "grade": grade})
	b.mood = "push"
	return grade


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= go:
				state = "board"
				b.start(go, beat.bounce_len(), beat.beat_len())
				b.vx = 0.0
		"board":
			if driver != null and b.state == "run":
				driver.update(at)
			# the board gives more as the spring builds
			b.arc = lerpf(b.low_arc, b.high_arc, b.spring) if b.to_slot - b.from_slot == 1 else b.arc
			b.update(at, dt)
			b.x = 0.0
			if b.state == "run" and b.to_slot == MAX_BOUNCES - 4 and not _hurried:
				_hurried = true
				log.append({"kind": "hurry"})
			if b.state == "run" and b.to_slot > MAX_BOUNCES:
				_balk(at)
				return
			if b.state == "hold":
				_take_off(at)
		"air":
			b.update(at, dt, GRAVITY)
			if b.cpu:
				_cpu_tricks(at)
			var into := clampf((at - _launch_t) / _flight, 0.0, 1.0)
			turn = 180.0 * smoothstep(0.0, 1.0, into)
			flips = 0.0
			twist = 0.0
			for tr in tricks:
				var p := clampf((at - float(tr.at)) / beat.beat_len(), 0.0, 1.0)
				if tr.kind == "flip":
					flips += 360.0 * smoothstep(0.0, 1.0, p)
				elif tr.kind == "twist" and p > 0.0 and p < 1.0:
					twist = p
			b.angle = turn + flips
			if height() <= 0.0:
				_enter(at)
		"water":
			if at - _water_t > 2.2:
				state = "done"


func _take_off(at: float) -> void:
	var bonus: float = {"perfect": 0.04, "good": 0.02}.get(b.hold_grade, 0.0)
	var vy := (3.0 + 5.2 * b.spring) * (1.0 + bonus)
	b.state = "air"
	b.vx = 0.9
	b.vy = vy
	b.mood = "fly"
	state = "air"
	_launch_t = at
	var rise := vy * vy / (2.0 * GRAVITY)
	_flight = vy / GRAVITY + sqrt(2.0 * (BOARD_H + rise) / GRAVITY)
	log.append({"kind": "take_off", "flight": _flight, "beats": _flight / beat.beat_len()})
	if b.cpu:
		_plan_cpu()


func _plan_cpu() -> void:
	var beats := int(floor(_flight / beat.beat_len() - 0.6))
	_cpu_plan = []
	var r := driver.rng
	for k in range(1, beats):
		if r.randf() < 0.35 + b.skill * 0.5:
			var at := _launch_t + k * beat.beat_len() + r.randfn(0.0, driver.sigma)
			_cpu_plan.append({"at": at, "kind": "flip" if r.randf() < 0.65 else "twist"})


func _cpu_tricks(at: float) -> void:
	while not _cpu_plan.is_empty() and at >= float(_cpu_plan[0].at):
		var p: Dictionary = _cpu_plan.pop_front()
		_trick(String(p.kind), float(p.at))


func _enter(at: float) -> void:
	state = "water"
	_water_t = at
	b.y = -BOARD_H
	b.vy = 0.0
	b.state = "down"
	var still_tricking := at < trick_end
	var a := fposmod(b.angle, 360.0)
	entry = absf(a - 180.0)
	if still_tricking:
		entry = maxf(entry, 70.0)
	splash = clampf(entry / 90.0, 0.0, 1.0)
	_judge()
	b.mood = "joy" if score >= float(info.get("qualify", {}).get(level, 0.0)) else "happy"
	log.append({"kind": "splash", "size": splash, "score": score})


func _judge() -> void:
	var flips_n := 0
	var twists_n := 0
	var deduct := 0.0
	for tr in tricks:
		match String(tr.grade):
			"perfect":
				pass
			"good":
				deduct += 0.3
			"ok":
				deduct += 0.7
			"off":
				deduct += 1.2
			"fumble":
				deduct += 1.5
		if tr.kind == "flip":
			flips_n += 1
		elif tr.kind == "twist":
			twists_n += 1
	difficulty = 1.2 + 0.5 * flips_n + 0.4 * twists_n
	deduct += entry / 12.0
	if b.hold_grade == "ok":
		deduct += 0.5
	if tricks.is_empty():
		deduct += 1.0             # a plain dive is pretty, not clever
	marks = []
	for j in 5:
		var m := clampf(10.0 - deduct + rng.randfn(0.0, 0.35), 0.0, 10.0)
		marks.append(roundf(m * 2.0) / 2.0)
	var sorted := marks.duplicate()
	sorted.sort()
	score = (float(sorted[1]) + float(sorted[2]) + float(sorted[3])) * difficulty


var _hurried := false


## Too long on the board: a balk. The hot dog topples in, and the judges give
## it nothing.
func _balk(at: float) -> void:
	log.append({"kind": "foul", "why": "balk"})
	state = "water"
	_water_t = at
	b.y = -BOARD_H
	b.vy = 0.0
	b.state = "down"
	b.mood = "ouch"
	entry = 90.0
	splash = 1.0
	marks = [0.0, 0.0, 0.0, 0.0, 0.0]
	score = 0.0
	log.append({"kind": "splash", "size": splash, "score": score})


func finished() -> bool:
	return state == "done"
