extends McpTestSuite
## An age's entry gate: hidden required achievements plus a minimum time in the previous age.
## When it opens the age's turn event asks how to settle (never whether), and every kind of
## player gets there.

const DAY: int = SimFixture.TICKS_PER_DAY
const SEEDS: Array[int] = [1, 2]


func suite_name() -> String:
	return "sim_gate"


func _settled() -> EraDef:
	return SimFixture.load_content().get_era(&"settled")


func _grant_all(sim: Simulation) -> void:
	for key: StringName in _settled().required_achievements:
		if not sim.world.has_achievement(key):
			sim.world.achievements.append(key)


func _age_the_cave(sim: Simulation, ticks: int) -> void:
	sim.world.era_started_tick = sim.world.tick - ticks


func test_the_settled_age_takes_days_of_real_time() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var real_days: float = float(_settled().min_ticks_in_previous_era) \
			* sim.config.seconds_per_tick() / 86400.0
	assert_gt(real_days, 3.0, "The minimum should stop luck rushing the age")


func test_the_gate_stays_shut_without_the_milestones() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_age_the_cave(sim, 1_000_000)
	sim.advance_ticks(DAY)
	assert_eq(sim.world.era, &"cave")
	assert_eq(sim.world.event_counts.get(&"seeds_of_a_new_life", 0), 0)


func test_the_gate_stays_shut_before_the_minimum_time() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_grant_all(sim)
	_age_the_cave(sim, _settled().min_ticks_in_previous_era - DAY * 2)
	sim.advance_ticks(DAY)
	assert_eq(sim.world.event_counts.get(&"seeds_of_a_new_life", 0), 0)


func test_every_single_milestone_is_needed() -> void:
	for missing: StringName in _settled().required_achievements:
		var sim: Simulation = SimFixture.new_sim()
		_grant_all(sim)
		sim.world.achievements.erase(missing)
		_age_the_cave(sim, _settled().min_ticks_in_previous_era)
		sim.advance_ticks(DAY)
		assert_eq(sim.world.era, &"cave", "Without %s the age must not turn" % missing)
		assert_eq(sim.world.event_counts.get(&"seeds_of_a_new_life", 0), 0)


func test_when_the_gate_opens_the_player_is_asked_how_to_settle() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_grant_all(sim)
	_age_the_cave(sim, _settled().min_ticks_in_previous_era)
	sim.advance_ticks(1)
	var turn: PendingDecision = SimFixture.pending_for(sim, &"seeds_of_a_new_life")
	assert_true(turn != null, "The turn decision opens")
	assert_eq(sim.world.era, &"cave", "Still the Cave Age until the player answers")
	sim.advance_ticks(DAY * 3)
	var turns: int = 0
	for decision: PendingDecision in sim.world.pending:
		if decision.event_id == &"seeds_of_a_new_life":
			turns += 1
	assert_eq(turns, 1, "It is asked once, not every tick")


func test_either_answer_turns_the_age() -> void:
	for choice_id: StringName in [&"settle_field", &"settle_herds"]:
		var sim: Simulation = SimFixture.new_sim()
		_grant_all(sim)
		_age_the_cave(sim, _settled().min_ticks_in_previous_era)
		sim.advance_ticks(1)
		var turn: PendingDecision = SimFixture.pending_for(sim, &"seeds_of_a_new_life")
		assert_true(sim.resolve_decision(turn.id, choice_id))
		assert_eq(sim.world.era, &"settled")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		sim.advance_ticks(DAY * 5)
		assert_eq(sim.world.event_counts.get(&"seeds_of_a_new_life", 0), 1, "Only turns once")


