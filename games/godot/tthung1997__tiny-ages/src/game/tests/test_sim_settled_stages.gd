extends McpTestSuite
## The small decisions and journal lines that fill the Settled Age between its milestones
## (docs/ages.md): every one has two harmless answers, opens on its day, and is told only in the
## age (docs/gameplay.md P3, P10).

const STORIES: Array[StringName] = [
	&"what_the_cave_is_for", &"marking_the_ground", &"first_furrows", &"pasture_gate",
	&"mending_the_roof", &"the_well", &"the_scarecrow", &"the_herd_dog", &"a_dry_store",
	&"the_quarrel", &"harvest_festival", &"the_oldest_voice", &"the_kiln_pit", &"a_wet_summer",
	&"wild_fowl", &"dyed_cloth", &"the_loom_frame", &"the_flood", &"smoke_in_the_next_valley",
	&"pots_for_salt", &"winter_count", &"green_beads", &"the_low_wall", &"looking_back",
]
## Journal lines that only happen once an earlier answer set a flag: line id -> flag.
const REMEMBERED: Dictionary = {
	&"stores_in_the_cave": &"cave_store", &"well_water": &"well_dug",
	&"scarecrow_hat": &"scarecrow", &"festival_tune": &"festival", &"kiln_night": &"kiln",
	&"red_tunic": &"dyed_cloth", &"wall_at_dusk": &"low_wall", &"beads_clicking": &"green_beads",
}
const DAY_TICKS: int = 24
const REAL_HOUR_TICKS: int = 72
const SEEDS: Array[int] = [1, 2]


func suite_name() -> String:
	return "sim_settled_stages"


func _settled(rng_seed: int = 1, path: StringName = &"path_agriculture") -> Simulation:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	sim.advance_era(&"settled")
	sim.world.flags[path] = true
	sim.world.resources[&"wood"] = 60
	sim.world.resources[&"food"] = 60
	return sim


func test_every_story_decision_exists_and_has_two_ways_to_answer() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for event_id: StringName in STORIES:
		var event: EventDef = content.get_event(event_id)
		assert_true(event != null, "Missing story decision %s" % event_id)
		if event == null:
			continue
		assert_true(event.is_decision(), "%s should ask something" % event_id)
		assert_eq(event.choices.size(), 2, "%s should have two answers" % event_id)
		assert_true(event.once, "%s should be asked once" % event_id)


func test_every_answer_resolves_and_is_remembered() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for event_id: StringName in STORIES:
		var event: EventDef = content.get_event(event_id)
		for choice: ChoiceDef in event.choices:
			var sim: Simulation = _settled()
			var journal_before: int = sim.world.journal.size()
			sim.fire_event(event, sim.world.villagers[0] if event.needs_subject else null)
			var decision: PendingDecision = SimFixture.pending_for(sim, event_id)
			assert_true(decision != null, "%s should open a decision" % event_id)
			assert_true(
				sim.resolve_decision(decision.id, choice.id),
				"%s / %s should resolve with plenty in store" % [event_id, choice.id]
			)
			assert_gt(
				sim.world.journal.size(), journal_before,
				"%s / %s should leave a journal line" % [event_id, choice.id]
			)


func test_a_costly_answer_waits_for_stock_but_the_other_is_always_open() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var sim: Simulation = _settled()
	sim.world.resources[&"wood"] = 0
	sim.world.resources[&"food"] = 0
	var costly: int = 0
	for event_id: StringName in STORIES:
		var event: EventDef = content.get_event(event_id)
		var open: int = 0
		for choice: ChoiceDef in event.choices:
			if sim.choice_available(choice, sim.world.villagers[0]):
				open += 1
		assert_gt(open, 0, "%s: something can always be answered" % event_id)
		if open == 1:
			costly += 1
	assert_gt(costly, 10, "Most decisions have an answer that costs something")


func test_paying_for_an_answer_takes_the_stock() -> void:
	var sim: Simulation = _settled()
	sim.fire_event(SimFixture.load_content().get_event(&"the_low_wall"), null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"the_low_wall")
	assert_true(sim.resolve_decision(decision.id, &"build_a_low_wall"))
	assert_eq(sim.world.resource_amount(&"wood"), 35)
	assert_true(sim.world.has_flag(&"low_wall"))


func test_stories_open_on_their_day_and_only_in_the_settled_age() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for event_id: StringName in STORIES:
		var event: EventDef = content.get_event(event_id)
		var cave: Simulation = SimFixture.new_sim()
		SimFixture.jump_to_day(cave, 1000)
		cave.world.flags[&"path_agriculture"] = true
		cave.world.flags[&"path_herding"] = true
		for milestone: StringName in [
			&"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth", &"green_stone",
		]:
			cave.world.achievements.append(milestone)
		var subject: VillagerState = cave.world.villagers[0]
		assert_false(
			SimCondition.all_met(event.requires, cave.world, cave.config, subject),
			"%s should never happen in the Cave Age" % event_id
		)
		var settled: Simulation = SimFixture.new_sim()
		settled.advance_era(&"settled")
		settled.world.flags[&"path_agriculture"] = true
		settled.world.flags[&"path_herding"] = true
		for milestone: StringName in [
			&"first_roof", &"first_harvest", &"fired_clay", &"woven_cloth", &"green_stone",
		]:
			settled.world.achievements.append(milestone)
		assert_false(
			SimCondition.all_met(event.requires, settled.world, settled.config, subject),
			"%s should wait for its day" % event_id
		)
		settled.world.era_started_tick -= DAY_TICKS * 330
		_enter_the_season_of(settled, event)
		assert_true(
			SimCondition.all_met(event.requires, settled.world, settled.config, subject),
			"%s should be open late in the age" % event_id
		)


