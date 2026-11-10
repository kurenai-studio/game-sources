class_name Controls
extends RefCounted
## What each player's buttons do right now, said on the buttons, and which one
## to press next (it lights up). The event screen asks every frame; the pad
## draws it, and the phones and joined tablets are told when it changes.
##
## A button's word is what it does: RUN, then JUMP, HOP, SKIP or ARCH in the
## jumps; FLIP and TWIST in the air; HIGH and LOW in the bobsleigh; TUCK,
## STEADY and LAND on the ski jump; ROCK and SPIN in breaking; PUSH, OLLIE,
## GRIND and LAND on the skateboard. Words stay short (six letters at most)
## so they fit four players' buttons.
##
## of() returns {"b": the BOUNCE (or RUN) buttons' word, "j": the JUMP
## button's, "lit": BOUNCE (the RUN buttons, when running), JUMP or NONE}.

const NONE := -1
const BOUNCE := 0
const JUMP := 1
const SOON := 0.22                   ## seconds before a beat to light its button
const SLOW := 2.5                    ## RUN taps a second below which the RUN buttons light up


static func of(es: Node, h: int, t: float) -> Dictionary:
	var out := {"b": "RUN" if es.bashing() else "BOUNCE", "j": "JUMP", "lit": NONE}
	if es.meet == null:
		return out
	if es.meet.kind == "race" and es.race != null:
		return _race(es, h, t, out)
	if es.attempt == null or es.turn != h:
		return out
	var a: Variant = es.attempt
	var cue := _cue(es, h)
	match String(es.meet.kind):
		"jump":
			return _jump(a, t, cue, out)
		"high":
			return _high(a, t, cue, out)
		"throw":
			out.j = "THROW"
			if a.b.state == "hold":
				out.j = _aim_word(cue)
				out.lit = JUMP
			elif _cue_lit(cue):
				out.lit = JUMP
			elif a.run_up() and _run_lit(a.b, t):
				out.lit = BOUNCE
			return out
		"dive":
			return _dive(es, a, t, cue, out)
		"bob":
			return _bob(a, t, cue, out)
		"skijump":
			return _ski(es, a, t, cue, out)
		"tramp":
			return _tramp(a, t, out)
		"battle":
			return _battle(a, t, out)
		"skate":
			return _skate(a, t, out)
	return out


## This player's JUMP cue on screen: {} or the circle ({k, now}) or the hold ({hold}).
static func _cue(es: Node, h: int) -> Dictionary:
	for c in es.fx.cues:
		if int(c.get("h", -1)) == h:
			return c
	return {}


## While aiming: HOLD below the green, GO! in it (and the button lit either way).
static func _aim_word(cue: Dictionary) -> String:
	if not cue.has("aim"):
		return "HOLD"
	return "GO!" if float(cue.aim.angle) >= float(cue.aim.lo) else "HOLD"


static func _cue_lit(cue: Dictionary) -> bool:
	return cue.has("hold") or float(cue.get("k", 0.0)) > 0.45


## The RUN buttons light up while a runner is slow (or not going yet).
static func _run_lit(b: Bouncer, t: float) -> bool:
	return b.bash_rate(t) < SLOW


## Is a landing (a beat to tap BOUNCE on) just about to come?
static func _landing_soon(b: Bouncer, t: float) -> bool:
	if b.state != "run":
		return false
	var left := b.slot_time(b.to_slot) - t
	return left >= -0.05 and left <= SOON


static func _race(es: Node, h: int, t: float, out: Dictionary) -> Dictionary:
	var r: Race = es.race
	var b: Bouncer = r.athletes[h]
	out.b = es.pad.run_word if es.pad else "RUN"
	if r.legs > 1:
		out.j = "TAG"
	elif r.breath > 0:
		out.j = "AIR"
	if r.times.has(h) or b.coasting:
		return out
	var cue := _cue(es, h)
	if _cue_lit(cue):
		out.lit = JUMP
	elif b.state == "run" and _run_lit(b, t):
		out.lit = BOUNCE
	return out


static func _jump(a: Jump, t: float, cue: Dictionary, out: Dictionary) -> Dictionary:
	if a.phase_i < a.phases.size():
		out.j = {"hop": "HOP", "skip": "SKIP"}.get(String(a.phases[a.phase_i]), "JUMP")
	if a.b.state == "hold":
		out.j = _aim_word(cue)
		out.lit = JUMP
		return out
	if _cue_lit(cue):
		out.lit = JUMP
	elif a.run_up() and _run_lit(a.b, t):
		out.lit = BOUNCE
	return out


static func _high(a: High, t: float, cue: Dictionary, out: Dictionary) -> Dictionary:
	if a.b.state == "hold":
		out.j = _aim_word(cue)
		out.lit = JUMP
	elif a.state == "air":
		out.j = "ARCH"
		if a.arched_at < 0.0 and t >= a.apex_time - 0.3:
			out.lit = JUMP
	elif _cue_lit(cue):
		out.lit = JUMP
	elif a.run_up() and _run_lit(a.b, t):
		out.lit = BOUNCE
	return out


