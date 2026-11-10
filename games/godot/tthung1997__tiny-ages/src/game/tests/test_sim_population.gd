extends McpTestSuite
## Eating, room and the group's size (docs/gameplay.md P5, P13): the group eats a little more per
## head as it grows, a shortage only moves effort, arrivals need room and food, and a crowded camp
## eases by building or by a family leaving: nobody dies and nothing blocks an age.

const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "population"


func _own_config(sim: Simulation) -> SimConfig:
	sim.config = sim.config.duplicate() as SimConfig
	return sim.config


func _away(villager: VillagerState) -> void:
	villager.activity = VillagerState.ACTIVITY_AWAY
	villager.location = &"western_forest"
	villager.away_until_tick = 100000


# ---- eating ---------------------------------------------------------------------------------

func test_everyone_eats_the_same_whatever_the_size_of_the_group() -> void:
	var config: SimConfig = SimFixture.load_config()
	assert_eq(FoodSystem.ration_per_tick(0, config), 0.0)
	var per_tick: float = config.food_per_villager_per_day / float(config.ticks_per_day)
	for size: int in [1, 3, 8, 12]:
		var share: float = FoodSystem.ration_per_tick(size, config) / float(size)
		assert_true(absf(share - per_tick) < 0.00001, "%d villagers eat %f each" % [size, share])


func test_a_later_ages_villager_eats_and_brings_in_more() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var config: SimConfig = SimFixture.load_config()
	var last_limit: int = 0
	var last_need: float = 0.0
	var last_food: float = 0.0
	var last_wood: float = 0.0
	for era: EraDef in content.eras:
		assert_gt(era.max_villagers, last_limit - 1, "%s holds at least as many as the age before" % era.id)
		assert_true(era.max_villagers <= config.max_villagers, "%s is inside the safety net" % era.id)
		assert_true(era.housing <= era.max_villagers, "%s: housing is stretched to the ceiling" % era.id)
		assert_gt(era.food_need_scale, last_need - 0.001, "%s eats at least as much per villager" % era.id)
		assert_gt(era.food_yield_scale, last_food - 0.001, "%s forages at least as well" % era.id)
		assert_gt(era.wood_yield_scale, last_wood - 0.001, "%s cuts at least as well" % era.id)
		# What a villager eats and brings in grow together, so no age is starved or flooded.
		assert_true(
			absf(era.food_yield_scale - era.food_need_scale) < 0.001,
			"%s: foraging keeps pace with eating" % era.id
		)
		last_limit = era.max_villagers
		last_need = era.food_need_scale
		last_food = era.food_yield_scale
		last_wood = era.wood_yield_scale
	assert_eq(content.get_era(&"cave").max_villagers, 6)
	assert_eq(content.get_era(&"classical").max_villagers, 14)
	var scaled: float = FoodSystem.ration_per_tick(4, config, 1.5)
	assert_true(absf(scaled - FoodSystem.ration_per_tick(4, config) * 1.5) < 0.00001)


func test_the_simulation_reads_the_scales_of_the_current_age() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(sim.food_need_scale(), 1.0)
	sim.advance_era(&"settled")
	var settled: EraDef = sim.content.get_era(&"settled")
	assert_eq(sim.food_need_scale(), settled.food_need_scale)
	assert_eq(sim.food_yield_scale(), settled.food_yield_scale)
	assert_eq(sim.wood_yield_scale(), settled.wood_yield_scale)
	assert_eq(sim.world.villager_limit, settled.max_villagers)


func test_the_cave_ages_buildings_and_answers_cannot_stretch_past_the_ceiling() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var ceiling: int = sim.content.get_era(&"cave").max_villagers
	sim.world.flags[&"lean_to"] = true
	sim.world.flags[&"extra_roofs"] = true
	sim.world.flags[&"town_wall"] = true
	sim.refresh_housing()
	assert_gt(sim.world.housing, ceiling, "The answers would give more room than the age allows")
	while sim.world.room() > 0:
		sim.add_villager()
	assert_eq(sim.world.villagers.size(), ceiling, "...but the age's ceiling holds")


func test_a_group_over_its_ceiling_keeps_everyone_and_waits_for_room() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var ceiling: int = sim.content.get_era(&"cave").max_villagers
	for _newcomer: int in ceiling + 3 - sim.world.villagers.size():
		sim.add_villager()
	var names: Array[StringName] = []
	for villager: VillagerState in sim.world.villagers:
		names.append(villager.id)
	assert_gt(sim.world.villagers.size(), ceiling)
	assert_eq(sim.world.room(), 0, "No negative room")
	sim.advance_ticks(DAY * 3)
	for id: StringName in names:
		assert_true(sim.world.find_villager(id) != null, "%s is still here" % id)
	sim.advance_era(&"settled")
	assert_eq(sim.world.villagers.size(), names.size(), "The turn removes nobody")


