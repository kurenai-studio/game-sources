extends McpTestSuite
## The view's decisions that need no nodes: where villagers go, and the light through the day.


func suite_name() -> String:
	return "view_logic"


func _plan_for(activity: StringName, hour: int = 10) -> VillagerPlan:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(hour)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = activity
	return VillagerPlanner.new().plan(villager, sim.world, sim.config, 0)


func test_asleep_villager_is_hidden_at_night_only() -> void:
	var night: VillagerPlan = _plan_for(VillagerState.ACTIVITY_REST, 23)
	assert_false(night.visible)
	assert_eq(night.hidden_reason, VillagerPlan.HIDDEN_ASLEEP)
	var day: VillagerPlan = _plan_for(VillagerState.ACTIVITY_REST, 12)
	assert_true(day.visible, "Resting by day means sitting by the fire")


func test_away_villager_is_hidden() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_AWAY)
	assert_false(plan.visible)
	assert_eq(plan.hidden_reason, VillagerPlan.HIDDEN_AWAY)


func test_wood_gatherers_chop_at_the_forest_stump() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_GATHER_WOOD)
	assert_eq(plan.pose, &"chop")
	assert_true(WorldLayout.WOOD_SPOTS.has(plan.target))
	assert_eq(plan.focus_x, WorldLayout.CHOP_X)
	assert_true(plan.target.x < 0.0, "Wood is cut in the west forest, not at the camp")


func test_socializing_gathers_at_the_fire() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_SOCIALIZE)
	assert_true(WorldLayout.SOCIAL_SPOTS.has(plan.target))
	assert_eq(plan.pose, &"idle")


func test_without_fire_the_group_gathers_in_the_cave_mouth() -> void:
	for activity: StringName in [
		VillagerState.ACTIVITY_SOCIALIZE, VillagerState.ACTIVITY_REST, VillagerState.ACTIVITY_BUILD,
	]:
		var sim: Simulation = SimFixture.new_sim(1, false)
		sim.world.tick = sim.config.tick_for_hour(10)
		var villager: VillagerState = sim.world.villagers[0]
		villager.activity = activity
		var plan: VillagerPlan = VillagerPlanner.new().plan(villager, sim.world, sim.config, 0)
		assert_true(WorldLayout.COLD_SPOTS.has(plan.target), "%s should wait in the cave mouth" % activity)
		assert_eq(plan.focus_x, WorldLayout.COLD_X)


func test_wanderers_pick_a_point_inside_the_wander_area() -> void:
	for _attempt: int in 20:
		var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_WANDER)
		assert_true(plan.wander)
		assert_true(plan.target.x >= WorldLayout.WANDER_X.x and plan.target.x <= WorldLayout.WANDER_X.y)
		assert_true(plan.target.y >= WorldLayout.WANDER_Y.x and plan.target.y <= WorldLayout.WANDER_Y.y)


func test_builders_hammer_at_the_active_site() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var site: BuildingState = BuildingState.new()
	site.def_id = &"hut"
	site.complete = false
	sim.world.buildings.append(site)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_BUILD
	sim.world.tick = sim.config.tick_for_hour(10)
	var plan: VillagerPlan = VillagerPlanner.new().plan(villager, sim.world, sim.config, 0)
	assert_eq(plan.pose, &"hammer")
	assert_eq(plan.focus_x, float(WorldLayout.BUILDINGS[&"hut"]["cx"]))


func _bronze_plan(activity: StringName, profession: StringName, flags: Array, slot: int = 0) \
		-> VillagerPlan:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(10)
	for flag: StringName in flags:
		if SimFixture.load_content().get_building(flag) != null:
			var building: BuildingState = BuildingState.new()
			building.def_id = flag
			building.complete = true
			sim.world.buildings.append(building)
		else:
			sim.world.flags[flag] = true
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = activity
	villager.profession = profession
	return VillagerPlanner.new().plan(villager, sim.world, sim.config, slot)


func test_a_smith_hammers_in_front_of_the_smithy_instead_of_cutting_wood() -> void:
	var plan: VillagerPlan = _bronze_plan(VillagerState.ACTIVITY_GATHER_WOOD, &"smith", [&"smithy"])
	assert_eq(plan.pose, &"hammer")
	assert_true(WorldLayout.SMITHY_SPOTS.has(plan.target))
	assert_eq(plan.focus_x, float(WorldLayout.BUILDINGS[&"smithy"]["cx"]))
	var no_smithy: VillagerPlan = _bronze_plan(VillagerState.ACTIVITY_GATHER_WOOD, &"smith", [])
	assert_eq(no_smithy.pose, &"chop", "A smith with nowhere to work still cuts wood")
	var other: VillagerPlan = _bronze_plan(VillagerState.ACTIVITY_GATHER_WOOD, &"", [&"smithy"])
	assert_eq(other.pose, &"chop", "Only the smith works the smithy")


