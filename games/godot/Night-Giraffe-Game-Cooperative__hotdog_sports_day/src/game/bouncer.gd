class_name Bouncer
extends RefCounted
## One hot dog in one attempt: where it is, how springy it is, and its
## bounces on the beat.
##
## A hot dog has no legs; it bounces. Every bounce leaves the ground on a
## bounce slot and lands on a later one (one slot for a bounce, two for a big
## bounce), so every landing is on the beat. A tap close to a landing is
## judged by how close: perfect, good or ok, and each builds spring; spring is
## speed. A landing with no tap is a miss (spring drains), and a tap with no
## landing near it, or a second tap on the same landing, is a fumble. So
## mashing never helps: rhythm does.
##
## The action button does what the event says (`action_mode`): "big" turns
## the next bounce into a big one (a hurdle, a hop, a skip), "hold" plants the
## hot dog on its landing to squash and aim, "tap" counts as a bounce, and
## "none" ignores it. The event turns a hold into a flight with launch().
##
## Times are song times (see Beat); distances are metres; heights are metres
## above the ground to the bottom of the bun.

const GRADES := ["perfect", "good", "ok"]

var name := ""
var lane := 0
var cpu := false
var skill := 0.8

var x := 0.0
var y := 0.0
var vx := 0.0
var vy := 0.0
var spring := 0.0
var streak := 0
var best_streak := 0
var counts := {"perfect": 0, "good": 0, "ok": 0, "miss": 0, "fumble": 0}
var state := "wait"            ## wait, run, hold, air, down, done
var angle := 0.0               ## body turn in degrees: 0 upright, 90 lying forward
var spin := 0.0                ## extra turn the event adds (flips, tumbles)
var squash := 1.0              ## the view's squash and stretch, 1 = neutral
var mood := "ready"            ## for the face: ready, happy, push, ouch, dizzy, joy, sad, fly
var events: Array = []         ## what happened since the view last looked
var listeners: Array[Callable] = []  ## called with each happening as it happens (the event, the view)

# the bounce chain
var origin := 0.0              ## song time of slot 0 (the go)
var slot_len := 0.333
var beat_len := 0.666
var from_slot := 0             ## the slot this bounce left the ground at
var to_slot := 1               ## the slot it lands on
var arc := 0.5                 ## this bounce's height
var tapped := {}               ## landing slot -> grade
var missed := {}               ## landing slot -> true
var landed_x := {}             ## landing slot -> where it landed
var pending := ""              ## the action asked for at the next landing
var action_mode := "tap"       ## big, hold, tap, none
var hold_from := 0.0           ## when the hold began
var hold_grade := ""           ## how well the hold was timed
var windows: Array = [0.05, 0.09, 0.125]
var grace := 0.0                 ## extra wait before a beat counts as missed (a phone's press may still be on its way)
var t := 0.0                   ## the last song time update() saw

# tuning (data/events.json sets these per event)
var v_min := 2.4
var v_max := 10.4
var accel := 7.0
var brake := 12.0
## Each judged landing pulls spring part of the way toward the level its
## grade earns, so spring always tells how well the last few went.
var levels := {"perfect": 1.0, "good": 0.74, "ok": 0.45, "miss": 0.12, "fumble": 0.05}
var pull := 0.22
var curve := 1.4               ## speed = spring ^ curve: the last bit of speed is for perfect taps
var low_arc := 0.62            ## bounce height when slow
var high_arc := 0.42           ## bounce height at full spring (skims, so it looks fast)
var big_arc := 1.4
var sizzle_at := 8             ## perfects in a row to start sizzling
var sizzle_bonus := 0.05
var frozen := false            ## the event has stopped this one moving
var coasting := false          ## past the line: bouncing on, nothing judged
var floor_y := 0.0             ## what it rests on once down (a mat is higher than the track)
var stride_scale := 1.0        ## stretches ground covered per second (keeps hops fair at any tempo)
var steady := false            ## the event sets the speed; taps only build spring
## Button bash (every player's run-ups): spring comes from how fast two RUN
## buttons are tapped in turn, not from the beat. The hot dog still bounces on
## the beat; nothing is judged but JUMP.
var bash := false
const BASH_FULL := 4.0         ## taps a second, in turn, for full spring
const BASH_CURVE := 0.45       ## below that, generous: three a second is most of the way
const BASH_WINDOW := 1.5       ## seconds of tapping the rate is taken over
const BASH_SIZZLE := 5.5       ## taps a second that set it sizzling (a little faster still)
const BASH_EASE := 1.6         ## how quickly spring follows the tapping (per second)
var _bash_taps: Array[float] = []
var overdrive := 0.0           ## bashing past flat out: a little more speed, up to BASH_TOP
const BASH_TOP := 0.16         ## the most, at BASH_FULL + BASH_OVER taps a second
const BASH_OVER := 4.0
var boost := 0.0               ## the computer's extra speed in a race at the older age bands
## A player's aim climbs this many degrees a second while the action button is
## held (game/aim.gd); 0: so many degrees a beat (the computer).
var aim_speed := 0.0
var _bash_side := -1