## Bounce on the beat to build spring, then JUMP when the circle closes.
static func _bounce_then(b: Bouncer, t: float, cue: Dictionary, out: Dictionary, going: bool) -> Dictionary:
	if b.state == "hold":
		out.j = "HOLD"
		out.lit = JUMP
	elif _cue_lit(cue):
		out.lit = JUMP
	elif going and _landing_soon(b, t):
		out.lit = BOUNCE
	return out


static func _dive(es: Node, a: Dive, t: float, cue: Dictionary, out: Dictionary) -> Dictionary:
	if a.state == "air":
		out.b = "FLIP"
		out.j = "TWIST"
		# room for a trick before the water? then light FLIP for the next beat
		var beat_len: float = a.beat.beat_len()
		var next := a.beat.time_of_beat(int(ceil(a.beat.beat_at(t))))
		var water: float = a._launch_t + a._flight
		if t >= a.trick_end and next - t <= SOON and next + beat_len < water - 0.05:
			out.lit = BOUNCE
		return out
	return _bounce_then(a.b, t, cue, out, a.state == "board")


static func _bob(a: Bob, t: float, cue: Dictionary, out: Dictionary) -> Dictionary:
	if a.state == "push" or a.state == "set":
		out.j = "HOP"
		if _cue_lit(cue):
			out.lit = JUMP
		elif a.run_up() and _run_lit(a.b, t):
			out.lit = BOUNCE
		return out
	out.b = "LOW"
	out.j = "HIGH"
	for bd in a.bends:
		if bd.grade != "":
			continue
		var left: float = a.bend_time(bd) - t
		if left < -0.15:
			continue
		if left <= 0.45:
			out.lit = JUMP if bool(bd.high) else BOUNCE
		break
	return out


static func _ski(es: Node, a: SkiJump, t: float, cue: Dictionary, out: Dictionary) -> Dictionary:
	var on_beat := _beat_soon(a.beat, t)
	if a.state == "inrun" or a.state == "set":
		out.b = "TUCK"
		if _cue_lit(cue):
			out.lit = JUMP
		elif a.state == "inrun" and on_beat:
			out.lit = BOUNCE
		return out
	if a.state == "flight":
		out.b = "STEADY"
		out.j = "LAND"
		var above: float = a.y - SkiJump.hill(a.x)
		if a.vy < 0.0 and above / maxf(-a.vy, 0.1) < 0.45:
			out.lit = JUMP
		elif on_beat:
			out.lit = BOUNCE
	return out


static func _beat_soon(beat: Beat, t: float) -> bool:
	var next := beat.time_of_beat(int(ceil(beat.beat_at(t))))
	return next - t <= SOON


static func _tramp(a: Tramp, t: float, out: Dictionary) -> Dictionary:
	if a.state == "set" or a.state == "done" or a.b.state != "run":
		return out
	var land: float = a.b.slot_time(a.b.to_slot)
	var top: float = a.top_time()
	var stick: bool = a.b.to_slot == Tramp.WARMUP + Tramp.SKILLS + 1
	if a.state == "routine" and top > t - 0.1 and top < land:
		# the top of the bounce comes next: a trick
		out.b = "FLIP"
		out.j = "TWIST"
		return out
	out.j = "STICK" if stick else "TWIST"
	if land - t <= SOON:
		out.lit = JUMP if stick else BOUNCE
	return out


static func _battle(a: Battle, t: float, out: Dictionary) -> Dictionary:
	out.b = "ROCK"
	out.j = "SPIN"
	if a.state != "answer":
		return out
	for n in a.notes:
		if n.grade != "":
			continue
		var left: float = float(n.at) - t
		if left < -0.12:
			continue
		if left <= 0.3:
			out.lit = JUMP if bool(n.action) else BOUNCE
		break
	return out


static func _skate(a: Skate, t: float, out: Dictionary) -> Dictionary:
	out.b = "PUSH"
	out.j = "OLLIE"
	if a.state != "ride":
		return out
	var n := roundf(a.now_beat(t) + 0.5)          # the next beat
	var left: float = a.beat_time(n) - t
	var f := a._feature
	if a.pose == "grind":
		out.j = "GRIND"
		out.lit = JUMP
		return out
	if not f.is_empty() and f.kind == "ramp":
		if int(n) == int(f.at) + 1:
			out.b = "FLIP"
			out.j = "SPIN"
			return out
		if int(n) == int(f.at) + 2:
			out.b = "LAND"
			if left <= SOON:
				out.lit = BOUNCE
			return out
	var start := a.feature_at(n)
	if not start.is_empty() and int(start.at) == int(n):
		out.j = "GRIND" if start.kind == "rail" else "OLLIE"
		if left <= SOON + 0.1:
			out.lit = JUMP
		return out
	if left <= SOON and not a._judged.has(int(n)):
		out.lit = BOUNCE
	return out
