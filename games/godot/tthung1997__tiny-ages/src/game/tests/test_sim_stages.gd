extends McpTestSuite
## The small decisions and journal lines that fill the Cave Age between its milestones, and the
## economy they run on: stores that hover instead of piling up (docs/gameplay.md P2, P3, P10).

const STORY_DECISIONS: Array[StringName] = [
	&"wolf_at_the_edge", &"hungry_mornings", &"flint_edge", &"first_hard_frost",
	&"strange_prints", &"too_much_food", &"second_hearth", &"mammoth_neighbour", &"work_song",
	&"crowded_wall", &"living_story", &"smoke_on_the_ridge", &"newcomers_shelter",
	&"rising_river", &"wild_grain", &"hurt_deer", &"trader", &"star_watching", &"tools_pile",
	&"smoke_in_the_cave",
]
## Journal lines that only happen once an earlier answer set a flag: line id -> flag.
const REMEMBERED: Dictionary = {
	&"wolf_waits": &"wolf_fed", &"wolf_howl": &"wolf_driven_off", &"song_again": &"work_song",
	&"herd_on_the_wall": &"art_herd", &"moon_on_the_wall": &"art_sky",
	&"two_fires": &"second_hearth", &"snare_rabbit": &"snares", &"mammoth_stays": &"mammoth_fed",
	&"deer_returns": &"deer_tended", &"hunter_overhead": &"star_names",
	&"tale_told_again": &"living_tale", &"hunters_home": &"path_hunting",
	&"one_that_got_away": &"path_hunting", &"baskets_full": &"path_foraging",
}
const DAY_TICKS: int = 24
const REAL_HOUR_TICKS: int = 72


func suite_name() -> String:
	return "sim_stages"


func _plenty_sim() -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 60
	sim.world.resources[&"food"] = 60
	return sim


func test_every_story_decision_exists_and_has_two_ways_to_answer() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for event_id: StringName in STORY_DECISIONS:
		var event: EventDef = content.get_event(event_id)
		assert_true(event != null, "Missing story decision %s" % event_id)
		if event == null:
			continue
		assert_true(event.is_decision(), "%s should ask something" % event_id)
		assert_eq(event.choices.size(), 2, "%s should have two answers" % event_id)
		assert_true(
			event.once or event_id == &"hungry_mornings", "%s should be asked once" % event_id
		)


func test_every_answer_to_every_story_decision_resolves_and_is_remembered() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for event_id: StringName in STORY_DECISIONS:
		var event: EventDef = content.get_event(event_id)
		for choice: ChoiceDef in event.choices:
			var sim: Simulation = _plenty_sim()
			var subject: VillagerState = sim.world.villagers[0]
			var journal_before: int = sim.world.journal.size()
			sim.fire_event(event, subject if event.needs_subject else null)
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
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 0
	sim.world.resources[&"food"] = 0
	for event_id: StringName in [
		&"wolf_at_the_edge", &"first_hard_frost", &"newcomers_shelter", &"trader",
	]:
		var event: EventDef = content.get_event(event_id)
		var open: int = 0
		for choice: ChoiceDef in event.choices:
			if sim.choice_available(choice, sim.world.villagers[0]):
				open += 1
		assert_eq(open, 1, "%s: only the free answer with nothing in store" % event_id)


func test_paying_for_an_answer_takes_the_stock() -> void:
	var sim: Simulation = _plenty_sim()
	var event: EventDef = SimFixture.load_content().get_event(&"first_hard_frost")
	sim.fire_event(event, null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"first_hard_frost")
	assert_true(sim.resolve_decision(decision.id, &"keep_fire_high"))
	assert_eq(sim.world.resource_amount(&"wood"), 52)
	assert_true(sim.world.has_flag(&"warm_winter"))


