class_name Machine
extends RefCounted
## The company's machines, the bosses. This is the feller buncher, and what every machine shares:
## steel that shrugs off most of a hit, a weak joint that takes double when it's open, tracks or
## wheels that crush what's under them while they move, and a wreck that stays where it stopped.
## The other machines are their own scripts, each doing its work its own way (see make()).
##
## The feller buncher is a tracked machine with a long boom, whose head grabs a tree and saws it
## through in one bite.
##
## It crawls on its tracks toward the nearest cat, turning on the spot as tracked machines do,
## and whatever is under its tracks while they turn is crushed. Within reach, it swings its boom
## out over him: the head's shadow on the ground is the warning. Then the head drops and its jaws
## shut, cutting whatever is between them. After a bite the head sits on the ground a moment,
## its hydraulic joint exposed; hits there do double. Anywhere else, the steel shrugs off most of
## a hit. Broken, the engine dies and the boom comes down, and it stays where it stopped: a wreck.

enum State { DRIVING, AIMING, BITING, STUCK, RAISING, BROKEN }

## Every machine there is, by kind, in the order the forest meets them.
const KINDS: Array[String] = ["feller_buncher", "log_loader", "logging_truck", "bulldozer", "helicopter"]

## Its footprint, along its heading and across it, in meters, and how tall it stands at the cab.
const LENGTH := 3.0
const WIDTH := 2.0
const TALL := 2.0
const HEALTH := 300.0
const WORTH := 200
## Its tracks: how fast it drives, and turns on the spot, and how far off its heading he has to be
## before it stops to turn rather than drive on.
const SPEED := 0.8
const TURN_RATE := 0.6
const DRIVE_WITHIN := 0.5
## What its tracks do to a cat they run over, and how often.
const CRUSH_DAMAGE := 3.0
const CRUSH_INTERVAL := 0.6
## The boom: where it's mounted, along from the middle and up; how far it reaches, and how close it
## can bite; where the head rests, tucked in, and how high it's raised to swing.
const BOOM_ROOT := Vector2(0.9, 0.35)
const ROOT_HEIGHT := 1.2
const BOOM_REACH := 4.2
const BOOM_CLOSEST := 1.4
const REST_FORWARD := 2.0
const REST_HEIGHT := 1.0
const SWING_HEIGHT := 1.4
## The bite: the swing out over him (the warning), the drop, the time the head sits on the ground
## afterward, the lift back, and the rest before the next.
const AIM_TIME := 0.9
const BITE_TIME := 0.18
const STUCK_TIME := 1.4
const RAISE_TIME := 0.6
const BITE_INTERVAL := 2.4
## What closing jaws reach and do.
const JAW_RADIUS := 0.55
const BITE_DAMAGE := 6.0
const BITE_KNOCK := 3.0
## The share of a hit that gets through its steel, and what a hit on the exposed joint does.
const ARMOR_SHARE := 0.25
const JOINT_SHARE := 2.0


## The hydraulic joint at the boom's head: something to aim at, alive only while it's exposed.
class Joint:
	## Held weakly: the machine holds its joint, so a strong hold back would keep both forever.
	var _machine: WeakRef
	var machine: Machine:
		get:
			return _machine.get_ref()
	var body := Body.new()
	var health: float:
		get:
			return machine.health

	func alive() -> bool:
		return machine.alive() and machine.exposed()


var kind := "feller_buncher"
var body := Body.new()
var health := HEALTH
var most_health := HEALTH
var worth := WORTH
## Its footprint, along and across, and whether it's in the air, where nothing on the ground is
## under it and no blade reaches.
var length := LENGTH
var width := WIDTH
var flying := false
## How far it attacks from, and how close is too close; how long its warning lasts; and what its
## tracks or wheels do to a cat they run over.
var reach := BOOM_REACH
var closest := BOOM_CLOSEST
var aim_time := AIM_TIME
var crush_damage := CRUSH_DAMAGE
var state := State.DRIVING
## The way it faces, as an angle, and how fast it's turning, for the tracks.
var heading := 0.0
var turning := 0.0
## How far its tracks have run, so the view can step the treads.
var tracks_run := 0.0
## The boom's head: where it is over the ground and how high, and where a bite will come down.
var head := Vector2.ZERO
var head_height := REST_HEIGHT
var bite_at := Vector2.ZERO
var joint := Joint.new()
var state_for := 0.0
var bite_ready_in := 1.5
## Bites it has made, and hits on its steel, counted, so the view and the sound know.
var bites := 0
var broken_for := 0.0
var _swing_from := Vector2.ZERO
var _crush_ready := {}


