extends McpTestSuite
## The Bronze Age (docs/ages.md, "Bronze Age: design proposal"): its gate, its turn, six hidden
## milestones each with more than one road, the forks between them, and the roles that start to
## tilt a villager's day.

const DAY: int = SimFixture.TICKS_PER_DAY
const SETTLED_SIX: Array[StringName] = [
	&"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth", &"a_village", &"green_stone",
]
const MILESTONES: Array[StringName] = [
	&"first_casting", &"bronze_alloy", &"mud_brick_walls", &"wheel_and_road", &"a_town",
	&"beyond_the_water",
]
## Era day each milestone opens (BRONZE_DAY in tools/build_sim_content.gd); the Smithy's earns
## the first as soon as it stands.
const OPENS: Dictionary = {
	&"first_casting": 18, &"bronze_alloy": 54, &"mud_brick_walls": 108, &"wheel_and_road": 162,
	&"a_town": 216, &"beyond_the_water": 252,
}
## Everything a group may have answered in the Settled Age that a Bronze road reads.
const SETTLED_ANSWERS: Array[StringName] = [
	&"path_agriculture", &"path_herding", &"low_wall", &"open_village", &"good_neighbours",
	&"salt", &"kiln", &"green_beads", &"copper_tried", &"dugout_canoe", &"reed_raft",
	&"pot_marks",
]


func suite_name() -> String:
	return "sim_bronze"


func _content() -> ContentLibrary:
	return SimFixture.load_content()


func _bronze(rng_seed: int = 1, path: StringName = &"path_smithing") -> Simulation:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	sim.advance_era(&"settled")
	for key: StringName in SETTLED_SIX:
		sim.world.achievements.append(key)
	sim.advance_era(&"bronze")
	sim.world.flags[path] = true
	return sim


## A Bronze world where the group has done and answered everything a road could read, except the
## milestone `missing`.
func _prepared(missing: StringName) -> Simulation:
	var sim: Simulation = _bronze()
	sim.world.flags[&"path_trading"] = true
	for flag: StringName in SETTLED_ANSWERS:
		sim.world.flags[flag] = true
	sim.world.flags.erase(&"far_shore")
	for key: StringName in MILESTONES:
		if key != missing and not sim.world.has_achievement(key):
			sim.world.achievements.append(key)
	var post: BuildingState = BuildingState.new()
	post.def_id = &"trading_post"
	sim.world.buildings.append(post)
	sim.world.resources[&"wood"] = 60
	sim.world.resources[&"food"] = 40
	return sim


func _gate() -> EraDef:
	return _content().get_era(&"bronze")


func _grant_gate(sim: Simulation) -> void:
	for key: StringName in _gate().required_achievements:
		if not sim.world.has_achievement(key):
			sim.world.achievements.append(key)


func _age_the_settled(sim: Simulation, ticks: int) -> void:
	sim.world.era_started_tick = sim.world.tick - ticks


# ---- The gate and the turn ----------------------------------------------------------------------

func test_the_bronze_age_follows_the_settled_age_and_takes_five_days() -> void:
	var gate: EraDef = _gate()
	assert_eq(gate.order, 2)
	assert_eq(gate.min_ticks_in_previous_era, 8640)
	assert_eq(gate.turn_event, &"the_metals_road")
	for key: StringName in SETTLED_SIX:
		assert_true(gate.required_achievements.has(key), "The gate asks for %s" % key)
	assert_eq(gate.required_achievements.size(), SETTLED_SIX.size())


func test_the_gate_stays_shut_without_every_settled_milestone_and_the_time() -> void:
	for missing: StringName in SETTLED_SIX:
		var sim: Simulation = SimFixture.new_sim()
		sim.advance_era(&"settled")
		_grant_gate(sim)
		sim.world.achievements.erase(missing)
		_age_the_settled(sim, _gate().min_ticks_in_previous_era)
		sim.advance_ticks(DAY)
		assert_eq(sim.world.era, &"settled", "Without %s the age must not turn" % missing)
	var early: Simulation = SimFixture.new_sim()
	early.advance_era(&"settled")
	_grant_gate(early)
	_age_the_settled(early, _gate().min_ticks_in_previous_era - DAY * 2)
	early.advance_ticks(DAY)
	assert_eq(early.world.event_counts.get(&"the_metals_road", 0), 0, "Not before the time")


func test_when_the_gate_opens_the_player_is_asked_how_to_work_the_stone() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	_grant_gate(sim)
	_age_the_settled(sim, _gate().min_ticks_in_previous_era)
	sim.advance_ticks(1)
	assert_true(SimFixture.pending_for(sim, &"the_metals_road") != null, "The turn opens")
	assert_eq(sim.world.era, &"settled", "Still the Settled Age until the player answers")


