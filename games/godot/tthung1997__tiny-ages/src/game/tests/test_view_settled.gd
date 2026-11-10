extends McpTestSuite
## The Settled Age in the world view (docs/ages.md V10): a slot's art is upgraded in place when the
## age turns, and props appear because of what the settlement chose, not only because a building
## stands.


func suite_name() -> String:
	return "view_settled"


func _view_for(sim: Simulation) -> WorldView:
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	return view


func _free(view: WorldView) -> void:
	view.free()


func test_a_piece_is_found_in_the_newest_age_that_has_it() -> void:
	assert_true(WorldLayout.piece_path(&"building_hut", 0).contains("/cave/"))
	assert_true(WorldLayout.piece_path(&"building_hut", 1).contains("/settled/"))
	assert_true(
		WorldLayout.piece_path(&"building_lookout", 1).contains("/cave/"),
		"A slot the Settled Age did not redraw keeps its Cave art"
	)
	assert_eq(WorldLayout.piece_path(&"no_such_piece", 1), "")
	assert_true(
		WorldLayout.piece_path(&"building_hut", 1).contains("/settled/"),
		"The Settled Age's roundhouse"
	)
	assert_true(
		WorldLayout.piece_path(&"building_hut", 2).contains("/bronze/"),
		"The Bronze Age redraws it in mud-brick"
	)
	assert_true(
		WorldLayout.piece_path(&"building_hut", 3).contains("/iron/"),
		"The Iron Age redraws it in timber and daub"
	)
	assert_true(
		WorldLayout.piece_path(&"building_hut", 4).contains("/classical/"),
		"The Classical Age redraws it as a plastered stone house"
	)
	assert_true(
		WorldLayout.piece_path(&"building_hut", 9).contains("/classical/"),
		"A later age with no folder yet uses the newest there is"
	)
	assert_true(
		WorldLayout.piece_path(&"building_lookout", 4).contains("/iron/"),
		"A slot the Classical Age leaves alone keeps the Iron Age's piece"
	)
	assert_true(
		WorldLayout.piece_path(&"building_lookout", 1).contains("/cave/"),
		"Untouched slots keep their art through the Settled Age"
	)
	assert_true(
		WorldLayout.piece_path(&"building_lookout", 2).contains("/bronze/"),
		"The Lookout becomes a gate tower in the Bronze Age"
	)
	assert_true(
		WorldLayout.piece_path(&"building_lookout", 3).contains("/iron/"),
		"And an iron-bound one in the Iron Age"
	)
	assert_true(
		WorldLayout.piece_path(&"building_drying_rack", 3).contains("/cave/"),
		"The Cave Age's memory stays"
	)


func test_every_building_and_prop_has_art_in_the_age_that_shows_it() -> void:
	var last: int = WorldLayout.ERA_DIRS.size() - 1
	for building_id: StringName in WorldLayout.BUILDINGS:
		for prefix: String in ["building_", "site_"]:
			var layer: StringName = StringName(prefix + building_id)
			assert_true(
				not WorldLayout.piece_path(layer, last).is_empty(), "No art for %s" % layer
			)
	for prop_id: StringName in SceneProps.ids():
		var from_era: int = int(SceneProps.PROPS[prop_id].get("from_era", 0))
		assert_true(
			not WorldLayout.piece_path(prop_id, maxi(from_era, 1)).is_empty()
			or not WorldLayout.piece_path(prop_id, last).is_empty(),
			"No art for prop %s" % prop_id
		)
		var at_x: float = SceneProps.at_x_of(prop_id)
		assert_true(
			at_x >= float(WorldLayout.WORLD_LEFT)
			and at_x + 384.0 <= float(WorldLayout.WORLD_RIGHT),
			"%s is inside the world" % prop_id
		)


func test_props_follow_flags() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(
		SceneProps.shown(sim.world), [&"cave_standard_cave"] as Array[StringName],
		"A new world shows only the cave's own pennant"
	)
	sim.world.flags[&"path_agriculture"] = true
	assert_eq(
		SceneProps.shown(sim.world), [&"cave_standard_cave"] as Array[StringName],
		"Farming is the Field's to show, not a prop's"
	)
	sim.world.flags[&"path_herding"] = true
	var shown: Array[StringName] = SceneProps.shown(sim.world)
	assert_true(shown.has(&"west_pen"))
	assert_false(SceneProps.is_shown(&"no_such_prop", sim.world))