func test_remembered_lines_only_happen_after_the_answer_that_earned_them() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for line_id: StringName in REMEMBERED:
		var event: EventDef = content.get_event(line_id)
		assert_true(event != null, "Missing line %s" % line_id)
		if event == null:
			continue
		var sim: Simulation = SimFixture.new_sim()
		SimFixture.jump_to_day(sim, 400)
		assert_false(
			SimCondition.all_met(event.requires, sim.world, sim.config),
			"%s should wait for its flag" % line_id
		)
		sim.world.flags[REMEMBERED[line_id]] = true
		assert_true(
			SimCondition.all_met(event.requires, sim.world, sim.config),
			"%s should be possible once %s is set" % [line_id, REMEMBERED[line_id]]
		)


func test_following_the_prints_sends_a_scout_who_comes_home_with_food() -> void:
	var sim: Simulation = _plenty_sim()
	sim.world.resources[&"food"] = 0
	var scout: VillagerState = sim.world.villagers[0]
	var event: EventDef = SimFixture.load_content().get_event(&"strange_prints")
	sim.fire_event(event, scout)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"strange_prints")
	assert_true(sim.resolve_decision(decision.id, &"follow_the_prints"))
	assert_true(scout.is_away())
	sim.advance_ticks(19)
	assert_false(scout.is_away(), "Home after 18 ticks")
	assert_gt(SimFixture.journal_index(sim.world, "pine nuts"), -1)
	assert_gt(sim.world.resource_amount(&"food"), 0)


func test_the_ridge_scout_finds_footprints() -> void:
	var sim: Simulation = _plenty_sim()
	var scout: VillagerState = sim.world.villagers[0]
	sim.fire_event(SimFixture.load_content().get_event(&"smoke_on_the_ridge"), scout)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"smoke_on_the_ridge")
	assert_true(sim.resolve_decision(decision.id, &"climb_up"))
	sim.advance_ticks(15)
	assert_true(sim.world.has_flag(&"ridge_footprints"))
	assert_false(scout.is_away())


func test_the_hunger_question_only_appears_when_food_is_low() -> void:
	var event: EventDef = SimFixture.load_content().get_event(&"hungry_mornings")
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 10)
	sim.world.resources[&"food"] = 2
	assert_true(SimCondition.all_met(event.requires, sim.world, sim.config), "Low food: asked")
	sim.world.resources[&"food"] = 30
	assert_false(SimCondition.all_met(event.requires, sim.world, sim.config), "Plenty: not asked")


func test_stories_for_the_two_routes_to_shared_stories_do_not_overlap() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var wall: EventDef = content.get_event(&"crowded_wall")
	var story: EventDef = content.get_event(&"living_story")
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 200)
	sim.world.achievements.append(&"shared_stories")
	assert_true(SimCondition.all_met(story.requires, sim.world, sim.config))
	assert_false(SimCondition.all_met(wall.requires, sim.world, sim.config))
	sim.world.flags[&"cave_art"] = true
	assert_false(SimCondition.all_met(story.requires, sim.world, sim.config))
	assert_true(SimCondition.all_met(wall.requires, sim.world, sim.config))


func test_a_bot_is_asked_something_every_few_real_hours_through_the_cave_age() -> void:
	for rng_seed: int in [1, 2]:
		var sim: Simulation = SimFixture.new_sim(rng_seed, false)
		var bot: DecisionBot = DecisionBot.new()
		var asked: int = 0
		var last_ask: int = 0
		var longest: int = 0
		var seen: Dictionary = {}
		var cave_ticks: int = 360 * DAY_TICKS
		for _tick: int in cave_ticks:
			sim.advance_ticks(1)
			for decision: PendingDecision in sim.world.pending:
				if not seen.has(decision.id):
					seen[decision.id] = true
					asked += 1
					longest = maxi(longest, sim.world.tick - last_ask)
					last_ask = sim.world.tick
			bot.answer_all(sim)
		assert_true(
			asked >= 22, "Seed %d: %d questions in the Cave Age, want 22+" % [rng_seed, asked]
		)
		assert_true(
			longest <= 18 * REAL_HOUR_TICKS,
			"Seed %d: %.1f real hours without a question"
			% [rng_seed, float(longest) / REAL_HOUR_TICKS]
		)


