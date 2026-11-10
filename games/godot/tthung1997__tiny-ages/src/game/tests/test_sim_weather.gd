extends McpTestSuite
## Seasons and weather (docs/gameplay.md P14): the calendar, spells and what they slow, damage
## and mending, and the rule that waiting never makes anything worse.

const DAY: int = SimFixture.TICKS_PER_DAY
const SAVE_PATH: String = "user://test_weather_save.tres"
## Season-named story decisions and the season each waits for.
const SEASONAL: Dictionary = {
	&"first_hard_frost": Season.WINTER, &"first_snow": Season.WINTER,
	&"rising_river": Season.SPRING, &"a_wet_summer": Season.SUMMER,
	&"midsummer": Season.SUMMER, &"a_lean_spring": Season.SPRING,
	&"winter_count": Season.AUTUMN, &"first_calves": Season.SPRING,
	&"the_flood": Season.SPRING,
}
const FORKS: Array[StringName] = [
	&"river_over_its_banks", &"thunder_storm", &"dry_summer", &"tornado",
]


var _content: ContentLibrary
var _events: Array[EventDef] = []


func suite_name() -> String:
	return "sim_weather"


func teardown() -> void:
	if _content != null:
		_content.events = _events
		_content = null
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


## A sim with no events and nobody to eat or forage, so only what a test sets up happens. The
## content is shared, so the events are put back in teardown.
func _quiet_sim() -> Simulation:
	var sim: Simulation = SimFixture.new_sim(5)
	_content = sim.content
	_events = sim.content.events.duplicate()
	sim.content.events = []
	sim.world.villagers.clear()
	sim.world.resources[&"food"] = 0
	sim.world.resources[&"wood"] = 0
	return sim


func _build(sim: Simulation, def_id: StringName) -> BuildingState:
	var building: BuildingState = BuildingState.new()
	building.id = sim.world.new_id("building_")
	building.def_id = def_id
	building.complete = true
	sim.world.buildings.append(building)
	return building


func _food(sim: Simulation) -> float:
	return float(sim.world.resource_amount(&"food")) + sim.world.resource_fraction.get(&"food", 0.0)


func _food_in_a_day(sim: Simulation) -> float:
	var before: float = _food(sim)
	sim.advance_ticks(DAY)
	return _food(sim) - before


func test_a_year_is_four_seasons_of_twenty_days() -> void:
	var config: SimConfig = SimFixture.load_config()
	assert_eq(config.season_at(0), Season.SPRING, "A new world starts in spring")
	assert_eq(config.season_at(19 * DAY + 23), Season.SPRING)
	assert_eq(config.season_at(20 * DAY), Season.SUMMER)
	assert_eq(config.season_at(40 * DAY), Season.AUTUMN)
	assert_eq(config.season_at(60 * DAY), Season.WINTER)
	assert_eq(config.season_at(80 * DAY), Season.SPRING, "The year comes round")
	assert_eq(config.day_of_season(25 * DAY), 5)
	assert_eq(Season.describe(Season.SPRING, 1, 20), "Early spring")
	assert_eq(Season.describe(Season.SPRING, 10, 20), "Spring")
	assert_eq(Season.describe(Season.SPRING, 18, 20), "Late spring")


func test_the_season_condition_reads_the_calendar() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var condition: SimCondition = SimCondition.new()
	condition.kind = SimCondition.Kind.SEASON_IS
	condition.amount = Season.SUMMER
	assert_false(condition.is_met(sim.world, sim.config))
	SimFixture.jump_to_day(sim, 25)
	assert_true(condition.is_met(sim.world, sim.config))
	condition.negate = true
	assert_false(condition.is_met(sim.world, sim.config))


