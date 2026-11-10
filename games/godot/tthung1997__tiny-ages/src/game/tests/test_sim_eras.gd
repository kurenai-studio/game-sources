extends McpTestSuite
## Ages: the settlement starts in the Cave Age, moves forward only, and era-gated content
## appears and disappears accordingly. How an age is entered is tested in test_sim_gate.gd.

const DAY: int = SimFixture.TICKS_PER_DAY
const SAVE_PATH: String = "user://test_era_save.tres"


func suite_name() -> String:
	return "sim_eras"


func teardown() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func test_a_new_world_starts_in_the_cave_age() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(sim.world.era, &"cave")
	assert_eq(sim.world.era_order, 0)


func test_era_conditions_follow_the_current_age() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var settled_or_later: SimCondition = SimCondition.new()
	settled_or_later.kind = SimCondition.Kind.ERA_AT_LEAST
	settled_or_later.amount = 1
	assert_false(settled_or_later.is_met(sim.world, sim.config))
	sim.advance_era(&"settled")
	assert_true(settled_or_later.is_met(sim.world, sim.config))


func test_ages_only_move_forward() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_false(sim.advance_era(&"cave"), "Already in the Cave Age")
	assert_false(sim.advance_era(&"no_such_age"))
	assert_true(sim.advance_era(&"settled"))
	assert_false(sim.advance_era(&"cave"), "No going back")
	assert_false(sim.advance_era(&"settled"), "Already there")
	assert_eq(sim.world.era, &"settled")


func test_entering_an_age_is_journaled_and_announced() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var announced: Array[StringName] = []
	sim.era_advanced.connect(func(era: EraDef) -> void: announced.append(era.id))
	sim.advance_era(&"settled")
	assert_eq(announced, [&"settled"] as Array[StringName])
	assert_gt(SimFixture.journal_index(sim.world, "a new way of living began"), -1)


func test_settled_age_buildings_wait_for_the_settled_age() -> void:
	var sim: Simulation = SimFixture.new_sim(3)
	for _tick: int in DAY * 10:
		sim.advance_ticks(1)
		sim.world.resources[&"wood"] = 50
	assert_eq(sim.world.event_counts.get(&"settled_building_opportunity", 0), 0)
	sim.advance_era(&"settled")
	sim.world.resources[&"wood"] = 50
	var used: int = SimFixture.advance_until_asked(sim, &"settled_building_opportunity", DAY * 25)
	assert_gt(used, 0, "Once settled, field and hut decisions open")


func test_cave_only_events_stop_in_the_settled_age() -> void:
	var cave: Simulation = SimFixture.new_sim(8)
	cave.advance_ticks(DAY * 400)
	assert_gt(cave.world.event_counts.get(&"cold_night", 0), 0, "Cold nights happen in the cave")
	var settled: Simulation = SimFixture.new_sim(8)
	settled.advance_era(&"settled")
	settled.advance_ticks(DAY * 400)
	assert_eq(settled.world.event_counts.get(&"cold_night", 0), 0)


func test_the_era_is_saved() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	SaveStore.save_world(sim.world, SAVE_PATH)
	var loaded: WorldState = SaveStore.load_world(SAVE_PATH)
	assert_eq(loaded.era, &"settled")
	assert_eq(loaded.era_order, 1)
	assert_eq(loaded.era_started_tick, sim.world.era_started_tick)


func test_a_new_age_waits_to_be_told_until_acknowledged() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(sim.world.unseen_era, &"")
	sim.advance_era(&"settled")
	assert_eq(sim.world.unseen_era, &"settled")
	SaveStore.save_world(sim.world, SAVE_PATH)
	assert_eq(SaveStore.load_world(SAVE_PATH).unseen_era, &"settled", "Quitting does not lose it")
	sim.acknowledge_era()
	assert_eq(sim.world.unseen_era, &"")
	assert_eq(sim.world.era, &"settled", "Telling the player changes nothing else")


func test_validation_catches_broken_era_references() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	var far_future: SimCondition = SimCondition.new()
	far_future.kind = SimCondition.Kind.ERA_AT_LEAST
	far_future.amount = 9
	content.events[0].requires.append(far_future)
	var unknown_age: SimEffect = SimEffect.new()
	unknown_age.kind = SimEffect.Kind.ADVANCE_ERA
	unknown_age.key = &"space_age"
	content.events[0].effects.append(unknown_age)
	assert_gt(content.validate().size(), 1)
