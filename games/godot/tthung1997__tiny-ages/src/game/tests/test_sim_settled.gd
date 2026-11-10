extends McpTestSuite
## The Settled Age's six hidden milestones: each has more than one route, the routes differ for
## a group that farms and one that herds, they are staged over the age, and every group can finish.

const DAY: int = SimFixture.TICKS_PER_DAY
const MILESTONES: Array[StringName] = [
	&"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth", &"a_village", &"green_stone",
]
## Era day each milestone opens (SETTLED_DAY in tools/build_sim_content.gd).
const OPENS: Dictionary = {
	&"first_roof": 18, &"first_harvest": 54, &"fired_clay": 108, &"woven_cloth": 162,
	&"a_village": 216, &"green_stone": 252,
}
const SEEDS: Array[int] = [1, 2]


func suite_name() -> String:
	return "sim_settled"


func _settled(rng_seed: int = 1, path: StringName = &"path_agriculture") -> Simulation:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	sim.advance_era(&"settled")
	sim.world.flags[path] = true
	return sim


func _ask(sim: Simulation, event_id: StringName, choice_id: StringName) -> bool:
	sim.fire_event(sim.content.get_event(event_id), sim.world.villagers[0])
	var decision: PendingDecision = SimFixture.pending_for(sim, event_id)
	return decision != null and sim.resolve_decision(decision.id, choice_id)


func test_the_era_day_condition_counts_from_the_start_of_the_age() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 400)
	sim.advance_era(&"settled")
	var condition: SimCondition = SimCondition.new()
	condition.kind = SimCondition.Kind.ERA_DAYS_AT_LEAST
	condition.amount = 3
	assert_false(condition.is_met(sim.world, sim.config), "Day 400 is not three days in")
	sim.advance_ticks(DAY * 3)
	assert_true(condition.is_met(sim.world, sim.config))


func test_the_hut_and_the_field_are_offered_together() -> void:
	var sim: Simulation = _settled()
	sim.world.resources[&"wood"] = 50
	var event: EventDef = sim.content.get_event(&"settled_building_opportunity")
	var hut: ChoiceDef = event.get_choice(&"build_hut")
	var field: ChoiceDef = event.get_choice(&"build_field")
	assert_false(sim.choice_available(hut, null), "No hut on the first day")
	assert_false(sim.choice_available(field, null), "No field on the first day")
	SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + OPENS[&"first_roof"])
	assert_true(sim.choice_available(hut, null))
	assert_true(sim.choice_available(field, null), "A fork needs both, so they open together")


func test_buildings_grant_their_milestones() -> void:
	var sim: Simulation = _settled()
	for site_id: StringName in [&"hut", &"field"]:
		var site: BuildingState = BuildingState.new()
		site.def_id = site_id
		sim.world.buildings.append(site)
		sim.complete_building(site)
	assert_true(sim.world.has_achievement(&"first_roof"))
	assert_true(sim.world.has_achievement(&"first_harvest"))


func test_every_milestone_has_more_than_one_route() -> void:
	var routes: Dictionary = {
		&"first_roof": [[&"thatched_roof", &"thatch_it"]],
		&"first_harvest": [[&"first_calves", &"tend_the_calves"]],
		&"fired_clay": [[&"clay_hardens", &"fire_a_pot"], [&"shaped_bowls", &"bake_them"]],
		&"woven_cloth": [
			[&"flax_in_the_field", &"twist_the_fibres"], [&"plaited_reeds", &"show_the_others"],
		],
		&"a_village": [[&"families_on_the_road", &"make_room"]],
		&"green_stone": [
			[&"green_stone_found", &"follow_the_stream"],
			[&"green_stone_traded", &"trade_for_stones"],
		],
	}
	for milestone: StringName in routes:
		for route: Array in routes[milestone]:
			var sim: Simulation = _settled(1, &"path_agriculture")
			sim.world.flags[&"path_herding"] = true
			sim.world.resources[&"food"] = 40
			if milestone == &"a_village":
				sim.world.achievements.append(&"first_roof")
			assert_true(_ask(sim, route[0], route[1]), "%s: %s" % [milestone, route[0]])
			assert_true(sim.world.has_achievement(milestone), "%s via %s" % [milestone, route[0]])
			if milestone == &"green_stone":
				assert_true(sim.world.has_flag(&"green_stone"), "The next age reads this flag")


func test_the_building_routes_and_the_event_routes_all_exist() -> void:
	var sim: Simulation = _settled()
	for site_id: StringName in [&"hut", &"field"]:
		assert_true(sim.content.get_building(site_id).completion_achievement != &"")
	var wool: Simulation = _settled(1, &"path_herding")
	assert_true(_ask(wool, &"wool_on_the_thorns", &"spin_the_wool"))
	assert_true(wool.world.has_achievement(&"woven_cloth"))
	var table: Simulation = _settled()
	table.world.achievements.append(&"first_harvest")
	table.world.resources[&"food"] = 12
	assert_true(_ask(table, &"the_long_table", &"lay_the_table"))
	assert_true(table.world.has_achievement(&"a_village"))
	assert_eq(table.world.resource_amount(&"food"), 2, "The table costs 10 food")


