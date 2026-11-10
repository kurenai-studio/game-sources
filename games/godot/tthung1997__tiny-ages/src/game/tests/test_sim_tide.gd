extends McpTestSuite
## The tide and what it asks (issue #9): a pure function of the tick, a condition the content can
## use, and the forks that only open while the sea is out.

const DAY: int = SimFixture.TICKS_PER_DAY
const CROSSINGS: Array[StringName] = [&"stepping_stones", &"log_bridge"]


func suite_name() -> String:
	return "sim_tide"


## A tick, from `from`, at which the sea is low (or not low).
func _find_tick(config: SimConfig, from: int, low: bool) -> int:
	for tick: int in range(from, from + 100):
		if config.is_low_tide(tick) == low:
			return tick
	return -1


func test_the_tide_rises_and_falls_between_zero_and_one() -> void:
	var config: SimConfig = SimFixture.load_config()
	var lowest: float = 1.0
	var highest: float = 0.0
	for tick: int in 200:
		var level: float = config.tide_at(tick)
		assert_true(level >= 0.0 and level <= 1.0)
		lowest = minf(lowest, level)
		highest = maxf(highest, level)
	assert_true(lowest < 0.05, "It goes right out")
	assert_true(highest > 0.95, "And comes right in")


func test_low_tide_is_a_part_of_the_time_that_drifts_through_the_day() -> void:
	var config: SimConfig = SimFixture.load_config()
	var low: int = 0
	var hours: Dictionary = {}
	for tick: int in DAY * 30:
		if config.is_low_tide(tick):
			low += 1
			hours[config.hour_of(tick)] = true
	var share: float = float(low) / float(DAY * 30)
	assert_true(share > 0.15 and share < 0.45, "Low about a third of the time, was %f" % share)
	assert_gt(hours.size(), 12, "It does not always fall at the same hours")


func test_the_tide_is_the_same_whether_played_through_or_caught_up() -> void:
	var live: Simulation = SimFixture.new_sim()
	var away: Simulation = SimFixture.new_sim()
	live.advance_ticks(DAY * 5)
	away.advance_ticks(DAY * 5)
	assert_eq(live.config.tide_at(live.world.tick), away.config.tide_at(away.world.tick))


func test_the_tide_condition_follows_the_sea_and_can_be_negated() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var low: SimCondition = SimCondition.new()
	low.kind = SimCondition.Kind.TIDE_LOW
	var high: SimCondition = SimCondition.new()
	high.kind = SimCondition.Kind.TIDE_LOW
	high.negate = true
	sim.world.tick = _find_tick(sim.config, 0, true)
	assert_true(low.is_met(sim.world, sim.config))
	assert_false(high.is_met(sim.world, sim.config))
	sim.world.tick = _find_tick(sim.config, 0, false)
	assert_false(low.is_met(sim.world, sim.config))
	assert_true(high.is_met(sim.world, sim.config))


func _cave_sim_with(crossing: StringName) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 230)
	sim.world.flags[crossing] = true
	return sim


## Marks every other one-off decision as already asked, so the backlog of a jumped clock does not
## keep the decision slot busy while the sea is out.
func _quiet_the_others(sim: Simulation, keep: StringName) -> void:
	for event: EventDef in sim.content.events:
		if event.is_decision() and event.id != keep:
			sim.world.event_counts[event.id] = 1


func test_the_low_tide_fork_needs_a_crossing_and_the_sea_out() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for crossing: StringName in CROSSINGS:
		var event: EventDef = content.get_event(
			&"low_tide_stones" if crossing == &"stepping_stones" else &"low_tide_log"
		)
		assert_true(event != null, "A low tide fork for %s" % crossing)
		var sim: Simulation = _cave_sim_with(crossing)
		sim.world.tick = _find_tick(sim.config, sim.world.tick, true)
		assert_true(SimCondition.all_met(event.requires, sim.world, sim.config), "%s" % crossing)
		sim.world.tick = _find_tick(sim.config, sim.world.tick, false)
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config), "Not at high tide"
		)
		var other: StringName = &"stepping_stones"
		if crossing == other:
			other = &"log_bridge"
		sim.world.flags.erase(crossing)
		sim.world.flags[other] = true
		sim.world.tick = _find_tick(sim.config, sim.world.tick, true)
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config),
			"Only for the crossing that was laid"
		)


