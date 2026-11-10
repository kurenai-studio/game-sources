class_name EventSystem
extends RefCounted
## Decides when events fire: first anything scheduled that has come due, then at most one new
## event rolled from the eligible templates. Waiting never makes anything worse.


func step(sim: Simulation) -> void:
	_fire_scheduled(sim)
	_roll_new_event(sim)


func _fire_scheduled(sim: Simulation) -> void:
	var world: WorldState = sim.world
	var due: Array[ScheduledEvent] = []
	for item: ScheduledEvent in world.scheduled:
		if item.due_tick <= world.tick:
			due.append(item)
	if due.is_empty():
		return
	due.sort_custom(
		func(a: ScheduledEvent, b: ScheduledEvent) -> bool: return a.due_tick < b.due_tick
	)
	for item: ScheduledEvent in due:
		world.scheduled.erase(item)
		var event: EventDef = sim.content.get_event(item.event_id)
		if event == null:
			push_error("Scheduled unknown event '%s'" % item.event_id)
			continue
		# A consequence that no longer applies (the fire was lit another way) is dropped.
		if not SimCondition.all_met(event.requires, world, sim.config):
			continue
		sim.fire_event(event, world.find_villager(item.subject_id))


func _roll_new_event(sim: Simulation) -> void:
	var world: WorldState = sim.world
	var config: SimConfig = sim.config
	var decision_slot_free: bool = world.pending.size() < config.max_pending_decisions \
			and world.tick - world.last_decision_tick >= config.decision_cooldown_ticks
	# Most events cannot happen at any given tick, so find the ones that can first (no randomness
	# is used for that) and only shuffle those: the order among them is uniformly random.
	var eligible: Array[EventDef] = []
	var day: int = config.day_of(world.tick)
	var era_day: int = config.day_of(world.tick - world.era_started_tick)
	for event: EventDef in sim.content.events:
		if event.chance_per_tick <= 0.0:
			continue
		if not event.may_be_open(day, world.era_order, era_day):
			continue
		var is_decision: bool = not event.choices.is_empty()
		if is_decision and (not decision_slot_free or _has_pending(world, event.id)):
			continue
		if not _passes_history(world, event):
			continue
		if not SimCondition.all_met(event.requires, world, config):
			continue
		eligible.append(event)
	if eligible.is_empty():
		return
	for index: int in SimRandom.shuffled_indices(sim.rng, eligible.size()):
		var event: EventDef = eligible[index]
		var subject: VillagerState = null
		if event.needs_subject:
			subject = _pick_subject(sim, event)
			if subject == null:
				continue
		if event.is_decision() and _available_choices(sim, event, subject) < event.min_choices:
			continue
		var chance: float = minf(event.chance_per_tick * event.subject_weight(subject), 1.0)
		if sim.rng.randf() >= chance:
			continue
		sim.fire_event(event, subject)
		return


func _has_pending(world: WorldState, event_id: StringName) -> bool:
	for decision: PendingDecision in world.pending:
		if decision.event_id == event_id:
			return true
	return false


func _passes_history(world: WorldState, event: EventDef) -> bool:
	var times_fired: int = world.event_counts.get(event.id, 0)
	if event.once and times_fired > 0:
		return false
	if event.cooldown_ticks > 0 and times_fired > 0:
		var last: int = world.event_last_tick.get(event.id, 0)
		if world.tick - last < event.cooldown_ticks:
			return false
	return true


## A decision is only worth asking while the player really has something to decide.
func _available_choices(sim: Simulation, event: EventDef, subject: VillagerState) -> int:
	var count: int = 0
	for choice: ChoiceDef in event.choices:
		if sim.choice_available(choice, subject):
			count += 1
	return count


func _pick_subject(sim: Simulation, event: EventDef) -> VillagerState:
	var candidates: Array[VillagerState] = []
	var weights: Array[float] = []
	for villager: VillagerState in sim.world.villagers:
		if SimCondition.all_met(event.subject_requires, sim.world, sim.config, villager):
			candidates.append(villager)
			weights.append(event.subject_weight(villager))
	var picked: int = SimRandom.pick_weighted(sim.rng, weights)
	return null if picked < 0 else candidates[picked]