func test_either_answer_turns_the_age_and_sets_the_path() -> void:
	for row: Array in [
		[&"work_it_here", &"path_smithing"], [&"follow_it_to_the_source", &"path_trading"],
	]:
		var sim: Simulation = SimFixture.new_sim()
		sim.advance_era(&"settled")
		_grant_gate(sim)
		_age_the_settled(sim, _gate().min_ticks_in_previous_era)
		sim.advance_ticks(1)
		var turn: PendingDecision = SimFixture.pending_for(sim, &"the_metals_road")
		assert_true(sim.resolve_decision(turn.id, row[0]))
		assert_eq(sim.world.era, &"bronze")
		assert_eq(sim.world.era_started_tick, sim.world.tick)
		assert_true(sim.world.has_flag(row[1]))
		assert_gt(sim.world.housing, sim.content.get_era(&"settled").housing, "More room in Bronze")


func test_the_settled_ages_last_forks_end_its_quiet_stretch_and_expire_with_it() -> void:
	var sim: Simulation = _bronze()
	for event_id: StringName in [&"heavy_loads", &"whose_pot"]:
		var event: EventDef = _content().get_event(event_id)
		assert_true(event != null, "%s exists" % event_id)
		SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + 400)
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config, sim.world.villagers[0]),
			"%s is not asked once the Settled Age is over" % event_id
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


func test_the_last_milestone_sets_the_flag_a_later_age_reads() -> void:
	for road: Array in _roads(&"beyond_the_water"):
		var sim: Simulation = _prepared(&"beyond_the_water")
		var event: EventDef = sim.content.get_event(road[0])
		sim.fire_event(event, sim.world.villagers[0])
		sim.resolve_decision(SimFixture.pending_for(sim, event.id).id, road[1])
		assert_true(sim.world.has_flag(&"far_shore"), "%s sets far_shore" % road[1])


func test_a_late_road_is_open_to_every_group() -> void:
	var bare: Simulation = _bronze(1, &"path_trading")
	SimFixture.jump_to_day(bare, bare.config.day_of(bare.world.tick) + 300)
	for event_id: StringName in [
		&"hammered_flat", &"panned_in_the_stream", &"ditch_and_bank", &"rollers_and_rope",
		&"the_tally", &"watch_the_water",
	]:
		var event: EventDef = bare.content.get_event(event_id)
		var grants: bool = event_id != &"hammered_flat"
		if grants:
			bare.world.achievements.append(&"first_casting")
		var met: bool = SimCondition.all_met(
			event.requires, bare.world, bare.config, bare.world.villagers[0]
		)
		if grants:
			bare.world.achievements.erase(&"first_casting")
		assert_true(met, "%s needs nothing a group may lack" % event_id)


func test_the_smithy_earns_the_first_casting_and_the_trading_post_does_not() -> void:
	var sim: Simulation = _bronze()
	var post: BuildingState = BuildingState.new()
	post.def_id = &"trading_post"
	sim.world.buildings.append(post)
	sim.complete_building(post)
	assert_false(sim.world.has_achievement(&"first_casting"))
	var smithy: BuildingState = BuildingState.new()
	smithy.def_id = &"smithy"
	sim.world.buildings.append(smithy)
	sim.complete_building(smithy)
	assert_true(sim.world.has_achievement(&"first_casting"))


func test_the_smithy_and_the_trading_post_are_a_fork_that_opens_together() -> void:
	var sim: Simulation = _bronze()
	sim.world.resources[&"wood"] = 50
	var event: EventDef = sim.content.get_event(&"bronze_building_opportunity")
	var smithy: ChoiceDef = event.get_choice(&"build_smithy")
	var post: ChoiceDef = event.get_choice(&"build_trading_post")
	assert_false(sim.choice_available(smithy, null), "Nothing on the first day")
	SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + OPENS[&"first_casting"])
	assert_true(sim.choice_available(smithy, null))
	assert_true(sim.choice_available(post, null), "A fork needs both")


func test_a_wall_answer_gives_room() -> void:
	var sim: Simulation = _bronze()
	var before: int = sim.world.housing
	sim.world.flags[&"palisade"] = true
	sim.refresh_housing()
	assert_eq(sim.world.housing, before + 3)


func test_the_quay_is_a_fork_between_a_pier_and_mooring_posts() -> void:
	var sim: Simulation = _bronze()
	sim.world.resources[&"wood"] = 30
	SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + 210)
	var event: EventDef = sim.content.get_event(&"the_quay")
	var pier: ChoiceDef = event.get_choice(&"build_quay")
	var posts: ChoiceDef = event.get_choice(&"drive_mooring_posts")
	assert_true(sim.choice_available(pier, null))
	assert_true(sim.choice_available(posts, null))
	sim.fire_event(event, null)
	var decision: PendingDecision = SimFixture.pending_for(sim, event.id)
	assert_true(sim.resolve_decision(decision.id, &"drive_mooring_posts"))
	assert_true(sim.world.has_flag(&"mooring_posts"))
	var quay: Simulation = _bronze()
	var site: BuildingState = BuildingState.new()
	site.def_id = &"quay"
	quay.world.buildings.append(site)
	quay.complete_building(site)
	assert_true(quay.world.has_flag(&"quay_built"), "A finished quay is remembered")


