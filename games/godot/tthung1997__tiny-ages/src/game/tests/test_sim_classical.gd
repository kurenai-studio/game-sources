extends McpTestSuite
## The Classical Age (docs/ages.md, "Classical Age"): its gate, its turn, six hidden milestones each
## with more than one road, the forks between them and the three that look toward a later age.

const DAY: int = SimFixture.TICKS_PER_DAY
const IRON_SIX: Array[StringName] = [
	&"first_bloom", &"fuller_harvest", &"the_hill_fort", &"silver_by_weight", &"written_word",
	&"name_abroad",
]
const MILESTONES: Array[StringName] = [
	&"paved_streets", &"water_from_afar", &"written_law", &"the_square", &"lamp_and_stage",
	&"wider_world",
]
## Era day each milestone opens (CLASSICAL_DAY in tools/build_sim_content.gd).
const OPENS: Dictionary = {
	&"paved_streets": 18, &"water_from_afar": 54, &"written_law": 108, &"the_square": 162,
	&"lamp_and_stage": 216, &"wider_world": 252,
}
## Everything a group may have answered in the Iron Age that a Classical road reads, and nothing
## the guaranteed Iron milestones do not already set.
const IRON_ANSWERS: Array[StringName] = [
	&"cut_stone", &"timber_town", &"well_dug", &"well_carriers", &"market_day", &"council",
	&"learned_words", &"taught_words", &"festival", &"standing_stone", &"coin_tree",
]
## A road that is open to every group asks for nothing a group may lack: only the age, its day and
## an earlier milestone of the age.
const OPEN_KINDS: Array[int] = [
	SimCondition.Kind.ERA_AT_LEAST, SimCondition.Kind.ERA_DAYS_AT_LEAST,
	SimCondition.Kind.ACHIEVEMENT_EARNED,
]
const LATE_ROADS: Array[StringName] = [
	&"shared_doorsteps", &"rain_into_a_basin", &"a_promise_worth_keeping", &"a_shaded_place",
	&"a_bench_for_reading", &"craftspeople_on_the_road",
]
const OVERTURES: Array[StringName] = [
	&"who_keeps_the_water_running", &"a_book_for_the_journey", &"when_the_market_returns",
]


func suite_name() -> String:
	return "sim_classical"


func _content() -> ContentLibrary:
	return SimFixture.load_content()


func _classical(rng_seed: int = 1, path: StringName = &"path_assembly") -> Simulation:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	for era_id: StringName in [&"settled", &"bronze", &"iron"]:
		sim.advance_era(era_id)
	for key: StringName in IRON_SIX:
		sim.world.achievements.append(key)
	# What the Iron milestones' own roads always set.
	for flag: StringName in [&"letters", &"hill_fort", &"coin_struck", &"known_abroad"]:
		sim.world.flags[flag] = true
	sim.advance_era(&"classical")
	sim.world.flags[path] = true
	return sim


## A Classical world where the group has done and answered everything a road could read, except the
## milestone `missing` (and the milestones that depend on it).
func _prepared(missing: StringName) -> Simulation:
	var sim: Simulation = _classical()
	sim.world.flags[&"path_league"] = true
	for flag: StringName in IRON_ANSWERS:
		sim.world.flags[flag] = true
	for key: StringName in MILESTONES:
		if key != missing and not sim.world.has_achievement(key):
			sim.world.achievements.append(key)
	sim.world.resources[&"wood"] = 60
	sim.world.resources[&"food"] = 40
	return sim


func _gate() -> EraDef:
	return _content().get_era(&"classical")


func _grant_gate(sim: Simulation) -> void:
	for key: StringName in _gate().required_achievements:
		if not sim.world.has_achievement(key):
			sim.world.achievements.append(key)


func _iron_age(sim: Simulation) -> void:
	for era_id: StringName in [&"settled", &"bronze", &"iron"]:
		sim.advance_era(era_id)