func test_props_can_follow_achievements_and_buildings() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_false(SceneProps.holds(SceneProps.Kind.ACHIEVEMENT, &"fired_clay", sim.world))
	sim.world.achievements.append(&"fired_clay")
	assert_true(SceneProps.holds(SceneProps.Kind.ACHIEVEMENT, &"fired_clay", sim.world))
	assert_false(SceneProps.holds(SceneProps.Kind.BUILDING, &"hut", sim.world))
	var hut: BuildingState = BuildingState.new()
	hut.def_id = &"hut"
	hut.complete = true
	sim.world.buildings.append(hut)
	assert_true(SceneProps.holds(SceneProps.Kind.BUILDING, &"hut", sim.world))


func test_every_prop_shows_for_its_trigger_and_only_then() -> void:
	for prop_id: StringName in SceneProps.ids():
		if SceneProps.is_decor(prop_id):
			continue # decor is always there
		var sim: Simulation = SimFixture.new_sim()
		var spec: Dictionary = SceneProps.PROPS[prop_id]
		sim.world.era_order = int(spec.get("from_era", 0))
		if spec["kind"] == SceneProps.Kind.ALWAYS:
			sim.world.era_order = int(spec.get("from_era", 0)) - 1
			assert_false(SceneProps.is_shown(prop_id, sim.world), "%s waits for its age" % prop_id)
			sim.world.era_order = int(spec.get("from_era", 0))
			assert_true(SceneProps.is_shown(prop_id, sim.world), "%s shows when its age turns" % prop_id)
			continue
		assert_false(SceneProps.is_shown(prop_id, sim.world), "%s starts hidden" % prop_id)
		match spec["kind"]:
			SceneProps.Kind.FLAG:
				sim.world.flags[spec["key"]] = true
			SceneProps.Kind.ACHIEVEMENT:
				sim.world.achievements.append(spec["key"])
			SceneProps.Kind.BUILDING:
				var site: BuildingState = BuildingState.new()
				site.def_id = spec["key"]
				site.complete = true
				sim.world.buildings.append(site)
		assert_true(SceneProps.is_shown(prop_id, sim.world), "%s should show" % prop_id)


func test_every_prop_waits_for_something_the_game_can_actually_give() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var flags: Dictionary = {}
	var earned: Dictionary = {}
	for event: EventDef in content.events:
		var effects: Array[SimEffect] = []
		effects.append_array(event.effects)
		for choice: ChoiceDef in event.choices:
			effects.append_array(choice.effects)
		for effect: SimEffect in effects:
			if effect.kind == SimEffect.Kind.SET_FLAG:
				flags[effect.key] = true
			elif effect.kind == SimEffect.Kind.ACHIEVEMENT:
				earned[effect.key] = true
	for building: BuildingDef in content.buildings:
		earned[building.completion_achievement] = true
	for prop_id: StringName in SceneProps.ids():
		var spec: Dictionary = SceneProps.PROPS[prop_id]
		var key: StringName = spec["key"]
		if SceneProps.is_decor(prop_id):
			continue
		if spec["kind"] == SceneProps.Kind.ALWAYS:
			assert_true(spec.has("from_era"), "%s would show in the first age" % prop_id)
		elif spec["kind"] == SceneProps.Kind.FLAG:
			assert_true(flags.has(key), "%s waits for flag %s, which nothing sets" % [prop_id, key])
		elif spec["kind"] == SceneProps.Kind.ACHIEVEMENT:
			assert_true(earned.has(key), "%s waits for %s, which nothing grants" % [prop_id, key])
		else:
			assert_true(content.get_building(key) != null, "%s: unknown building" % prop_id)


func test_a_played_settled_age_fills_the_world_with_what_the_group_did() -> void:
	var sim: Simulation = SimFixture.new_sim(1)
	sim.advance_era(&"settled")
	sim.world.flags[&"path_agriculture"] = true
	var bot: DecisionBot = DecisionBot.new()
	for _tick: int in 330 * SimFixture.TICKS_PER_DAY:
		sim.advance_ticks(1)
		bot.answer_all(sim)
	var shown: Array[StringName] = SceneProps.shown(sim.world)
	assert_true(shown.size() >= 8, "Only %d props after a whole age: %s" % [shown.size(), shown])
	for expected: StringName in [&"pots", &"cloth_line", &"west_roof_a"]:
		assert_true(shown.has(expected), "%s should have appeared" % expected)