func test_foragers_share_the_ground_and_only_foragers() -> void:
	var config: SimConfig = SimFixture.load_config()
	assert_eq(VillagerSystem.shared_ground(0, config), 1.0)
	assert_eq(VillagerSystem.shared_ground(1, config), 1.0, "A lone forager has it to themself")
	var two: float = VillagerSystem.shared_ground(2, config)
	var four: float = VillagerSystem.shared_ground(4, config)
	assert_true(two < 1.0 and four < two, "More at once, less each")
	# The group's catch still grows with every forager added, only more slowly.
	assert_true(4.0 * four > 2.0 * two)


func test_eating_takes_food_and_never_goes_below_zero_or_hurts_anyone() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"food"] = 0
	var before: int = sim.world.villagers.size()
	for _tick: int in DAY * 3:
		sim.world.resources[&"food"] = 0
		sim.advance_ticks(1)
		assert_true(sim.world.resource_amount(&"food") >= 0)
	assert_eq(sim.world.villagers.size(), before, "Nobody is lost")
	var fed: Simulation = SimFixture.new_sim()
	fed.world.resources[&"food"] = 40
	var ration: float = FoodSystem.ration_per_tick(fed.world.villagers.size(), fed.config)
	fed.advance_ticks(1)
	assert_true(fed.world.resource_amount(&"food") <= 40, "The group ate")
	assert_true(ration > 0.0)


func test_being_away_costs_nothing_extra() -> void:
	var ticked: Simulation = SimFixture.new_sim(3)
	var caught_up: Simulation = SimFixture.new_sim(3)
	ticked.advance_ticks(DAY * 4)
	var start: float = 1000000.0
	caught_up.world.last_seen_unix = start
	caught_up.advance_real_time(start + float(DAY * 4) * caught_up.config.seconds_per_tick())
	assert_eq(caught_up.world.tick, ticked.world.tick)
	assert_eq(caught_up.world.resource_amount(&"food"), ticked.world.resource_amount(&"food"))
	assert_eq(caught_up.world.villagers.size(), ticked.world.villagers.size())


func test_a_shortage_shifts_effort_to_food_and_away_from_wood() -> void:
	var counts: Dictionary = {}
	for food: int in [0, 20]:
		var sim: Simulation = SimFixture.new_sim(5)
		var wood_picks: int = 0
		var food_picks: int = 0
		for _tick: int in DAY * 60:
			sim.world.resources[&"food"] = food
			sim.world.resources[&"wood"] = 20
			sim.advance_ticks(1)
			for villager: VillagerState in sim.world.villagers:
				if villager.activity == VillagerState.ACTIVITY_GATHER_WOOD:
					wood_picks += 1
				elif villager.activity == VillagerState.ACTIVITY_FORAGE:
					food_picks += 1
		counts[food] = [wood_picks, food_picks]
	assert_true(counts[0][1] > counts[20][1], "More foraging while hungry: %s" % [counts])
	assert_true(counts[0][0] < counts[20][0], "Less wood while hungry: %s" % [counts])


# ---- room -----------------------------------------------------------------------------------

func test_the_camp_holds_what_the_age_buildings_and_answers_give() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var cave: int = sim.content.get_era(&"cave").housing
	assert_eq(sim.world.housing, cave)
	assert_eq(sim.world.room(), cave - sim.world.villagers.size())
	var hut: BuildingState = BuildingState.new()
	hut.def_id = &"hut"
	sim.world.buildings.append(hut)
	sim.complete_building(hut)
	assert_eq(sim.world.housing, cave + sim.content.get_building(&"hut").housing)
	sim.world.flags[&"lean_to"] = true
	sim.refresh_housing()
	assert_eq(sim.world.housing, cave + sim.content.get_building(&"hut").housing + 2)


func test_a_newcomer_uses_up_room_and_a_full_camp_has_none() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var needs_one: SimCondition = SimCondition.new()
	needs_one.kind = SimCondition.Kind.HAS_ROOM
	needs_one.amount = 1
	var before: int = sim.world.room()
	assert_true(needs_one.is_met(sim.world, sim.config))
	sim.add_villager()
	assert_eq(sim.world.room(), before - 1)
	while sim.world.room() > 0:
		sim.add_villager()
	assert_false(needs_one.is_met(sim.world, sim.config), "No room left")
	needs_one.negate = true
	assert_true(needs_one.is_met(sim.world, sim.config), "...which is what crowded means")