func _init() -> void:
	body.radius = WIDTH * 0.5
	body.tall = TALL
	body.kind = kind
	joint._machine = weakref(self)
	joint.body.radius = 0.3
	joint.body.tall = 0.4


## When it comes into the arena: anything a kind sets up once it's in place.
func arrived(_arena: Arena) -> void:
	pass


## The nearest cat, and the way to him.
func _prey(arena: Arena) -> Cat:
	return arena.nearest_cat(body.position)


## Turns toward an angle at its turn rate, on the spot. Returns how far off it still is.
func _turn_toward(angle: float, rate: float, delta: float) -> float:
	var off := angle_difference(heading, angle)
	turning = clampf(off / maxf(delta, 0.0001), -rate, rate)
	heading += turning * delta
	return off


## A machine of a kind.
static func make(machine_kind: String) -> Machine:
	match machine_kind:
		"log_loader": return LogLoader.new()
		"logging_truck": return LoggingTruck.new()
		"bulldozer": return Bulldozer.new()
		"helicopter": return Helicopter.new()
	return Machine.new()


## Sets its kind's size, health and worth.
func _fit(machine_kind: String, footprint: Vector2, tall: float, machine_health: float, machine_worth: int) -> void:
	kind = machine_kind
	body.kind = kind
	length = footprint.x
	width = footprint.y
	body.radius = minf(footprint.x, footprint.y) * 0.5
	body.tall = tall
	most_health = machine_health
	health = machine_health
	worth = machine_worth


func alive() -> bool:
	return health > 0.0


func standing() -> bool:
	return state != State.BROKEN


## The joint is open to hits while the head sits on the ground after a bite.
func exposed() -> bool:
	return state == State.STUCK


func facing() -> Vector2:
	return Vector2.from_angle(heading)


## Where a point on the machine is over the ground: along its heading and across it.
func point(along: float, across: float) -> Vector2:
	return body.position + facing() * along + facing().orthogonal() * across


## The boom's root over the ground.
func root() -> Vector2:
	return point(BOOM_ROOT.x, BOOM_ROOT.y)


## Whether a point is under it: inside its footprint, with a margin.
func covers(where: Vector2, margin := 0.0) -> bool:
	if flying:
		return false
	var local := (where - body.position).rotated(-heading)
	return absf(local.x) <= length * 0.5 + margin and absf(local.y) <= width * 0.5 + margin


## Pushes a point out of its footprint, the shortest way: the steel doesn't give.
func push_out(where: Vector2, margin: float) -> Vector2:
	var local := (where - body.position).rotated(-heading)
	var half := Vector2(length * 0.5 + margin, width * 0.5 + margin)
	if absf(local.x) > half.x or absf(local.y) > half.y:
		return where
	if half.x - absf(local.x) < half.y - absf(local.y):
		local.x = half.x * signf(local.x if local.x != 0.0 else 1.0)
	else:
		local.y = half.y * signf(local.y if local.y != 0.0 else 1.0)
	return body.position + local.rotated(heading)


## Hurt by a hit. On its steel, most of it is shrugged off; on the exposed joint, it's doubled.
func take(damage: float, on_joint := false) -> float:
	if not alive():
		return 0.0
	var dealt := damage * (JOINT_SHARE if on_joint and exposed() else ARMOR_SHARE)
	health -= dealt
	if not alive():
		state = State.BROKEN
		state_for = 0.0
		body.velocity = Vector2.ZERO
		turning = 0.0
	return dealt


func step(delta: float, arena: Arena) -> void:
	state_for = maxf(state_for - delta, 0.0)
	bite_ready_in = maxf(bite_ready_in - delta, 0.0)
	for cat: Cat in _crush_ready.keys():
		_crush_ready[cat] = maxf(_crush_ready[cat] - delta, 0.0)
	_work(delta, arena)
	if standing():
		body.position += body.velocity * delta
		tracks_run += body.velocity.length() * delta + absf(turning) * width * 0.5 * delta
	# Working or wrecked, it's steel: nothing walks through it.
	_crush(arena)


## What this kind of machine does with a step. The feller buncher drives, swings, bites, and sits
## with its head down.
func _work(delta: float, arena: Arena) -> void:
	match state:
		State.DRIVING: _drive(delta, arena)
		State.AIMING: _aim(delta)
		State.BITING: _bite(delta, arena)
		State.STUCK:
			if state_for <= 0.0:
				state = State.RAISING
				state_for = RAISE_TIME
				_swing_from = head
		State.RAISING: _raise(delta)
		State.BROKEN: _break(delta)
	joint.body.position = head
	joint.body.height = head_height


