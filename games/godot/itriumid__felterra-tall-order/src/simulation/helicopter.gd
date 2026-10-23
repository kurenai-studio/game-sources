class_name Helicopter
extends Machine
## The helicopter: the company's, out of every cat's reach in the air. It hovers off from him and
## strafes: its run marked on the ground in a dotted line (the warning), then rounds stitched along
## that line, through him if he's still on it and through the horde either way. After a couple of
## runs it sets down to unload workers, and while it's on the ground its tail rotor is open to hits,
## and blades can reach it at all. Then it lifts off again. Shot down, it drops out of the sky.

const HOVER := 3.0
const FLY_SPEED := 4.0
const STAND_OFF := 5.0
const MARK_TIME := 1.0
const STRAFE_SPEED := 7.0
const STRAFE_LENGTH := 9.0
const STRAFE_HURT := 2.0
const STRAFE_WIDTH := 0.45
const RUNS_BEFORE_LANDING := 2
const LANDED_TIME := 3.2
const DESCENT := 2.5
const UNLOADS := 2

## The run it's marked: from where to where; how many runs since it last landed; the climb or the
## drop it's in; and what this run has hit.
var strafe_from := Vector2.ZERO
var strafe_to := Vector2.ZERO
var runs := 0
var landed := false
var _strafed := {}
var _unloaded := false
## How far its rotor has turned, for the sound of its blades.
var rotor := 0.0


func _init() -> void:
	super()
	_fit("helicopter", Vector2(3.6, 1.4), 1.2, 420.0, 320)
	flying = true


func arrived(_arena: Arena) -> void:
	body.height = HOVER


## Its tail rotor is open to hits only while it's on the ground.
func exposed() -> bool:
	return landed and standing()


func _work(delta: float, arena: Arena) -> void:
	if standing():
		rotor += delta * (12.0 if not landed else 6.0)
	var prey := _prey(arena)
	match state:
		State.DRIVING:
			if prey == null:
				body.velocity = Vector2.ZERO
				return
			# Off to one side of him, nose toward him.
			var spot := prey.body.position + (body.position - prey.body.position).normalized() * STAND_OFF
			body.velocity = (spot - body.position).limit_length(FLY_SPEED)
			_turn_toward((prey.body.position - body.position).angle(), 1.2, delta)
			if bite_ready_in <= 0.0 and body.position.distance_to(spot) < 1.0:
				if runs >= RUNS_BEFORE_LANDING:
					state = State.STUCK
					state_for = LANDED_TIME + HOVER / DESCENT
					runs = 0
					_unloaded = false
				else:
					# The run goes straight through where he is now.
					var across := (prey.body.position - body.position).normalized()
					strafe_from = prey.body.position - across * STRAFE_LENGTH * 0.5
					strafe_to = prey.body.position + across * STRAFE_LENGTH * 0.5
					state = State.AIMING
					state_for = MARK_TIME
					arena.events.append({"position": strafe_from, "height": HOVER, "direction": across, "killed": false, "by": "strafe_marked", "giant": true, "kind": kind})
		State.AIMING:
			body.velocity = (strafe_from - body.position).limit_length(FLY_SPEED * 2.0)
			if state_for <= 0.0:
				state = State.BITING
				body.position = strafe_from
				_strafed.clear()
		State.BITING:
			var along := (strafe_to - strafe_from).normalized()
			body.velocity = along * STRAFE_SPEED
			heading = along.angle()
			_strafe(arena)
			if body.position.distance_to(strafe_from) >= STRAFE_LENGTH:
				state = State.DRIVING
				body.velocity = Vector2.ZERO
				runs += 1
				bite_ready_in = 1.2
		State.STUCK:
			# Down to the ground, unload, wait, then up.
			body.velocity = Vector2.ZERO
			body.height = maxf(body.height - DESCENT * delta, 0.0)
			landed = body.height <= 0.0
			flying = not landed
			if landed and not _unloaded:
				_unloaded = true
				for index in UNLOADS:
					arena.add_giant(point(-0.5, (1.0 if index == 0 else -1.0) * (width * 0.5 + 0.6)))
			if state_for <= 0.0:
				state = State.RAISING
				landed = false
				flying = true
		State.RAISING:
			body.height = minf(body.height + DESCENT * delta, HOVER)
			if body.height >= HOVER:
				state = State.DRIVING
				bite_ready_in = 1.0
		State.BROKEN:
			# Shot down: it falls, and is a wreck where it lands.
			broken_for += delta
			body.velocity = Vector2.ZERO
			if body.height > 0.0:
				joint.body.vertical_speed -= Body.GRAVITY * delta
				body.height = maxf(body.height + joint.body.vertical_speed * delta, 0.0)
			flying = body.height > 0.0
			landed = not flying
	# The tail rotor, at the end of its boom.
	joint.body.position = point(-length * 0.5 - 0.5, 0.0)
	joint.body.height = body.height + 0.3


## The run: rounds hit the ground under it as it goes, the horde and any cat in the line.
func _strafe(arena: Arena) -> void:
	var under := body.position
	for creature: Creature in arena.creatures.duplicate():
		if creature.body.position.distance_to(under) <= STRAFE_WIDTH + creature.body.radius:
			arena.strike(creature, 100.0, Vector2.ZERO, 0.0, 0.0, "strafe")
	for cat in arena.cats:
		if cat.alive() and not _strafed.has(cat) and cat.body.position.distance_to(under) <= STRAFE_WIDTH + cat.body.radius:
			if cat.hurt(STRAFE_HURT, (cat.body.position - under).normalized() * 1.5):
				_strafed[cat] = true