## EASY: an ok tap still builds a fair spring, and a miss or a wobble costs
## less, so a young player's near-misses still get them down the track.
func forgive() -> void:
	levels = {"perfect": 1.0, "good": 0.86, "ok": 0.68, "miss": 0.32, "fumble": 0.28}


func setup(tuning: Dictionary) -> void:
	for k in tuning:
		if k in self:
			set(k, tuning[k])


func slot_time(k: int) -> float:
	return origin + k * slot_len


func sizzling() -> bool:
	return streak >= sizzle_at


func target_speed() -> float:
	var v := v_min + (v_max - v_min) * pow(clampf(spring, 0.0, 1.0), curve)
	if bash:
		v *= 1.0 + overdrive
	elif sizzling():
		v *= 1.0 + sizzle_bonus
	v *= 1.0 + boost
	return v


## Off the line at song time `go`, bouncing every `p_slot_len` seconds.
func start(go: float, p_slot_len: float, p_beat_len: float) -> void:
	origin = go
	slot_len = p_slot_len
	beat_len = p_beat_len
	state = "run"
	from_slot = 0
	to_slot = 1
	arc = _arc()
	landed_x[0] = x
	mood = "push"
	_emit("go")


func _arc() -> float:
	return lerpf(low_arc, high_arc, clampf(spring, 0.0, 1.0))


## A tap of a RUN button (side 0 or 1). The same button twice in a row
## doesn't count: it's both in turn that runs. Taps while waiting to start
## count toward the rate (a field event's run-up starts on the bar line).
func bash_tap(at: float, side: int) -> void:
	if (state != "run" and state != "wait") or coasting:
		return
	if side == _bash_side:
		return
	_bash_side = side
	_bash_taps.append(at)
	mood = "push"
	_emit("bash", {"side": side})


## A BOUNCE press where RUN is wanted (an older phone page): the other RUN button.
func bash_other(at: float) -> void:
	bash_tap(at, 1 - _bash_side if _bash_side >= 0 else 0)


## Taps a second (in turn), over the last moment or so.
func bash_rate(at: float) -> float:
	while not _bash_taps.is_empty() and _bash_taps[0] < at - BASH_WINDOW:
		_bash_taps.pop_front()
	return float(_bash_taps.size()) / BASH_WINDOW


## The spring a rate of tapping earns.
static func bash_spring(rate: float) -> float:
	return pow(clampf(rate / BASH_FULL, 0.0, 1.0), BASH_CURVE)


## A press of the bounce button (action=false) or the action button.
## Returns the grade, or "fumble", or "" if it didn't count for anything.
func tap(at: float, action := false) -> String:
	if state != "run":
		return ""
	if action and action_mode == "none":
		return ""
	if action and action_mode == "tap":
		action = false
	var k := from_slot
	if absf(at - slot_time(to_slot)) < absf(at - slot_time(from_slot)):
		k = to_slot
	var err := at - slot_time(k)
	var grade := _grade(err)
	if grade == "" or tapped.has(k) or missed.has(k):
		_fumble(at)
		return "fumble"
	tapped[k] = grade
	_score(grade, err, k)
	if action:
		if k == to_slot:
			pending = action_mode
		else:
			_act_now(k, at)
	return grade


