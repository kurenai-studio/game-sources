class_name Throw
extends RefCounted
## One attempt at the meatball put.
##
## A hot dog has no arms, so it puts the meatball with its head. It stands in
## the circle with the meatball balanced on top and bounces on the spot: a
## player taps RUN, RUN to spin up the spring (the computer bounces on the
## beat). Holding THROW crouches it there and then, while a needle climbs from
## 20 degrees (game/aim.gd); letting go springs it up and heads the meatball
## away. The mark is where the meatball
## first lands, measured from the front of the circle.

const RELEASE_H := 1.9           ## the meatball leaves from this high
const GRAVITY := 9.8
const CIRCLE := 1.07             ## the circle's radius: the hot dog stands at -CIRCLE
const MAX_BOUNCES := 16          ## bounce longer than this in the circle and it's a foul

var info: Dictionary = {}
var beat: Beat
var level := "junior"
var b: Bouncer
var driver: Rival
var go := 0.0
var state := "set"               ## set, run, flight, landed, done
var mark := 0.0
var foul := ""
var ball := Vector2.ZERO         ## the meatball: x along the field, y up (metres)
var ball_v := Vector2.ZERO
var ball_spin := 0.0
var log: Array = []
var t := 0.0
var cpu_angle := 40.0
var cpu_bounces := 5
var _landed_at := 0.0
var band := "gentle"             ## a player's age band: how the aim goes (game/aim.gd)
var aim_target := 40.0
var aim_green := 7.0


func setup(p_beat: Beat, entrant: Dictionary, p_level: String, now: float, seed := 1) -> void:
	info = Catalog.event("meatball_put")
	beat = p_beat
	level = p_level
	b = Bouncer.new()
	b.setup(info.get("tuning", {}))
	b.name = String(entrant.get("name", "?"))
	b.cpu = bool(entrant.get("cpu", false))
	b.skill = float(entrant.get("skill", 0.8))
	b.bash = not b.cpu                 # players spin up on two RUN buttons
	band = String(entrant.get("band", "gentle"))
	aim_green = Aim.green(band)
	if not b.cpu:
		b.aim_speed = Aim.speed(band)
	b.windows = Catalog.windows(level)
	if level == "easy":
		b.forgive()
	b.action_mode = "hold"
	b.steady = true
	b.x = -CIRCLE
	go = beat.next_bar(now + 0.4) + beat.bar_len()
	if b.cpu:
		driver = Rival.new(b, b.skill, seed)
		cpu_bounces = 5 + driver.rng.randi_range(0, 3)
		driver.think = func(_r: Rival, slot: int) -> bool: return slot >= cpu_bounces
		cpu_angle = 40.0 + driver.rng.randfn(0.0, lerpf(8.0, 1.5, b.skill))


func press(action: bool, at: float) -> String:
	if state == "run" and b.state == "run":
		if b.bash and not action:
			b.bash_other(at)
			return ""
		if action and not b.cpu:
			# crouch there and then: the spring built so far is what it has
			var g := "perfect" if b.spring >= 0.95 else ("good" if b.spring >= 0.8 else "ok")
			b.take_off_now(at, g, "hold")
			return g
		return b.tap(at, action)
	return ""


## A RUN button: before the throw, spinning up; otherwise BOUNCE.
func run(side: int, at: float) -> String:
	if run_up():
		b.bash_tap(at, side)
		return ""
	return press(false, at)


## Whether RUN taps are building the spring now.
func run_up() -> bool:
	return b.bash and (state == "set" or (state == "run" and b.state == "run"))


## The aim while THROW is held, for the dial.
func aim(at: float) -> Dictionary:
	return {"angle": b.hold_angle(at, 30.0, 20.0, 80.0), "start": 20.0, "top": 80.0, "lo": aim_target - aim_green,
		"hi": aim_target + aim_green}


func release(at: float) -> void:
	if state != "run" or b.state != "hold":
		return
	var deg := b.hold_angle(at, 30.0, 20.0, 80.0)
	var bonus: float = {"perfect": 0.04, "good": 0.02}.get(b.hold_grade, 0.0)
	var v := (7.0 + 7.0 * b.spring) * (1.0 + bonus)
	ball = Vector2(b.x + 0.2, RELEASE_H)
	ball_v = Vector2(cos(deg_to_rad(deg)), sin(deg_to_rad(deg))) * v
	# the hot dog springs up after it, and comes down in the circle
	b.state = "air"
	b.vx = 0.4
	b.vy = 3.2
	b.mood = "fly"
	state = "flight"
	log.append({"kind": "put", "angle": deg, "speed": v})


func update(at: float, dt: float) -> void:
	t = at
	match state:
		"set":
			if at >= go:
				state = "run"
				b.start(go, beat.bounce_len(), beat.beat_len())
				b.vx = 0.0
		"run":
			if driver != null and b.state == "run":
				driver.update(at)
			b.arc = lerpf(0.25, 0.55, b.spring) if b.to_slot - b.from_slot == 1 else b.arc
			b.update(at, dt)
			b.x = -CIRCLE
			if b.state == "run" and b.to_slot == MAX_BOUNCES - 4 and not _hurried:
				_hurried = true
				log.append({"kind": "hurry"})
			if b.state == "run" and not b.cpu and Aim.helps(band) and b.to_slot > MAX_BOUNCES - 2:
				press(true, at)            # (5-7: out of time? it throws anyway)
			if b.state == "run" and b.to_slot > MAX_BOUNCES:
				_time_up(at)
				return
			if b.state == "hold":
				var deg := b.hold_angle(at, 30.0, 20.0, 80.0)
				if (b.cpu and deg >= cpu_angle) or deg >= 79.9:
					release(at)
				elif not b.cpu and Aim.helps(band) and deg >= aim_target:
					release(at)            # (5-7: it lets go for them, at the best angle)
		"flight", "landed":
			if b.state == "air":
				b.update(at, dt, GRAVITY)
				if b.y <= 0.0 and b.vy < 0.0:
					b.y = 0.0
					b.state = "down"
					b.vx = 0.0
					if b.x > 0.0:
						foul = "out of the circle"
						log.append({"kind": "foul", "why": foul})
			if state == "flight":
				ball_v.y -= GRAVITY * dt
				ball += ball_v * dt
				ball_spin += dt * 720.0
				if ball.y <= 0.0:
					ball.y = 0.0
					mark = maxf(0.0, ball.x)
					state = "landed"
					_landed_at = at
					ball_v = Vector2(ball_v.x * 0.15, 0.0)
					var good := mark >= float(info.get("qualify", {}).get(level, 0.0))
					b.mood = "joy" if good else "happy"
					log.append({"kind": "thud", "mark": mark})
			else:
				ball.x += ball_v.x * dt
				ball_v.x = move_toward(ball_v.x, 0.0, 6.0 * dt)
				if at - _landed_at > 1.6:
					state = "done"


var _hurried := false


## Out of time in the circle: a foul, and the meatball rolls off its head.
func _time_up(at: float) -> void:
	foul = "time"
	log.append({"kind": "foul", "why": foul})
	b.state = "down"
	b.mood = "ouch"
	ball = Vector2(b.x + 0.3, 0.0)
	ball_v = Vector2(0.6, 0.0)
	state = "landed"
	_landed_at = at


func finished() -> bool:
	return state == "done"


func result() -> float:
	return -1.0 if foul != "" else mark