func test_the_low_tide_fork_gets_asked_and_both_answers_work() -> void:
	for answer: Array in [
		[&"gather_shellfish", &"food", &"shellfish_gathered"],
		[&"comb_the_tideline", &"wood", &"driftwood_gathered"],
	]:
		var sim: Simulation = _cave_sim_with(&"stepping_stones")
		_quiet_the_others(sim, &"low_tide_stones")
		var asked: int = SimFixture.advance_until_asked(sim, &"low_tide_stones", DAY * 12)
		assert_gt(asked, 0, "It is asked within a few tides")
		var decision: PendingDecision = SimFixture.pending_for(sim, &"low_tide_stones")
		var before: int = sim.world.resource_amount(answer[1])
		assert_true(sim.resolve_decision(decision.id, answer[0]))
		assert_true(sim.world.has_flag(answer[2]))
		assert_true(sim.world.resource_amount(answer[1]) >= before + 5)


func test_a_question_asked_at_low_tide_waits_when_the_sea_comes_back() -> void:
	var sim: Simulation = _cave_sim_with(&"log_bridge")
	_quiet_the_others(sim, &"low_tide_log")
	assert_gt(SimFixture.advance_until_asked(sim, &"low_tide_log", DAY * 12), 0)
	sim.world.tick = _find_tick(sim.config, sim.world.tick, false)
	sim.withdraw_stale_decisions()
	assert_true(SimFixture.pending_for(sim, &"low_tide_log") != null, "Waiting is not punished")


func _settled_sim_with(crossing: StringName) -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	sim.world.era_started_tick -= DAY * 330
	sim.world.flags[crossing] = true
	return sim


func test_the_weir_fork_is_settled_low_tide_and_has_two_real_answers() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var event: EventDef = content.get_event(&"fish_on_the_turn_stones")
	var sim: Simulation = _settled_sim_with(&"stepping_stones")
	sim.world.tick = _find_tick(sim.config, sim.world.tick, true)
	assert_true(SimCondition.all_met(event.requires, sim.world, sim.config))
	var cave: Simulation = _cave_sim_with(&"stepping_stones")
	cave.world.tick = _find_tick(cave.config, cave.world.tick, true)
	assert_false(
		SimCondition.all_met(event.requires, cave.world, cave.config), "Not in the Cave Age"
	)
	sim.world.resources[&"wood"] = 10
	sim.fire_event(event, null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"fish_on_the_turn_stones")
	assert_true(sim.resolve_decision(decision.id, &"build_a_weir"))
	assert_true(sim.world.has_flag(&"tide_weir"))
	assert_eq(sim.world.resource_amount(&"wood"), 4, "The weir costs six wood")


func test_the_boat_fork_gives_a_different_boat_to_each_answer() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var event: EventDef = content.get_event(&"a_boat_for_the_river")
	for answer: Array in [[&"hollow_a_dugout", &"dugout_canoe"], [&"bind_a_raft", &"reed_raft"]]:
		var sim: Simulation = _settled_sim_with(&"stepping_stones")
		sim.world.resources[&"wood"] = 10
		sim.fire_event(event, null)
		var decision: PendingDecision = SimFixture.pending_for(sim, &"a_boat_for_the_river")
		assert_true(sim.resolve_decision(decision.id, answer[0]))
		assert_true(sim.world.has_flag(answer[1]))
	var poor: Simulation = _settled_sim_with(&"stepping_stones")
	poor.world.resources[&"wood"] = 0
	poor.fire_event(event, null)
	var waiting: PendingDecision = SimFixture.pending_for(poor, &"a_boat_for_the_river")
	assert_false(poor.resolve_decision(waiting.id, &"hollow_a_dugout"), "A dugout needs wood")
	assert_true(poor.resolve_decision(waiting.id, &"bind_a_raft"), "A raft never does")


func test_the_content_still_validates() -> void:
	assert_eq(SimFixture.load_content().validate().size(), 0)