func _grade(err: float) -> String:
	var e := absf(err)
	for i in 3:
		if e <= float(windows[i]):
			return GRADES[i]
	return ""


func _score(grade: String, err: float, k: int) -> void:
	counts[grade] += 1
	_pull(grade)
	if grade == "perfect":
		streak += 1
		best_streak = maxi(best_streak, streak)
		if streak == sizzle_at:
			_emit("sizzle")
	else:
		if streak >= sizzle_at:
			_emit("cool")
		streak = 0
	mood = "happy" if grade == "perfect" else "push"
	_emit("grade", {"grade": grade, "err": err, "slot": k})


func _pull(grade: String) -> void:
	spring = clampf(lerpf(spring, float(levels[grade]), pull), 0.0, 1.0)


func _fumble(at: float) -> void:
	counts["fumble"] += 1
	_pull("fumble")
	if streak >= sizzle_at:
		_emit("cool")
	streak = 0
	mood = "ouch"
	_emit("grade", {"grade": "fumble", "err": 0.0, "slot": -1})


## The action asked for just after landing on slot k: change this bounce.
func _act_now(k: int, at: float) -> void:
	match action_mode:
		"big":
			to_slot = from_slot + 2
			arc = big_arc
			_emit("big")
		"hold":
			_begin_hold(k, slot_time(k))


func _begin_hold(k: int, when: float) -> void:
	state = "hold"
	hold_from = when
	hold_grade = String(tapped.get(k, "ok"))
	x = float(landed_x.get(k, x))
	y = 0.0
	vy = 0.0
	mood = "push"
	_emit("hold")


## How far the aim has come up in a hold: 45 degrees a beat, so a hold
## started on a beat and let go on the next is the classic 45.
func hold_angle(at: float, per_beat := 45.0, start := 0.0, top := 88.0) -> float:
	var rate := aim_speed if aim_speed > 0.0 else per_beat / beat_len
	return clampf(start + (at - hold_from) * rate, start, top)


## An action asked for in the air, ahead of the landing (the triple jump's
## SKIP and JUMP): it happens as the hot dog lands. `grade` is how close to the
## landing it was asked for.
func queue_action(at: float, grade: String) -> void:
	if state != "run" or pending != "":
		return
	pending = action_mode
	tapped[to_slot] = grade
	counts[grade] = int(counts.get(grade, 0)) + 1
	mood = "happy" if grade == "perfect" else "push"
	_emit("grade", {"grade": grade, "err": at - slot_time(to_slot), "slot": to_slot})


## Take off right here, right now (a jump timed to its line, not to a landing):
## a new bounce starts from where it is, as a plant ("hold") or a hop ("big").
## `grade` is how well it was timed to the line.
func take_off_now(at: float, grade: String, mode: String) -> void:
	if state != "run":
		return
	from_slot = to_slot
	landed_x[from_slot] = x
	origin = at - from_slot * slot_len        # the bounces go on from here, off the beat
	tapped[from_slot] = grade
	counts[grade] = int(counts.get(grade, 0)) + 1
	mood = "happy" if grade == "perfect" else "push"
	_emit("grade", {"grade": grade, "err": 0.0, "slot": from_slot})
	y = 0.0
	if mode == "hold":
		_begin_hold(from_slot, at)
	else:
		to_slot = from_slot + 2
		arc = big_arc
		_emit("big")


## Leave the ground: speed v along angle deg (0 = flat, 90 = straight up).
func launch(v: float, deg: float) -> void:
	state = "air"
	vx = v * cos(deg_to_rad(deg))
	vy = v * sin(deg_to_rad(deg))
	mood = "fly"
	_emit("launch", {"angle": deg, "speed": v})


