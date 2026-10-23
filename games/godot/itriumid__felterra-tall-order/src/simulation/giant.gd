class_name Giant
extends RefCounted
## A human at real scale: a logging worker, five or six times a cat's height. Slow, heavy, and
## dangerous underfoot. He walks at the nearest cat and stomps; felled, he topples like the tall
## body he is and crushes what he lands on.
##
## The chainsaw worker is the elite: tougher, slower, in ear defenders, and instead of stomping
## he revs his saw (its arc marked on the ground, the warning) and sweeps it at a cat's height
## across the ground in front of him, cutting whatever is there, his own horde included.

enum State { WALKING, WINDING, FALLING, FALLEN, REVVING, SWEEPING }

## Each kind: its health, its walking speed, and the experience felling it is worth.
const KINDS := {
	"worker": {"health": 60.0, "speed": 1.1, "worth": 15},
	"chainsaw": {"health": 90.0, "speed": 0.9, "worth": 30},
	# The handler: the deep forest's boss. He keeps his distance and whistles his dogs in.
	"handler": {"health": 150.0, "speed": 1.0, "worth": 40},
}
## The handler: how far off he keeps, how often he whistles, and how many dogs come to it.
const HANDLER_DISTANCE := 5.0
const WHISTLE_INTERVAL := 9.0
const WHISTLE_PACK := 3
## The chainsaw's sweep: how far it reaches, how high off the ground it cuts (his shins: a cat
## leaping clears it), the arc it cuts, the rev before it (the warning), how long the cut takes,
## how often he can, and what it does to a cat.
const SAW_REACH := 1.5
const SAW_HEIGHT := 0.35
const SAW_ARC := deg_to_rad(140.0)
const REV_TIME := 0.6
const SWEEP_TIME := 0.35
const SAW_INTERVAL := 2.6
const SAW_DAMAGE := 4.0
const SAW_KNOCK := 2.6

const TALL := 1.75
const RADIUS := 0.25
## Against a rat's one: a round that throws a rat barely moves him.
const HEFT := 40.0
const SPEED := 1.1
const MOST_HEALTH := 60.0
## The stomp: he goes for it within this reach, raises the boot for WIND_TIME (its shadow on the
## ground is the warning), and slams it down.
const STOMP_REACH := 0.9
const WIND_TIME := 0.55
const STOMP_INTERVAL := 2.2
const BOOT_HEIGHT := 0.35
## Under the boot is crushed; the shockwave around it throws and stings.
const CRUSH_RADIUS := 0.3
const SHOCK_RADIUS := 1.3
const CRUSH_DAMAGE := 3.0
const SHOCK_DAMAGE := 1.0
const SHOCK_KNOCK := 2.2
## Falling, he crushes a strip this wide along his length.
const FALLEN_WIDTH := 0.35
const FALL_DAMAGE := 4.0
const WORTH := 15

var kind := "worker"
var body := Body.new()
var health := MOST_HEALTH
var most_health := MOST_HEALTH
var speed := SPEED
var worth := WORTH
## The chainsaw: the angle the sweep is centered on, where the saw is pointing in it, and the
## time left revving or sweeping.
var sweep_center := 0.0
var saw_angle := 0.0
var saw_for := 0.0
var state := State.WALKING
var facing := Vector2.RIGHT
var stomp_ready_in := 1.0
var wind_for := 0.0
## Where the raised boot will come down, and how high it is.
var foot := Vector2.ZERO
var foot_height := 0.0
## The fall: the angle from upright, how fast it's growing, and which way along the ground.
var fall_angle := 0.0
var fall_speed := 0.0
var fall_direction := Vector2.RIGHT
var fallen_for := 0.0
var _last_knock := Vector2.RIGHT
## Poison and fire on him, as {dps, left, by}: he takes them as the horde does.
var afflictions := {}
## Caught by the foot in a snare: he can't walk off, though he can still stomp, for this long.
var snared_for := 0.0
var whistle_in := 3.0
## Where he walks when there's no cat to go after, or nowhere (INF).
var wander_to := Vector2.INF


func _init(giant_kind := "worker") -> void:
	kind = giant_kind
	most_health = KINDS[kind].health
	health = most_health
	speed = KINDS[kind].speed
	worth = KINDS[kind].worth
	body.radius = RADIUS
	body.tall = TALL
	body.kind = kind


func alive() -> bool:
	return health > 0.0


func standing() -> bool:
	return state in [State.WALKING, State.WINDING, State.REVVING, State.SWEEPING]


func has_chainsaw() -> bool:
	return kind == "chainsaw"


## Hurt by a hit; the direction it came from decides which way he falls.
func take(damage: float, direction: Vector2) -> void:
	if not alive():
		return
	health -= damage
	_last_knock = direction
	if not alive():
		state = State.FALLING
		fall_direction = direction.normalized() if direction.length_squared() > 0.0 else facing
		# A nudge off true: a body balanced dead upright never starts to fall.
		fall_angle = 0.05


