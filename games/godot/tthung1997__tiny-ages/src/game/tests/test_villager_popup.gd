extends McpTestSuite
## Clicking a villager: what they are shown (VillagerPresenter), the panel that shows it, and the
## view telling a click on a villager from a drag or a click on empty ground (docs/gameplay.md P11).

const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "villager_popup"


func _sim_at(hour: int, lit: bool = true) -> Simulation:
	var sim: Simulation = SimFixture.new_sim(1, lit)
	sim.world.tick = sim.config.tick_for_hour(hour) + DAY * 3
	return sim


## Samples thoughts over `samples` different days, always in the daytime so nobody is asleep.
func _thoughts(sim: Simulation, villager: VillagerState, samples: int) -> Dictionary:
	var seen: Dictionary = {}
	var start: int = sim.world.tick
	for step: int in samples:
		sim.world.tick = start + step * DAY + (step * 7) % 8
		seen[VillagerPresenter.thought_for(villager, sim.world, sim.config)] = true
	sim.world.tick = start
	return seen


func _allowed(villager: VillagerState, extra: Array[String] = []) -> Array[String]:
	var lines: Array[String] = extra.duplicate()
	for line: Variant in VillagerPresenter.BY_ACTIVITY[villager.activity]:
		lines.append(line as String)
	for trait_name: StringName in villager.traits:
		for line: Variant in VillagerPresenter.BY_TRAIT[trait_name]:
			lines.append(line as String)
	return lines


# ---- VillagerPresenter ----------------------------------------------------------------------

func test_the_card_has_a_name_traits_and_a_role() -> void:
	var sim: Simulation = _sim_at(12)
	var villager: VillagerState = sim.world.villagers[0]
	villager.display_name = "Mira"
	villager.traits.assign([VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_NATURE_LOVING])
	villager.profession = &"scout"
	var view: VillagerPresenter = VillagerPresenter.present(villager, sim.world, sim.config)
	assert_eq(view.display_name, "Mira")
	assert_eq(view.traits_text, "Curious, nature-loving")
	assert_eq(view.role_text, "Scout")
	assert_eq(view.byline(), "Curious, nature-loving - Scout", "Traits and role share one line")
	assert_false(view.thought.is_empty())
	assert_true(ResourceLoader.exists("%s%s.png" % [WorldLayout.VILLAGER_DIR, view.look]))


func test_a_villager_with_no_role_or_traits_has_empty_lines() -> void:
	var sim: Simulation = _sim_at(12)
	var villager: VillagerState = sim.world.villagers[0]
	villager.traits.clear()
	villager.profession = &""
	var view: VillagerPresenter = VillagerPresenter.present(villager, sim.world, sim.config)
	assert_eq(view.traits_text, "")
	assert_eq(view.role_text, "")
	assert_eq(view.byline(), "", "Nothing to show, so no empty line")
	villager.profession = &"scout"
	assert_eq(VillagerPresenter.present(villager, sim.world, sim.config).byline(), "Scout")


func test_the_group_lists_everyone_in_order_without_thoughts() -> void:
	var sim: Simulation = _sim_at(12)
	sim.world.villagers[1].profession = &"scout"
	var cards: Array[VillagerPresenter] = VillagerPresenter.group(sim.world)
	assert_eq(cards.size(), sim.world.villagers.size())
	for index: int in cards.size():
		var villager: VillagerState = sim.world.villagers[index]
		assert_eq(cards[index].id, villager.id)
		assert_eq(cards[index].display_name, villager.display_name)
		assert_eq(cards[index].thought, "", "Thoughts are for the single-villager panel")
	assert_eq(cards[1].role_text, "Scout")
	assert_eq(cards[0].look, VillagerPresenter.present(
		sim.world.villagers[0], sim.world, sim.config
	).look)


func test_a_thought_holds_still_within_a_moment_and_changes_over_time() -> void:
	var sim: Simulation = _sim_at(12)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_GATHER_WOOD
	var first: String = VillagerPresenter.thought_for(villager, sim.world, sim.config)
	assert_eq(VillagerPresenter.thought_for(villager, sim.world, sim.config), first, "Stable")
	var seen: Dictionary = _thoughts(sim, villager, 40)
	assert_gt(seen.size(), 1, "More than one thought across a few hours")