func _age_the_iron(sim: Simulation, ticks: int) -> void:
	sim.world.era_started_tick = sim.world.tick - ticks


# ---- The gate and the turn ----------------------------------------------------------------------

func test_the_classical_age_follows_the_iron_age_and_takes_five_days() -> void:
	var gate: EraDef = _gate()
	assert_eq(gate.order, 4)
	assert_eq(gate.min_ticks_in_previous_era, 8640)
	assert_eq(gate.turn_event, &"a_seat_at_the_table")
	for key: StringName in IRON_SIX:
		assert_true(gate.required_achievements.has(key), "The gate asks for %s" % key)
	assert_eq(gate.required_achievements.size(), IRON_SIX.size())


func test_the_gate_stays_shut_without_every_iron_milestone_and_the_time() -> void:
	for missing: StringName in IRON_SIX:
		var sim: Simulation = SimFixture.new_sim()
		_iron_age(sim)
		_grant_gate(sim)
		sim.world.achievements.erase(missing)
		_age_the_iron(sim, _gate().min_ticks_in_previous_era)
		sim.advance_ticks(DAY)
		assert_eq(sim.world.era, &"iron", "Without %s the age must not turn" % missing)
	var early: Simulation = SimFixture.new_sim()
	_iron_age(early)
	_grant_gate(early)
	_age_the_iron(early, _gate().min_ticks_in_previous_era - DAY * 2)
	early.advance_ticks(DAY)
	assert_eq(early.world.event_counts.get(&"a_seat_at_the_table", 0), 0, "Not before the time")


func test_when_the_gate_opens_the_player_is_asked_how_to_take_a_seat() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_iron_age(sim)
	_grant_gate(sim)
	_age_the_iron(sim, _gate().min_ticks_in_previous_era)
	sim.advance_ticks(1)
	assert_true(SimFixture.pending_for(sim, &"a_seat_at_the_table") != null, "The turn opens")
	assert_eq(sim.world.era, &"iron", "Still the Iron Age until the player answers")


func test_either_answer_turns_the_age_and_sets_the_path() -> void:
	for row: Array in [
		[&"keep_our_own_ways", &"path_assembly"], [&"take_a_place_among_theirs", &"path_league"],
	]:
		var sim: Simulation = SimFixture.new_sim()
		_iron_age(sim)
		_grant_gate(sim)
		_age_the_iron(sim, _gate().min_ticks_in_previous_era)
		sim.advance_ticks(1)
		var turn: PendingDecision = SimFixture.pending_for(sim, &"a_seat_at_the_table")
		assert_true(sim.resolve_decision(turn.id, row[0]))
		assert_eq(sim.world.era, &"classical")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		assert_true(sim.world.has_flag(row[1]))


func test_the_turn_needs_none_of_the_optional_iron_flags() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_iron_age(sim)
	_grant_gate(sim)
	for flag: StringName in IRON_ANSWERS:
		assert_false(sim.world.has_flag(flag), "%s is optional" % flag)
	_age_the_iron(sim, _gate().min_ticks_in_previous_era)
	sim.advance_ticks(1)
	assert_true(SimFixture.pending_for(sim, &"a_seat_at_the_table") != null)


func test_the_iron_ages_lead_in_forks_are_not_asked_once_the_next_age_opens() -> void:
	var sim: Simulation = _classical()
	for event_id: StringName in [
		&"a_stone_with_a_name", &"a_rider_with_a_sash", &"a_table_for_strangers",
	]:
		var event: EventDef = _content().get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + 400)
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config, sim.world.villagers[0]),
			"%s is not asked in the Classical Age" % event_id
		)


# ---- Milestones --------------------------------------------------------------------------------

## Every (event, answer) in the content that earns `milestone`.
func _roads(milestone: StringName) -> Array:
	var roads: Array = []
	for event: EventDef in _content().events:
		for choice: ChoiceDef in event.choices:
			for effect: SimEffect in choice.effects:
				if effect.kind == SimEffect.Kind.ACHIEVEMENT and effect.key == milestone:
					roads.append([event.id, choice.id])
	return roads


