extends McpTestSuite
## Hover tooltips (issue #22): what the pointer rests on is named, the one in front wins, nothing
## unearned is named, and the plate only shows after the pointer has rested.

const DAY: int = 24


func suite_name() -> String:
	return "hover"


func _view(sim: Simulation = null) -> WorldView:
	if sim == null:
		sim = SimFixture.new_sim()
		sim.world.tick = sim.config.tick_for_hour(12) + DAY * 3
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	for id: StringName in view._actors:
		(view._actors[id] as VillagerActor).position = Vector2(-300, 78)
	return view


## A spot on a sprite that is solidly drawn, in the sprite's own pixels, or INF.
func _solid_spot(sprite: Sprite2D, within: Rect2 = Rect2(0, 0, 384, 80)) -> Vector2:
	var image: Image = sprite.texture.get_image()
	for y: int in image.get_height():
		for x: int in image.get_width():
			if image.get_pixel(x, y).a > 0.9 and within.has_point(Vector2(x, y)):
				return Vector2(x, y) + Vector2(0.5, 0.5)
	return Vector2.INF


## Looks at a sprite's spot: the camera jumps to put it on screen and the point returned is the
## window position to rest the pointer at.
func _look_at(view: WorldView, sprite: Sprite2D, spot: Vector2) -> Vector2:
	var world_x: float = sprite.position.x + spot.x
	view.jump_camera(clampf(world_x - 100.0, -384.0, 384.0))
	return Vector2(world_x - float(view.camera_x()), sprite.position.y + spot.y)


func _rest(view: WorldView, at: Vector2) -> void:
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = at
	view._unhandled_input(motion)


# ---- Names ------------------------------------------------------------------------------------

func test_every_prop_and_landmark_has_a_name() -> void:
	for prop_id: StringName in SceneProps.ids():
		assert_true(not SceneProps.name_of(prop_id).is_empty(), "%s has no name" % prop_id)
	for landmark_id: StringName in WorldLandmarks.ids():
		assert_true(
			not WorldLandmarks.name_of(landmark_id).is_empty(), "%s has no name" % landmark_id
		)
	assert_eq(SceneProps.name_of(&"no_such_prop"), "")


func test_every_building_has_a_name_to_show() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for building_id: StringName in WorldLayout.BUILDINGS:
		var def: BuildingDef = content.get_building(building_id)
		assert_true(def != null and not def.display_name.is_empty(), "%s is unnamed" % building_id)


func test_a_villager_is_named_with_their_role() -> void:
	var villager: VillagerState = VillagerState.new()
	villager.display_name = "Aldo"
	assert_eq(VillagerPresenter.tooltip_for(villager), "Aldo")
	villager.profession = &"scout"
	assert_eq(VillagerPresenter.tooltip_for(villager), "Aldo - Scout")


func test_every_landmark_rectangle_holds_something_drawn() -> void:
	var view: WorldView = _view()
	for id: StringName in WorldLandmarks.ids():
		var source: StringName = WorldLandmarks.source_of(id)
		var found: bool = false
		for rect: Rect2 in WorldLandmarks.LANDMARKS[id]["rects"]:
			if source != &"":
				var layer: Sprite2D = view._landmark_sources[source]
				found = found or _solid_spot(layer, rect) != Vector2.INF
			else:
				found = found or _life_frames_draw_in(view, rect)
		assert_true(found, "%s no longer matches the art" % id)
	view.free()


func _life_frames_draw_in(view: WorldView, rect: Rect2) -> bool:
	var local: Rect2 = Rect2(rect.position - Vector2(WorldLandmarks.EAST_X, 0.0), rect.size)
	for texture: Texture2D in view._life_frames:
		var image: Image = texture.get_image()
		for y: int in range(int(local.position.y), mini(int(local.end.y), image.get_height())):
			for x: int in range(int(local.position.x), int(local.end.x)):
				if image.get_pixel(x, y).a > 0.5:
					return true
	return false


# ---- What is under the pointer -----------------------------------------------------------------