func test_thoughts_follow_what_the_villager_is_doing() -> void:
	for activity: StringName in VillagerPresenter.BY_ACTIVITY:
		var sim: Simulation = _sim_at(12)
		sim.world.resources[&"food"] = 30
		var villager: VillagerState = sim.world.villagers[0]
		villager.activity = activity
		var allowed: Array[String] = _allowed(villager)
		for thought: String in _thoughts(sim, villager, 60):
			assert_true(allowed.has(thought), "%s: unexpected thought '%s'" % [activity, thought])


func test_thoughts_reflect_the_traits() -> void:
	var sim: Simulation = _sim_at(12)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_FORAGE
	villager.traits.assign([VillagerState.TRAIT_SOCIAL])
	var from_trait: bool = false
	for thought: String in _thoughts(sim, villager, 80):
		if VillagerPresenter.BY_TRAIT[VillagerState.TRAIT_SOCIAL].has(thought):
			from_trait = true
	assert_true(from_trait, "A social villager sometimes thinks social thoughts")


func test_thoughts_reflect_a_role_and_the_bronze_age() -> void:
	var sim: Simulation = _sim_at(12)
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_FORAGE
	villager.profession = &"smith"
	var from_role: bool = false
	for thought: String in _thoughts(sim, villager, 80):
		if VillagerPresenter.BY_PROFESSION[&"smith"].has(thought):
			from_role = true
		assert_false(VillagerPresenter.BRONZE_AGE.has(thought), "Not before the Bronze Age")
	assert_true(from_role, "A smith sometimes thinks about the hearth")
	sim.world.era_order = 2
	var bronze: bool = false
	for thought: String in _thoughts(sim, villager, 120):
		if VillagerPresenter.BRONZE_AGE.has(thought):
			bronze = true
	assert_true(bronze, "The Bronze Age has its own thoughts")


func test_without_fire_the_idle_are_cold_and_with_fire_they_are_not() -> void:
	for lit: bool in [false, true]:
		var sim: Simulation = _sim_at(12, lit)
		sim.world.resources[&"food"] = 30
		var villager: VillagerState = sim.world.villagers[0]
		villager.traits.clear()
		villager.activity = VillagerState.ACTIVITY_REST
		var cold: bool = false
		for thought: String in _thoughts(sim, villager, 60):
			if VillagerPresenter.COLD.has(thought):
				cold = true
		assert_eq(cold, not lit, "Cold thoughts only while there is no fire (lit: %s)" % lit)


func test_a_low_food_pile_shows_up_as_a_thought() -> void:
	var sim: Simulation = _sim_at(12)
	sim.world.resources[&"food"] = 1
	var villager: VillagerState = sim.world.villagers[0]
	villager.activity = VillagerState.ACTIVITY_FORAGE
	var hungry: bool = false
	for thought: String in _thoughts(sim, villager, 80):
		if VillagerPresenter.LOW_FOOD.has(thought):
			hungry = true
	assert_true(hungry, "Scarcity is told as a thought, not a number")
	sim.world.resources[&"food"] = 30
	for thought: String in _thoughts(sim, villager, 80):
		assert_false(VillagerPresenter.LOW_FOOD.has(thought), "Plenty of food: no worry")


func test_the_asleep_and_the_away_say_so() -> void:
	var night: Simulation = _sim_at(2)
	var sleeper: VillagerState = night.world.villagers[0]
	sleeper.activity = VillagerState.ACTIVITY_REST
	assert_true(VillagerPresenter.ASLEEP.has(
		VillagerPresenter.thought_for(sleeper, night.world, night.config)
	))
	var day: Simulation = _sim_at(12)
	var scout: VillagerState = day.world.villagers[0]
	scout.activity = VillagerState.ACTIVITY_AWAY
	scout.location = &"western_forest"
	assert_eq(
		VillagerPresenter.thought_for(scout, day.world, day.config),
		"Out in the western forest, far from the camp."
	)


func test_every_activity_and_trait_has_thoughts() -> void:
	for activity: StringName in [
		VillagerState.ACTIVITY_REST, VillagerState.ACTIVITY_GATHER_WOOD,
		VillagerState.ACTIVITY_FORAGE, VillagerState.ACTIVITY_SOCIALIZE,
		VillagerState.ACTIVITY_BUILD, VillagerState.ACTIVITY_WANDER, VillagerState.ACTIVITY_HUNT,
	]:
		assert_true(VillagerPresenter.BY_ACTIVITY.has(activity), "No thoughts for %s" % activity)
	for trait_name: StringName in SimFixture.load_content().villager_traits:
		assert_true(VillagerPresenter.BY_TRAIT.has(trait_name), "No thoughts for %s" % trait_name)
	var fixed: Array[String] = []
	fixed.append_array(VillagerPresenter.COLD)
	fixed.append_array(VillagerPresenter.LOW_FOOD)
	fixed.append_array(VillagerPresenter.ASLEEP)
	for line: String in fixed:
		assert_true(line.length() < 70, "Short enough for the panel: %s" % line)