func test_a_spell_lasts_its_span_then_the_sky_clears() -> void:
	var sim: Simulation = _quiet_sim()
	var changes: Array[StringName] = []
	sim.weather_changed.connect(func(id: StringName) -> void: changes.append(id))
	sim.set_weather(&"drought")
	assert_eq(sim.world.weather, &"drought")
	var def: WeatherDef = sim.content.get_weather(&"drought")
	var span: int = sim.world.weather_until_tick - sim.world.tick
	assert_true(span >= int(def.min_days) * DAY and span <= int(def.max_days) * DAY)
	sim.advance_ticks(span - 1)
	assert_eq(sim.world.weather, &"drought")
	sim.advance_ticks(1)
	assert_eq(sim.world.weather, &"")
	assert_eq(changes, [&"drought", &""])


func test_a_tornado_leaves_wreckage_that_clears_by_itself() -> void:
	var sim: Simulation = _quiet_sim()
	sim.set_weather(&"tornado")
	sim.advance_ticks(DAY)
	assert_eq(sim.world.weather, &"debris")
	assert_true(sim.food_multiplier() < 1.0)
	sim.advance_ticks(DAY * 7)
	assert_eq(sim.world.weather, &"", "Nothing waits on the player to clear")


func test_every_harmful_weather_slows_the_food() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for id: StringName in [&"storm", &"drought", &"flood", &"tornado", &"debris"]:
		var def: WeatherDef = content.get_weather(id)
		assert_true(def != null and def.food_multiplier < 1.0, "%s slows food" % id)
	for id: StringName in [&"rain", &"snow"]:
		assert_eq(content.get_weather(id).food_multiplier, 1.0, "%s is only scenery" % id)


func test_weather_slows_a_buildings_food() -> void:
	var sim: Simulation = _quiet_sim()
	_build(sim, &"field")
	var clear: float = _food_in_a_day(sim)
	assert_true(absf(clear - 3.0) < 0.01, "A field brings in 3 food a day, got %f" % clear)
	sim.set_weather(&"drought", DAY * 3)
	var dry: float = _food_in_a_day(sim)
	assert_true(absf(dry - 3.0 * 0.65) < 0.01, "A drought slows it, got %f" % dry)


func test_a_damaged_building_gives_half_until_mended() -> void:
	var sim: Simulation = _quiet_sim()
	var field: BuildingState = _build(sim, &"field")
	sim.damage_building(&"river", "")
	assert_true(field.damaged)
	var half: float = _food_in_a_day(sim)
	assert_true(absf(half - 1.5) < 0.01, "Half the output, got %f" % half)
	sim.repair_buildings()
	assert_false(field.damaged)
	assert_true(absf(_food_in_a_day(sim) - 3.0) < 0.01)


func test_damage_mends_itself_in_time() -> void:
	var sim: Simulation = _quiet_sim()
	var field: BuildingState = _build(sim, &"field")
	sim.damage_building(&"", "")
	sim.advance_ticks(DAY * (sim.config.self_repair_days - 1))
	assert_true(field.damaged)
	sim.advance_ticks(DAY * 2)
	assert_false(field.damaged, "The villagers mend it with their own hands")
	assert_gt(SimFixture.journal_index(sim.world, "mended by the villagers"), -1)


func test_weather_reaches_only_what_it_can() -> void:
	var sim: Simulation = _quiet_sim()
	var hut: BuildingState = _build(sim, &"hut")
	assert_true(sim.damage_building(&"river", "") == null, "A hut is not by the river")
	assert_false(hut.damaged)
	assert_true(sim.damage_building(&"exposed", "The {building} broke.") == hut)
	assert_gt(SimFixture.journal_index(sim.world, "The Hut broke."), -1)
	assert_true(sim.damage_building(&"", "") == null, "It cannot break twice")