func test_the_alpha_test_sees_only_drawn_pixels() -> void:
	var image: Image = Image.create(4, 4, false, Image.FORMAT_RGBA8)
	image.set_pixel(1, 1, Color.WHITE)
	var texture: ImageTexture = ImageTexture.create_from_image(image)
	var alpha: AlphaHit = AlphaHit.new()
	assert_true(alpha.opaque_near(texture, Vector2(1.5, 1.5)))
	assert_false(alpha.opaque_near(texture, Vector2(3.5, 3.5)))
	assert_true(alpha.opaque_near(texture, Vector2(2.5, 2.5), 1), "Reach takes in the neighbours")
	assert_false(alpha.opaque_near(texture, Vector2(-5.0, 9.0), 1), "Outside is empty")
	assert_false(alpha.opaque_near(null, Vector2.ZERO))


func test_the_front_one_wins_and_a_tie_goes_to_the_later() -> void:
	var back: HoverHit = HoverHit.make(&"a", "Back", 10)
	var front: HoverHit = HoverHit.make(&"b", "Front", 70)
	assert_eq(HoverHit.in_front(back, front), front)
	assert_eq(HoverHit.in_front(front, back), front)
	var tie: HoverHit = HoverHit.make(&"c", "Tie", 70)
	assert_eq(HoverHit.in_front(front, tie), tie)
	assert_eq(HoverHit.in_front(front, null), front)
	assert_eq(HoverHit.in_front(null, back), back)


func test_a_prop_is_named_only_once_the_world_shows_it() -> void:
	var view: WorldView = _view()
	var sprite: Sprite2D = view._props[&"west_well"]
	var spot: Vector2 = _solid_spot(sprite)
	assert_true(spot.is_finite(), "The well is drawn somewhere")
	var at: Vector2 = _look_at(view, sprite, spot)
	assert_eq(view.thing_at(at), null, "Nothing is named before the well exists")
	view._sim.world.flags[&"well_dug"] = true
	view.on_world_changed()
	var hit: HoverHit = view.thing_at(at)
	assert_true(hit != null and hit.text == "Well", "The well is named")
	view.free()


func test_the_empty_part_of_a_piece_is_not_named() -> void:
	var view: WorldView = _view()
	view._sim.world.flags[&"loom"] = true
	view.on_world_changed()
	view.jump_camera(0.0)
	assert_eq(view.thing_at(Vector2(370, 4)), null)
	view.free()


func test_a_building_is_named_and_its_site_says_so() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = sim.config.tick_for_hour(12) + DAY * 3
	var site: BuildingState = BuildingState.new()
	site.def_id = &"drying_rack"
	sim.world.buildings.append(site)
	sim.complete_building(site)
	var view: WorldView = _view(sim)
	var sprite: Sprite2D = view._buildings[&"drying_rack"]
	var hit: HoverHit = view.thing_at(_look_at(view, sprite, _solid_spot(sprite)))
	assert_true(hit != null and hit.key == &"building:drying_rack")
	assert_eq(hit.text, sim.content.get_building(&"drying_rack").display_name)
	view.free()


func test_the_fire_is_named_only_where_it_burns() -> void:
	var view: WorldView = _view()
	view.jump_camera(0.0)
	var spot: Vector2 = _solid_spot(view._fire_pit, WorldLayout.FIRE_HIT)
	assert_true(view._fire_pit.visible and spot.is_finite(), "The new world is lit")
	var hit: HoverHit = view.thing_at(spot)
	assert_true(hit != null and hit.key == &"fire", "The pit is the fire")
	var cave_mouth: HoverHit = view.thing_at(Vector2(34, 60))
	assert_true(cave_mouth == null or cave_mouth.key != &"fire", "The firelit cave is not the fire")
	view.free()


func test_a_landmark_is_named_where_it_is_drawn() -> void:
	var view: WorldView = _view()
	view.jump_camera(0.0)
	var layer: Sprite2D = view._landmark_sources[&"static_back"]
	var spot: Vector2 = _solid_spot(layer, WorldLandmarks.LANDMARKS[&"cave"]["rects"][0])
	var hit: HoverHit = view.thing_at(spot)
	assert_true(hit != null and hit.key == &"landmark:cave", "The cliff is the cave")
	view.free()


