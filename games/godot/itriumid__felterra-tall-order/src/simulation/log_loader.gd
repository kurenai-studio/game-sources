class_name LogLoader
extends Machine
## The log loader: tracks, a cab, and a grapple on a long arm that lifts logs off the pile beside
## it and throws them. It swings a log up overhead while the log's shadow grows where it will land
## (the warning), lets go, and while the log is in the air reaches back down to its pile for the
## next: that's when its grapple's joint is open to hits.

## How far it throws, and how close is too close to throw at; how long the log flies, and how much
## ground it crushes landing.
const THROW_REACH := 8.0
const THROW_CLOSEST := 2.5
const FLIGHT := 0.9
const SLAM_RADIUS := 0.9
const LIFT_HEIGHT := 2.6

## Seconds left in the air for a thrown log (0 while none is), and where it left the grapple.
var log_flying := 0.0
var thrown_from := Vector2.ZERO


func _init() -> void:
	super()
	_fit("log_loader", Vector2(3.2, 2.0), 2.0, 340.0, 220)
	reach = THROW_REACH
	closest = THROW_CLOSEST
	aim_time = 1.0


func _work(delta: float, arena: Arena) -> void:
	if log_flying > 0.0:
		log_flying = maxf(log_flying - delta, 0.0)
		if log_flying <= 0.0:
			arena.jaws(self, bite_at, SLAM_RADIUS, "log_lands")
	match state:
		State.DRIVING: _drive(delta, arena)
		State.AIMING:
			# Up overhead with the log: its shadow closes in where it'll land.
			var done := 1.0 - state_for / aim_time
			head = _swing_from.lerp(point(0.6, 0.0), minf(done * 2.0, 1.0))
			head_height = lerpf(REST_HEIGHT, LIFT_HEIGHT, minf(done * 1.5, 1.0))
			if state_for <= 0.0:
				thrown_from = head
				log_flying = FLIGHT
				bites += 1
				state = State.STUCK
				state_for = STUCK_TIME + FLIGHT
				arena.events.append({"position": head, "height": head_height, "direction": facing(), "killed": false, "by": "throw", "giant": true, "kind": kind})
		State.STUCK:
			# Down to the pile beside it for the next log: the grapple's joint open.
			head = head.move_toward(point(0.2, -width * 0.5 - 0.9), 5.0 * delta)
			head_height = move_toward(head_height, 0.1, 4.0 * delta)
			if state_for <= 0.0:
				state = State.RAISING
				state_for = RAISE_TIME
				_swing_from = head
		State.RAISING: _raise(delta)
		State.BROKEN: _break(delta)
	joint.body.position = head
	joint.body.height = head_height