func test_the_building_conditions_follow_damage() -> void:
	var sim: Simulation = _quiet_sim()
	_build(sim, &"field")
	var reachable: SimCondition = SimCondition.new()
	reachable.kind = SimCondition.Kind.HAS_BUILDING_TAG
	reachable.key = &"river"
	var damaged: SimCondition = SimCondition.new()
	damaged.kind = SimCondition.Kind.HAS_DAMAGED_BUILDING
	assert_true(reachable.is_met(sim.world, sim.config))
	assert_false(damaged.is_met(sim.world, sim.config))
	sim.damage_building(&"river", "")
	assert_false(reachable.is_met(sim.world, sim.config))
	assert_true(damaged.is_met(sim.world, sim.config))


func test_weather_and_damage_survive_a_save() -> void:
	var sim: Simulation = _quiet_sim()
	var field: BuildingState = _build(sim, &"field")
	sim.damage_building(&"", "")
	sim.set_weather(&"flood")
	assert_eq(SaveStore.save_world(sim.world, SAVE_PATH), OK)
	var loaded: WorldState = SaveStore.load_world(SAVE_PATH)
	assert_eq(loaded.weather, &"flood")
	assert_eq(loaded.weather_until_tick, sim.world.weather_until_tick)
	assert_true(loaded.buildings[0].damaged and field.damaged)
	assert_eq(loaded.buildings[0].damaged_tick, field.damaged_tick)


func test_a_save_from_before_weather_loads_clear() -> void:
	assert_eq(WorldState.new().weather, &"")
	assert_false(BuildingState.new().damaged)


func test_catching_up_through_weather_equals_ticking() -> void:
	var away: Simulation = SimFixture.new_sim(11)
	var present: Simulation = SimFixture.new_sim(11)
	var ticks: int = DAY * 90
	away.advance_real_time(SimFixture.START_UNIX)
	away.advance_real_time(SimFixture.START_UNIX + away.config.seconds_per_tick() * float(ticks))
	present.advance_ticks(ticks)
	assert_eq(SimFixture.snapshot(away.world), SimFixture.snapshot(present.world))


func test_the_same_seed_gives_the_same_weather() -> void:
	var first: Array = _weather_log(8)
	var second: Array = _weather_log(8)
	assert_gt(first.size(), 0, "Some weather happened in a year")
	assert_eq(first, second)


func _weather_log(rng_seed: int) -> Array:
	var sim: Simulation = SimFixture.new_sim(rng_seed)
	var log: Array = []
	var world: WorldState = sim.world
	sim.weather_changed.connect(
		func(id: StringName) -> void: log.append([world.tick, id])
	)
	sim.advance_ticks(DAY * 120)
	return log


func test_a_decision_asked_in_its_season_waits_through_the_turn() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 65)
	sim.fire_event(sim.content.get_event(&"first_hard_frost"), null)
	assert_true(SimFixture.pending_for(sim, &"first_hard_frost") != null)
	SimFixture.jump_to_day(sim, 85)
	sim.advance_ticks(1)
	assert_true(
		SimFixture.pending_for(sim, &"first_hard_frost") != null,
		"Spring does not withdraw a question asked in winter"
	)


func test_season_named_story_waits_for_its_season() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for id: StringName in SEASONAL:
		var event: EventDef = content.get_event(id)
		var gated: bool = false
		for condition: SimCondition in event.requires:
			if condition.kind == SimCondition.Kind.SEASON_IS and not condition.negate:
				gated = condition.amount == SEASONAL[id]
		assert_true(gated, "%s waits for %s" % [id, Season.display_name(SEASONAL[id])])


func test_flood_only_comes_from_rain() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var floods: int = 0
	for event: EventDef in content.events:
		var starts_flood: bool = false
		for effect: SimEffect in event.effects:
			if effect.kind == SimEffect.Kind.SET_WEATHER and effect.key == &"flood":
				starts_flood = true
		if not starts_flood:
			continue
		floods += 1
		var needs_rain: bool = false
		for condition: SimCondition in event.requires:
			if condition.kind == SimCondition.Kind.WEATHER_IS and condition.key == &"rain":
				needs_rain = not condition.negate
		assert_true(needs_rain, "%s needs rain" % event.id)
	assert_gt(floods, 0)


