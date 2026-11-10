extends McpTestSuite
## The Iron Age (docs/ages.md, "Iron Age"): its gate, its turn, six hidden milestones each with more
## than one road, the forks between them and the three that lead into the next age.

const DAY: int = SimFixture.TICKS_PER_DAY
const SETTLED_SIX: Array[StringName] = [
	&"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth", &"a_village", &"green_stone",
]
const BRONZE_SIX: Array[StringName] = [
	&"first_casting", &"bronze_alloy", &"mud_brick_walls", &"wheel_and_road", &"a_town",
	&"beyond_the_water",
]
const MILESTONES: Array[StringName] = [
	&"first_bloom", &"fuller_harvest", &"the_hill_fort", &"silver_by_weight", &"written_word",
	&"name_abroad",
]
## Era day each milestone opens (IRON_DAY in tools/build_sim_content.gd); the Bloomery earns the
## first as soon as it stands.
const OPENS: Dictionary = {
	&"first_bloom": 18, &"fuller_harvest": 54, &"the_hill_fort": 108, &"silver_by_weight": 162,
	&"written_word": 216, &"name_abroad": 252,
}
## Everything a group may have answered in the Bronze Age that an Iron road reads.
const BRONZE_ANSWERS: Array[StringName] = [
	&"path_agriculture", &"path_herding", &"good_neighbours", &"town_wall", &"palisade", &"dug_in",
	&"stone_weights", &"handful_weights", &"clay_tablets", &"knot_cords", &"dugout_canoe",
	&"reed_raft", &"road_laid", &"far_shore", &"dark_stone_bell",
]
## A road that is open to every group asks for nothing a group may lack: only the age, its day and
## an earlier milestone of the age.
const OPEN_KINDS: Array[int] = [
	SimCondition.Kind.ERA_AT_LEAST, SimCondition.Kind.ERA_DAYS_AT_LEAST,
	SimCondition.Kind.ACHIEVEMENT_EARNED,
]
const LATE_ROADS: Array[StringName] = [
	&"a_lump_in_the_slag", &"an_axe_at_the_pines", &"ring_the_ridge", &"bind_the_gate_in_iron",
	&"a_mark_in_a_lump", &"copy_the_traders_tablet", &"a_name_for_the_traveller",
]


func suite_name() -> String:
	return "sim_iron"


func _content() -> ContentLibrary:
	return SimFixture.load_content()


func _iron(rng_seed: int = 1, path: StringName = &"path_bloomery") -> Simulation:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	sim.advance_era(&"settled")
	for key: StringName in SETTLED_SIX:
		sim.world.achievements.append(key)
	sim.advance_era(&"bronze")
	for key: StringName in BRONZE_SIX:
		sim.world.achievements.append(key)
	sim.advance_era(&"iron")
	sim.world.flags[path] = true
	return sim


## An Iron world where the group has done and answered everything a road could read, except the
## milestone `missing`.
func _prepared(missing: StringName) -> Simulation:
	var sim: Simulation = _iron()
	sim.world.flags[&"path_ore"] = true
	for flag: StringName in BRONZE_ANSWERS:
		sim.world.flags[flag] = true
	for key: StringName in MILESTONES:
		if key != missing and not sim.world.has_achievement(key):
			sim.world.achievements.append(key)
	for building_id: StringName in [&"trading_post", &"granary"]:
		var state: BuildingState = BuildingState.new()
		state.def_id = building_id
		sim.world.buildings.append(state)
	sim.world.resources[&"wood"] = 60
	sim.world.resources[&"food"] = 40
	return sim


func _gate() -> EraDef:
	return _content().get_era(&"iron")


func _grant_gate(sim: Simulation) -> void:
	for key: StringName in _gate().required_achievements:
		if not sim.world.has_achievement(key):
			sim.world.achievements.append(key)


func _bronze_age(sim: Simulation) -> void:
	sim.advance_era(&"settled")
	sim.advance_era(&"bronze")


func _age_the_bronze(sim: Simulation, ticks: int) -> void:
	sim.world.era_started_tick = sim.world.tick - ticks


# ---- The gate and the turn ----------------------------------------------------------------------

func test_the_iron_age_follows_the_bronze_age_and_takes_five_days() -> void:
	var gate: EraDef = _gate()
	assert_eq(gate.order, 3)
	assert_eq(gate.min_ticks_in_previous_era, 8640)
	assert_eq(gate.turn_event, &"a_harder_fire")
	for key: StringName in BRONZE_SIX:
		assert_true(gate.required_achievements.has(key), "The gate asks for %s" % key)
	assert_eq(gate.required_achievements.size(), BRONZE_SIX.size())


func test_the_gate_stays_shut_without_every_bronze_milestone_and_the_time() -> void:
	for missing: StringName in BRONZE_SIX:
		var sim: Simulation = SimFixture.new_sim()
		_bronze_age(sim)
		_grant_gate(sim)
		sim.world.achievements.erase(missing)
		_age_the_bronze(sim, _gate().min_ticks_in_previous_era)
		sim.advance_ticks(DAY)
		assert_eq(sim.world.era, &"bronze", "Without %s the age must not turn" % missing)
	var early: Simulation = SimFixture.new_sim()
	_bronze_age(early)
	_grant_gate(early)
	_age_the_bronze(early, _gate().min_ticks_in_previous_era - DAY * 2)
	early.advance_ticks(DAY)
	assert_eq(early.world.event_counts.get(&"a_harder_fire", 0), 0, "Not before the time")


