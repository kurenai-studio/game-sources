class_name LoggingTruck
extends Machine
## The logging truck: a cab and a trailer stacked with trunks, on wheels, so it can't turn on the
## spot; it turns as it drives. When it has him in line, it revs and sounds its horn (the warning,
## its path marked on the ground), then charges straight down that line, running over whatever's
## in it. A charge ends where it ends, and the truck stalls there a moment, its fuel tank open to
## hits; then it backs up and comes round again. Wrecked, it tips over on its side.

const DRIVE_SPEED := 1.4
const TURN := 0.8
const REV_TIME := 0.9
const CHARGE_SPEED := 7.0
const CHARGE_LENGTH := 10.0
const STALL_TIME := 1.8
const BACK_TIME := 0.7
const CHARGE_HURT := 5.0
## How well lined up it has to be, and how close, to charge.
const LINED_UP := 0.2
const CHARGE_FROM := 13.0

## How far this charge has gone.
var charged := 0.0


func _init() -> void:
	super()
	_fit("logging_truck", Vector2(4.6, 1.6), 2.0, 320.0, 240)
	crush_damage = CHARGE_HURT


func _work(delta: float, arena: Arena) -> void:
	match state:
		State.DRIVING:
			var prey := _prey(arena)
			if prey == null:
				body.velocity = Vector2.ZERO
				return
			var toward := prey.body.position - body.position
			# Wheels: it turns only as it rolls.
			var off := _turn_toward(toward.angle(), TURN, delta)
			body.velocity = facing() * DRIVE_SPEED
			if absf(off) < LINED_UP and toward.length() < CHARGE_FROM and bite_ready_in <= 0.0:
				state = State.AIMING
				state_for = REV_TIME
				body.velocity = Vector2.ZERO
				turning = 0.0
				arena.events.append({"position": body.position, "height": 1.0, "direction": facing(), "killed": false, "by": "horn", "giant": true, "kind": kind})
		State.AIMING:
			body.velocity = Vector2.ZERO
			if state_for <= 0.0:
				state = State.BITING
				charged = 0.0
		State.BITING:
			body.velocity = facing() * CHARGE_SPEED
			charged += CHARGE_SPEED * delta
			var ahead := point(length * 0.5 + 0.5, 0.0)
			var off_the_edge := ahead.x < 0.5 or ahead.y < 0.5 or ahead.x > Arena.SIZE.x - 0.5 or ahead.y > Arena.SIZE.y - 0.5
			if charged >= CHARGE_LENGTH or off_the_edge:
				state = State.STUCK
				state_for = STALL_TIME
				body.velocity = Vector2.ZERO
				arena.events.append({"position": body.position, "height": 0.5, "direction": facing(), "killed": false, "by": "stall", "giant": true, "kind": kind})
		State.STUCK:
			body.velocity = Vector2.ZERO
			if state_for <= 0.0:
				state = State.RAISING
				state_for = BACK_TIME
		State.RAISING:
			body.velocity = -facing() * DRIVE_SPEED
			if state_for <= 0.0:
				state = State.DRIVING
				bite_ready_in = 1.5
		State.BROKEN:
			broken_for += delta
			body.velocity = Vector2.ZERO
	# The fuel tank, under the cab's side.
	joint.body.position = point(length * 0.15, width * 0.5 + 0.2)
	joint.body.height = 0.0


## The line it will charge down, for the warning: from its front, as far as it goes.
func charge_line() -> PackedVector2Array:
	return PackedVector2Array([point(length * 0.5, 0.0), point(length * 0.5 + CHARGE_LENGTH, 0.0)])