func test_a_trader_walks_between_the_trading_post_and_the_market() -> void:
	var post: VillagerPlan = _bronze_plan(
		VillagerState.ACTIVITY_WANDER, &"trader", [&"trading_post"]
	)
	assert_false(post.wander, "A trader does not wander at random")
	assert_true(WorldLayout.POST_SPOTS.has(post.target))
	var market: VillagerPlan = _bronze_plan(
		VillagerState.ACTIVITY_SOCIALIZE, &"trader", [&"market_day"]
	)
	assert_true(WorldLayout.MARKET_SPOTS.has(market.target))
	assert_eq(market.focus_x, WorldLayout.MARKET_X)
	var both: Array[Vector2] = []
	for slot: int in 2:
		both.append(
			_bronze_plan(
				VillagerState.ACTIVITY_WANDER, &"trader", [&"trading_post", &"market_day"], slot
			).target
		)
	assert_true(
		WorldLayout.MARKET_SPOTS.has(both[0]) != WorldLayout.MARKET_SPOTS.has(both[1]),
		"With both, traders go to each on alternate days"
	)
	var nowhere: VillagerPlan = _bronze_plan(VillagerState.ACTIVITY_WANDER, &"trader", [])
	assert_true(nowhere.wander, "With neither, a trader wanders like anyone")


func test_nobody_is_sent_to_stand_behind_a_building() -> void:
	var spot_lists: Array = [
		WorldLayout.FORAGE_SPOTS, WorldLayout.SOCIAL_SPOTS, WorldLayout.FIRE_SPOTS,
		WorldLayout.SMITHY_SPOTS, WorldLayout.POST_SPOTS, WorldLayout.COLD_SPOTS,
		WorldLayout.WOOD_SPOTS, WorldLayout.MARKET_SPOTS,
	]
	var last: int = WorldLayout.ERA_DIRS.size() - 1
	for building_id: StringName in WorldLayout.BUILDINGS:
		var path: String = WorldLayout.piece_path(StringName("building_%s" % building_id), last)
		var used: Rect2i = (load(path) as Texture2D).get_image().get_used_rect()
		used.position += Vector2i(WorldLayout.building_offset(building_id))
		var z: int = int(WorldLayout.BUILDINGS[building_id]["z"])
		for spots: Array in spot_lists:
			for spot: Vector2 in spots:
				var under: bool = spot.x > float(used.position.x) and spot.x < float(used.end.x)
				assert_false(
					under and int(spot.y) < z,
					"%s would stand behind the %s" % [spot, building_id]
				)


func test_buildings_stand_on_the_back_lane_with_the_cave() -> void:
	var last: int = WorldLayout.ERA_DIRS.size() - 1
	for building_id: StringName in [
		&"hut", &"field", &"drying_rack", &"smithy", &"trading_post", &"bloomery", &"granary",
	]:
		var slot: Dictionary = WorldLayout.BUILDINGS[building_id]
		assert_eq(int(slot["foot"]), WorldLayout.BACK_LANE, "%s's foot" % building_id)
		assert_eq(int(slot["z"]), WorldLayout.BACK_LANE, "%s's depth" % building_id)
		var path: String = WorldLayout.piece_path(StringName("building_%s" % building_id), last)
		var used: Rect2i = (load(path) as Texture2D).get_image().get_used_rect()
		var bottom: int = used.end.y - 1 + int(WorldLayout.building_offset(building_id).y)
		assert_true(
			absi(bottom - WorldLayout.BACK_LANE) <= 1,
			"%s's art ends at row %d, not on the back lane" % [building_id, bottom]
		)


func test_no_building_covers_another_by_more_than_a_quarter() -> void:
	var last: int = WorldLayout.ERA_DIRS.size() - 1
	var rects: Dictionary = {}
	for building_id: StringName in WorldLayout.BUILDINGS:
		var path: String = WorldLayout.piece_path(StringName("building_%s" % building_id), last)
		var used: Rect2i = (load(path) as Texture2D).get_image().get_used_rect()
		used.position += Vector2i(WorldLayout.building_offset(building_id))
		rects[building_id] = Rect2(used)
	var ids: Array = rects.keys()
	for i: int in ids.size():
		for j: int in range(i + 1, ids.size()):
			var a: Rect2 = rects[ids[i]]
			var b: Rect2 = rects[ids[j]]
			# A building the view folds into another shares its ground on purpose: only one shows.
			if WorldLayout.BUILDING_FOLDED_INTO.get(ids[i], &"") == ids[j] \
					or WorldLayout.BUILDING_FOLDED_INTO.get(ids[j], &"") == ids[i]:
				continue
			var common: float = a.intersection(b).get_area()
			var share: float = common / minf(a.get_area(), b.get_area())
			assert_true(share <= 0.25, "%s and %s cover each other (%d%%)" % [
				ids[i], ids[j], int(share * 100.0)
			])