func test_the_signature_building_is_named_for_its_age() -> void:
	var view: WorldView = _view()
	view.jump_camera(0.0)
	var layer: Sprite2D = view._landmark_sources[&"static_back"]
	for era_order: int in WorldLandmarks.SIGNATURE_NAMES.size():
		view._sim.world.era_order = era_order
		view._refresh_props()
		var spot: Vector2 = _solid_spot(layer, WorldLandmarks.LANDMARKS[&"cave"]["rects"][0])
		var hit: HoverHit = view.thing_at(spot)
		assert_true(hit != null and hit.key == &"landmark:cave", "Age %d: the landmark is hovered" % era_order)
		if hit != null:
			assert_eq(hit.text, WorldLandmarks.SIGNATURE_NAMES[era_order])
	view.free()


func test_the_fish_are_named_across_their_rectangles() -> void:
	var view: WorldView = _view()
	view.jump_camera(384.0)
	var hit: HoverHit = view.thing_at(Vector2(20, 64))
	assert_true(hit != null and hit.text == "Fish")
	view.free()


func test_hovering_and_clicking_name_the_same_villager_when_two_stand_together() -> void:
	var view: WorldView = _view()
	var first: VillagerState = view._sim.world.villagers[0]
	var second: VillagerState = view._sim.world.villagers[1]
	var spot: Vector2 = Vector2(100, 78)
	(view._actors[first.id] as VillagerActor).position = spot
	(view._actors[second.id] as VillagerActor).position = spot
	view.jump_camera(60.0)
	var at: Vector2 = Vector2(40, 66)
	var clicked: StringName = view.villager_at(at)
	assert_true(clicked != &"")
	var hit: HoverHit = view.thing_at(at)
	assert_true(hit != null)
	assert_eq(hit.key, StringName("villager:%s" % clicked), "The tooltip names who a click picks")
	view.free()


func test_a_villager_is_named_and_wins_a_tie_with_a_prop() -> void:
	var view: WorldView = _view()
	view._sim.world.achievements.append(&"fired_clay")
	view.on_world_changed()
	var sprite: Sprite2D = view._props[&"pots"]
	var spot: Vector2 = _solid_spot(sprite, Rect2(0, 60, 384, 20))
	assert_true(spot.is_finite())
	var at: Vector2 = _look_at(view, sprite, spot)
	var villager: VillagerState = view._sim.world.villagers[0]
	var actor: VillagerActor = view._actors[villager.id]
	actor.position = Vector2(at.x + float(view.camera_x()), float(SceneProps.z_of(&"pots")))
	actor.visible = true
	var hit: HoverHit = view.thing_at(at)
	assert_true(hit != null and hit.key == StringName("villager:%s" % villager.id))
	assert_eq(hit.text, VillagerPresenter.tooltip_for(villager))
	actor.visible = false
	hit = view.thing_at(at)
	assert_true(hit != null and hit.text == "Clay pots", "A hidden villager is not named")
	view.free()


# ---- When it shows -----------------------------------------------------------------------------

func test_the_wait_starts_again_with_each_new_thing() -> void:
	var dwell: HoverDwell = HoverDwell.new()
	assert_false(dwell.is_ready())
	dwell.advance(1.0)
	assert_false(dwell.is_ready(), "Nothing under the pointer, nothing to show")
	dwell.point_at(&"a")
	dwell.advance(HoverDwell.DELAY_SECONDS * 0.5)
	assert_false(dwell.is_ready())
	dwell.advance(HoverDwell.DELAY_SECONDS)
	assert_true(dwell.is_ready())
	dwell.point_at(&"a")
	assert_true(dwell.is_ready(), "Resting on the same thing keeps it")
	dwell.point_at(&"b")
	assert_false(dwell.is_ready(), "Another thing starts the wait again")
	dwell.advance(HoverDwell.DELAY_SECONDS)
	dwell.clear()
	assert_false(dwell.is_ready())