## A story that names a season waits for it: move the clock to the middle of that season.
func _enter_the_season_of(sim: Simulation, event: EventDef) -> void:
	for condition: SimCondition in event.requires:
		if condition.kind == SimCondition.Kind.SEASON_IS and not condition.negate:
			var seasons_on: int = posmod(condition.amount - sim.config.first_season, Season.COUNT)
			var day: int = seasons_on * sim.config.days_per_season \
					+ sim.config.days_per_season / 2
			sim.world.tick = day * DAY_TICKS


func test_the_farmers_and_the_herders_get_their_own_versions() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var farm: Simulation = _settled(1, &"path_agriculture")
	var herd: Simulation = _settled(1, &"path_herding")
	for sim: Simulation in [farm, herd]:
		SimFixture.jump_to_day(sim, 1000)
	for pair: Array in [[&"first_furrows", &"pasture_gate"], [&"the_scarecrow", &"the_herd_dog"]]:
		var farmers_only: EventDef = content.get_event(pair[0])
		var herders_only: EventDef = content.get_event(pair[1])
		assert_true(SimCondition.all_met(farmers_only.requires, farm.world, farm.config))
		assert_false(SimCondition.all_met(herders_only.requires, farm.world, farm.config))
		assert_true(SimCondition.all_met(herders_only.requires, herd.world, herd.config))
		assert_false(SimCondition.all_met(farmers_only.requires, herd.world, herd.config))


func test_stories_that_need_a_milestone_wait_for_it() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for pair: Array in [
		[&"mending_the_roof", &"first_roof"], [&"a_dry_store", &"first_harvest"],
		[&"the_kiln_pit", &"fired_clay"], [&"dyed_cloth", &"woven_cloth"],
		[&"green_beads", &"green_stone"],
	]:
		var sim: Simulation = _settled()
		sim.world.era_started_tick -= DAY_TICKS * 330
		var event: EventDef = content.get_event(pair[0])
		var subject: VillagerState = sim.world.villagers[0]
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config, subject),
			"%s should wait for %s" % [pair[0], pair[1]]
		)
		sim.world.achievements.append(pair[1])
		assert_true(SimCondition.all_met(event.requires, sim.world, sim.config, subject))


func test_remembered_lines_only_happen_after_the_answer_that_earned_them() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for line_id: StringName in REMEMBERED:
		var event: EventDef = content.get_event(line_id)
		assert_true(event != null, "Missing line %s" % line_id)
		if event == null:
			continue
		var sim: Simulation = _settled()
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config),
			"%s should wait for its flag" % line_id
		)
		sim.world.flags[REMEMBERED[line_id]] = true
		assert_true(
			SimCondition.all_met(event.requires, sim.world, sim.config),
			"%s should be possible once %s is set" % [REMEMBERED[line_id], line_id]
		)
		var cave: Simulation = SimFixture.new_sim()
		cave.world.flags[REMEMBERED[line_id]] = true
		assert_false(
			SimCondition.all_met(event.requires, cave.world, cave.config),
			"%s is a Settled Age line" % line_id
		)


func test_every_remembered_flag_is_set_by_some_answer() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var set_by: Dictionary = {}
	for event: EventDef in content.events:
		for choice: ChoiceDef in event.choices:
			for effect: SimEffect in choice.effects:
				if effect.kind == SimEffect.Kind.SET_FLAG:
					set_by[effect.key] = true
	for line_id: StringName in REMEMBERED:
		assert_true(set_by.has(REMEMBERED[line_id]), "Nothing sets %s" % REMEMBERED[line_id])


func test_a_bot_is_asked_something_every_few_real_hours_through_the_settled_age() -> void:
	for rng_seed: int in SEEDS:
		for path: StringName in [&"path_agriculture", &"path_herding"]:
			var sim: Simulation = _settled(rng_seed, path)
			var bot: DecisionBot = DecisionBot.new()
			var asked: int = 0
			var last_ask: int = sim.world.tick
			var longest: int = 0
			var seen: Dictionary = {}
			for _tick: int in 330 * DAY_TICKS:
				sim.advance_ticks(1)
				for decision: PendingDecision in sim.world.pending:
					if not seen.has(decision.id):
						seen[decision.id] = true
						asked += 1
						longest = maxi(longest, sim.world.tick - last_ask)
						last_ask = sim.world.tick
				bot.answer_all(sim)
			var label: String = "Seed %d, %s" % [rng_seed, path]
			assert_true(asked >= 28, "%s: %d questions in the Settled Age, want 28+" % [label, asked])
			assert_true(
				longest <= 14 * REAL_HOUR_TICKS,
				"%s: %.1f real hours without a question" % [label, float(longest) / REAL_HOUR_TICKS]
			)


func test_no_settled_line_about_a_villager_is_told_while_they_sleep() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var about: Dictionary = {}
	for event_id: StringName in [
		&"counting_roofs", &"everyones_business", &"same_fence", &"flower_corner",
		&"with_the_herd",
	]:
		assert_true(content.get_event(event_id) != null, "Missing %s" % event_id)
		about[event_id] = true
	var told: int = 0
	for rng_seed: int in [1, 2]:
		var sim: Simulation = _settled(rng_seed, &"path_herding")
		for _tick: int in 250 * DAY_TICKS:
			sim.advance_ticks(1)
			sim.world.pending.clear()
		for entry: JournalEntry in sim.world.journal:
			if not about.has(entry.event_id):
				continue
			told += 1
			assert_false(
				sim.config.is_sleeping_hour(sim.config.hour_of(entry.tick)),
				"Told at %02d:00: %s" % [sim.config.hour_of(entry.tick), entry.text]
			)
	assert_gt(told, 3, "Enough lines were told for the check to mean something")
