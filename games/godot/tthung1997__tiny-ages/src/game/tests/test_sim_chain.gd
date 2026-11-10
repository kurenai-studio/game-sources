extends McpTestSuite
## The first vertical slice, from the MVP concept: build the Lookout, a curious villager wants
## to scout, returns with a seed, it is planted, it flowers and a rare butterfly comes. Turning
## that into the Settled Age is gated and is tested in test_sim_gate.gd.
## Each step is a consequence of the previous player choice. Run across several seeds so the
## chain does not depend on one lucky roll.

const SEEDS: Array[int] = [1, 2, 3, 4, 5, 6, 7, 8]
const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "sim_chain"


func test_the_exploration_chain_plays_out_for_every_seed() -> void:
	for rng_seed: int in SEEDS:
		_run_chain(rng_seed)


func test_the_chain_is_reproducible_from_a_seed() -> void:
	var first: Simulation = SimFixture.new_sim(11)
	var second: Simulation = SimFixture.new_sim(11)
	_play_through_hut_and_exploration(first)
	_play_through_hut_and_exploration(second)
	assert_eq(SimFixture.snapshot(first.world), SimFixture.snapshot(second.world))


func test_walking_out_together_still_brings_the_seed_home() -> void:
	var sim: Simulation = SimFixture.new_sim(2)
	_build_hut(sim)
	assert_gt(SimFixture.advance_until_asked(sim, &"curious_explorer", DAY * 20), 0)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	assert_true(sim.resolve_decision(decision.id, &"walk_together"))
	assert_true(sim.world.has_flag(&"scouted_together"))
	var returned: int = SimFixture.advance_until_pending(sim, &"explorer_returns", DAY * 4)
	assert_gt(returned, 0, "Going together is slower, but the seed still comes home")
	assert_eq(sim.world.item_count(&"strange_seed"), 1)


func test_without_a_lookout_the_scout_still_asks_a_month_later() -> void:
	var sim: Simulation = SimFixture.new_sim(2)
	SimFixture.jump_to_day(sim, 216)
	SimFixture.advance_until_asked(sim, &"curious_explorer", DAY * 20)
	assert_eq(sim.world.event_counts.get(&"curious_explorer", 0), 0)
	var late: int = SimFixture.advance_until_asked(sim, &"restless_explorer", DAY * 40)
	assert_gt(late, 0, "A group that never built a Lookout still gets its scout")


func _run_chain(rng_seed: int) -> void:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	var label: String = "seed %d" % rng_seed
	_build_hut(sim)
	assert_true(sim.world.has_building(&"lookout"), "%s: lookout built" % label)

	var asked: int = SimFixture.advance_until_asked(sim, &"curious_explorer", DAY * 20)
	assert_gt(asked, 0, "%s: a scout asks to explore" % label)
	if asked < 0:
		return
	var ask: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	var scout: VillagerState = sim.world.find_villager(ask.subject_id)
	assert_true(scout.has_trait(VillagerState.TRAIT_CURIOUS), "%s: the curious one asks" % label)
	assert_true(sim.resolve_decision(ask.id, &"encourage"))
	assert_true(scout.is_away(), "%s: the scout leaves" % label)
	assert_eq(scout.profession, &"scout")

	var returned: int = SimFixture.advance_until_pending(sim, &"explorer_returns", DAY * 3)
	assert_gt(returned, 0, "%s: the scout returns" % label)
	if returned < 0:
		return
	assert_false(scout.is_away())
	assert_eq(sim.world.item_count(&"strange_seed"), 1, "%s: with a seed" % label)
	assert_true(sim.world.has_flag(&"western_forest_explored"))
	var found: PendingDecision = SimFixture.pending_for(sim, &"explorer_returns")
	assert_true(sim.resolve_decision(found.id, &"plant_it"))
	assert_eq(sim.world.plants.size(), 1, "%s: the seed is planted" % label)
	assert_eq(sim.world.item_count(&"strange_seed"), 0)

	var bloomed: int = SimFixture.advance_until_flag(sim, &"strange_flower_bloomed", DAY * 4)
	assert_gt(bloomed, 0, "%s: it flowers" % label)
	assert_true(sim.world.has_achievement(&"unexpected_garden"))

	var visited: int = SimFixture.advance_until_flag(sim, &"butterfly_seen", DAY * 30)
	assert_gt(visited, 0, "%s: a rare butterfly visits" % label)
	assert_true(sim.world.has_achievement(&"rare_visitor"))
	_assert_journal_tells_the_story(sim.world, scout.display_name, label)


func _assert_journal_tells_the_story(world: WorldState, scout: String, label: String) -> void:
	var beats: Array[String] = [
		"Construction of the Lookout began",
		"The Lookout was completed",
		"%s set off to scout" % scout,
		"%s returned from the western forest" % scout,
		"%s pressed the strange seed" % scout,
		"The strange seed flowered",
		"A butterfly nobody had seen before",
		"Achievement: A Rare Visitor",
	]
	var previous: int = -1
	for beat: String in beats:
		var index: int = SimFixture.journal_index(world, beat)
		assert_gt(index, previous, "%s: journal has '%s' after the previous beat" % [label, beat])
		previous = index


## Waits for the building decision, picks the Lookout, and waits for it to be built. There is
## nothing to choose between before day 18, so the first building decision is not asked until then.
func _build_hut(sim: Simulation) -> void:
	SimFixture.jump_to_day(sim, 18)
	sim.world.resources[&"wood"] = 12
	var opened: int = SimFixture.advance_until_pending(sim, &"building_opportunity", DAY * 12)
	assert_gt(opened, 0, "A building decision opens once there are two buildings to choose from")
	if opened < 0:
		return
	var decision: PendingDecision = SimFixture.pending_for(sim, &"building_opportunity")
	assert_true(sim.resolve_decision(decision.id, &"build_lookout"))
	var built: int = SimFixture.advance_until_built(sim, &"lookout", DAY * 8)
	assert_gt(built, 0, "The lookout gets built")
	# The scout's story is staged for later in the age.
	SimFixture.jump_to_day(sim, 216)


func _play_through_hut_and_exploration(sim: Simulation) -> void:
	_build_hut(sim)
	SimFixture.advance_until_asked(sim, &"curious_explorer", DAY * 20)
	var ask: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	if ask == null:
		return
	sim.resolve_decision(ask.id, &"encourage")
	SimFixture.advance_until_pending(sim, &"explorer_returns", DAY * 3)
	var found: PendingDecision = SimFixture.pending_for(sim, &"explorer_returns")
	if found != null:
		sim.resolve_decision(found.id, &"plant_in_shade")
	sim.advance_ticks(DAY * 5)