func _rest_on_a_prop(view: WorldView) -> Vector2:
	view._sim.world.flags[&"loom"] = true
	view.on_world_changed()
	var sprite: Sprite2D = view._props[&"loom"]
	return _look_at(view, sprite, _solid_spot(sprite))


func test_a_tooltip_shows_only_after_the_pointer_has_rested() -> void:
	var view: WorldView = _view()
	var at: Vector2 = _rest_on_a_prop(view)
	var shown: Array[String] = []
	view.hover_changed.connect(func(text: String, _at: Vector2) -> void: shown.append(text))
	_rest(view, at)
	view._process(HoverDwell.DELAY_SECONDS * 0.5)
	assert_eq(shown.size(), 0, "Not yet")
	view._process(HoverDwell.DELAY_SECONDS)
	assert_eq(shown, ["Loom"] as Array[String])
	view._process(1.0)
	assert_eq(shown.size(), 1, "It is said once, not every frame")
	_rest(view, Vector2(370, 4))
	assert_eq(shown, ["Loom", ""] as Array[String], "Moving off puts it away")
	view.free()


func test_a_click_puts_the_tooltip_away_until_the_pointer_moves() -> void:
	var view: WorldView = _view()
	var at: Vector2 = _rest_on_a_prop(view)
	var shown: Array[String] = []
	view.hover_changed.connect(func(text: String, _at: Vector2) -> void: shown.append(text))
	_rest(view, at)
	view._process(1.0)
	var press: InputEventMouseButton = InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	press.position = at
	view._unhandled_input(press)
	assert_eq(shown, ["Loom", ""] as Array[String])
	view._process(1.0)
	assert_eq(shown.size(), 2, "It stays away while the pointer is still")
	view.free()


func test_a_pointer_outside_the_view_names_nothing() -> void:
	var view: WorldView = _view()
	var at: Vector2 = _rest_on_a_prop(view)
	var shown: Array[String] = []
	view.hover_changed.connect(func(text: String, _at: Vector2) -> void: shown.append(text))
	_rest(view, at)
	view._process(1.0)
	_rest(view, Vector2(at.x, -20.0))
	assert_eq(shown, ["Loom", ""] as Array[String], "Above the viewport is the panel's")
	view.free()


# ---- The plate ---------------------------------------------------------------------------------

func test_the_plate_sits_above_the_pointer_and_inside_the_view() -> void:
	var view_size: Vector2i = WorldLayout.VIEW_SIZE
	var plate: Vector2 = Vector2(60, 16)
	var above: Vector2 = WorldTooltip.place(Vector2(200, 60), plate, view_size)
	assert_true(above.y + plate.y < 60.0, "Above the pointer")
	assert_eq(above.x, 170.0, "Centred on it")
	var left: Vector2 = WorldTooltip.place(Vector2(3, 60), plate, view_size)
	assert_eq(left.x, 0.0, "Kept inside the left edge")
	var right: Vector2 = WorldTooltip.place(Vector2(382, 60), plate, view_size)
	assert_eq(right.x + plate.x, 384.0, "Kept inside the right edge")
	var low: Vector2 = WorldTooltip.place(Vector2(200, 8), plate, view_size)
	assert_true(low.y > 8.0, "Drops below when there is no room above")
	var bottom: Vector2 = WorldTooltip.place(Vector2(200, 79), plate, view_size)
	assert_true(bottom.y >= 0.0 and bottom.y + plate.y <= 80.0)


func test_the_plate_asks_for_its_own_click_region_only_while_shown() -> void:
	var tooltip: WorldTooltip = WorldTooltip.new()
	tooltip.origin = Vector2(10, 40)
	assert_false(tooltip.region().has_area(), "Hidden, it takes no room")
	tooltip.show_at("Clay pots", Vector2(100, 60))
	var region: Rect2i = tooltip.region()
	assert_true(region.has_area())
	assert_true(Rect2i(Vector2i.ZERO, WorldLayout.VIEW_SIZE).encloses(region), "Inside the view")
	assert_eq(tooltip.position, Vector2(region.position) + Vector2(10, 40), "In the window")
	tooltip.hide_tip()
	assert_false(tooltip.region().has_area())
	tooltip.free()