func test_every_prop_that_is_a_building_or_a_yard_is_on_the_back_lane() -> void:
	var last: int = WorldLayout.ERA_DIRS.size() - 1
	for prop_id: StringName in [
		&"west_roof_a", &"west_roof_b", &"west_kiln", &"potters_yard", &"weavers_row",
		&"farmstead_herd", &"west_pen",
	]:
		var path: String = WorldLayout.piece_path(prop_id, last)
		var used: Rect2i = (load(path) as Texture2D).get_image().get_used_rect()
		var bottom: int = used.end.y - 1 + int(SceneProps.at_y_of(prop_id))
		assert_true(
			absi(bottom - WorldLayout.BACK_LANE) <= 2,
			"%s's art ends at row %d, not on the back lane" % [prop_id, bottom]
		)


func test_builders_with_no_site_wait_at_the_fire() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_BUILD)
	assert_eq(plan.pose, &"idle")
	assert_true(WorldLayout.FIRE_SPOTS.has(plan.target))


func test_hunters_stand_at_the_far_end_of_the_forest_with_a_spear() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_HUNT)
	assert_eq(plan.pose, &"spear")
	assert_true(WorldLayout.HUNT_SPOTS.has(plan.target))
	assert_true(plan.has_focus())
	assert_true(plan.focus_x < plan.target.x, "They face further west")
	for spot: Vector2 in WorldLayout.HUNT_SPOTS:
		assert_true(spot.x < WorldLayout.WANDER_X.x, "Beyond where anyone wanders")
		assert_true(spot.x > float(WorldLayout.WORLD_LEFT), "Inside the world")
		assert_true(spot.y >= WorldLayout.WANDER_Y.x and spot.y <= WorldLayout.WANDER_Y.y)


func test_villagers_who_stay_put_never_share_a_spot() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(10)
	var planner: VillagerPlanner = VillagerPlanner.new()
	for count: int in [4, 7]:
		var plans: Array[VillagerPlan] = []
		for slot: int in count:
			var villager: VillagerState = sim.world.villagers[slot % sim.world.villagers.size()]
			villager.activity = VillagerState.ACTIVITY_GATHER_WOOD
			plans.append(planner.plan(villager, sim.world, sim.config, slot))
		VillagerPlanner.spread(plans)
		for first: int in plans.size():
			for second: int in range(first + 1, plans.size()):
				var gap: float = absf(plans[first].target.x - plans[second].target.x)
				assert_true(gap >= VillagerPlanner.MIN_GAP, "%d and %d are %s apart" % [
					first, second, gap
				])


func test_spreading_leaves_wanderers_and_the_hidden_alone() -> void:
	var wanderer: VillagerPlan = VillagerPlan.new()
	wanderer.wander = true
	wanderer.target = Vector2(50, 78)
	var asleep: VillagerPlan = VillagerPlan.new()
	asleep.visible = false
	asleep.target = Vector2(50, 78)
	var standing: VillagerPlan = VillagerPlan.new()
	standing.target = Vector2(50, 78)
	VillagerPlanner.spread([wanderer, asleep, standing] as Array[VillagerPlan])
	assert_eq(wanderer.target, Vector2(50, 78))
	assert_eq(asleep.target, Vector2(50, 78))
	assert_eq(standing.target, Vector2(50, 78))


func test_a_plan_with_no_target_to_face_says_so() -> void:
	var plan: VillagerPlan = _plan_for(VillagerState.ACTIVITY_WANDER)
	assert_false(plan.has_focus(), "Wanderers just face where they walk")
	assert_true(_plan_for(VillagerState.ACTIVITY_GATHER_WOOD).has_focus())


func _actor_at(x: float, focus: float, pose: StringName) -> VillagerActor:
	var actor: VillagerActor = VillagerActor.new()
	actor.setup(&"t", load("%smira.png" % WorldLayout.VILLAGER_DIR) as Texture2D)
	var plan: VillagerPlan = VillagerPlan.new()
	plan.target = Vector2(x, 78.0)
	plan.focus_x = focus
	plan.pose = pose
	actor.apply_plan(plan)
	actor._process(0.1)
	return actor


