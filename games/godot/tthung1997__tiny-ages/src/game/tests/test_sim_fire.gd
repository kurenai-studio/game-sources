extends McpTestSuite
## Fire is the first milestone: the Cave Age starts cold and dark, fire is found by one of two
## routes, and a group that waits for the embers instead of carrying a branch home still gets it,
## a little later.

const DAY: int = SimFixture.TICKS_PER_DAY
const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]


func suite_name() -> String:
	return "sim_fire"


func test_a_new_world_has_no_fire() -> void:
	var sim: Simulation = SimFixture.new_sim(1, false)
	assert_false(sim.world.has_flag(&"fire_found"))
	assert_false(sim.world.has_achievement(&"fire"))


func test_nothing_can_be_built_before_fire() -> void:
	var sim: Simulation = SimFixture.new_sim(2, false)
	for _tick: int in DAY * 10:
		sim.advance_ticks(1)
		sim.world.resources[&"wood"] = 50
	assert_eq(sim.world.event_counts.get(&"building_opportunity", 0), 0)


func test_the_first_decision_is_about_fire() -> void:
	for rng_seed: int in SEEDS:
		var sim: Simulation = SimFixture.new_sim(rng_seed, false)
		SimFixture.advance_until(sim, func() -> bool: return not sim.world.pending.is_empty(), DAY * 6)
		assert_eq(sim.world.pending.size(), 1, "seed %d: a decision opened" % rng_seed)
		var first: StringName = sim.world.pending[0].event_id
		assert_true(
			first == &"fire_from_storm" or first == &"fire_from_sparks",
			"seed %d: first decision was %s" % [rng_seed, first]
		)


func test_accepting_lights_the_fire() -> void:
	for rng_seed: int in SEEDS:
		var sim: Simulation = SimFixture.new_sim(rng_seed, false)
		var bot: DecisionBot = DecisionBot.new()
		var used: int = SimFixture.advance_until_flag_with(sim, bot, &"fire_found", DAY * 6)
		assert_gt(used, 0, "seed %d: fire was found" % rng_seed)
		assert_true(sim.world.has_achievement(&"fire"))


func test_waiting_for_the_embers_still_ends_with_fire() -> void:
	for rng_seed: int in SEEDS:
		var sim: Simulation = SimFixture.new_sim(rng_seed, false)
		for _tick: int in DAY * 14:
			sim.advance_ticks(1)
			for decision: PendingDecision in sim.world.pending.duplicate():
				var event: EventDef = sim.content.get_event(decision.event_id)
				var decline: StringName = &"wait_for_embers" if event.id == &"fire_from_storm" \
						else &"tend_the_spark"
				if event.get_choice(decline) != null:
					sim.resolve_decision(decision.id, decline)
				else:
					sim.world.pending.erase(decision)
			if sim.world.has_flag(&"fire_found"):
				break
		assert_true(sim.world.has_flag(&"fire_found"), "seed %d: fire came anyway" % rng_seed)
		assert_gt(SimFixture.journal_index(sim.world, "embers"), -1)


func test_the_sparks_route_works_without_the_storm() -> void:
	var sim: Simulation = SimFixture.new_sim(4, false)
	SimFixture.set_traits(sim, [
		[VillagerState.TRAIT_INDUSTRIOUS, VillagerState.TRAIT_SOCIAL],
		[VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING],
		[VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING],
	])
	var used: int = SimFixture.advance_until_pending(sim, &"fire_from_sparks", DAY * 10)
	assert_gt(used, 0, "The industrious one strikes a spark")
	assert_eq(sim.world.event_counts.get(&"fire_from_storm", 0), 0, "Nobody curious to go")
	var decision: PendingDecision = SimFixture.pending_for(sim, &"fire_from_sparks")
	assert_true(sim.resolve_decision(decision.id, &"blow_on_it"))
	assert_true(sim.world.has_flag(&"fire_found"))
	assert_true(sim.world.has_achievement(&"fire"))


func test_embers_are_dropped_if_fire_was_already_lit() -> void:
	var sim: Simulation = SimFixture.new_sim(6, false)
	var decision: PendingDecision = null
	sim.fire_event(sim.content.get_event(&"fire_from_storm"), sim.world.villagers[0])
	decision = SimFixture.pending_for(sim, &"fire_from_storm")
	assert_true(sim.resolve_decision(decision.id, &"wait_for_embers"))
	SimFixture.light_fire(sim.world)
	sim.advance_ticks(100)
	assert_eq(SimFixture.journal_index(sim.world, "glowing embers"), -1)


func test_fire_is_the_first_achievement() -> void:
	var sim: Simulation = SimFixture.new_sim(3, false)
	var bot: DecisionBot = DecisionBot.new()
	SimFixture.advance_until_flag_with(sim, bot, &"fire_found", DAY * 6)
	assert_eq(sim.world.achievements[0], &"fire")