func test_every_milestone_has_more_than_one_road() -> void:
	for milestone: StringName in MILESTONES:
		var events: Dictionary = {}
		for road: Array in _roads(milestone):
			events[road[0]] = true
		assert_gt(events.size(), 1, "%s has more than one road" % milestone)


func test_every_answer_on_every_road_earns_the_milestone() -> void:
	for milestone: StringName in MILESTONES:
		for road: Array in _roads(milestone):
			var sim: Simulation = _prepared(milestone)
			var event: EventDef = sim.content.get_event(road[0])
			sim.fire_event(event, sim.world.villagers[0])
			var decision: PendingDecision = SimFixture.pending_for(sim, event.id)
			assert_true(decision != null, "%s is asked" % event.id)
			if decision == null:
				continue
			assert_true(sim.resolve_decision(decision.id, road[1]), "%s: %s" % [event.id, road[1]])
			assert_true(sim.world.has_achievement(milestone), "%s via %s" % [milestone, road[1]])


func test_every_road_to_the_last_milestone_connects_the_towns() -> void:
	for road: Array in _roads(&"wider_world"):
		var sim: Simulation = _prepared(&"wider_world")
		var event: EventDef = sim.content.get_event(road[0])
		sim.fire_event(event, sim.world.villagers[0])
		sim.resolve_decision(SimFixture.pending_for(sim, event.id).id, road[1])
		assert_true(sim.world.has_flag(&"towns_connected"), "%s sets towns_connected" % road[1])


func test_a_late_road_is_open_to_every_group() -> void:
	for event_id: StringName in LATE_ROADS:
		var event: EventDef = _content().get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		for condition: SimCondition in event.requires:
			assert_true(
				OPEN_KINDS.has(int(condition.kind)),
				"%s asks for nothing a group may lack (%s)" % [event_id, condition.key]
			)
		for choice: ChoiceDef in event.choices:
			for condition: SimCondition in choice.requires:
				assert_true(false, "%s's answer %s asks for %s" % [event_id, choice.id, condition.key])


func test_a_milestones_earlier_milestone_gates_its_roads() -> void:
	for row: Array in [
		[&"written_law", &"paved_streets"], [&"the_square", &"written_law"],
		[&"lamp_and_stage", &"the_square"], [&"wider_world", &"the_square"],
		[&"wider_world", &"water_from_afar"],
	]:
		var sim: Simulation = _prepared(row[0])
		sim.world.achievements.erase(row[1])
		var open: int = 0
		for road: Array in _roads(row[0]):
			var event: EventDef = sim.content.get_event(road[0])
			if SimCondition.all_met(
				event.requires, sim.world, sim.config, sim.world.villagers[0]
			):
				open += 1
		assert_eq(open, 0, "%s waits for %s" % [row[0], row[1]])


func test_the_age_adds_no_building() -> void:
	var content: ContentLibrary = _content()
	for building: BuildingDef in content.buildings:
		assert_false(String(building.id).begins_with("classical"), "No Classical building")
	assert_eq(content.buildings.size(), 10, "Classical adds no standalone building")


# ---- Stories -----------------------------------------------------------------------------------

func test_the_last_forks_look_ahead_without_promising_a_later_age() -> void:
	for event_id: StringName in OVERTURES:
		var event: EventDef = _content().get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		for choice: ChoiceDef in event.choices:
			for effect: SimEffect in choice.effects:
				assert_false(
					effect.kind == SimEffect.Kind.ADVANCE_ERA, "%s does not turn the age" % event_id
				)
		assert_eq(_content().next_era(4), null, "There is no age after the Classical Age yet")