func test_facing_works_west_of_the_camp() -> void:
	var east_of_stump: VillagerActor = _actor_at(-54.0, WorldLayout.CHOP_X, &"chop")
	var west_of_stump: VillagerActor = _actor_at(-82.0, WorldLayout.CHOP_X, &"chop")
	assert_true(east_of_stump._sprite.flip_h, "East of the stump faces west")
	assert_false(west_of_stump._sprite.flip_h, "West of the stump faces east")
	var hunter: VillagerActor = _actor_at(-300.0, WorldLayout.HUNT_X, &"spear")
	assert_true(hunter._sprite.flip_h, "Hunters face west")
	assert_eq(hunter._sprite.animation, &"spear")
	for actor: VillagerActor in [east_of_stump, west_of_stump, hunter]:
		actor.free()


func test_every_villager_sheet_has_every_pose() -> void:
	var cells: int = 0
	for animation: StringName in VillagerActor.SHEET_FRAMES:
		for cell: int in VillagerActor.SHEET_FRAMES[animation]:
			cells = maxi(cells, cell + 1)
	for look: StringName in SimFixture.load_content().villager_looks:
		var sheet: Texture2D = load("%s%s.png" % [WorldLayout.VILLAGER_DIR, look]) as Texture2D
		assert_eq(sheet.get_width(), cells * WorldLayout.CELL_SIZE.x, "%s's sheet" % look)
		assert_eq(sheet.get_height(), WorldLayout.CELL_SIZE.y)


func test_every_building_has_a_layout_slot() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for building: BuildingDef in content.buildings:
		assert_true(
			WorldLayout.BUILDINGS.has(building.id), "No layout slot for %s" % building.id
		)


func test_every_villager_look_has_a_sheet() -> void:
	for look: StringName in SimFixture.load_content().villager_looks:
		var path: String = "%s%s.png" % [WorldLayout.VILLAGER_DIR, look]
		assert_true(ResourceLoader.exists(path), "No sheet for look %s" % look)


func test_every_layout_asset_exists() -> void:
	var names: Array[String] = []
	for layer: StringName in WorldLayout.BACKDROP:
		names.append(String(layer))
	for layer: StringName in WorldLayout.STATIC_Z:
		names.append(String(layer))
	for building_id: StringName in WorldLayout.BUILDINGS:
		for prefix: String in ["building_", "site_"]:
			var layer: String = "%s%s" % [prefix, building_id]
			assert_true(
				not WorldLayout.piece_path(StringName(layer), WorldLayout.ERA_DIRS.size() - 1)
				.is_empty(), "Missing %s" % layer
			)
	names.append_array(["flower_sprout", "flower_bloom"])
	names.append(String(WorldLayout.FIRE_GLOW))
	names.append(String(WorldLayout.STARS))
	names.append(String(WorldLayout.CELESTIAL))
	for frame: int in WorldLayout.FIRE_FRAMES:
		names.append(String(WorldLayout.fire_frame_name(frame)))
	for prefix: String in WorldLayout.SIDE_PAGES:
		for layer: StringName in WorldLayout.BACKDROP:
			names.append(prefix + layer)
		for layer: StringName in WorldLayout.SIDE_STATIC[prefix]:
			names.append(prefix + layer)
	for asset: String in names:
		assert_true(
			ResourceLoader.exists(WorldLayout.ASSET_DIR + asset + ".png"), "Missing %s" % asset
		)


func test_night_is_darker_and_bluer_than_noon() -> void:
	var noon: Color = DayNight.tint(12.0)
	var midnight: Color = DayNight.tint(0.0)
	assert_true(midnight.r < noon.r)
	assert_true(midnight.b > midnight.r, "Night should read blue")
	assert_eq(DayNight.tint(0.0), DayNight.tint(24.0), "The day should wrap without a jump")


func test_unlit_nights_are_darker_but_days_are_not() -> void:
	assert_eq(DayNight.tint(12.0, false), DayNight.tint(12.0, true), "Days are the same")
	var lit: Color = DayNight.tint(0.0, true)
	var unlit: Color = DayNight.tint(0.0, false)
	assert_true(unlit.r < lit.r and unlit.g < lit.g and unlit.b < lit.b)
	assert_true(unlit.b > unlit.r, "Still reads blue")
	var previous: Color = DayNight.tint(17.0, false)
	for step: int in range(1, 81):
		var current: Color = DayNight.tint(17.0 + float(step) * 0.1, false)
		assert_true(absf(current.r - previous.r) < 0.1, "Unlit dusk jumped at step %d" % step)
		previous = current