func test_when_the_gate_opens_the_player_is_asked_how_to_work_the_dark_stone() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_bronze_age(sim)
	_grant_gate(sim)
	_age_the_bronze(sim, _gate().min_ticks_in_previous_era)
	sim.advance_ticks(1)
	assert_true(SimFixture.pending_for(sim, &"a_harder_fire") != null, "The turn opens")
	assert_eq(sim.world.era, &"bronze", "Still the Bronze Age until the player answers")


func test_either_answer_turns_the_age_and_sets_the_path() -> void:
	for row: Array in [
		[&"work_it_at_home", &"path_bloomery"], [&"follow_it_to_the_hills", &"path_ore"],
	]:
		var sim: Simulation = SimFixture.new_sim()
		_bronze_age(sim)
		_grant_gate(sim)
		_age_the_bronze(sim, _gate().min_ticks_in_previous_era)
		sim.advance_ticks(1)
		var turn: PendingDecision = SimFixture.pending_for(sim, &"a_harder_fire")
		assert_true(sim.resolve_decision(turn.id, row[0]))
		assert_eq(sim.world.era, &"iron")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		assert_true(sim.world.has_flag(row[1]))
		assert_gt(sim.world.housing, sim.content.get_era(&"bronze").housing, "More room in Iron")


func test_the_turn_needs_none_of_the_optional_bronze_flags() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_bronze_age(sim)
	_grant_gate(sim)
	assert_false(sim.world.has_flag(&"dark_stone_bell"))
	assert_false(sim.world.has_flag(&"dark_stone_tried"))
	_age_the_bronze(sim, _gate().min_ticks_in_previous_era)
	sim.advance_ticks(1)
	assert_true(SimFixture.pending_for(sim, &"a_harder_fire") != null)


func test_the_bronze_ages_last_forks_end_its_quiet_stretch_and_expire_with_it() -> void:
	var sim: Simulation = _iron()
	for event_id: StringName in [&"red_water", &"fuel_for_the_long_burn"]:
		var event: EventDef = _content().get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + 400)
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config, sim.world.villagers[0]),
			"%s is not asked once the Bronze Age is over" % event_id
		)


func test_the_iron_ages_last_forks_lead_into_the_next_age() -> void:
	var content: ContentLibrary = _content()
	for event_id: StringName in [
		&"a_stone_with_a_name", &"a_rider_with_a_sash", &"a_table_for_strangers",
	]:
		var event: EventDef = content.get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		var needs_the_outlook: bool = false
		for condition: SimCondition in event.requires:
			if condition.kind == SimCondition.Kind.FLAG_SET and condition.key == &"known_abroad":
				needs_the_outlook = true
		assert_true(needs_the_outlook, "%s reads known_abroad" % event_id)


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
		var buildings: int = 0
		for building: BuildingDef in _content().buildings:
			if building.completion_achievement == milestone:
				buildings += 1
		assert_gt(events.size() + buildings, 1, "%s has more than one road" % milestone)


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


func test_the_roads_set_the_flags_a_later_age_reads() -> void:
	for row: Array in [
		[&"the_hill_fort", &"hill_fort"], [&"silver_by_weight", &"coin_struck"],
		[&"written_word", &"letters"], [&"name_abroad", &"known_abroad"],
	]:
		for road: Array in _roads(row[0]):
			var sim: Simulation = _prepared(row[0])
			var event: EventDef = sim.content.get_event(road[0])
			sim.fire_event(event, sim.world.villagers[0])
			sim.resolve_decision(SimFixture.pending_for(sim, event.id).id, road[1])
			assert_true(sim.world.has_flag(row[1]), "%s sets %s" % [road[1], row[1]])


func test_a_late_road_is_open_to_every_group() -> void:
	for event_id: StringName in LATE_ROADS:
		var event: EventDef = _content().get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		for condition: SimCondition in event.requires:
			assert_true(
				OPEN_KINDS.has(int(condition.kind)),
				"%s asks for nothing a group may lack (%s)" % [event_id, condition.key]
			)