## Every answer to a milestone question gets there: some at once, some a little later.
func test_answering_a_milestone_the_other_way_still_earns_it() -> void:
	for row: Array in [
		[&"thatched_roof", &"make_do", &"first_roof", false],
		[&"clay_hardens", &"leave_the_shell", &"fired_clay", false],
		[&"shaped_bowls", &"keep_drying", &"fired_clay", false],
		[&"plaited_reeds", &"keep_it_a_mat", &"woven_cloth", false],
		[&"families_on_the_road", &"point_the_way", &"a_village", false],
		[&"green_stone_found", &"keep_the_bead", &"green_stone", true],
		[&"green_stone_traded", &"send_them_on", &"green_stone", true],
		[&"the_long_table", &"eat_as_usual", &"a_village", true],
	]:
		var sim: Simulation = _settled()
		sim.world.achievements.append(&"first_roof")
		sim.world.achievements.append(&"first_harvest")
		var milestone: StringName = row[2]
		sim.world.achievements.erase(milestone)
		assert_true(_ask(sim, row[0], row[1]), "%s: %s" % [row[0], row[1]])
		var later: bool = row[3]
		if later:
			assert_false(sim.world.has_achievement(milestone), "%s waits a little" % row[1])
			sim.advance_ticks(120)
		assert_true(sim.world.has_achievement(milestone), "%s reaches %s" % [row[1], milestone])


func test_making_room_grows_the_group() -> void:
	var sim: Simulation = _settled()
	sim.world.achievements.append(&"first_roof")
	assert_true(_ask(sim, &"families_on_the_road", &"make_room"))
	assert_eq(sim.world.villagers.size(), 5)


func test_the_long_table_needs_the_harvest_and_food() -> void:
	var sim: Simulation = _settled()
	sim.world.resources[&"food"] = 40
	SimFixture.jump_to_day(sim, 400)
	var table: EventDef = sim.content.get_event(&"the_long_table")
	assert_false(
		SimCondition.all_met(table.requires, sim.world, sim.config, sim.world.villagers[0]),
		"No long table without a first harvest"
	)
	sim.world.achievements.append(&"first_harvest")
	assert_true(
		SimCondition.all_met(table.requires, sim.world, sim.config, sim.world.villagers[0])
	)
	sim.world.resources[&"food"] = 3
	assert_false(sim.choice_available(table.get_choice(&"lay_the_table"), sim.world.villagers[0]))


func test_each_path_has_its_own_road_to_woven_cloth_and_everyone_has_one() -> void:
	var farm: Simulation = _settled(1, &"path_agriculture")
	var herd: Simulation = _settled(1, &"path_herding")
	for sim: Simulation in [farm, herd]:
		SimFixture.jump_to_day(sim, sim.config.day_of(sim.world.tick) + OPENS[&"woven_cloth"])
	var flax: EventDef = farm.content.get_event(&"flax_in_the_field")
	var wool: EventDef = farm.content.get_event(&"wool_on_the_thorns")
	var subject: VillagerState = farm.world.villagers[0]
	assert_true(SimCondition.all_met(flax.requires, farm.world, farm.config, subject))
	assert_false(SimCondition.all_met(wool.requires, farm.world, farm.config, subject))
	assert_true(SimCondition.all_met(wool.requires, herd.world, herd.config, subject))
	assert_false(SimCondition.all_met(flax.requires, herd.world, herd.config, subject))
	var reeds: EventDef = farm.content.get_event(&"plaited_reeds")
	var bare: Simulation = _settled(1, &"no_path")
	SimFixture.jump_to_day(bare, bare.config.day_of(bare.world.tick) + 220)
	assert_true(
		SimCondition.all_met(reeds.requires, bare.world, bare.config, bare.world.villagers[0]),
		"The reed mats are open to every group"
	)


func test_settled_milestones_never_happen_in_the_cave_age() -> void:
	var sim: Simulation = SimFixture.new_sim(5)
	var bot: DecisionBot = DecisionBot.new()
	for _tick: int in DAY * 300:
		sim.advance_ticks(1)
		bot.answer_all(sim)
		if sim.world.era == &"settled":
			break
	for milestone: StringName in MILESTONES:
		assert_false(
			sim.world.has_achievement(milestone) and sim.world.era == &"cave",
			"%s was earned in the Cave Age" % milestone
		)
	for event_id: StringName in [&"thatched_roof", &"clay_hardens", &"families_on_the_road"]:
		assert_eq(sim.world.event_counts.get(event_id, 0), 0, "%s in the cave" % event_id)


func test_a_player_who_accepts_everything_finishes_the_age_on_either_path() -> void:
	for rng_seed: int in SEEDS:
		for path: StringName in [&"path_agriculture", &"path_herding"]:
			_assert_finishes(rng_seed, path, 0)


func test_a_player_who_passes_on_things_first_still_finishes() -> void:
	for rng_seed: int in SEEDS:
		_assert_finishes(rng_seed, &"path_herding", 2)


## Plays the Settled Age from its first day. `declines` is how many times the player passes on
## each question (choosing the last answer) before accepting. Every milestone must be earned, none
## before its staged day, and the whole age should take about as long as the Cave Age.
func _assert_finishes(rng_seed: int, path: StringName, declines: int) -> void:
	var label: String = "seed %d, %s, declining %d" % [rng_seed, path, declines]
	var sim: Simulation = _settled(rng_seed, path)
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
			# The Field opens with the Hut, so its harvest can come as early as the roof.
			var opens: int = OPENS[&"first_roof"] if milestone == &"first_harvest" \
					else OPENS[milestone]
			assert_gt(
				earned[milestone] + 1, opens * DAY,
				"%s: %s came before day %d" % [label, milestone, opens]
			)
	if earned.has(&"a_village"):
		assert_gt(earned[&"a_village"], DAY * 150, "%s: the milestones cover most of the age" % label)


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