## On its tracks toward the nearest cat: it turns on the spot until it faces him, then drives.
## Close enough, it swings the boom out over him.
func _drive(delta: float, arena: Arena) -> void:
	_tuck(delta)
	var prey := arena.nearest_cat(body.position)
	if prey == null:
		body.velocity = Vector2.ZERO
		turning = 0.0
		return
	var toward := prey.body.position - body.position
	var off := angle_difference(heading, toward.angle())
	turning = clampf(off / maxf(delta, 0.0001), -TURN_RATE, TURN_RATE)
	heading += turning * delta
	var distance := prey.body.position.distance_to(root())
	if distance <= reach and distance >= closest * 0.8 and bite_ready_in <= 0.0:
		# It commits to where he is now; the head's shadow is his warning to be elsewhere.
		state = State.AIMING
		state_for = aim_time
		bite_at = prey.body.position
		_swing_from = head
		body.velocity = Vector2.ZERO
		turning = 0.0
		arena.events.append({"position": root(), "height": ROOT_HEIGHT, "direction": facing(), "killed": false, "by": "boom", "giant": true, "kind": kind})
		return
	# Too far, it drives in; too close for the boom, it backs off to bring him into reach.
	if absf(off) >= DRIVE_WITHIN:
		body.velocity = Vector2.ZERO
	elif distance > reach * 0.7:
		body.velocity = facing() * SPEED
	elif distance < closest:
		body.velocity = -facing() * SPEED * 0.6
	else:
		body.velocity = Vector2.ZERO


## The head held tucked in front of it as it drives.
func _tuck(delta: float) -> void:
	head = head.move_toward(point(REST_FORWARD, BOOM_ROOT.y), 3.0 * delta)
	head_height = move_toward(head_height, REST_HEIGHT, 1.5 * delta)


## The swing out: the head travels over him, raised, as its shadow closes in on where it'll bite.
func _aim(_delta: float) -> void:
	var done := 1.0 - state_for / aim_time
	var eased := done * done * (3.0 - 2.0 * done)
	head = _swing_from.lerp(bite_at, eased)
	head_height = lerpf(REST_HEIGHT, SWING_HEIGHT, minf(done * 2.0, 1.0))
	if state_for <= 0.0:
		state = State.BITING
		state_for = BITE_TIME


## The drop: the head comes down and its jaws shut on whatever is there.
func _bite(_delta: float, arena: Arena) -> void:
	head = bite_at
	head_height = SWING_HEIGHT * (state_for / BITE_TIME)
	if state_for > 0.0:
		return
	head_height = 0.0
	bites += 1
	arena.jaws(self, bite_at)
	state = State.STUCK
	state_for = STUCK_TIME


func _raise(_delta: float) -> void:
	var done := 1.0 - state_for / RAISE_TIME
	head = _swing_from.lerp(point(REST_FORWARD, BOOM_ROOT.y), done)
	head_height = lerpf(0.0, REST_HEIGHT, done)
	if state_for <= 0.0:
		state = State.DRIVING
		bite_ready_in = BITE_INTERVAL


## Broken: the engine dies, and the boom comes down under its own weight, the head falling the way
## anything falls.
func _break(delta: float) -> void:
	broken_for += delta
	body.velocity = Vector2.ZERO
	if head_height > 0.0:
		joint.body.vertical_speed -= Body.GRAVITY * delta
		head_height = maxf(head_height + joint.body.vertical_speed * delta, 0.0)


## What its tracks do while they turn: the horde under them is crushed, a cat run over is hurt
## and thrown clear. Standing still, they just don't give.
func _crush(arena: Arena) -> void:
	if flying:
		return
	var moving := body.velocity.length() > 0.05 or absf(turning) > 0.05
	for creature: Creature in arena.creatures.duplicate():
		if creature.body.airborne() or not covers(creature.body.position, creature.body.radius):
			continue
		if moving and covers(creature.body.position):
			arena.strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "tracks")
		else:
			creature.body.position = push_out(creature.body.position, creature.body.radius)
	for cat in arena.cats:
		if not cat.alive() or cat.body.height > 0.5 or not covers(cat.body.position, cat.body.radius):
			continue
		var clear := push_out(cat.body.position, cat.body.radius + 0.02)
		if moving and _crush_ready.get(cat, 0.0) <= 0.0:
			_crush_ready[cat] = CRUSH_INTERVAL
			cat.hurt(crush_damage, (clear - body.position).normalized() * 2.0)
		cat.body.position = clear