func test_a_milestones_earlier_milestone_gates_its_roads() -> void:
	for row: Array in [
		[&"fuller_harvest", &"first_bloom"], [&"silver_by_weight", &"fuller_harvest"],
		[&"written_word", &"silver_by_weight"], [&"name_abroad", &"silver_by_weight"],
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


func test_the_bloomery_earns_the_first_bloom_and_the_granary_does_not() -> void:
	var sim: Simulation = _iron()
	var granary: BuildingState = BuildingState.new()
	granary.def_id = &"granary"
	sim.world.buildings.append(granary)
	sim.complete_building(granary)
	assert_false(sim.world.has_achievement(&"first_bloom"))
	var bloomery: BuildingState = BuildingState.new()
	bloomery.def_id = &"bloomery"
	sim.world.buildings.append(bloomery)
	sim.complete_building(bloomery)
	assert_true(sim.world.has_achievement(&"first_bloom"))


func test_the_bloomery_and_the_granary_are_a_fork_that_opens_together() -> void:
	var sim: Simulation = _iron()
	sim.world.resources[&"wood"] = 50
	var event: EventDef = sim.content.get_event(&"iron_building_opportunity")
	var bloomery: ChoiceDef = event.get_choice(&"build_bloomery")
	var granary: ChoiceDef = event.get_choice(&"build_granary")
	assert_false(sim.choice_available(bloomery, null), "Nothing on the first day")
	SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + OPENS[&"first_bloom"])
	assert_true(sim.choice_available(bloomery, null))
	assert_true(sim.choice_available(granary, null), "A fork needs both")


func test_the_hill_fort_gives_room() -> void:
	var sim: Simulation = _iron()
	var before: int = sim.world.housing
	sim.world.flags[&"hill_fort"] = true
	sim.refresh_housing()
	assert_eq(sim.world.housing, before + 4)


func test_the_town_may_grow_to_twelve_before_the_next_age() -> void:
	assert_eq(_gate().max_villagers, 12)
	assert_eq(SimFixture.load_config().max_villagers, 14)


func test_the_late_forks_set_the_flags_the_world_shows() -> void:
	for row: Array in [
		[&"a_fire_the_sea_can_see", &"light_the_headland", &"beacon_lit"],
		[&"a_stone_with_a_name", &"stand_it_at_the_crossing", &"standing_stone"],
		[&"a_stone_with_a_name", &"cut_it_over_the_gate", &"gate_name"],
		[&"a_rider_with_a_sash", &"send_a_guide", &"envoy_guided"],
		[&"a_table_for_strangers", &"lay_a_long_table", &"long_table"],
		[&"stone_from_the_hill", &"wedge_out_blocks", &"cut_stone"],
		[&"stone_from_the_hill", &"keep_to_timber_and_earth", &"timber_town"],
	]:
		var sim: Simulation = _prepared(&"never")
		sim.world.flags[&"known_abroad"] = true
		sim.fire_event(sim.content.get_event(row[0]), sim.world.villagers[0])
		var decision: PendingDecision = SimFixture.pending_for(sim, row[0])
		assert_true(decision != null, "%s is asked" % row[0])
		if decision != null:
			assert_true(sim.resolve_decision(decision.id, row[1]), "%s: %s" % [row[0], row[1]])
			assert_true(sim.world.has_flag(row[2]), "%s sets %s" % [row[1], row[2]])


func test_the_roads_to_a_fuller_harvest_show_the_plough_and_the_shears() -> void:
	for row: Array in [
		[&"a_share_of_iron", &"tip_the_stick", &"iron_share"],
		[&"a_share_of_iron", &"fit_a_share", &"iron_share"],
		[&"sharper_shears", &"iron_shears", &"iron_shears"],
		[&"sharper_shears", &"iron_knife_and_patience", &"iron_shears"],
	]:
		var sim: Simulation = _prepared(&"fuller_harvest")
		sim.fire_event(sim.content.get_event(row[0]), sim.world.villagers[0])
		var decision: PendingDecision = SimFixture.pending_for(sim, row[0])
		assert_true(decision != null, "%s is asked" % row[0])
		if decision != null:
			assert_true(sim.resolve_decision(decision.id, row[1]), "%s: %s" % [row[0], row[1]])
			assert_true(sim.world.has_flag(row[2]), "%s sets %s" % [row[1], row[2]])


# ---- Growth -------------------------------------------------------------------------------------

func test_a_family_is_taken_in_only_when_there_is_room() -> void:
	var sim: Simulation = _prepared(&"never")
	var count: int = sim.world.villagers.size()
	sim.fire_event(sim.content.get_event(&"hands_for_the_field"), null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"hands_for_the_field")
	assert_true(decision != null)
	if decision != null and sim.world.housing > count:
		assert_true(sim.resolve_decision(decision.id, &"take_a_family_in"))
		assert_eq(sim.world.villagers.size(), count + 1)


# ---- A whole age --------------------------------------------------------------------------------

func test_a_player_who_accepts_everything_finishes_the_age_on_either_path() -> void:
	_assert_finishes(1, &"path_bloomery", 0)
	_assert_finishes(2, &"path_ore", 0)


func test_a_player_who_passes_on_things_first_still_finishes() -> void:
	_assert_finishes(1, &"path_ore", 2)


## Plays the Iron Age from its first day with no Bronze answer to lean on. `declines` is how many
## times the player passes on each question (choosing the last answer) before accepting. Every
## milestone must be earned, none before its day.
func _assert_finishes(rng_seed: int, path: StringName, declines: int) -> void:
	var label: String = "seed %d, %s, declining %d" % [rng_seed, path, declines]
	var sim: Simulation = _iron(rng_seed, path)
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
	assert_true(sim.world.has_flag(&"known_abroad"), "%s: the town is known abroad" % label)


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
