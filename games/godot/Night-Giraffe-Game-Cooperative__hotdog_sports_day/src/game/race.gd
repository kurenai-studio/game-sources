class_name Race
extends RefCounted
## A race down the straight, every lane at once: the 100m Bounce; the 110m
## Hurdles; the Steeplechase (barriers that don't fall over, and a water jump);
## and the Relay (four of a nation's hot dogs, one after another).
##
## The start is on the music: "on your marks" for a bar, "set" for a bar with
## the beats counted, and the gun on the next downbeat. A tap before the gun is
## a false start: that hot dog wobbles and leaves two bounces late.
##
## Hurdles fall when clipped and cost some spring. Steeplechase barriers stand
## firm: clip one and the hot dog clambers over, losing most of its speed.
## Landing in the water jump is a splash and a slower getaway.
##
## In the relay each lane's hot dog runs a leg, then must tag the next one by
## pressing JUMP on a landing inside the changeover box (the yellow lines). A
## tag on the beat hands over all the spring; running through the box without
## tagging is a fumbled changeover.

var id := "sprint"
var info: Dictionary = {}
var beat: Beat
var level := "junior"
var athletes: Array[Bouncer] = []
var drivers: Array = []          ## a Rival, or null for a player's athlete
var go := 0.0
var finish := 100.0
var times := {}                  ## athlete index -> seconds from the gun to the line
var false_starts := {}           ## athlete index -> true
var hurdles: Array = []          ## per lane: [{x, down, passed}]
var hurdle_h := 0.84
var barriers := false            ## steeplechase: they don't fall
var water: Array = []            ## [{x, len}] water pits
var legs := 1                    ## relay: hot dogs per team
var leg_len := 0.0
var leg: Array = []              ## relay: which leg each lane is on (0..legs-1)
var breath := 0                  ## swim: breathe (JUMP) on this beat of every bar (0: never)
var breathed: Array = []         ## swim: per lane, landing slot -> true when JUMP was pressed on it
var _breath_checked: Array = []  ## swim: per lane, the last breath slot judged
var log: Array = []              ## what happened, for the view
var t := 0.0
var _prev_x: Array = []
var _prev_y: Array = []


func setup(p_id: String, p_beat: Beat, entrants: Array, p_level: String, now: float, seed := 1) -> void:
	id = p_id
	info = Catalog.event(id)
	beat = p_beat
	level = p_level
	finish = float(info.get("distance", 100.0))
	go = beat.next_bar(now + 0.5) + beat.bar_len() * 2.0
	var tuning: Dictionary = info.get("tuning", {})
	var hs: Dictionary = info.get("hurdles", {})
	hurdle_h = float(hs.get("height", 0.84))
	barriers = bool(hs.get("barrier", false))
	water = info.get("water", [])
	legs = int(info.get("legs", 1))
	breath = int(info.get("breath", 0))
	leg_len = finish / legs
	var spots: Array = hs.get("at", [])
	if spots.is_empty() and not hs.is_empty():
		for h in int(hs.count):
			spots.append(float(hs.first) + h * float(hs.gap))
	for i in entrants.size():
		var e: Dictionary = entrants[i]
		var b := Bouncer.new()
		b.setup(tuning)
		b.name = String(e.get("name", "?"))
		b.lane = int(e.get("lane", i))
		b.cpu = bool(e.get("cpu", false))
		b.skill = float(e.get("skill", 0.8))
		b.windows = Catalog.windows(level)
		if level == "easy":
			b.forgive()
		b.bash = not b.cpu              # players bash two RUN buttons, at every age
		b.boost = float(e.get("boost", 0.0))
		b.action_mode = "big" if not hs.is_empty() else "tap"
		if legs > 1:
			b.action_mode = "none"     # JUMP is the tag, handled here
		athletes.append(b)
		_prev_x.append(0.0)
		_prev_y.append(0.0)
		leg.append(0)
		breathed.append({})
		_breath_checked.append(-1)
		var lane_h: Array = []
		for x in spots:
			lane_h.append({"x": float(x), "down": false})
		hurdles.append(lane_h)
		if b.cpu:
			var r := Rival.new(b, b.skill, seed * 31 + i)
			if not hs.is_empty():
				r.think = _cpu_hurdle.bind(i)
			elif legs > 1:
				r.think = _cpu_tag.bind(i)
				r.tapper = func(when: float, action: bool) -> void: press(i, action, when)
			elif breath > 0:
				r.think = func(_r: Rival, slot: int) -> bool: return is_breath(slot)
				r.tapper = func(when: float, action: bool) -> void: press(i, action, when)
			drivers.append(r)
		else:
			drivers.append(null)


func phase(at := -1.0) -> String:
	if at < 0.0:
		at = t
	if at < go - beat.bar_len() * 2.0:
		return "intro"
	if at < go - beat.bar_len():
		return "marks"
	if at < go:
		return "set"
	return "run"


## The beat of the count-in, 1-4, during "set" (0 otherwise).
func count(at: float) -> int:
	if phase(at) != "set":
		return 0
	return int(floor((at - (go - beat.bar_len())) / beat.beat_len())) + 1


