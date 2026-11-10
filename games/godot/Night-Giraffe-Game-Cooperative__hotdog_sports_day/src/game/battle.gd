class_name Battle
extends RefCounted
## Breaking: a dance battle, call and response, to the beat.
##
## Three rounds. In each, the MC (a hot dog in headphones) throws down a
## pattern over two bars: moves on the beat and between beats, each a BOUNCE
## move (toprock) or a JUMP move (a spin on its head). Then it's your two bars:
## dance the same pattern back. Every move on time and on the right button
## scores; a wrong button scores a little; a move missed scores nothing; extra
## taps lose a little. The patterns get busier round by round. Everyone in the
## competition dances to the same patterns, so the scores compare.

const ROUNDS := 3
const STEPS := 16                ## eighth notes in two bars
const POINTS := {"perfect": 10, "good": 7, "ok": 4, "wrong": 2, "miss": 0}

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer                   ## the dancer (bouncing on the spot; it carries the face and the moves)
var cpu := false
var skill := 0.8
var rng := RandomNumberGenerator.new()
var go := 0.0
var state := "set"               ## set, call, answer, done
var round_i := 0
var patterns: Array = []         ## per round: [{step, action}]
var notes: Array = []            ## the current answer's notes: {at, action, grade}
var score := 0.0
var extras := 0
var log: Array = []
var t := 0.0
var move := ""                   ## the move being danced now (for the view): top, spin, freeze
var move_at := -10.0
var mc_move := ""
var mc_move_at := -10.0
var windows: Array = [0.05, 0.09, 0.13]
var grace := 0.0                 ## extra wait before a beat counts as missed (a phone's press may still be on its way)
var _cpu_plan: Array = []
var _done_at := 0.0


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, pattern_seed := 1, seed := 1) -> void:
	info = Catalog.event("breaking")
	beat = p_beat
	level = p_level
	windows = Catalog.windows(level)
	cpu = bool(entrant.get("cpu", false))
	skill = float(entrant.get("skill", 0.8))
	rng.seed = seed * 17 + 5
	b = Bouncer.new()
	b.name = String(entrant.get("name", "?"))
	b.cpu = cpu
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	patterns = make_patterns(pattern_seed)


## Three patterns, busier each round, from a seed (so a whole competition
## dances the same ones).
static func make_patterns(seed: int) -> Array:
	var r := RandomNumberGenerator.new()
	r.seed = seed * 101 + 7
	var out: Array = []
	var sizes := [5, 7, 9]
	for round_ in ROUNDS:
		var steps: Array = []
		# round one keeps to the beats; later rounds use the off-beats too
		var pool: Array = []
		for s in STEPS:
			if round_ == 0 and s % 2 == 1:
				continue
			pool.append(s)
		# a stable mix of the steps, the same for everyone with this seed
		pool.sort_custom(func(a, c): return ((a * 37 + seed * 13 + round_ * 7) % 23) < ((c * 37 + seed * 13 + round_ * 7) % 23))
		for k in mini(sizes[round_], pool.size()):
			steps.append(pool[k])
		steps.sort()
		var notes_: Array = []
		for s in steps:
			notes_.append({"step": s, "action": r.randf() < (0.25 + 0.12 * round_)})
		# always start on the one
		if notes_.is_empty() or int(notes_[0].step) != 0:
			notes_.push_front({"step": 0, "action": false})
		out.append(notes_)
	return out


func step_len() -> float:
	return beat.beat_len() / 2.0


## When round r's call (or answer) begins.
func call_at(r: int) -> float:
	return go + r * beat.bar_len() * 4.0


func answer_at(r: int) -> float:
	return call_at(r) + beat.bar_len() * 2.0