func update(at: float, dt: float, gravity := 13.0) -> void:
	t = at
	match state:
		"run":
			_run(at, dt)
		"hold":
			y = 0.0
			squash = lerpf(squash, 0.7, clampf(dt * 10.0, 0.0, 1.0))
		"air":
			x += vx * dt
			vy -= gravity * dt
			y += vy * dt
		"down":
			vx = move_toward(vx, 0.0, 14.0 * dt)
			x += vx * dt
			y = floor_y


func _run(at: float, dt: float) -> void:
	if at < origin:
		y = 0.0
		squash = lerpf(squash, 0.86, clampf(dt * 8.0, 0.0, 1.0))
		return
	# landings
	var guard := 0
	while at >= slot_time(to_slot) and state == "run" and guard < 8:
		guard += 1
		_land()
	if state != "run":
		return
	if bash and not coasting:
		var rate := bash_rate(at)
		spring = move_toward(spring, bash_spring(rate), dt * BASH_EASE)
		overdrive = move_toward(overdrive, clampf((rate - BASH_FULL) / BASH_OVER, 0.0, 1.0) * BASH_TOP, dt * 0.2)
		var hot := rate >= BASH_SIZZLE
		if hot and streak < sizzle_at:
			streak = sizzle_at
			_emit("sizzle")
		elif not hot and streak >= sizzle_at:
			streak = 0
			_emit("cool")
	# a landing gone by with no tap is a miss
	if not bash and at > slot_time(from_slot) + float(windows[2]) + grace and from_slot > 0 and not coasting \
			and not tapped.has(from_slot) and not missed.has(from_slot):
		missed[from_slot] = true
		counts["miss"] += 1
		_pull("miss")
		if streak >= sizzle_at:
			_emit("cool")
		streak = 0
		mood = "ouch"
		_emit("grade", {"grade": "miss", "err": 0.0, "slot": from_slot})
	# along
	if not frozen:
		if not steady:
			var want := target_speed()
			vx = move_toward(vx, want, (accel if want > vx else brake) * dt)
		x += vx * dt * stride_scale
	# up and down
	var span := (to_slot - from_slot) * slot_len
	var u := clampf((at - slot_time(from_slot)) / span, 0.0, 1.0)
	y = arc * 4.0 * u * (1.0 - u)
	# squash on the ground, stretch leaving it
	if u < 0.12:
		squash = lerpf(0.72, 1.18, u / 0.12)
	elif u > 0.9:
		squash = lerpf(1.08, 0.8, (u - 0.9) / 0.1)
	else:
		squash = lerpf(squash, 1.0 + 0.1 * (1.0 - absf(u - 0.5) * 2.0), 0.3)


func _land() -> void:
	from_slot = to_slot
	landed_x[from_slot] = x
	_emit("land", {"slot": from_slot})
	var act := pending
	pending = ""
	if act == "hold":
		_begin_hold(from_slot, slot_time(from_slot))
		return
	if act == "big":
		to_slot = from_slot + 2
		arc = big_arc
		_emit("big")
	else:
		to_slot = from_slot + 1
		arc = _arc()


## Where this hot dog will be at song time `when`, if its spring holds.
func predict_x(when: float) -> float:
	var px := x
	var pv := vx
	var want := target_speed()
	var tt := t
	while tt < when:
		var step := minf(1.0 / 60.0, when - tt)
		pv = move_toward(pv, want, (accel if want > pv else brake) * step)
		px += pv * step
		tt += step
	return px


## The slot this bouncer will land on next, and roughly where.
func next_landing() -> Dictionary:
	return {"slot": to_slot, "time": slot_time(to_slot), "x": x + vx * maxf(0.0, slot_time(to_slot) - t)}


func _emit(kind: String, data := {}) -> void:
	var e := data.duplicate()
	e["kind"] = kind
	e["who"] = self
	events.append(e)
	if events.size() > 64:
		events = events.slice(-64)
	for l in listeners:
		if l.is_valid():
			l.call(e)


func take_events() -> Array:
	var e := events
	events = []
	return e


func accuracy() -> float:
	var n: int = counts.perfect + counts.good + counts.ok + counts.miss + counts.fumble
	if n == 0:
		return 0.0
	return (counts.perfect * 1.0 + counts.good * 0.7 + counts.ok * 0.4) / n
