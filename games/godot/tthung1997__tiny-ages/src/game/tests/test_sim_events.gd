extends McpTestSuite
## Events and decisions: when they open, what is allowed, and that waiting is always safe.


func suite_name() -> String:
	return "sim_events"


func test_building_decision_opens_once_there_are_two_buildings_to_choose_from() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 18)
	sim.world.resources[&"wood"] = 12
	var used: int = SimFixture.advance_until_pending(sim, &"building_opportunity", 30)
	assert_gt(used, 0, "A building decision should open once there are two to choose from")


func test_a_single_building_to_choose_is_not_a_decision() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 30
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 10)
	assert_eq(sim.world.event_counts.get(&"building_opportunity", 0), 0, "Only the Lookout so far")


func test_choices_the_settlement_cannot_afford_are_refused() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 60)
	sim.world.resources[&"wood"] = 10
	var event: EventDef = sim.content.get_event(&"building_opportunity")
	sim.fire_event(event, null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"building_opportunity")
	assert_false(
		sim.resolve_decision(decision.id, &"build_knapping_spot"), "Knapping Spot costs 12 wood"
	)
	assert_true(
		sim.world.find_pending(decision.id) != null, "A refused choice leaves the decision open"
	)
	assert_true(sim.resolve_decision(decision.id, &"build_drying_rack"))
	assert_eq(sim.world.resource_amount(&"wood"), 0)
	assert_true(sim.world.constructing() != null)
	assert_true(sim.world.find_pending(decision.id) == null)


func test_unknown_decision_or_choice_is_refused() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_false(sim.resolve_decision(&"nope", &"nothing"))
	sim.world.resources[&"wood"] = 10
	sim.fire_event(sim.content.get_event(&"building_opportunity"), null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"building_opportunity")
	assert_false(sim.resolve_decision(decision.id, &"not_a_choice"))


func test_a_decision_waits_indefinitely_without_consequence() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 10
	sim.fire_event(sim.content.get_event(&"building_opportunity"), null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"building_opportunity")
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 30)
	assert_true(
		sim.world.find_pending(decision.id) != null, "Thirty days later it is still waiting"
	)
	assert_eq(sim.world.villagers.size(), 3)
	assert_true(sim.world.resource_amount(&"wood") >= 10, "Nothing was lost while ignoring it")


func test_answering_one_fire_decision_withdraws_the_other() -> void:
	var sim: Simulation = SimFixture.new_sim(5, false)
	sim.fire_event(sim.content.get_event(&"fire_from_storm"), sim.world.villagers[0])
	sim.fire_event(sim.content.get_event(&"fire_from_sparks"), sim.world.villagers[1])
	assert_eq(sim.world.pending.size(), 2)
	var storm: PendingDecision = SimFixture.pending_for(sim, &"fire_from_storm")
	assert_true(sim.resolve_decision(storm.id, &"carry_fire"))
	assert_eq(sim.world.pending.size(), 0, "The fire is lit, so asking about sparks makes no sense")


func test_a_decision_the_world_moved_past_is_withdrawn_on_the_next_tick() -> void:
	var sim: Simulation = SimFixture.new_sim(5, false)
	sim.fire_event(sim.content.get_event(&"fire_from_sparks"), sim.world.villagers[0])
	SimFixture.light_fire(sim.world)
	sim.advance_ticks(1)
	assert_eq(sim.world.pending.size(), 0)


func test_waiting_for_resources_does_not_withdraw_a_decision() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 10
	sim.fire_event(sim.content.get_event(&"building_opportunity"), null)
	sim.world.resources[&"wood"] = 0
	sim.advance_ticks(5)
	assert_eq(sim.world.pending.size(), 1, "An unaffordable choice waits, it is not dropped")


func test_a_decision_can_still_be_answered_after_others_are_withdrawn() -> void:
	var sim: Simulation = SimFixture.new_sim(5, false)
	sim.fire_event(sim.content.get_event(&"fire_from_storm"), sim.world.villagers[0])
	var decision: PendingDecision = SimFixture.pending_for(sim, &"fire_from_storm")
	sim.advance_ticks(10)
	assert_true(sim.world.find_pending(decision.id) != null, "Nothing changed, so it stays")
	assert_true(sim.resolve_decision(decision.id, &"carry_fire"))


func test_the_same_decision_never_stacks_up() -> void:
	var sim: Simulation = SimFixture.new_sim(3)
	SimFixture.jump_to_day(sim, 18)
	sim.world.resources[&"wood"] = 50
	var most_at_once: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * 15:
		sim.advance_ticks(1)
		sim.world.resources[&"wood"] = 50
		var count: int = 0
		for decision: PendingDecision in sim.world.pending:
			if decision.event_id == &"building_opportunity":
				count += 1
		most_at_once = maxi(most_at_once, count)
	assert_eq(most_at_once, 1)


func test_pending_decisions_respect_the_cap() -> void:
	var sim: Simulation = SimFixture.new_sim(5)
	var cap: int = sim.config.max_pending_decisions
	var most: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * 30:
		sim.advance_ticks(1)
		sim.world.resources[&"wood"] = 50
		sim.world.inventory[&"strange_seed"] = 1
		most = maxi(most, sim.world.pending.size())
	assert_true(most <= cap, "At most %d pending decisions, saw %d" % [cap, most])


func test_scheduled_event_fires_when_due() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var queued: ScheduledEvent = ScheduledEvent.new()
	queued.event_id = &"heavy_rain"
	queued.due_tick = sim.world.tick + 3
	sim.world.scheduled.append(queued)
	sim.advance_ticks(2)
	assert_eq(SimFixture.journal_index(sim.world, "It rained"), -1, "Not due yet")
	sim.advance_ticks(1)
	assert_gt(SimFixture.journal_index(sim.world, "It rained"), -1)
	assert_true(sim.world.scheduled.is_empty())


func test_once_only_events_fire_once() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.flags[&"strange_flower_bloomed"] = true
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 60)
	assert_eq(sim.world.event_counts.get(&"rare_butterfly", 0), 1)


func test_events_respect_their_conditions() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 30)
	assert_eq(sim.world.event_counts.get(&"rare_butterfly", 0), 0, "No flower, no butterfly")
	assert_eq(sim.world.event_counts.get(&"curious_explorer", 0), 0, "No hut, no explorer")