func test_the_roads_set_the_flags_the_world_shows() -> void:
	for row: Array in [
		[&"a_cart", &"solid_wheels", &"cart"],
		[&"a_cart", &"spoked_wheels", &"cart"],
		[&"donkeys_to_the_pack", &"train_two_donkeys", &"donkeys"],
		[&"donkeys_to_the_pack", &"borrow_the_string", &"donkeys"],
		[&"a_hard_road", &"lay_a_stone_road", &"road_laid"],
		[&"a_hard_road", &"beat_a_gravel_track", &"road_laid"],
		[&"market_day", &"market_at_the_gate", &"market_day"],
		[&"market_day", &"market_at_the_crossing", &"market_day"],
	]:
		var sim: Simulation = _prepared(&"never")
		sim.world.achievements.erase(&"wheel_and_road")
		sim.fire_event(sim.content.get_event(row[0]), sim.world.villagers[0])
		var decision: PendingDecision = SimFixture.pending_for(sim, row[0])
		assert_true(decision != null, "%s is asked" % row[0])
		if decision != null:
			assert_true(sim.resolve_decision(decision.id, row[1]), "%s: %s" % [row[0], row[1]])
			assert_true(sim.world.has_flag(row[2]), "%s sets %s" % [row[1], row[2]])


# ---- Roles --------------------------------------------------------------------------------------

func test_a_profession_tilts_the_day_like_a_trait_and_never_assigns_it() -> void:
	var sim: Simulation = _bronze()
	var villager: VillagerState = sim.world.villagers[0]
	villager.profession = &""
	assert_eq(VillagerSystem.profession_bias(villager, VillagerState.ACTIVITY_GATHER_WOOD), 1.0)
	villager.profession = &"smith"
	assert_gt(VillagerSystem.profession_bias(villager, VillagerState.ACTIVITY_GATHER_WOOD), 1.0)
	assert_eq(VillagerSystem.profession_bias(villager, VillagerState.ACTIVITY_FORAGE), 1.0)
	villager.profession = &"trader"
	assert_gt(VillagerSystem.profession_bias(villager, VillagerState.ACTIVITY_WANDER), 1.0)
	villager.profession = &"forager"
	assert_gt(VillagerSystem.profession_bias(villager, VillagerState.ACTIVITY_FORAGE), 1.0)


func test_the_hearth_and_the_road_can_make_a_smith_and_a_trader() -> void:
	for row: Array in [
		[&"who_tends_the_hearth", &"one_keeps_it", &"smith"],
		[&"who_walks_the_road", &"make_a_trader", &"trader"],
	]:
		var sim: Simulation = _prepared(&"never")
		var event: EventDef = sim.content.get_event(row[0])
		var subject: VillagerState = sim.world.villagers[0]
		sim.fire_event(event, subject)
		var decision: PendingDecision = SimFixture.pending_for(sim, event.id)
		assert_true(sim.resolve_decision(decision.id, row[1]))
		assert_eq(sim.world.find_villager(decision.subject_id).profession, row[2])


# ---- A whole age --------------------------------------------------------------------------------

func test_a_player_who_accepts_everything_finishes_the_age_on_either_path() -> void:
	_assert_finishes(1, &"path_smithing", 0)
	_assert_finishes(2, &"path_trading", 0)


func test_a_player_who_passes_on_things_first_still_finishes() -> void:
	_assert_finishes(1, &"path_trading", 2)


## Plays the Bronze Age from its first day with no Settled answer to lean on. `declines` is how
## many times the player passes on each question (choosing the last answer) before accepting.
## Every milestone must be earned, none before its day.
func _assert_finishes(rng_seed: int, path: StringName, declines: int) -> void:
	var label: String = "seed %d, %s, declining %d" % [rng_seed, path, declines]
	var sim: Simulation = _bronze(rng_seed, path)
	var start: int = sim.world.tick
	var earned: Dictionary = {}
	sim.achievement_earned.connect(
		func(key: StringName, _title: String) -> void: earned[key] = sim.world.tick - start
	)
	var bot: DecisionBot = DecisionBot.new()
	var passed: Dictionary = {}
	for _tick: int in DAY * 330:
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
	assert_true(sim.world.has_flag(&"far_shore"), "%s: the far shore was seen" % label)


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
