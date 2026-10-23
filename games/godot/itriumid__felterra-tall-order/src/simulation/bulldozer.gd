class_name Bulldozer
extends Machine
## The bulldozer: tracks, a cab, and a blade as wide as it is. It crawls toward him, raises its
## blade (the warning, the ground it'll take marked out in front), then rams forward, shoving
## whatever is in front of the blade along with it, and crushing what's caught under. Its engine
## sits at the back, behind the cab, and that's its weak point: open to hits all the time, but only
## from behind it.

const DRIVE_SPEED := 0.7
const TURN := 0.6
const RAM_FROM := 5.0
const BLADE_UP := 1.0
const RAM_SPEED := 3.5
const RAM_LENGTH := 4.5
const SETTLE := 1.0
const BLADE_HURT := 4.0
## How deep in front of it the blade's reach goes.
const BLADE_DEPTH := 0.7

var rammed := 0.0
var _shoved := {}


func _init() -> void:
	super()
	_fit("bulldozer", Vector2(3.4, 2.4), 2.0, 380.0, 260)


## Its engine is always there to hit, if he can get round behind it.
func exposed() -> bool:
	return standing()


func _work(delta: float, arena: Arena) -> void:
	match state:
		State.DRIVING:
			var prey := _prey(arena)
			if prey == null:
				body.velocity = Vector2.ZERO
				return
			var toward := prey.body.position - body.position
			var off := _turn_toward(toward.angle(), TURN, delta)
			body.velocity = facing() * DRIVE_SPEED if absf(off) < 0.5 else Vector2.ZERO
			if absf(off) < 0.25 and toward.length() < RAM_FROM and bite_ready_in <= 0.0:
				state = State.AIMING
				state_for = BLADE_UP
				body.velocity = Vector2.ZERO
				turning = 0.0
				arena.events.append({"position": body.position, "height": 1.0, "direction": facing(), "killed": false, "by": "blade_up", "giant": true, "kind": kind})
		State.AIMING:
			body.velocity = Vector2.ZERO
			if state_for <= 0.0:
				state = State.BITING
				rammed = 0.0
				_shoved.clear()
		State.BITING:
			body.velocity = facing() * RAM_SPEED
			rammed += RAM_SPEED * delta
			_shove(delta, arena)
			if rammed >= RAM_LENGTH:
				state = State.RAISING
				state_for = SETTLE
				body.velocity = Vector2.ZERO
		State.RAISING:
			body.velocity = Vector2.ZERO
			if state_for <= 0.0:
				state = State.DRIVING
				bite_ready_in = 1.2
		State.BROKEN:
			broken_for += delta
			body.velocity = Vector2.ZERO
	# The engine, at the back.
	joint.body.position = point(-length * 0.5 - 0.15, 0.0)
	joint.body.height = 0.6


## Whether a point is in front of the blade, within its reach.
func in_front(where: Vector2, margin := 0.0) -> bool:
	var local := (where - body.position).rotated(-heading)
	return local.x >= length * 0.5 - 0.1 and local.x <= length * 0.5 + BLADE_DEPTH + margin and absf(local.y) <= width * 0.5 + margin


## Ramming: what's in front of the blade goes along with it. The horde is crushed against it; a
## cat is shoved, and hurt once a ram.
func _shove(delta: float, arena: Arena) -> void:
	for creature: Creature in arena.creatures.duplicate():
		if not creature.body.airborne() and in_front(creature.body.position, creature.body.radius):
			arena.strike(creature, 100.0, facing(), 3.0, 1.0, "blade")
	for cat in arena.cats:
		if cat.alive() and cat.body.height < 0.6 and in_front(cat.body.position, cat.body.radius):
			cat.body.position += facing() * RAM_SPEED * delta
			if not _shoved.has(cat):
				_shoved[cat] = true
				cat.hurt(BLADE_HURT, facing() * 2.5)