func test_the_group_never_passes_its_safety_limit() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_own_config(sim).max_villagers = 5
	for _newcomer: int in 10:
		sim.add_villager()
	assert_eq(sim.world.villagers.size(), 5)
	assert_true(sim.add_villager() == null)


# ---- leaving --------------------------------------------------------------------------------

func test_the_newest_villager_at_home_leaves() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_villager()
	sim.add_villager()
	var newest: VillagerState = sim.world.villagers[sim.world.villagers.size() - 1]
	var left: Array[VillagerState] = []
	sim.villager_left.connect(func(villager: VillagerState) -> void: left.append(villager))
	var size: int = sim.world.villagers.size()
	assert_eq(sim.remove_villager(), newest)
	assert_eq(sim.world.villagers.size(), size - 1)
	assert_eq(left, [newest] as Array[VillagerState])
	assert_true(sim.world.find_villager(newest.id) == null)
	assert_true(
		SimFixture.journal_index(sim.world, "%s left the group" % newest.display_name) >= 0,
		"The journal says who left, as it says who joined",
	)


func test_someone_who_is_away_is_not_the_one_who_leaves() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_villager()
	var newest: VillagerState = sim.world.villagers[sim.world.villagers.size() - 1]
	_away(newest)
	var gone: VillagerState = sim.remove_villager()
	assert_true(gone != newest and gone != null)
	for villager: VillagerState in sim.world.villagers:
		_away(villager)
	assert_true(sim.remove_villager() == null, "Nobody at home, nobody leaves")


func test_what_waited_on_a_villager_who_leaves_is_dropped() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_villager()
	var leaver: VillagerState = sim.world.villagers[sim.world.villagers.size() - 1]
	var asked: PendingDecision = PendingDecision.new()
	asked.id = &"decision_for_leaver"
	asked.event_id = &"flint_edge"
	asked.subject_id = leaver.id
	sim.world.pending.append(asked)
	var queued: ScheduledEvent = ScheduledEvent.new()
	queued.event_id = &"explorer_returns"
	queued.subject_id = leaver.id
	sim.world.scheduled.append(queued)
	sim.remove_villager()
	assert_true(sim.world.find_pending(&"decision_for_leaver") == null)
	assert_false(sim.world.scheduled.has(queued))


func test_the_view_drops_the_figure_of_a_villager_who_left() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var window: DesktopWindow = DesktopWindow.new()
	var view: WorldView = WorldView.new()
	view.setup(sim, window)
	view.on_world_changed()
	var actors: int = view._actors.size()
	assert_eq(actors, sim.world.villagers.size())
	sim.remove_villager()
	view.on_world_changed()
	assert_eq(view._actors.size(), actors - 1)
	view.free()
	window.free()


# ---- the decisions --------------------------------------------------------------------------

func _earn(sim: Simulation, key: StringName) -> void:
	if not sim.world.has_achievement(key):
		sim.world.achievements.append(key)


func _asked(sim: Simulation, event_id: StringName) -> bool:
	var event: EventDef = sim.content.get_event(event_id)
	return SimCondition.all_met(event.requires, sim.world, sim.config)


func test_a_traveller_is_only_asked_while_there_is_room_and_food() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_earn(sim, &"bigger_group")
	sim.world.resources[&"food"] = 20
	sim.world.tick = DAY * 210
	assert_true(_asked(sim, &"traveller_at_dusk"), "Room and food")
	sim.world.resources[&"food"] = 5
	assert_false(_asked(sim, &"traveller_at_dusk"), "Not without food to share")
	sim.world.resources[&"food"] = 20
	while sim.world.room() > 0:
		sim.add_villager()
	assert_false(_asked(sim, &"traveller_at_dusk"), "Not without room")
	assert_true(_asked(sim, &"too_many_for_the_cave") or sim.world.resource_amount(&"wood") < 8)