func step(delta: float, arena: Arena) -> void:
	match state:
		State.WALKING: _walk(delta, arena)
		State.WINDING: _wind(delta, arena)
		State.REVVING: _rev(delta, arena)
		State.SWEEPING: _sweep(delta, arena)
		State.FALLING: _fall(delta, arena)
		State.FALLEN: fallen_for += delta
	if snared_for > 0.0:
		snared_for = maxf(snared_for - delta, 0.0)
		body.velocity = Vector2.ZERO
	if standing():
		body.step(delta)


func _walk(delta: float, arena: Arena) -> void:
	stomp_ready_in = maxf(stomp_ready_in - delta, 0.0)
	var prey := arena.nearest_cat(body.position)
	if prey == null:
		var toward_wander := (wander_to - body.position) if wander_to.is_finite() else Vector2.ZERO
		body.velocity = toward_wander.limit_length(1.0) * speed * 0.6
		if toward_wander.length_squared() > 0.01:
			facing = toward_wander.normalized()
		return
	var toward := prey.body.position - body.position
	facing = toward.normalized()
	if kind == "handler":
		_handle(delta, toward, arena)
		return
	if has_chainsaw():
		if toward.length() <= SAW_REACH * 0.85 and stomp_ready_in <= 0.0:
			# He commits to the way he is now; the rev is his warning to be elsewhere.
			state = State.REVVING
			saw_for = REV_TIME
			sweep_center = facing.angle()
			saw_angle = sweep_center - SAW_ARC * 0.5
			body.velocity = Vector2.ZERO
			arena.events.append({"position": body.position, "height": 0.9, "direction": facing, "killed": false, "by": "rev", "giant": true, "kind": kind})
			return
		body.velocity = facing * speed if toward.length() > SAW_REACH * 0.6 else Vector2.ZERO
		return
	if toward.length() <= STOMP_REACH and stomp_ready_in <= 0.0:
		state = State.WINDING
		wind_for = WIND_TIME
		# He stomps where he is now: he has the wind-up to get out from under it.
		foot = prey.body.position
		body.velocity = Vector2.ZERO
		return
	body.velocity = facing * speed if toward.length() > STOMP_REACH * 0.6 else Vector2.ZERO


## The handler keeps off at his distance, backing away if he comes close, and whistles a pack in.
func _handle(delta: float, toward: Vector2, arena: Arena) -> void:
	var gap := toward.length() - HANDLER_DISTANCE
	body.velocity = toward.normalized() * speed * clampf(gap, -1.0, 1.0)
	whistle_in -= delta
	if whistle_in <= 0.0:
		whistle_in = WHISTLE_INTERVAL
		arena.events.append({"position": body.position, "height": 1.5, "direction": facing, "killed": false, "by": "whistle", "giant": true, "kind": kind})
		for index in WHISTLE_PACK:
			arena.add_creature(body.position + facing.rotated((index - 1) * 0.8) * 0.8, "dog")


func _rev(delta: float, arena: Arena) -> void:
	saw_for = maxf(saw_for - delta, 0.0)
	if saw_for <= 0.0:
		state = State.SWEEPING
		saw_for = SWEEP_TIME
		arena.events.append({"position": body.position, "height": 0.3, "direction": facing, "killed": false, "by": "cut", "giant": true, "kind": kind})


## The saw sweeps across its arc; each step, what it passed through is cut.
func _sweep(delta: float, arena: Arena) -> void:
	var before := saw_angle
	saw_for = maxf(saw_for - delta, 0.0)
	saw_angle = sweep_center - SAW_ARC * 0.5 + SAW_ARC * (1.0 - saw_for / SWEEP_TIME)
	arena.saw(self, before, saw_angle)
	if saw_for <= 0.0:
		state = State.WALKING
		stomp_ready_in = SAW_INTERVAL


func _wind(delta: float, arena: Arena) -> void:
	wind_for = maxf(wind_for - delta, 0.0)
	var done := 1.0 - wind_for / WIND_TIME
	# Up for most of it, then down hard.
	foot_height = BOOT_HEIGHT * (sin(done * PI * 0.5 / 0.8) if done < 0.8 else (1.0 - done) / 0.2)
	if wind_for <= 0.0:
		foot_height = 0.0
		state = State.WALKING
		stomp_ready_in = STOMP_INTERVAL
		arena.stomp(self, foot)


## A tall body toppling about its feet: for a rod pivoting at one end, the angle accelerates by
## (3g / 2L) · sin(angle). When it reaches the ground, it lands along its length.
func _fall(delta: float, arena: Arena) -> void:
	fall_speed += 1.5 * Body.GRAVITY / TALL * sin(fall_angle) * delta
	fall_angle += fall_speed * delta
	if fall_angle >= PI * 0.5:
		fall_angle = PI * 0.5
		state = State.FALLEN
		arena.land(self)