func test_a_role_overlay_follows_the_body_and_comes_off_with_the_role() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	var villager: VillagerState = sim.world.villagers[0]
	var actor: VillagerActor = view._actors[villager.id]
	assert_eq(actor.role(), &"", "No role, no overlay")
	var sheet: Texture2D = load(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.FUR))
	actor.set_role(&"smith", sheet)
	assert_eq(actor.role(), &"smith")
	assert_true(actor._role_sprite.visible)
	actor._sprite.play(&"walk")
	actor._sprite.frame = 2
	actor._sprite.flip_h = true
	actor._sync_role()
	assert_eq(actor._role_sprite.animation, &"walk")
	assert_eq(actor._role_sprite.frame, 2)
	assert_true(actor._role_sprite.flip_h, "It faces the way the body does")
	actor.set_role(&"", null)
	assert_false(actor._role_sprite.visible)
	_free(view)


func test_the_view_dresses_each_profession_that_has_an_overlay() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.villagers[0].profession = &"smith"
	var view: WorldView = _view_for(sim)
	view.on_world_changed()
	var actor: VillagerActor = view._actors[sim.world.villagers[0].id]
	var path: String = WorldLayout.role_sheet_path(&"smith")
	assert_false(path.is_empty(), "There is art for the smith")
	assert_eq(actor.role(), &"smith")
	assert_eq(WorldLayout.role_sheet_path(&"no_such_role"), "")
	assert_eq(WorldLayout.role_sheet_path(&""), "")
	sim.world.villagers[0].profession = &""
	view.on_world_changed()
	assert_eq(actor.role(), &"", "Taking the role away takes the overlay off")
	_free(view)


func test_the_hut_art_is_upgraded_when_the_age_turns() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	var hut: Sprite2D = view._buildings[&"hut"]
	assert_true(hut.texture.resource_path.contains("/cave/"), "Cave art in the Cave Age")
	sim.advance_era(&"settled")
	view.on_world_changed()
	assert_true(hut.texture.resource_path.contains("/settled/"), "The roundhouse once settled")
	var lookout: Sprite2D = view._buildings[&"lookout"]
	assert_true(lookout.texture.resource_path.contains("/cave/"), "Untouched slots stay")
	_free(view)


func test_the_view_shows_props_only_when_the_world_says_so() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	var view: WorldView = _view_for(sim)
	for prop_id: StringName in view._props:
		var spec: Dictionary = SceneProps.PROPS[prop_id]
		if SceneProps.is_decor(prop_id):
			# Always there, if the lane has a space for it.
			assert_true(SceneProps.is_shown(prop_id, sim.world))
			assert_eq(
				(view._props[prop_id] as Sprite2D).visible, view._layout.is_placed(prop_id),
				"%s is drawn when it has a space" % prop_id
			)
			continue
		if spec["kind"] == SceneProps.Kind.ALWAYS:
			assert_eq(
				(view._props[prop_id] as Sprite2D).visible, SceneProps.is_shown(prop_id, sim.world),
				"%s follows the age alone" % prop_id
			)
			continue
		assert_false((view._props[prop_id] as Sprite2D).visible, "%s starts hidden" % prop_id)
	var before: String = view._signature
	sim.world.flags[&"path_herding"] = true
	view.on_world_changed()
	assert_true((view._props[&"west_pen"] as Sprite2D).visible)
	assert_true(view._signature != before, "The click region is rebuilt for the new pieces")
	_free(view)


func test_the_bronze_age_folds_scattered_props_into_tidier_pieces() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.advance_era(&"settled")
	sim.world.achievements.append(&"fired_clay")
	sim.world.achievements.append(&"woven_cloth")
	sim.world.flags[&"loom"] = true
	sim.world.flags[&"low_wall"] = true
	var view: WorldView = _view_for(sim)
	view.on_world_changed()
	for old: StringName in [&"pots", &"loom", &"cloth_line", &"low_wall"]:
		assert_true((view._props[old] as Sprite2D).visible, "%s stands in the Settled Age" % old)
	assert_false((view._props[&"potters_yard"] as Sprite2D).visible)
	sim.advance_era(&"bronze")
	sim.world.flags[&"town_wall"] = true
	view.on_world_changed()
	for old: StringName in [&"pots", &"loom", &"cloth_line", &"low_wall"]:
		assert_false((view._props[old] as Sprite2D).visible, "%s is folded away" % old)
	for tidy: StringName in [&"potters_yard", &"weavers_row", &"town_wall"]:
		assert_true((view._props[tidy] as Sprite2D).visible, "%s stands in the Bronze Age" % tidy)
	var hut: Sprite2D = view._buildings[&"hut"]
	assert_true(hut.texture.resource_path.contains("/bronze/"), "The roundhouse is mud-brick")
	_free(view)


func test_the_click_region_changes_with_the_age() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = _view_for(sim)
	var cave: String = view._signature
	sim.advance_era(&"settled")
	view.on_world_changed()
	assert_true(view._signature != cave, "New art has new outlines")
	_free(view)
