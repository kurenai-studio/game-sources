extends McpTestSuite
## Villagers live on their own: sleep, work, bias by trait, and come home from trips.


func suite_name() -> String:
	return "sim_villagers"


func test_villagers_sleep_at_night() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(23) - 1
	sim.advance_ticks(1)
	for villager: VillagerState in sim.world.villagers:
		assert_eq(villager.activity, VillagerState.ACTIVITY_REST)


func test_villagers_gather_resources_by_day() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_ticks(SimFixture.TICKS_PER_DAY * 2)
	var gathered: int = sim.world.resource_amount(&"wood") + sim.world.resource_amount(&"food")
	assert_gt(gathered, 6, "Two days of work should yield more than the starting stock")


func test_industrious_villagers_gather_wood_more_often() -> void:
	var sim: Simulation = SimFixture.new_sim(7)
	SimFixture.set_traits(sim, [
		[VillagerState.TRAIT_INDUSTRIOUS, VillagerState.TRAIT_SOCIAL],
		[VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING],
		[VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_NATURE_LOVING],
	])
	var worker: VillagerState = sim.world.villagers[0]
	var other: VillagerState = sim.world.villagers[1]
	var worker_ticks: int = 0
	var other_ticks: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * 20:
		sim.advance_ticks(1)
		sim.world.pending.clear()
		if worker.activity == VillagerState.ACTIVITY_GATHER_WOOD:
			worker_ticks += 1
		if other.activity == VillagerState.ACTIVITY_GATHER_WOOD:
			other_ticks += 1
	assert_gt(worker_ticks, other_ticks, "An industrious villager should gather wood more often")


func test_away_villager_comes_home_on_time() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var scout: VillagerState = sim.world.villagers[0]
	scout.activity = VillagerState.ACTIVITY_AWAY
	scout.location = &"western_forest"
	scout.away_until_tick = sim.world.tick + 5
	sim.advance_ticks(4)
	assert_true(scout.is_away(), "Still away one tick early")
	sim.advance_ticks(1)
	assert_false(scout.is_away())
	assert_eq(scout.location, VillagerState.LOCATION_CAMP)


func test_same_seed_gives_the_same_world() -> void:
	var first: Simulation = SimFixture.new_sim(42)
	var second: Simulation = SimFixture.new_sim(42)
	first.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	second.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	assert_eq(SimFixture.snapshot(first.world), SimFixture.snapshot(second.world))


func test_different_seeds_diverge() -> void:
	var first: Simulation = SimFixture.new_sim(1)
	var second: Simulation = SimFixture.new_sim(2)
	first.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	second.advance_ticks(SimFixture.TICKS_PER_DAY * 5)
	assert_ne(SimFixture.snapshot(first.world), SimFixture.snapshot(second.world))


## Counts, over some days, how many villager-ticks were spent on an activity.
func _ticks_spent(sim: Simulation, activity: StringName, days: int) -> int:
	var total: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * days:
		sim.advance_ticks(1)
		for villager: VillagerState in sim.world.villagers:
			if villager.activity == activity:
				total += 1
	return total


func test_nobody_hunts_unless_the_group_chose_to_hunt() -> void:
	var sim: Simulation = SimFixture.new_sim(4)
	assert_eq(_ticks_spent(sim, VillagerState.ACTIVITY_HUNT, 30), 0)
	var hunters: Simulation = SimFixture.new_sim(4)
	hunters.world.flags[&"path_hunting"] = true
	assert_gt(_ticks_spent(hunters, VillagerState.ACTIVITY_HUNT, 30), 0, "A hunting group hunts")


func test_the_foraging_path_never_hunts() -> void:
	var sim: Simulation = SimFixture.new_sim(4)
	sim.world.flags[&"path_foraging"] = true
	assert_eq(_ticks_spent(sim, VillagerState.ACTIVITY_HUNT, 30), 0)


func test_a_hunt_brings_back_more_food_than_foraging() -> void:
	var system: VillagerSystem = VillagerSystem.new()
	var gains: Dictionary = {}
	for activity: StringName in [VillagerState.ACTIVITY_FORAGE, VillagerState.ACTIVITY_HUNT]:
		var sim: Simulation = SimFixture.new_sim()
		sim.world.resources[&"food"] = 0
		var villager: VillagerState = sim.world.villagers[0]
		villager.traits.clear()
		villager.activity = activity
		for _tick: int in 48:
			system._work(sim, villager, 1, 1)
		gains[activity] = sim.world.resource_amount(&"food")
	assert_gt(gains[VillagerState.ACTIVITY_HUNT], gains[VillagerState.ACTIVITY_FORAGE])


func test_hunters_rest_through_the_night_like_everyone() -> void:
	var sim: Simulation = SimFixture.new_sim(4)
	sim.world.flags[&"path_hunting"] = true
	for villager: VillagerState in sim.world.villagers:
		villager.activity = VillagerState.ACTIVITY_HUNT
		villager.activity_ticks_left = 50
	sim.world.tick = sim.config.tick_for_hour(23) - 1
	sim.advance_ticks(1)
	for villager: VillagerState in sim.world.villagers:
		assert_eq(villager.activity, VillagerState.ACTIVITY_REST)


func test_a_full_larder_makes_hunting_rare() -> void:
	var hungry: Simulation = SimFixture.new_sim(4)
	var full: Simulation = SimFixture.new_sim(4)
	for sim: Simulation in [hungry, full]:
		sim.world.flags[&"path_hunting"] = true
	var comfortable: int = full.config.comfortable_stock
	var hunting_hungry: int = 0
	var hunting_full: int = 0
	for _tick: int in SimFixture.TICKS_PER_DAY * 20:
		hungry.world.resources[&"food"] = 0
		full.world.resources[&"food"] = comfortable
		hungry.advance_ticks(1)
		full.advance_ticks(1)
		for villager: VillagerState in hungry.world.villagers:
			hunting_hungry += 1 if villager.activity == VillagerState.ACTIVITY_HUNT else 0
		for villager: VillagerState in full.world.villagers:
			hunting_full += 1 if villager.activity == VillagerState.ACTIVITY_HUNT else 0
	assert_true(hunting_full * 2 < hunting_hungry, "%d vs %d" % [hunting_full, hunting_hungry])