func test_every_story_fork_sets_flags_a_choice_can_remember() -> void:
	var content: ContentLibrary = _content()
	for event: EventDef in content.events:
		var from_classical: bool = false
		for condition: SimCondition in event.requires:
			if condition.kind == SimCondition.Kind.ERA_AT_LEAST and condition.amount == 4 \
					and not condition.negate:
				from_classical = true
		if not from_classical or not event.is_decision():
			continue
		var flags: Dictionary = {}
		for choice: ChoiceDef in event.choices:
			for effect: SimEffect in choice.effects:
				if effect.kind == SimEffect.Kind.SET_FLAG:
					flags[effect.key] = true
		assert_true(
			flags.size() >= event.choices.size(), "%s: each answer sets its own flag" % event.id
		)


# ---- A whole age --------------------------------------------------------------------------------

func test_the_cheap_gate_skips_an_event_that_ended_with_its_age_and_never_a_live_one() -> void:
	var content: ContentLibrary = _content()
	var ended: EventDef = content.get_event(&"a_stone_with_a_name")
	assert_true(ended.may_be_open(1000, 3, 400), "It is still open in the Iron Age")
	assert_false(ended.may_be_open(1000, 4, 400), "...and skipped once the Classical Age opens")
	var sim: Simulation = _classical()
	SimFixture.jump_to_day(sim, 2000)
	sim.world.era_started_tick = sim.world.tick - 400 * DAY
	var day: int = sim.config.day_of(sim.world.tick)
	var era_day: int = 400
	for event: EventDef in content.events:
		if event.may_be_open(day, sim.world.era_order, era_day):
			continue
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config, sim.world.villagers[0]),
			"%s is skipped, so it must not be open" % event.id
		)


func test_a_player_who_accepts_everything_finishes_the_age_on_either_path() -> void:
	_assert_finishes(1, &"path_assembly", 0)
	_assert_finishes(2, &"path_league", 0)


func test_a_player_who_passes_on_things_first_still_finishes() -> void:
	_assert_finishes(1, &"path_league", 2)


## Plays the Classical Age from its first day with no Iron answer to lean on. `declines` is how many
## times the player passes on each question (choosing the last answer) before accepting. Every
## milestone must be earned, none before its day.
func _assert_finishes(rng_seed: int, path: StringName, declines: int) -> void:
	var label: String = "seed %d, %s, declining %d" % [rng_seed, path, declines]
	var sim: Simulation = _classical(rng_seed, path)
	var start: int = sim.world.tick
	var earned: Dictionary = {}
	sim.achievement_earned.connect(
		func(key: StringName, _title: String) -> void: earned[key] = sim.world.tick - start
	)
	var bot: DecisionBot = DecisionBot.new()
	var passed: Dictionary = {}
	for _tick: int in DAY * 340:
		sim.advance_ticks(1)
		_pass_on_first_asks(sim, passed, declines)
		bot.answer_all(sim)
	for milestone: StringName in MILESTONES:
		assert_true(earned.has(milestone), "%s: %s was earned" % [label, milestone])
		if earned.has(milestone):
			assert_gt(
				earned[milestone] + 1, OPENS[milestone] * DAY,
				"%s: %s came before day %d" % [label, milestone, OPENS[milestone]]
			)
	assert_true(sim.world.has_flag(&"towns_connected"), "%s: the towns are connected" % label)
	assert_eq(sim.world.era, &"classical", "%s: the age stays open-ended" % label)


func _pass_on_first_asks(sim: Simulation, passed: Dictionary, declines: int) -> void:
	for decision: PendingDecision in sim.world.pending.duplicate():
		if passed.get(decision.event_id, 0) >= declines:
			continue
		var event: EventDef = sim.content.get_event(decision.event_id)
		var subject: VillagerState = sim.world.find_villager(decision.subject_id)
		for index: int in range(event.choices.size() - 1, -1, -1):
			if sim.choice_available(event.choices[index], subject):
				passed[event.id] = passed.get(event.id, 0) + 1
				sim.resolve_decision(decision.id, event.choices[index].id)
				break