# ---- The panel ------------------------------------------------------------------------------

func test_the_panel_shows_the_villager_with_a_portrait() -> void:
	var sim: Simulation = _sim_at(12)
	var villager: VillagerState = sim.world.villagers[1]
	var panel: PanelHost = PanelHost.new()
	panel.show_villager(sim, villager.id)
	assert_eq(panel.mode(), &"villager")
	assert_eq(panel.villager_id(), villager.id)
	assert_true(panel.is_open())
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has(villager.display_name), "The name is the title")
	var view: VillagerPresenter = VillagerPresenter.present(villager, sim.world, sim.config)
	assert_true(texts.has(view.thought), "The thought is shown")
	var portraits: int = 0
	for node: Node in panel.find_children("*", "TextureRect", true, false):
		if (node as TextureRect).custom_minimum_size == PanelHost.PORTRAIT_SIZE:
			portraits += 1
			assert_true((node as TextureRect).texture != null, "The portrait has art")
	assert_eq(portraits, 1)
	panel.free()


func test_next_walks_through_the_group_and_wraps() -> void:
	var sim: Simulation = _sim_at(12)
	var panel: PanelHost = PanelHost.new()
	var first: VillagerState = sim.world.villagers[0]
	panel.show_villager(sim, first.id)
	var seen: Array[StringName] = [panel.villager_id()]
	for _step: int in sim.world.villagers.size():
		var next: Button = null
		for button: Button in _next_buttons(panel):
			next = button
		assert_true(next != null, "A Next button while there is more than one villager")
		next.pressed.emit()
		seen.append(panel.villager_id())
	assert_eq(seen[seen.size() - 1], first.id, "Wraps back to the first")
	assert_eq(seen.size(), sim.world.villagers.size() + 1)
	panel.free()


func _next_buttons(panel: PanelHost) -> Array[Button]:
	var found: Array[Button] = []
	for node: Node in panel.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button.visible and button.text.begins_with("Next"):
			found.append(button)
	return found


func test_a_lone_villager_has_no_next() -> void:
	var sim: Simulation = _sim_at(12)
	while sim.world.villagers.size() > 1:
		sim.world.villagers.pop_back()
	var panel: PanelHost = PanelHost.new()
	panel.show_villager(sim, sim.world.villagers[0].id)
	assert_eq(_next_buttons(panel).size(), 0)
	panel.free()


func test_an_unknown_villager_closes_the_panel() -> void:
	var sim: Simulation = _sim_at(12)
	var panel: PanelHost = PanelHost.new()
	panel.show_villager(sim, sim.world.villagers[0].id)
	panel.show_villager(sim, &"nobody")
	assert_false(panel.is_open())
	assert_eq(panel.villager_id(), &"")
	panel.free()


func test_the_villager_panel_closes_and_is_forgotten() -> void:
	var sim: Simulation = _sim_at(12)
	var panel: PanelHost = PanelHost.new()
	panel.show_villager(sim, sim.world.villagers[0].id)
	panel.close_panel()
	assert_eq(panel.mode(), &"")
	assert_eq(panel.villager_id(), &"", "No villager once it is closed")
	panel.free()


# ---- Clicking in the world ------------------------------------------------------------------

func _view_with_villagers(hour: int = 12) -> Array:
	var sim: Simulation = _sim_at(hour)
	var window: DesktopWindow = DesktopWindow.new()
	var view: WorldView = WorldView.new()
	view.setup(sim, window)
	for villager: VillagerState in sim.world.villagers:
		villager.activity = VillagerState.ACTIVITY_REST
	view.on_world_changed()
	for id: StringName in view._actors:
		(view._actors[id] as VillagerActor).position = Vector2(-300, 78)
	return [sim, window, view]


func _press(view: WorldView, at: Vector2, release_at: Vector2) -> void:
	view._unhandled_input(_button(true, at))
	view._unhandled_input(_button(false, release_at))


