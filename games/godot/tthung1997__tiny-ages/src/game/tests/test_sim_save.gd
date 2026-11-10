extends McpTestSuite
## Saving and loading a world loses nothing, and the loaded world carries on identically.

const SAVE_PATH: String = "user://test_world_save.tres"


func suite_name() -> String:
	return "sim_save"


func teardown() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func test_awkward_fractions_survive_a_save_exactly() -> void:
	var sim: Simulation = SimFixture.new_sim()
	for step: int in 80:
		sim.world.add_resource_fraction(&"wood", 0.06)
		sim.world.add_resource_fraction(&"food", 1.0 / 24.0 * 7.0)
		assert_eq(SaveStore.save_world(sim.world, SAVE_PATH), OK)
		var loaded: WorldState = SaveStore.load_world(SAVE_PATH)
		assert_eq(loaded.resource_fraction, sim.world.resource_fraction, "Step %d" % step)
		if loaded.resource_fraction != sim.world.resource_fraction:
			return


func test_a_saved_world_loads_back_the_same() -> void:
	var sim: Simulation = _lived_in_sim()
	assert_eq(SaveStore.save_world(sim.world, SAVE_PATH), OK)
	var loaded: WorldState = SaveStore.load_world(SAVE_PATH)
	assert_true(loaded != null)
	assert_eq(SimFixture.snapshot(loaded), SimFixture.snapshot(sim.world))


func test_a_loaded_world_continues_exactly_like_the_original() -> void:
	var sim: Simulation = _lived_in_sim()
	SaveStore.save_world(sim.world, SAVE_PATH)
	var resumed: Simulation = Simulation.new(
		SaveStore.load_world(SAVE_PATH), sim.config, sim.content
	)
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 10)
	resumed.advance_ticks(SimFixture.TICKS_PER_DAY * 10)
	assert_eq(SimFixture.snapshot(resumed.world), SimFixture.snapshot(sim.world))


func test_missing_save_loads_as_null() -> void:
	assert_true(SaveStore.load_world("user://no_such_save.tres") == null)
	assert_false(SaveStore.exists("user://no_such_save.tres"))


## A world with history: a finished building, a pending decision and a trip in progress.
func _lived_in_sim() -> Simulation:
	var sim: Simulation = SimFixture.new_sim(21)
	sim.world.resources[&"wood"] = 10
	sim.fire_event(sim.content.get_event(&"building_opportunity"), null)
	var decision: PendingDecision = SimFixture.pending_for(sim, &"building_opportunity")
	sim.resolve_decision(decision.id, &"build_lookout")
	SimFixture.advance_until_built(sim, &"lookout", SimFixture.TICKS_PER_DAY * 6)
	SimFixture.jump_to_day(sim, 216)
	SimFixture.advance_until_asked(sim, &"curious_explorer", SimFixture.TICKS_PER_DAY * 20)
	var ask: PendingDecision = SimFixture.pending_for(sim, &"curious_explorer")
	sim.resolve_decision(ask.id, &"encourage")
	sim.advance_ticks(SimFixture.TICKS_PER_DAY)
	return sim