func test_a_crowded_camp_can_build_out_or_let_a_family_go() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_earn(sim, &"bigger_group")
	sim.world.resources[&"wood"] = 20
	sim.world.tick = DAY * 200
	while sim.world.room() > 0:
		sim.add_villager()
	assert_true(_asked(sim, &"too_many_for_the_cave"))
	var event: EventDef = sim.content.get_event(&"too_many_for_the_cave")
	var before: int = sim.world.villagers.size()
	var room: int = sim.world.room()
	# Build out.
	assert_true(sim.choice_available(event.get_choice(&"raise_a_lean_to"), null))
	sim.fire_event(event, null)
	var decision: PendingDecision = sim.world.pending[sim.world.pending.size() - 1]
	assert_true(sim.resolve_decision(decision.id, &"raise_a_lean_to"))
	assert_eq(sim.world.resource_amount(&"wood"), 12)
	assert_eq(sim.world.room(), room + 2, "The lean-to made room")
	assert_eq(sim.world.villagers.size(), before)
	# Or let a family go.
	sim.fire_event(event, null)
	decision = sim.world.pending[sim.world.pending.size() - 1]
	assert_true(sim.resolve_decision(decision.id, &"a_family_goes"))
	assert_eq(sim.world.villagers.size(), before - 2)
	assert_true(sim.world.has_flag(&"kin_by_the_river"))


func test_a_forager_can_be_chosen_when_food_runs_short() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_earn(sim, &"bigger_group")
	sim.world.tick = DAY * 210
	sim.world.resources[&"food"] = 10
	assert_true(_asked(sim, &"who_leads_the_foraging"))
	var event: EventDef = sim.content.get_event(&"who_leads_the_foraging")
	var subject: VillagerState = sim.world.villagers[0]
	sim.fire_event(event, subject)
	var decision: PendingDecision = sim.world.pending[sim.world.pending.size() - 1]
	assert_true(sim.resolve_decision(decision.id, &"lead_the_baskets"))
	assert_eq(subject.profession, &"forager")
	var card: VillagerPresenter = VillagerPresenter.present(subject, sim.world, sim.config)
	assert_eq(card.role_text, "Forager")


func test_the_settled_arrivals_need_room_and_a_village() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	sim.world.era_started_tick = 0
	sim.world.tick = DAY * 300
	sim.world.resources[&"food"] = 30
	sim.world.resources[&"wood"] = 30
	assert_false(_asked(sim, &"family_at_the_door"), "Not before the camp is a village")
	_earn(sim, &"a_village")
	assert_true(_asked(sim, &"family_at_the_door"))
	var event: EventDef = sim.content.get_event(&"family_at_the_door")
	var before: int = sim.world.villagers.size()
	sim.fire_event(event, null)
	var decision: PendingDecision = sim.world.pending[sim.world.pending.size() - 1]
	assert_true(sim.resolve_decision(decision.id, &"take_them_in"))
	assert_eq(sim.world.villagers.size(), before + 2)


func test_a_lean_spring_gives_a_fork_when_the_stores_are_low() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	sim.world.tick = DAY * 400
	_earn(sim, &"a_village")
	sim.world.resources[&"food"] = 10
	assert_true(_asked(sim, &"a_lean_spring"))
	sim.world.resources[&"food"] = 40
	assert_false(_asked(sim, &"a_lean_spring"), "Only when the food is low")


## Every answer that makes someone leave still leads on: playing the whole way with a group that
## always lets a family go (and always takes the other road when there is none) reaches the
## Settled Age and its village, so no sequence of answers blocks an age (docs/gameplay.md P13).
func test_a_group_that_always_lets_a_family_go_still_reaches_the_village() -> void:
	var sim: Simulation = SimFixture.new_sim(2, false)
	var bot: DecisionBot = DecisionBot.new()
	var settled: EraDef = sim.content.get_era(&"settled")
	var limit: int = settled.min_ticks_in_previous_era + DAY * 330
	var departures: int = 0
	for _tick: int in limit:
		sim.advance_ticks(1)
		for decision: PendingDecision in sim.world.pending.duplicate():
			var event: EventDef = sim.content.get_event(decision.event_id)
			for choice: ChoiceDef in event.choices:
				var leaves: bool = false
				for effect: SimEffect in choice.effects:
					leaves = leaves or effect.kind == SimEffect.Kind.REMOVE_VILLAGER
				if leaves and sim.resolve_decision(decision.id, choice.id):
					departures += 1
					break
		bot.answer_all(sim)
		assert_true(sim.world.villagers.size() >= 1, "Never an empty camp")
		if sim.world.has_achievement(&"a_village"):
			break
	assert_eq(sim.world.era, &"settled", "The age turned")
	assert_true(sim.world.has_achievement(&"a_village"), "The village came")
	assert_gt(departures, 0, "A family did leave along the way")
