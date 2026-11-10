extends McpTestSuite
## The river and the east page in the view (issue #9): a crossing lets villagers walk to the spit,
## foragers fish, cut reeds and gather shellfish when the world gives them somewhere to, and the
## tide bares the flats. Pure logic, plus the view's few visible switches.

const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "view_river"


func _forager_targets(sim: Simulation, days: int = 6) -> Array[Vector2]:
	var planner: VillagerPlanner = VillagerPlanner.new()
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_FORAGE
	var found: Array[Vector2] = []
	var start: int = sim.world.tick
	for day: int in days:
		for hour: int in range(8, 17):
			sim.world.tick = start + day * DAY + hour
			for slot: int in 3:
				var plan: VillagerPlan = planner.plan(villager, sim.world, sim.config, slot)
				if not found.has(plan.target):
					found.append(plan.target)
	return found


func _any_in(targets: Array[Vector2], spots: Array[Vector2]) -> bool:
	for target: Vector2 in targets:
		if spots.has(target):
			return true
	return false


func test_wanderers_stay_west_of_the_river_until_a_crossing_is_laid() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_WANDER
	sim.world.tick = sim.config.tick_for_hour(10)
	var planner: VillagerPlanner = VillagerPlanner.new()
	for _attempt: int in 40:
		var plan: VillagerPlan = planner.plan(villager, sim.world, sim.config, 0)
		assert_true(plan.target.x <= WorldLayout.WANDER_X.y)
	for crossing: StringName in WorldLayout.CROSSING_FLAGS:
		sim.world.flags.clear()
		sim.world.flags[crossing] = true
		var furthest: float = 0.0
		for _attempt: int in 80:
			furthest = maxf(furthest, planner.plan(villager, sim.world, sim.config, 0).target.x)
		assert_true(furthest > WorldLayout.CROSSING_X.y, "%s: they reach the spit" % crossing)
		assert_true(furthest <= WorldLayout.WANDER_X_CROSSED.y)


func test_the_spit_is_in_the_world_and_the_crossing_spans_the_river() -> void:
	for spots: Array[Vector2] in [
		WorldLayout.FISH_SPOTS, WorldLayout.REED_SPOTS, WorldLayout.FLATS_SPOTS
	]:
		for spot: Vector2 in spots:
			assert_true(spot.x > float(WorldLayout.WORLD_LEFT))
			assert_true(spot.x < float(WorldLayout.WORLD_RIGHT))
			assert_true(spot.y >= WorldLayout.WANDER_Y.x and spot.y <= WorldLayout.WANDER_Y.y)
	for spot: Vector2 in WorldLayout.FISH_SPOTS:
		assert_true(spot.x < WorldLayout.CROSSING_X.x, "Fishers stand on the near bank")
	for spot: Vector2 in WorldLayout.REED_SPOTS:
		assert_true(spot.x > WorldLayout.CROSSING_X.y, "Reeds are cut on the far bank")
	assert_true(WorldLayout.WANDER_X_CROSSED.y > WorldLayout.CROSSING_X.y)


func test_foragers_only_go_where_the_world_has_given_them_a_reason() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var plain: Array[Vector2] = _forager_targets(sim)
	for target: Vector2 in plain:
		assert_true(WorldLayout.FORAGE_SPOTS.has(target), "Just the pines to begin with")
	var fishers: Simulation = SimFixture.new_sim()
	fishers.world.flags[&"fish_by_hand"] = true
	var fishing: Array[Vector2] = _forager_targets(fishers)
	assert_true(_any_in(fishing, WorldLayout.FISH_SPOTS), "They fish after the run of fish")
	assert_false(_any_in(fishing, WorldLayout.REED_SPOTS))
	var reeders: Simulation = SimFixture.new_sim()
	reeders.world.flags[&"reed_beds"] = true
	assert_false(
		_any_in(_forager_targets(reeders), WorldLayout.REED_SPOTS), "No crossing, no reeds"
	)
	reeders.world.flags[&"log_bridge"] = true
	assert_true(_any_in(_forager_targets(reeders), WorldLayout.REED_SPOTS), "Over the river")


func test_a_fisher_spears_the_water_and_a_reed_cutter_faces_the_reeds() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.flags[&"fish_trap"] = true
	sim.world.flags[&"stepping_stones"] = true
	sim.world.flags[&"path_foraging"] = true
	var planner: VillagerPlanner = VillagerPlanner.new()
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_FORAGE
	var saw_fish: bool = false
	var saw_reeds: bool = false
	for tick: int in range(8, 8 + DAY * 6):
		sim.world.tick = tick
		var plan: VillagerPlan = planner.plan(villager, sim.world, sim.config, 1)
		if WorldLayout.FISH_SPOTS.has(plan.target):
			saw_fish = true
			assert_eq(plan.pose, &"spear")
			assert_true(plan.focus_x > plan.target.x, "Facing the water")
		if WorldLayout.REED_SPOTS.has(plan.target):
			saw_reeds = true
			assert_true(plan.focus_x < plan.target.x, "Facing the reeds")
	assert_true(saw_fish and saw_reeds)