func test_the_subject_awake_condition_follows_the_sleeping_hours() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var villager: VillagerState = sim.world.villagers[0]
	var awake: SimCondition = SimCondition.new()
	awake.kind = SimCondition.Kind.SUBJECT_AWAKE
	for hour: int in 24:
		sim.world.tick = sim.config.tick_for_hour(hour)
		var sleeping: bool = sim.config.is_sleeping_hour(hour)
		assert_eq(awake.is_met(sim.world, sim.config, villager), not sleeping, "Hour %d" % hour)
	assert_false(awake.is_met(sim.world, sim.config, null), "Needs a subject, like the others")


func test_no_line_about_a_villager_is_told_while_they_sleep() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var about: Dictionary = {}
	for event: EventDef in content.events:
		if event.needs_subject and event.chance_per_tick > 0.0 and not event.is_decision():
			about[event.id] = true
	assert_true(about.size() >= 8, "There are trait-based lines to check")
	var told: int = 0
	for rng_seed: int in [1, 2]:
		var sim: Simulation = SimFixture.new_sim(rng_seed)
		var bot: DecisionBot = DecisionBot.new()
		for _tick: int in 120 * DAY_TICKS:
			sim.advance_ticks(1)
			bot.answer_all(sim)
		for entry: JournalEntry in sim.world.journal:
			if not about.has(entry.event_id):
				continue
			told += 1
			assert_false(
				sim.config.is_sleeping_hour(sim.config.hour_of(entry.tick)),
				"Told at %02d:00 about %s: %s"
				% [sim.config.hour_of(entry.tick), entry.subject_id, entry.text]
			)
	assert_gt(told, 10, "Enough lines were told for the check to mean something")


func test_stores_hover_instead_of_piling_up() -> void:
	var sim: Simulation = SimFixture.new_sim(3, false)
	var bot: DecisionBot = DecisionBot.new()
	for _tick: int in 300 * DAY_TICKS:
		sim.advance_ticks(1)
		bot.answer_all(sim)
	var wood: int = sim.world.resource_amount(&"wood")
	var food: int = sim.world.resource_amount(&"food")
	assert_true(wood < 300, "Wood: %d" % wood)
	assert_true(food < 300, "Food: %d" % food)


func test_villagers_gather_far_less_of_what_the_stores_already_hold() -> void:
	var poor: Simulation = SimFixture.new_sim(5)
	var rich: Simulation = SimFixture.new_sim(5)
	poor.world.resources[&"wood"] = 0
	var comfortable: int = rich.config.comfortable_stock
	rich.world.resources[&"wood"] = comfortable
	poor.advance_ticks(10 * DAY_TICKS)
	rich.advance_ticks(10 * DAY_TICKS)
	var poor_gain: int = poor.world.resource_amount(&"wood")
	var rich_gain: int = rich.world.resource_amount(&"wood") - comfortable
	assert_gt(poor_gain, 0, "A short store gets gathered")
	assert_true(
		rich_gain * 2 < poor_gain, "A full store barely grows (%d vs %d)" % [rich_gain, poor_gain]
	)


func test_buildings_stop_adding_to_full_stores() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var spot: BuildingState = BuildingState.new()
	spot.def_id = &"knapping_spot"
	spot.complete = true
	sim.world.buildings.append(spot)
	var system: ConstructionSystem = ConstructionSystem.new()
	sim.world.resources[&"wood"] = 0
	for _tick: int in DAY_TICKS * 4:
		system.step(sim)
	assert_gt(sim.world.resource_amount(&"wood"), 0, "A short store gets topped up")
	sim.world.resources[&"wood"] = sim.config.comfortable_stock
	sim.world.resource_fraction.clear()
	for _tick: int in DAY_TICKS * 4:
		system.step(sim)
	assert_eq(sim.world.resource_amount(&"wood"), sim.config.comfortable_stock)
