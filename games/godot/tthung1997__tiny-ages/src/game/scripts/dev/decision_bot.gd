class_name DecisionBot
extends RefCounted
## A stand-in player for development: answers pending decisions with the first choice it prefers
## that is available. Used by the timeline tool and the game's --bot flag to watch a story play
## out without clicking. Never part of normal play.

const PREFERENCE: Array[StringName] = [
	&"carry_fire", &"blow_on_it", &"keep_the_stone", &"hunt", &"tell_it", &"paint_the_wall",
	&"welcome_them", &"build_lookout", &"encourage", &"plant_it", &"settle_field",
	&"build_field", &"build_drying_rack", &"build_hut", &"build_knapping_spot",
]


## Answers every pending decision once. Returns how many were resolved.
func answer_all(sim: Simulation) -> int:
	var answered: int = 0
	for decision: PendingDecision in sim.world.pending.duplicate():
		if _answer(sim, decision):
			answered += 1
	return answered


## Answers the oldest pending decision. False if there is none or nothing can be chosen.
func answer_first(sim: Simulation) -> bool:
	if sim.world.pending.is_empty():
		return false
	return _answer(sim, sim.world.pending[0])


func _answer(sim: Simulation, decision: PendingDecision) -> bool:
	var event: EventDef = sim.content.get_event(decision.event_id)
	if event == null:
		return false
	var subject: VillagerState = sim.world.find_villager(decision.subject_id)
	var picked: StringName = &""
	for wanted: StringName in PREFERENCE:
		var choice: ChoiceDef = event.get_choice(wanted)
		if choice != null and sim.choice_available(choice, subject):
			picked = wanted
			break
	if picked == &"":
		for choice: ChoiceDef in event.choices:
			if sim.choice_available(choice, subject):
				picked = choice.id
				break
	return picked != &"" and sim.resolve_decision(decision.id, picked)