func test_shellfish_are_gathered_on_the_flats_at_low_tide_only() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.flags[&"stepping_stones"] = true
	var planner: VillagerPlanner = VillagerPlanner.new()
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_FORAGE
	var low_seen: bool = false
	for tick: int in DAY * 4:
		sim.world.tick = tick
		for slot: int in 3:
			var plan: VillagerPlan = planner.plan(villager, sim.world, sim.config, slot)
			var on_flats: bool = WorldLayout.FLATS_SPOTS.has(plan.target)
			if on_flats:
				low_seen = true
				assert_true(sim.config.is_low_tide(tick), "Nobody wades out at high tide")
				assert_true(plan.focus_x > plan.target.x, "They face the sea")
	assert_true(low_seen, "And they do go when it is low")
	sim.world.flags.clear()
	for tick: int in DAY * 4:
		sim.world.tick = tick
		var plan: VillagerPlan = planner.plan(villager, sim.world, sim.config, 0)
		assert_false(WorldLayout.FLATS_SPOTS.has(plan.target), "No crossing, no flats")


func test_the_flats_widen_as_the_sea_goes_out() -> void:
	assert_eq(TideLook.flats_step(1.0), 0, "Covered at high tide")
	assert_eq(TideLook.flats_step(0.55), 0)
	assert_eq(TideLook.flats_step(0.5), 1)
	assert_eq(TideLook.flats_step(0.3), 2)
	assert_eq(TideLook.flats_step(0.0), WorldLayout.FLATS_STEPS, "Fully out at the lowest")
	var last: int = -1
	for tenth: int in 11:
		var step: int = TideLook.flats_step(1.0 - float(tenth) / 10.0)
		assert_true(step >= last, "Falling water shows more sand")
		last = step
	assert_eq(TideLook.STEP_LEVELS.size(), WorldLayout.FLATS_STEPS)


func test_the_deer_comes_at_dawn_and_dusk() -> void:
	assert_true(RiverLife.deer_visible(6.0))
	assert_true(RiverLife.deer_visible(18.0))
	assert_false(RiverLife.deer_visible(12.0))
	assert_false(RiverLife.deer_visible(2.0))
	assert_false(RiverLife.deer_visible(22.0))


func test_the_river_art_exists() -> void:
	var names: Array[StringName] = []
	for step: int in range(1, WorldLayout.FLATS_STEPS + 1):
		for frame: int in WorldLayout.FLATS_FRAMES:
			names.append(WorldLayout.flats_frame_name(step, frame))
	for frame: int in WorldLayout.LIFE_FRAMES:
		names.append(WorldLayout.life_frame_name(frame))
	for frame: int in WorldLayout.DEER_FRAMES:
		names.append(WorldLayout.deer_frame_name(frame))
	for art: StringName in names:
		assert_true(ResourceLoader.exists("%s%s.png" % [WorldLayout.ASSET_DIR, art]), "%s" % art)


func test_the_view_follows_the_tide_and_the_hour() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	var bare: int = 0
	while sim.config.tide_at(bare) > 0.05:
		bare += 1
	sim.world.tick = bare
	view.on_world_changed()
	assert_true(view._flats.visible, "The flats show at low tide")
	assert_eq(view._flats_step, WorldLayout.FLATS_STEPS)
	var full_width: Texture2D = view._flats.texture
	var covered: int = bare
	while sim.config.tide_at(covered) < 0.8:
		covered += 1
	sim.world.tick = covered
	view.on_world_changed()
	assert_false(view._flats.visible, "The sea covers them at high tide")
	var halfway: int = bare
	while TideLook.flats_step(sim.config.tide_at(halfway)) != 1:
		halfway += 1
	sim.world.tick = halfway
	view.on_world_changed()
	assert_true(view._flats.visible)
	assert_true(view._flats.texture != full_width, "A thinner band as the water comes back")
	view._sea_frame = 1
	view._show_flats_frame()
	assert_eq(view._flats.texture, view._flats_sets[0][1], "The foam laps with the sea")
	var noon: int = DAY * 3 + 12
	sim.world.tick = noon
	view.on_world_changed()
	assert_false(view._deer.visible, "No deer at noon")
	sim.world.tick = DAY * 3 + 6
	view.on_world_changed()
	assert_true(view._deer.visible, "A deer at dawn")
	view.free()


func test_a_crossing_and_the_river_props_show_for_their_flags() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	for prop: StringName in [&"crossing_stones", &"east_crossing_stones", &"crossing_log"]:
		assert_false((view._props[prop] as Sprite2D).visible)
	sim.world.flags[&"stepping_stones"] = true
	view.on_world_changed()
	assert_true((view._props[&"crossing_stones"] as Sprite2D).visible)
	assert_true((view._props[&"east_crossing_stones"] as Sprite2D).visible)
	assert_false((view._props[&"crossing_log"] as Sprite2D).visible, "Only the one that was laid")
	view.free()