## A RUN button in a button-bash race (EASY): no false starts, no beat to
## keep; just both buttons in turn, fast.
func run(i: int, side: int, at: float) -> void:
	var b := athletes[i]
	if b.state == "wait" or times.has(i):
		return
	b.bash_tap(at, side)


func press(i: int, action: bool, at: float) -> String:
	var b := athletes[i]
	if b.bash and not action:
		# a BOUNCE where RUN is expected (an older phone page): count it as the other button
		run(i, 1 - b._bash_side if b._bash_side >= 0 else 0, at)
		return ""
	if b.bash and b.state == "wait":
		return ""                      # no false starts when bashing
	if b.state == "wait":
		var p := phase(at)
		if (p == "set" or p == "marks") and at < go - float(b.windows[2]):
			if not false_starts.has(i):
				false_starts[i] = true
				b.mood = "dizzy"
				log.append({"kind": "false_start", "who": i})
			return "false"
		if at >= go - float(b.windows[2]):
			# a tap just before the gun counts toward the start
			_start(i)
		else:
			return ""
	if legs > 1 and action:
		return _tag(i, at)
	if breath > 0:
		var g := b.tap(at, false)
		if action and g != "fumble" and g != "":
			var k: int = b.from_slot if absf(at - b.slot_time(b.from_slot)) < absf(at - b.slot_time(b.to_slot)) else b.to_slot
			breathed[i][k] = true
			if is_breath(k):
				log.append({"kind": "breath", "who": i})
		return g
	return b.tap(at, action)


## Swim: is the landing on `slot` a breath (beat `breath` of its bar)?
func is_breath(slot: int) -> bool:
	if breath <= 0:
		return false
	var per_bar := beat.sub * beat.beats_per_bar
	return slot > 0 and slot % per_bar == beat.sub * (breath - 1)


func _check_breath(i: int) -> void:
	var b := athletes[i]
	if b.state != "run" or b.coasting:
		return
	var k := b.from_slot
	if k <= _breath_checked[i] or not is_breath(k):
		return
	if t <= b.slot_time(k) + float(b.windows[2]) + b.grace:
		return
	_breath_checked[i] = k
	if not breathed[i].has(k):
		# no breath: a mouthful of pool
		b.spring = clampf(b.spring * 0.72, 0.0, 1.0)
		b.streak = 0
		b.mood = "ouch"
		log.append({"kind": "gulp", "who": i})


func _start(i: int) -> void:
	var b := athletes[i]
	if b.state != "wait":
		return
	var late := 2.0 if false_starts.has(i) else 0.0
	b.start(go + late * beat.bounce_len(), beat.bounce_len(), beat.beat_len())


# -- the relay -----------------------------------------------------------------------

## Where lane i's next changeover is (metres), or -1 on the last leg.
func exchange(i: int) -> float:
	if leg[i] >= legs - 1:
		return -1.0
	return leg_len * (leg[i] + 1)


const BOX_BEFORE := 4.5          ## the changeover box starts this far before the line
const BOX_AFTER := 1.5           ## and ends this far after it


func in_box(i: int, x: float) -> bool:
	var ex := exchange(i)
	return ex > 0.0 and x >= ex - BOX_BEFORE and x <= ex + BOX_AFTER


## JUMP in the relay: a tag, if a landing in the box is near.
func _tag(i: int, at: float) -> String:
	var b := athletes[i]
	var g := b.tap(at, false)
	if g == "fumble" or g == "":
		return g
	var k: int = b.from_slot if absf(at - b.slot_time(b.from_slot)) < absf(at - b.slot_time(b.to_slot)) else b.to_slot
	var x := float(b.landed_x.get(k, b.predict_x(b.slot_time(k))))
	if not in_box(i, x):
		return g
	_hand_over(i, g)
	return g


func _hand_over(i: int, grade: String) -> void:
	var b := athletes[i]
	var keep: float = {"perfect": 1.0, "good": 0.92, "ok": 0.8, "fumble": 0.35}.get(grade, 0.35)
	b.spring *= keep
	b.vx *= lerpf(0.6, 1.0, keep)
	leg[i] += 1
	b.mood = "happy" if keep > 0.9 else "push"
	if grade == "fumble":
		b.mood = "dizzy"
	log.append({"kind": "tag", "who": i, "leg": leg[i], "grade": grade, "x": b.x})


func _cpu_tag(r: Rival, slot: int, i: int) -> bool:
	var b := athletes[i]
	var x_here := b.predict_x(b.slot_time(slot))
	var x_next := b.predict_x(b.slot_time(slot + 1))
	var ok := in_box(i, x_here) and (not in_box(i, x_next) or x_next > exchange(i))
	if r.rng.randf() < (1.0 - b.skill) * 0.3:
		return in_box(i, x_here)
	return ok


# -- each frame ------------------------------------------------------------------------