func test_the_choice_shapes_how_the_age_looks() -> void:
	var field: Simulation = SimFixture.new_sim()
	_grant_all(field)
	_age_the_cave(field, _settled().min_ticks_in_previous_era)
	field.advance_ticks(1)
	field.resolve_decision(SimFixture.pending_for(field, &"seeds_of_a_new_life").id, &"settle_field")
	assert_true(field.world.has_flag(&"path_agriculture"))
	assert_false(field.world.has_flag(&"path_herding"))
	var herds: Simulation = SimFixture.new_sim()
	_grant_all(herds)
	_age_the_cave(herds, _settled().min_ticks_in_previous_era)
	herds.advance_ticks(1)
	herds.resolve_decision(SimFixture.pending_for(herds, &"seeds_of_a_new_life").id, &"settle_herds")
	assert_true(herds.world.has_flag(&"path_herding"))


func test_time_while_the_game_is_closed_counts() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_grant_all(sim)
	var closed_for: float = float(_settled().min_ticks_in_previous_era + 24) \
			* sim.config.seconds_per_tick()
	sim.advance_real_time(SimFixture.START_UNIX + closed_for)
	assert_true(
		SimFixture.pending_for(sim, &"seeds_of_a_new_life") != null,
		"Being away runs down the minimum time"
	)


func test_validation_catches_a_gate_nothing_can_open() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	content.get_era(&"settled").required_achievements.append(&"nothing_grants_this")
	assert_gt(content.validate().size(), 0)


func test_validation_catches_a_turn_choice_that_does_not_advance() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	var turn: EventDef = content.get_event(&"seeds_of_a_new_life")
	turn.choices[0].effects.clear()
	assert_gt(content.validate().size(), 0)


func test_buildings_grant_their_milestones() -> void:
	var sim: Simulation = SimFixture.new_sim()
	for site_id: StringName in [&"knapping_spot", &"drying_rack"]:
		var site: BuildingState = BuildingState.new()
		site.def_id = site_id
		sim.world.buildings.append(site)
		sim.complete_building(site)
	assert_true(sim.world.has_achievement(&"stone_tools"))
	assert_true(sim.world.has_achievement(&"reliable_food"))


func test_a_player_who_accepts_everything_reaches_the_settled_age() -> void:
	for rng_seed: int in SEEDS:
		_assert_reaches_settled(rng_seed, 0)


func test_a_player_who_passes_on_things_first_still_gets_there() -> void:
	for rng_seed: int in SEEDS:
		_assert_reaches_settled(rng_seed, 2)


## Plays from a cold start. `declines` is how many times the player passes on each question
## (picking the last choice, which is the "not now" one where there is one) before accepting.
func _assert_reaches_settled(rng_seed: int, declines: int) -> void:
	var label: String = "seed %d, declining %d times" % [rng_seed, declines]
	var sim: Simulation = SimFixture.new_sim(rng_seed, false)
	var start: int = sim.world.tick
	var bot: DecisionBot = DecisionBot.new()
	var passed: Dictionary = {}
	var limit: int = _settled().min_ticks_in_previous_era + DAY * 120
	for _tick: int in limit:
		sim.advance_ticks(1)
		_pass_on_first_asks(sim, passed, declines)
		bot.answer_all(sim)
		if sim.world.era == &"settled":
			break
	assert_eq(sim.world.era, &"settled", "%s: reached the Settled Age" % label)
	assert_gt(
		sim.world.era_started_tick - start, _settled().min_ticks_in_previous_era - 1,
		"%s: not before the minimum time" % label
	)
	for key: StringName in _settled().required_achievements:
		assert_true(sim.world.has_achievement(key), "%s: earned %s" % [label, key])


func _pass_on_first_asks(sim: Simulation, passed: Dictionary, declines: int) -> void:
	for decision: PendingDecision in sim.world.pending.duplicate():
		if passed.get(decision.event_id, 0) >= declines:
			continue
		var event: EventDef = sim.content.get_event(decision.event_id)
		if event.id == &"seeds_of_a_new_life":
			continue
		var subject: VillagerState = sim.world.find_villager(decision.subject_id)
		for index: int in range(event.choices.size() - 1, -1, -1):
			if sim.choice_available(event.choices[index], subject):
				passed[event.id] = passed.get(event.id, 0) + 1
				sim.resolve_decision(decision.id, event.choices[index].id)
				break