func test_the_tornado_is_a_rare_settled_thing() -> void:
	var event: EventDef = SimFixture.load_content().get_event(&"tornado")
	var settled_only: bool = false
	for condition: SimCondition in event.requires:
		if condition.kind == SimCondition.Kind.ERA_AT_LEAST and condition.amount >= 1:
			settled_only = true
	assert_true(settled_only)
	assert_true(event.chance_per_tick <= 0.001)


func test_an_earlier_answer_guards_against_the_flood() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_build(sim, &"field")
	sim.world.weather = &"rain"
	var flood: EventDef = sim.content.get_event(&"river_over_its_banks")
	assert_true(SimCondition.all_met(flood.requires, sim.world, sim.config))
	sim.world.flags[&"river_bank"] = true
	assert_false(SimCondition.all_met(flood.requires, sim.world, sim.config), "The bank holds")
	assert_true(
		SimCondition.all_met(
			sim.content.get_event(&"bank_holds").requires, sim.world, sim.config
		)
	)


func test_a_flood_fork_damages_and_offers_two_ways_on() -> void:
	var sim: Simulation = SimFixture.new_sim(3)
	var field: BuildingState = _build(sim, &"field")
	sim.world.resources[&"wood"] = 20
	var flood: EventDef = sim.content.get_event(&"river_over_its_banks")
	sim.fire_event(flood, null)
	assert_eq(sim.world.weather, &"flood")
	assert_true(field.damaged)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"river_over_its_banks")
	assert_true(decision != null, "The damage opens a decision")
	assert_true(sim.resolve_decision(decision.id, &"raise_it_again"))
	assert_false(field.damaged)
	assert_eq(sim.world.resource_amount(&"wood"), 12)


func test_waiting_for_the_water_costs_no_wood_and_leaves_the_damage_to_time() -> void:
	var sim: Simulation = SimFixture.new_sim(3)
	var field: BuildingState = _build(sim, &"field")
	sim.world.resources[&"wood"] = 20
	sim.fire_event(sim.content.get_event(&"river_over_its_banks"), null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"river_over_its_banks")
	assert_true(sim.resolve_decision(decision.id, &"wait_for_the_water"))
	assert_true(field.damaged)
	assert_eq(sim.world.resource_amount(&"wood"), 20)
	assert_true(sim.world.has_flag(&"wait_for_the_water"))


func test_a_fork_needs_wood_for_its_first_answer_or_it_is_not_asked() -> void:
	var sim: Simulation = SimFixture.new_sim(3)
	var event: EventDef = sim.content.get_event(&"thunder_storm")
	sim.world.resources[&"wood"] = 0
	var open: int = 0
	for choice: ChoiceDef in event.choices:
		if sim.choice_available(choice, null):
			open += 1
	assert_eq(open, 1, "Only one answer is open without wood, so it is not a decision")


## Plays a few years with the bot: weather forks stay rare, and every season-named decision
## is asked in its season.
func test_a_played_stretch_keeps_weather_rare_and_story_in_season() -> void:
	var sim: Simulation = SimFixture.new_sim(2, false)
	var bot: DecisionBot = DecisionBot.new()
	var spells: Array[int] = [0]
	sim.weather_changed.connect(func(id: StringName) -> void: spells[0] += 1 if id != &"" else 0)
	for _tick: int in DAY * 260:
		sim.advance_ticks(1)
		bot.answer_all(sim)
	var forks: int = 0
	for id: StringName in FORKS:
		forks += sim.world.event_counts.get(id, 0)
	assert_true(forks <= 8, "Weather forks stayed rare (%d in three years)" % forks)
	assert_gt(spells[0], 2, "There was weather to see")
	for id: StringName in SEASONAL:
		if sim.world.event_counts.get(id, 0) > 0:
			var last: int = sim.world.event_last_tick[id]
			assert_eq(sim.config.season_at(last), SEASONAL[id], "%s fired in its season" % id)