func _button(pressed: bool, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = at
	return event


func _place(view: WorldView, villager: VillagerState, at: Vector2) -> VillagerActor:
	var actor: VillagerActor = view._actors[villager.id]
	actor.position = at
	return actor


func test_clicking_a_villager_reports_them() -> void:
	var parts: Array = _view_with_villagers()
	var sim: Simulation = parts[0]
	var view: WorldView = parts[2]
	var villager: VillagerState = sim.world.villagers[0]
	_place(view, villager, Vector2(100, 78))
	var clicked: Array[StringName] = []
	view.villager_clicked.connect(func(id: StringName) -> void: clicked.append(id))
	_press(view, Vector2(100, 66), Vector2(100, 66))
	assert_eq(clicked, [villager.id] as Array[StringName])
	parts[2].free()
	parts[1].free()


func test_clicking_empty_ground_reports_nobody() -> void:
	var parts: Array = _view_with_villagers()
	var view: WorldView = parts[2]
	for villager: VillagerState in parts[0].world.villagers:
		_place(view, villager, Vector2(100, 78))
	var clicked: Array[StringName] = []
	view.villager_clicked.connect(func(id: StringName) -> void: clicked.append(id))
	_press(view, Vector2(250, 66), Vector2(250, 66))
	_press(view, Vector2(100, 30), Vector2(100, 30))
	assert_eq(clicked.size(), 0)
	view.free()
	parts[1].free()


func test_a_drag_is_not_a_click() -> void:
	var parts: Array = _view_with_villagers()
	var sim: Simulation = parts[0]
	var view: WorldView = parts[2]
	_place(view, sim.world.villagers[0], Vector2(100, 78))
	var clicked: Array[StringName] = []
	view.villager_clicked.connect(func(id: StringName) -> void: clicked.append(id))
	view._unhandled_input(_button(true, Vector2(100, 66)))
	var motion: InputEventMouseMotion = InputEventMouseMotion.new()
	motion.position = Vector2(60, 66)
	view._unhandled_input(motion)
	view._unhandled_input(_button(false, Vector2(60, 66)))
	assert_eq(clicked.size(), 0, "Dragging the world past a villager does not select them")
	view.free()
	parts[1].free()


func test_a_small_wobble_still_counts_as_a_click() -> void:
	var parts: Array = _view_with_villagers()
	var sim: Simulation = parts[0]
	var view: WorldView = parts[2]
	var villager: VillagerState = sim.world.villagers[0]
	_place(view, villager, Vector2(100, 78))
	var clicked: Array[StringName] = []
	view.villager_clicked.connect(func(id: StringName) -> void: clicked.append(id))
	_press(view, Vector2(100, 66), Vector2(102, 66))
	assert_eq(clicked.size(), 1)
	view.free()
	parts[1].free()


func test_the_one_in_front_is_picked_when_two_overlap() -> void:
	var parts: Array = _view_with_villagers()
	var sim: Simulation = parts[0]
	var view: WorldView = parts[2]
	var behind: VillagerState = sim.world.villagers[0]
	var front: VillagerState = sim.world.villagers[1]
	_place(view, behind, Vector2(100, 75))
	_place(view, front, Vector2(104, 79))
	assert_eq(view.villager_at(Vector2(102, 70)), front.id)
	view.free()
	parts[1].free()


func test_hidden_villagers_cannot_be_clicked() -> void:
	var parts: Array = _view_with_villagers()
	var sim: Simulation = parts[0]
	var view: WorldView = parts[2]
	var villager: VillagerState = sim.world.villagers[0]
	var actor: VillagerActor = _place(view, villager, Vector2(100, 78))
	assert_eq(view.villager_at(Vector2(100, 66)), villager.id)
	actor.visible = false
	assert_eq(view.villager_at(Vector2(100, 66)), &"")
	view.free()
	parts[1].free()


func test_a_click_lands_where_the_camera_is_looking() -> void:
	var parts: Array = _view_with_villagers()
	var sim: Simulation = parts[0]
	var view: WorldView = parts[2]
	var villager: VillagerState = sim.world.villagers[0]
	_place(view, villager, Vector2(100, 78))
	view.jump_camera(60.0)
	assert_eq(view.villager_at(Vector2(40, 66)), villager.id, "100 in the world is 40 on screen")
	assert_eq(view.villager_at(Vector2(100, 66)), &"", "Nobody is at 160 in the world")
	view.free()
	parts[1].free()