func test_night_amount_runs_from_day_to_night() -> void:
	assert_eq(DayNight.night_amount(12.0), 0.0)
	assert_eq(DayNight.night_amount(0.0), 1.0)
	assert_true(DayNight.night_amount(20.0) > 0.0 and DayNight.night_amount(20.0) < 1.0)


func test_the_sun_crosses_the_sky_by_day_and_is_down_at_night() -> void:
	for hour: float in [12.0, 8.0, 17.0]:
		assert_true(DayNight.sun_position(hour).is_finite(), "Sun up at %.0f" % hour)
	for hour: float in [0.0, 3.0, 5.9, 19.6, 22.0]:
		assert_false(DayNight.sun_position(hour).is_finite(), "Sun down at %.1f" % hour)
	var noon: Vector2 = DayNight.sun_position((DayNight.SUN_RISE + DayNight.SUN_SET) / 2.0)
	assert_eq(noon.y, DayNight.HORIZON_Y - DayNight.SKY_PEAK, "Highest at midday")
	assert_eq(noon.x, (DayNight.SKY_X.x + DayNight.SKY_X.y) / 2.0, "Over the middle")
	var morning: Vector2 = DayNight.sun_position(9.0)
	var evening: Vector2 = DayNight.sun_position(17.0)
	assert_true(morning.x < noon.x and evening.x > noon.x, "Rises on the left, sets on the right")
	var rising: Vector2 = DayNight.sun_position(DayNight.SUN_RISE)
	assert_eq(rising.y, DayNight.HORIZON_Y, "It rises from the horizon")


func test_the_moon_crosses_the_night_sky() -> void:
	for hour: float in [19.6, 21.0, 23.0, 0.0, 3.0, 5.5]:
		assert_true(DayNight.moon_position(hour).is_finite(), "Moon up at %.1f" % hour)
	for hour: float in [8.0, 12.0, 17.0, 19.0]:
		assert_false(DayNight.moon_position(hour).is_finite(), "Moon down at %.1f" % hour)
	var high: Vector2 = DayNight.moon_position(0.75)
	assert_eq(high.y, DayNight.HORIZON_Y - DayNight.SKY_PEAK, "Highest in the middle of the night")
	assert_true(
		DayNight.moon_position(21.0).x < DayNight.moon_position(4.0).x, "Rises left, sets right"
	)


func test_the_sun_and_moon_never_share_the_sky_at_midday_or_midnight() -> void:
	assert_false(DayNight.moon_position(12.0).is_finite())
	assert_false(DayNight.sun_position(0.0).is_finite())
	assert_true(DayNight.sun_position(12.0).is_finite() and DayNight.moon_position(0.0).is_finite())


func test_the_sky_bodies_move_smoothly() -> void:
	for body: Callable in [DayNight.sun_position, DayNight.moon_position]:
		var previous: Vector2 = Vector2.INF
		for step: int in range(0, 241):
			var current: Vector2 = body.call(float(step) * 0.1)
			if current.is_finite() and previous.is_finite():
				assert_true(current.distance_to(previous) < 6.0, "Jumped at %.1f" % (step * 0.1))
			previous = current


func test_stars_come_out_with_the_dark() -> void:
	assert_eq(DayNight.star_alpha(12.0), 0.0)
	assert_eq(DayNight.star_alpha(19.0), 0.0)
	assert_eq(DayNight.star_alpha(0.0), 1.0)
	assert_eq(DayNight.star_alpha(23.0), 1.0)
	assert_eq(DayNight.star_alpha(5.0), 1.0)
	assert_eq(DayNight.star_alpha(6.5), 0.0)
	var dusk: float = DayNight.star_alpha(20.0)
	assert_true(dusk > 0.0 and dusk < 1.0, "They fade in through the dusk: %f" % dusk)
	var previous: float = 0.0
	for step: int in range(190, 241):
		var alpha: float = DayNight.star_alpha(float(step) * 0.1)
		assert_true(alpha >= previous - 0.0001, "Never fewer stars as the night comes on")
		previous = alpha


func test_light_changes_smoothly_through_dusk() -> void:
	var previous: Color = DayNight.tint(17.0)
	for step: int in range(1, 41):
		var current: Color = DayNight.tint(17.0 + float(step) * 0.1)
		assert_true(absf(current.r - previous.r) < 0.1, "Dusk jumped at step %d" % step)
		previous = current
