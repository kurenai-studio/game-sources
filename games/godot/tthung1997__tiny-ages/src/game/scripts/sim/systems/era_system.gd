class_name EraSystem
extends RefCounted
## Opens the next age when its hidden gate is met (see EraDef): either advances at once or
## fires the age's turn event, whose choices decide how the settlement turns.


func step(sim: Simulation) -> void:
	var next: EraDef = sim.content.next_era(sim.world.era_order)
	if not sim.era_gate_open(next):
		return
	if next.turn_event == &"":
		sim.advance_era(next.id)
		return
	var event: EventDef = sim.content.get_event(next.turn_event)
	if event == null:
		push_error("Era '%s' has unknown turn event '%s'" % [next.id, next.turn_event])
		return
	for decision: PendingDecision in sim.world.pending:
		if decision.event_id == event.id:
			return
	sim.fire_event(event, null)
