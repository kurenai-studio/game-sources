class_name Rival
extends RefCounted
## The computer's thumbs for one athlete: it taps each landing a little early
## or late (how much depends on its skill), now and then misses one, and asks
## the event what to do with the action button.

var b: Bouncer
var rng := RandomNumberGenerator.new()
var sigma := 0.05          ## spread of its timing, seconds
var bias := 0.0            ## its habit of being early (-) or late (+)
var miss_p := 0.02
var plan := {}             ## landing slot -> tap time (-1: let it go by, -2: done)
var act := {}              ## landing slot -> press action instead of bounce
var think: Callable        ## (rival, slot) -> bool: should this landing be an action?
var tapper: Callable       ## (at, action) -> taps through the event instead of straight to the bouncer


func _init(bouncer: Bouncer, skill: float, seed := 0) -> void:
	b = bouncer
	rng.seed = seed
	sigma = lerpf(0.11, 0.021, clampf(skill, 0.0, 1.0))
	miss_p = (1.0 - skill) * 0.1
	bias = rng.randf_range(-0.012, 0.012)


func update(at: float) -> void:
	if b.state != "run":
		return
	var k := b.to_slot
	if not plan.has(k):
		if rng.randf() < miss_p:
			plan[k] = -1.0
		else:
			plan[k] = b.slot_time(k) + clampf(rng.randfn(0.0, sigma) + bias, -0.15, 0.15)
	# a landing it means to act on is never let go by
	if plan[k] == -1.0 and think.is_valid() and think.call(self, k):
		plan[k] = b.slot_time(k) + rng.randfn(0.0, sigma)
	for s in [b.from_slot, b.to_slot]:
		var when: float = plan.get(s, -2.0)
		if when >= 0.0 and at >= when:
			plan[s] = -2.0
			# what to do is decided at the last moment, when it can see best
			var action: bool = think.is_valid() and think.call(self, s)
			if action:
				act[s] = true
			if tapper.is_valid():
				tapper.call(when, action)
			else:
				b.tap(when, action)