func press(action: bool, at: float) -> String:
	if state != "answer":
		return ""
	var best := -1
	var err := INF
	for i in notes.size():
		var n: Dictionary = notes[i]
		if n.grade != "":
			continue
		var e := absf(at - float(n.at))
		if e < err:
			err = e
			best = i
	if best < 0 or err > float(windows[2]):
		extras += 1
		score -= 2.0
		log.append({"kind": "extra"})
		return "fumble"
	var n: Dictionary = notes[best]
	var grade := "perfect" if err <= float(windows[0]) else ("good" if err <= float(windows[1]) else "ok")
	if bool(n.action) != action:
		grade = "wrong"
	n.grade = grade
	score += float(POINTS[grade])
	move = "spin" if action else "top"
	move_at = at
	b.mood = "happy" if grade == "perfect" else ("push" if grade != "wrong" else "ouch")
	log.append({"kind": "move", "grade": grade, "action": action})
	return grade


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= call_at(0):
				_begin_call(0)
		"call":
			_mc(at)
			if at >= answer_at(round_i):
				_begin_answer()
		"answer":
			if cpu:
				_cpu(at)
			# notes gone by untouched are misses
			for n in notes:
				if n.grade == "" and at > float(n.at) + float(windows[2]) + grace:
					n.grade = "miss"
					b.mood = "ouch"
					log.append({"kind": "move", "grade": "miss", "action": n.action})
			if at >= answer_at(round_i) + beat.bar_len() * 2.0:
				log.append({"kind": "round_end", "round": round_i})
				move = "freeze"
				move_at = at
				if round_i + 1 < ROUNDS:
					_begin_call(round_i + 1)
				else:
					state = "done"
					_done_at = at
					b.mood = "joy"
					log.append({"kind": "done", "score": score})
		"done":
			pass
	# bob on the spot to the beat
	var ph := fposmod(beat.beat_at(at), 1.0)
	b.y = 0.12 * 4.0 * ph * (1.0 - ph) if state != "done" else 0.0
	b.squash = 0.86 if ph < 0.08 else 1.0


func _begin_call(r: int) -> void:
	round_i = r
	state = "call"
	log.append({"kind": "call", "round": r})


func _begin_answer() -> void:
	state = "answer"
	notes = []
	var start := answer_at(round_i)
	for n in patterns[round_i]:
		notes.append({"at": start + int(n.step) * step_len(), "action": bool(n.action), "grade": ""})
	log.append({"kind": "answer", "round": round_i})
	if cpu:
		_cpu_plan = []
		var sigma := lerpf(0.1, 0.02, skill)
		for n in notes:
			if rng.randf() < (1.0 - skill) * 0.15:
				continue          # forgot that one
			var act: bool = n.action
			if rng.randf() < (1.0 - skill) * 0.12:
				act = not act      # the wrong move
			_cpu_plan.append({"at": float(n.at) + rng.randfn(0.0, sigma), "action": act})


## The MC's moves during the call, for the view.
func _mc(at: float) -> void:
	var start := call_at(round_i)
	for n in patterns[round_i]:
		var when := start + int(n.step) * step_len()
		if at >= when and mc_move_at < when:
			mc_move = "spin" if bool(n.action) else "top"
			mc_move_at = when
			log.append({"kind": "mc", "action": n.action})


func _cpu(at: float) -> void:
	while not _cpu_plan.is_empty() and at >= float(_cpu_plan[0].at):
		var p: Dictionary = _cpu_plan.pop_front()
		press(bool(p.action), float(p.at))


## The notes of the current round, as the view's highway draws them: during
## the call the MC's (shown as they're danced), during the answer the player's.
func highway() -> Array:
	var out: Array = []
	if state == "call" or state == "answer":
		var r := round_i
		var start := answer_at(r) if state == "answer" else call_at(r)
		for k in patterns[r].size():
			var n: Dictionary = patterns[r][k]
			var g := ""
			if state == "answer" and k < notes.size():
				g = String(notes[k].grade)
			out.append({"at": start + int(n.step) * step_len(), "action": bool(n.action), "grade": g})
	return out


func max_score() -> float:
	var n := 0
	for p in patterns:
		n += p.size()
	return n * 10.0


func finished() -> bool:
	return state == "done" and t - _done_at > 1.6
