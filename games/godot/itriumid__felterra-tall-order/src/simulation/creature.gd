class_name Creature
extends RefCounted
## One of the horde: a rat from the company's supply crates, or one of its guard dogs. Runs at the
## nearest cat and bites. A dog that gets close crouches (the warning), then lunges: a real leap
## through the air, which a dodge can get out from under, and after it lands it needs a moment.

enum State { RUNNING, CROUCHING, LUNGING, RECOVERING }

## Each kind: how fast it runs, how fast it gets back up to pace (meters a second each second),
## its bite and how often, its health, its size, its mass against a rat's one (a hit's push is
## shared over it) and the experience its fall is worth. Dogs add their lunge.
const KINDS := {
	"rat": {
		"speed": 1.7, "grip": 12.0, "bite": 1.0, "bite_interval": 0.8, "health": 2.0,
		"radius": 0.08, "tall": 0.1, "heft": 1.0, "worth": 1,
	},
	"dog": {
		"speed": 3.1, "grip": 9.0, "bite": 2.0, "bite_interval": 1.2, "health": 9.0,
		"radius": 0.22, "tall": 0.5, "heft": 4.0, "worth": 4,
		"lunge_reach": 1.6, "crouch_time": 0.35, "lunge_speed": 6.0, "lunge_lift": 2.2, "recover_time": 0.9,
	},
	# The Rat Baron: the first area's boss, as big as a dog, a bottle cap for a crown. It calls
	# rats in around it as it comes.
	"rat_baron": {
		"speed": 1.5, "grip": 8.0, "bite": 3.0, "bite_interval": 1.0, "health": 160.0,
		"radius": 0.3, "tall": 0.34, "heft": 12.0, "worth": 40, "calls": 4, "call_interval": 5.0,
	},
}

var kind := "rat"
var body := Body.new()
var health := 2.0
## Experience its fall is worth to the crew.
var worth := 1
## Where it ambles when there's no cat to run at, or nowhere (INF).
var wander_to := Vector2.INF
var bite_ready_in := 0.0
var state := State.RUNNING
## The time left in a crouch or a recovery, and the way a crouch will lunge.
var state_for := 0.0
var lunge_direction := Vector2.RIGHT
## What's afflicting it: poison and fire, as {dps, left, by}, slowing, as {share, left}; and how
## long it's down from a trip.
var afflictions := {}
var tripped_for := 0.0
## How long until it calls the horde in again, if it's one that calls.
var call_in := 2.0


func _init(creature_kind := "rat") -> void:
	kind = creature_kind
	health = stat("health")
	worth = stat("worth")
	body.radius = stat("radius")
	body.tall = stat("tall")
	body.kind = kind


func stat(name: String) -> Variant:
	return KINDS[kind][name]


func alive() -> bool:
	return health > 0.0


func lunging() -> bool:
	return state == State.LUNGING


func tripped() -> bool:
	return tripped_for > 0.0


## How much of its pace it has, slowed or not.
func pace() -> float:
	var slowed: Dictionary = afflictions.get("slow", {})
	return 1.0 - (slowed.share if slowed.get("left", 0.0) > 0.0 else 0.0)


func step(delta: float, prey: Cat, arena: Arena = null) -> void:
	bite_ready_in = maxf(bite_ready_in - delta, 0.0)
	state_for = maxf(state_for - delta, 0.0)
	if KINDS[kind].has("calls") and arena != null:
		call_in -= delta
		if call_in <= 0.0:
			call_in = stat("call_interval")
			for index in int(stat("calls")):
				arena.add_creature(body.position + Vector2.from_angle(TAU * index / stat("calls")) * (body.radius + 0.3))
			arena.events.append({"position": body.position, "height": 0.3, "direction": Vector2.ZERO, "killed": false, "by": "call", "giant": false, "kind": kind})
	if tripped_for > 0.0:
		# Down on its side: it slides to a stop and gets up when it can.
		tripped_for = maxf(tripped_for - delta, 0.0)
		body.slide(delta)
		body.step(delta)
		return
	match state:
		State.CROUCHING:
			# Bunched, still: the warning a lunge is coming.
			body.velocity = body.velocity.move_toward(Vector2.ZERO, float(stat("grip")) * 2.0 * delta)
			if state_for <= 0.0:
				state = State.LUNGING
				body.velocity = Vector2.ZERO
				body.push(lunge_direction * float(stat("lunge_speed")), stat("lunge_lift"))
				if arena != null:
					arena.events.append({"position": body.position, "height": 0.3, "direction": lunge_direction, "killed": false, "by": "lunge", "giant": false, "kind": kind})
		State.LUNGING:
			# A leap is a throw: no steering in the air. It ends where it lands.
			if not body.airborne():
				state = State.RECOVERING
				state_for = stat("recover_time")
		State.RECOVERING:
			body.slide(delta)
			if state_for <= 0.0:
				state = State.RUNNING
		State.RUNNING:
			_run(delta, prey)
	body.step(delta)


func _run(delta: float, prey: Cat) -> void:
	if body.airborne():
		return
	var wanted := Vector2.ZERO
	if prey != null and prey.alive():
		var toward := prey.body.position - body.position
		wanted = toward.normalized() * float(stat("speed")) * pace()
		# A dog close enough crouches to lunge, committing to where he is now.
		if KINDS[kind].has("lunge_reach") and toward.length() < float(stat("lunge_reach")) and bite_ready_in <= 0.0:
			state = State.CROUCHING
			state_for = stat("crouch_time")
			lunge_direction = toward.normalized()
			return
	elif wander_to.is_finite():
		wanted = (wander_to - body.position).limit_length(1.0) * float(stat("speed")) * 0.35
	# Feet on the ground: it claws back to the pace it wants, so a knock carries it a way.
	body.velocity = body.velocity.move_toward(wanted, float(stat("grip")) * delta)