func update(at: float, dt: float) -> void:
	t = at
	if at >= go:
		for i in athletes.size():
			if athletes[i].state == "wait":
				_start(i)
	for i in athletes.size():
		var d: Variant = drivers[i]
		if d != null and not times.has(i):
			(d as Rival).update(at)
	for i in athletes.size():
		var b := athletes[i]
		_prev_x[i] = b.x
		_prev_y[i] = b.y
		b.update(at, dt)
		_check_hurdles(i)
		_check_water(i)
		if breath > 0:
			_check_breath(i)
		if legs > 1 and exchange(i) > 0.0 and b.x > exchange(i) + BOX_AFTER and b.state == "run":
			# ran through the box without a tag: a fumbled changeover
			log.append({"kind": "missed_tag", "who": i})
			_hand_over(i, "fumble")
		if b.state == "run" and not times.has(i) and b.x >= finish:
			var over := (b.x - finish) / maxf(b.vx, 0.1)
			times[i] = at - over - go
			b.mood = "joy"
			b.coasting = true
			b.v_max = 3.0
			b.v_min = 1.0
			b.spring = 0.0
			log.append({"kind": "finish", "who": i, "time": times[i], "place": times.size()})
		if times.has(i) and b.state == "run" and b.vx < 1.5:
			b.state = "done"


func _check_hurdles(i: int) -> void:
	var b := athletes[i]
	for h in hurdles[i]:
		if h.down or h.get("passed", false):
			continue
		var hx: float = h.x
		if _prev_x[i] < hx and b.x >= hx:
			h["passed"] = true
			if b.y < hurdle_h:
				b.streak = 0
				b.mood = "ouch"
				if barriers:
					# it doesn't fall: up and over it, slowly
					b.spring = clampf(b.spring * 0.45, 0.0, 1.0)
					b.vx *= 0.4
					log.append({"kind": "barrier_hit", "who": i, "x": hx})
				else:
					h["down"] = true
					b.spring = clampf(b.spring - 0.2, 0.0, 1.0)
					b.vx *= 0.8
					log.append({"kind": "hurdle_hit", "who": i, "x": hx})
			else:
				log.append({"kind": "hurdle_clear", "who": i, "x": hx})


func _check_water(i: int) -> void:
	var b := athletes[i]
	for w in water:
		var x0 := float(w.x)
		var x1 := x0 + float(w.len)
		# coming down into the pit
		if _prev_y[i] > 0.05 and b.y <= 0.05 and b.x >= x0 and b.x <= x1:
			b.spring = clampf(b.spring * 0.7, 0.0, 1.0)
			b.vx *= 0.75
			b.mood = "ouch"
			log.append({"kind": "splash", "who": i, "x": b.x})


## The next hurdle in an athlete's lane that it hasn't reached.
func next_hurdle(i: int) -> float:
	for h in hurdles[i]:
		if not h.get("passed", false) and float(h.x) > athletes[i].x:
			return float(h.x)
	return -1.0


## Where a big bounce from the landing on `slot` would carry the next
## hurdle: 0 = at take-off, 1 = at touch-down. -1 if there's no hurdle.
func hurdle_u(i: int, slot: int) -> float:
	var b := athletes[i]
	var hx := next_hurdle(i)
	if hx < 0.0:
		return -1.0
	var x0 := b.predict_x(b.slot_time(slot))
	var x1 := b.predict_x(b.slot_time(slot + 2))
	return (hx - x0) / maxf(x1 - x0, 0.01)


## Is the landing on `slot` the one to big-bounce from to clear the next
## hurdle? (The big bounce should carry the hurdle near its middle; over a
## water jump, a little early, so it lands beyond the water.)
func good_take_off(i: int, slot: int) -> bool:
	var u := hurdle_u(i, slot)
	if u < 0.0:
		return false
	if u <= 0.2 or u >= 0.8:
		return false
	var u_next := hurdle_u(i, slot + 1)
	if u_next <= 0.2 or u_next >= 0.8:
		return true                # the next landing would be too late (or too early)
	var aim := 0.5
	var hx := next_hurdle(i)
	for w in water:
		if absf(float(w.x) - hx) < 1.0:
			aim = 0.35
	return absf(u - aim) <= absf(u_next - aim)


## Should the relay hot dog in lane i tag on the landing at `slot`? (the helper ring)
func good_tag(i: int, slot: int) -> bool:
	var b := athletes[i]
	if exchange(i) < 0.0:
		return false
	var x_here := b.predict_x(b.slot_time(slot))
	var x_next := b.predict_x(b.slot_time(slot + 1))
	return in_box(i, x_here) and (not in_box(i, x_next) or x_next > exchange(i))


func _cpu_hurdle(r: Rival, slot: int, i: int) -> bool:
	var ok := good_take_off(i, slot)
	if r.rng.randf() < (1.0 - r.b.skill) * 0.25:
		return not ok and r.rng.randf() < 0.5
	return ok


func finished() -> bool:
	return times.size() >= athletes.size() or (t > go + finish * 0.25 + 20.0)


## Athlete indexes, fastest first (anyone who didn't finish last).
func standings() -> Array:
	var idx: Array = range(athletes.size())
	idx.sort_custom(func(a, b): return float(times.get(a, 999.0)) < float(times.get(b, 999.0)))
	return idx
