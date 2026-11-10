extends McpTestSuite
## The rules for what a decision is (docs/gameplay.md P13): it is only asked while at least
## two answers can be picked, it has no "pass" answer, and the economy does not pile up stock.

const DAY: int = SimFixture.TICKS_PER_DAY
const WOOD_CEILING: int = 100
const FOOD_CEILING: int = 300


func suite_name() -> String:
	return "decision_rules"


func _test_event(second_needs_wood: int) -> EventDef:
	var event: EventDef = EventDef.new()
	event.id = &"test_fork"
	event.title = "A fork"
	event.chance_per_tick = 1.0
	var left: ChoiceDef = ChoiceDef.new()
	left.id = &"left"
	var right: ChoiceDef = ChoiceDef.new()
	right.id = &"right"
	var need: SimCondition = SimCondition.new()
	need.kind = SimCondition.Kind.RESOURCE_AT_LEAST
	need.key = &"wood"
	need.amount = second_needs_wood
	right.requires.append(need)
	event.choices.append(left)
	event.choices.append(right)
	return event


func _sim_with(event: EventDef) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.content.events.clear()
	sim.content.events.append(event)
	sim.world.resources[&"wood"] = 0
	return sim


func test_a_decision_with_one_answer_left_is_not_asked() -> void:
	var sim: Simulation = _sim_with(_test_event(10))
	sim.advance_ticks(DAY * 3)
	assert_eq(sim.world.pending.size(), 0, "One answer is not a decision")


func test_a_decision_is_asked_once_two_answers_are_open() -> void:
	var sim: Simulation = _sim_with(_test_event(10))
	sim.world.resources[&"wood"] = 10
	sim.advance_ticks(DAY * 3)
	assert_eq(sim.world.pending.size(), 1)


func test_a_decision_can_be_authored_to_ask_with_one_answer() -> void:
	var event: EventDef = _test_event(10)
	event.min_choices = 1
	var sim: Simulation = _sim_with(event)
	sim.advance_ticks(DAY * 3)
	assert_eq(sim.world.pending.size(), 1)


func test_new_decisions_default_to_needing_two_answers() -> void:
	assert_eq(EventDef.new().min_choices, 2)


func test_a_decision_already_asked_waits_when_stock_drops() -> void:
	var sim: Simulation = _sim_with(_test_event(10))
	sim.world.resources[&"wood"] = 10
	sim.advance_ticks(DAY)
	sim.world.resources[&"wood"] = 0
	sim.advance_ticks(DAY)
	assert_eq(sim.world.pending.size(), 1, "Waiting is never punished or withdrawn")


## A pass is an answer that changes nothing but the journal.
func _is_pass(choice: ChoiceDef) -> bool:
	for effect: SimEffect in choice.effects:
		if effect.kind != SimEffect.Kind.JOURNAL:
			return false
	return true


func test_every_decision_is_a_fork_with_no_pass_answer() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var problems: PackedStringArray = []
	var decisions: int = 0
	for event: EventDef in content.events:
		if not event.is_decision():
			continue
		decisions += 1
		if event.min_choices < 2:
			problems.append("%s may be asked with one answer" % event.id)
		var real: int = 0
		for choice: ChoiceDef in event.choices:
			if not _is_pass(choice):
				real += 1
		if real < 2:
			problems.append("%s needs two answers that each do something" % event.id)
	assert_gt(decisions, 60, "The content has its decisions")
	assert_eq(problems.size(), 0, ", ".join(problems))


func test_stock_does_not_pile_up_over_a_long_game() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	var bot: DecisionBot = DecisionBot.new()
	var most_wood: int = 0
	var most_food: int = 0
	for _tick: int in DAY * 700:
		sim.advance_ticks(1)
		bot.answer_all(sim)
		most_wood = maxi(most_wood, sim.world.resource_amount(&"wood"))
		most_food = maxi(most_food, sim.world.resource_amount(&"food"))
	assert_true(most_wood <= WOOD_CEILING, "Wood peaked at %d" % most_wood)
	assert_true(most_food <= FOOD_CEILING, "Food peaked at %d" % most_food)


func test_a_pending_decision_for_a_removed_event_is_withdrawn() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var gone: PendingDecision = PendingDecision.new()
	gone.id = &"decision_gone"
	gone.event_id = &"an_event_an_older_version_had"
	sim.world.pending.append(gone)
	sim.advance_ticks(1)
	assert_true(sim.world.find_pending(&"decision_gone") == null, "Nothing is left unanswerable")


## Every order of building picks, and ignoring the question for good, must still reach the
## Settled Age: no building is something the age cannot do without.
func test_no_order_of_building_picks_blocks_the_age() -> void:
	var lookout: StringName = &"build_lookout"
	var rack: StringName = &"build_drying_rack"
	var knap: StringName = &"build_knapping_spot"
	var orders: Array = [
		[lookout, rack, knap], [lookout, knap, rack], [knap, rack, lookout], [],
	]
	for order: Array in orders:
		assert_true(_reaches_settled(order), "Order %s reaches the Settled Age" % [order])


func _reaches_settled(order: Array) -> bool:
	var sim: Simulation = SimFixture.new_sim(1, false)
	var bot: DecisionBot = DecisionBot.new()
	var settled: EraDef = sim.content.get_era(&"settled")
	var limit: int = settled.min_ticks_in_previous_era + DAY * 150
	for _tick: int in limit:
		sim.advance_ticks(1)
		for decision: PendingDecision in sim.world.pending.duplicate():
			if decision.event_id == &"building_opportunity":
				_answer_building(sim, decision, order)
		bot.answer_all(sim)
		if sim.world.era == &"settled":
			return true
	return false


## Picks the first building in `order` that can be chosen now; an empty order never answers.
func _answer_building(sim: Simulation, decision: PendingDecision, order: Array) -> void:
	var event: EventDef = sim.content.get_event(decision.event_id)
	for wanted: StringName in order:
		var choice: ChoiceDef = event.get_choice(wanted)
		if choice != null and sim.choice_available(choice, null):
			sim.resolve_decision(decision.id, wanted)
			return
	if order.is_empty():
		sim.world.pending.erase(decision)
