extends McpTestSuite
## The player's way into the details the strip does not show: the right-click menu, the stores
## panel and the settings panel (docs/gameplay.md P2), and the window settings they change.

const SETTINGS_PATH: String = "user://test_settings.cfg"


func suite_name() -> String:
	return "player_menu"


func teardown() -> void:
	if FileAccess.file_exists(SETTINGS_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SETTINGS_PATH))


func _buttons(panel: PanelHost) -> Array[Button]:
	var found: Array[Button] = []
	for node: Node in panel.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button.visible and button.text != "x":
			found.append(button)
	return found


func _button(panel: PanelHost, text: String) -> Button:
	for button: Button in _buttons(panel):
		if button.text == text:
			return button
	return null


func _texts(panel: PanelHost) -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


# ---- UserSettings ---------------------------------------------------------------------------

func test_the_defaults_match_a_fresh_window() -> void:
	var settings: UserSettings = UserSettings.new()
	var window: DesktopWindow = DesktopWindow.new()
	assert_eq(settings.window_mode(), window.mode)
	assert_eq(settings.pixel_scale, window.pixel_scale)
	assert_eq(settings.always_on_top, window.always_on_top)
	window.free()


func test_settings_round_trip_through_their_file() -> void:
	var settings: UserSettings = UserSettings.new()
	settings.mode = &"corner"
	settings.pixel_scale = 3
	settings.always_on_top = false
	assert_true(settings.save_to(SETTINGS_PATH))
	var loaded: UserSettings = UserSettings.load_from(SETTINGS_PATH)
	assert_eq(loaded.mode, &"corner")
	assert_eq(loaded.pixel_scale, 3)
	assert_false(loaded.always_on_top)


func test_a_missing_or_odd_file_falls_back_to_the_defaults() -> void:
	var missing: UserSettings = UserSettings.load_from("user://no_such_settings.cfg")
	assert_eq(missing.mode, &"strip")
	assert_eq(missing.pixel_scale, 2)
	var file: ConfigFile = ConfigFile.new()
	file.set_value("window", "mode", "sideways")
	file.set_value("window", "scale", 99)
	file.save(SETTINGS_PATH)
	var odd: UserSettings = UserSettings.load_from(SETTINGS_PATH)
	assert_eq(odd.mode, &"strip", "An unknown mode is ignored")
	assert_eq(odd.pixel_scale, DesktopWindow.MAX_SCALE, "A silly size is clamped")


func test_settings_are_applied_to_a_window_and_read_back() -> void:
	var window: DesktopWindow = DesktopWindow.new()
	var settings: UserSettings = UserSettings.new()
	settings.mode = &"window"
	settings.pixel_scale = 4
	settings.always_on_top = false
	settings.apply_to(window)
	assert_eq(window.mode, DesktopWindow.Mode.WINDOW)
	assert_eq(window.pixel_scale, 4)
	assert_false(window.always_on_top)
	var back: UserSettings = UserSettings.from_window(window)
	assert_eq(back.mode, &"window")
	assert_eq(back.pixel_scale, 4)
	assert_false(back.always_on_top)
	window.free()


func test_each_window_mode_maps_to_its_name_and_back() -> void:
	for index: int in UserSettings.MODES.size():
		var settings: UserSettings = UserSettings.new()
		settings.mode = UserSettings.MODES[index]
		assert_eq(int(settings.window_mode()), index)
	assert_eq(UserSettings.MODES, [&"strip", &"corner", &"window"] as Array[StringName])


func test_picking_an_action_changes_one_setting_and_leaves_the_original_alone() -> void:
	var settings: UserSettings = UserSettings.new()
	assert_eq(settings.changed_by(&"mode:window").mode, &"window")
	assert_eq(settings.changed_by(&"scale:up").pixel_scale, 3)
	assert_eq(settings.changed_by(&"scale:down").pixel_scale, 1)
	assert_false(settings.changed_by(&"ontop:off").always_on_top)
	assert_true(settings.changed_by(&"ontop:on").always_on_top)
	assert_eq(settings.mode, &"strip", "The original is untouched")
	assert_eq(settings.pixel_scale, 2)


func test_the_size_stays_between_the_smallest_and_the_largest() -> void:
	var settings: UserSettings = UserSettings.new()
	settings.pixel_scale = DesktopWindow.MAX_SCALE
	assert_eq(settings.changed_by(&"scale:up").pixel_scale, DesktopWindow.MAX_SCALE)
	settings.pixel_scale = DesktopWindow.MIN_SCALE
	assert_eq(settings.changed_by(&"scale:down").pixel_scale, DesktopWindow.MIN_SCALE)


func test_an_unknown_action_changes_nothing() -> void:
	var settings: UserSettings = UserSettings.new()
	for action: StringName in [&"", &"mode:sideways", &"scale:sideways", &"ontop:maybe", &"nope"]:
		var same: UserSettings = settings.changed_by(action)
		assert_eq(same.mode, &"strip", "%s" % action)
		assert_eq(same.pixel_scale, 2, "%s" % action)
		assert_true(same.always_on_top, "%s" % action)


# ---- MenuPresenter --------------------------------------------------------------------------

func test_the_menu_offers_the_journal_the_villagers_the_stores_settings_and_quit() -> void:
	var actions: Array[StringName] = []
	for item: Array in MenuPresenter.MENU_ITEMS:
		actions.append(item[1])
	assert_eq(
		actions,
		[
			&"journal", &"villagers", &"achievements", &"stores", &"settings", &"quit",
		] as Array[StringName],
	)


func test_the_settings_rows_mark_what_is_chosen_now() -> void:
	var settings: UserSettings = UserSettings.new()
	settings.mode = &"corner"
	settings.pixel_scale = 3
	settings.always_on_top = false
	var rows: Array[MenuPresenter.Row] = MenuPresenter.settings_rows(settings, 1)
	assert_eq(rows.size(), 4, "No screen row with one screen")
	var chosen: Array[String] = []
	for option: MenuPresenter.Option in rows[0].options:
		if option.selected:
			chosen.append(option.text)
	assert_eq(chosen, ["Corner"] as Array[String])
	assert_eq(rows[1].options[1].text, "x3", "The size is shown")
	assert_eq(rows[1].options[1].action, &"", "...but is a label, not a button")
	assert_false(rows[2].options[0].selected, "On is not chosen")
	assert_true(rows[2].options[1].selected, "Off is")
	assert_eq(rows[3].options[0].action, &"shortcuts")
	assert_eq(MenuPresenter.settings_rows(settings, 2).size(), 5, "A second screen adds a row")


func test_the_stores_say_where_the_settlement_is_and_what_it_holds() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 12
	sim.world.resources[&"food"] = 0
	sim.world.resources[&"flint"] = 5
	var view: MenuPresenter.Stores = MenuPresenter.stores(sim.world, sim.config, sim.content)
	assert_eq(view.heading, "Cave Age - day 1")
	var keys: Array[StringName] = []
	for row: MenuPresenter.StockRow in view.stock:
		keys.append(row.key)
	assert_eq(keys, [&"wood", &"food", &"flint"] as Array[StringName], "The usual two first, empty or not")
	assert_eq(view.stock[0].amount, 12)


func test_other_stock_only_shows_once_there_is_some() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"flint"] = 0
	var view: MenuPresenter.Stores = MenuPresenter.stores(sim.world, sim.config, sim.content)
	for row: MenuPresenter.StockRow in view.stock:
		assert_true(row.key != &"flint")


# ---- The panel ------------------------------------------------------------------------------

func test_the_menu_panel_reports_the_button_picked() -> void:
	var panel: PanelHost = PanelHost.new()
	var picked: Array[StringName] = []
	panel.action_picked.connect(func(action: StringName) -> void: picked.append(action))
	panel.show_menu()
	assert_eq(panel.mode(), &"menu")
	assert_eq(panel.current_height(), PanelHost.height_for(&"menu"))
	for text: String in ["Journal", "Villagers", "Achievements", "Stores", "Settings", "Quit"]:
		assert_true(_button(panel, text) != null, "%s button" % text)
		_button(panel, text).pressed.emit()
	assert_eq(
		picked,
		[
			&"journal", &"villagers", &"achievements", &"stores", &"settings", &"quit",
		] as Array[StringName],
	)
	panel.free()


func test_the_menu_is_a_short_panel_and_the_details_are_full_ones() -> void:
	assert_true(PanelHost.height_for(&"menu") < PanelHost.HEIGHT)
	assert_eq(PanelHost.height_for(&"stores"), PanelHost.HEIGHT)
	assert_eq(PanelHost.height_for(&"villagers"), PanelHost.HEIGHT)
	assert_eq(PanelHost.height_for(&"settings"), PanelHost.HEIGHT)


func test_the_stores_panel_shows_the_numbers_the_strip_never_does() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 17
	var panel: PanelHost = PanelHost.new()
	var picked: Array[StringName] = []
	panel.action_picked.connect(func(action: StringName) -> void: picked.append(action))
	panel.show_stores(sim)
	assert_eq(panel.mode(), &"stores")
	var texts: PackedStringArray = _texts(panel)
	assert_true(texts.has("Cave Age - day 1"))
	assert_true(texts.has("17"), "The wood count")
	_button(panel, "Back").pressed.emit()
	assert_eq(picked, [&"menu"] as Array[StringName], "Back returns to the menu")
	panel.free()


func test_the_villager_list_shows_everyone_and_opens_the_one_picked() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.villagers[0].display_name = "Mira"
	sim.world.villagers[0].traits.assign([VillagerState.TRAIT_SOCIAL])
	sim.world.villagers[0].profession = &"scout"
	var panel: PanelHost = PanelHost.new()
	var picked: Array[StringName] = []
	panel.action_picked.connect(func(action: StringName) -> void: picked.append(action))
	panel.show_villagers(sim)
	assert_eq(panel.mode(), &"villagers")
	assert_eq(panel.current_height(), PanelHost.HEIGHT)
	var texts: PackedStringArray = _texts(panel)
	assert_true(texts.has("Mira"))
	assert_true(texts.has("Social - Scout"), "Traits and profession under the name")
	var rows: Array[Button] = []
	for button: Button in _buttons(panel):
		if button.text.is_empty():
			rows.append(button)
	assert_eq(rows.size(), sim.world.villagers.size(), "One row each")
	for index: int in rows.size():
		var pictures: int = rows[index].find_children("*", "TextureRect", true, false).size()
		var role_art: bool = not WorldLayout.role_sheet_path(
			sim.world.villagers[index].profession
		).is_empty()
		assert_eq(pictures, 2 if role_art else 1, "...with a portrait, and the role's overlay")
	rows[0].pressed.emit()
	assert_eq(picked, [PanelHost.villager_action(sim.world.villagers[0].id)] as Array[StringName])
	_button(panel, "Back").pressed.emit()
	assert_eq(picked[1], &"menu", "Back returns to the menu")
	panel.free()


func test_the_settings_panel_shows_the_choices_and_reports_each_pick() -> void:
	var settings: UserSettings = UserSettings.new()
	var panel: PanelHost = PanelHost.new()
	var picked: Array[StringName] = []
	panel.action_picked.connect(func(action: StringName) -> void: picked.append(action))
	panel.show_settings(settings, 2)
	assert_eq(panel.mode(), &"settings")
	assert_true(_button(panel, "Strip").button_pressed, "The current mode is drawn pressed in")
	assert_false(_button(panel, "Window").button_pressed)
	assert_true(_button(panel, "On").button_pressed)
	assert_true(_texts(panel).has("x2"), "The size")
	for pair: Array in [
		["Window", &"mode:window"], ["Corner", &"mode:corner"], ["+", &"scale:up"],
		["-", &"scale:down"], ["Off", &"ontop:off"], ["Next screen", &"screen:next"],
	]:
		picked.clear()
		_button(panel, pair[0]).pressed.emit()
		assert_eq(picked, [pair[1]] as Array[StringName], "%s" % pair[0])
	assert_true(_button(panel, "Next screen") != null)
	panel.show_settings(settings, 1)
	assert_true(_button(panel, "Next screen") == null, "One screen, nothing to move to")
	panel.free()


# ---- The right click ------------------------------------------------------------------------

func _mouse(button_index: MouseButton, at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index
	event.pressed = true
	event.position = at
	return event


func test_a_right_click_on_the_strip_asks_for_the_menu() -> void:
	var view: WorldView = WorldView.new()
	var window: DesktopWindow = DesktopWindow.new()
	view.setup(SimFixture.new_sim(), window)
	var asked: Array[int] = []
	view.menu_requested.connect(func() -> void: asked.append(1))
	view._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, Vector2(50, 40)))
	assert_eq(asked.size(), 1)
	view._unhandled_input(_mouse(MOUSE_BUTTON_RIGHT, Vector2(-30, 40)))
	assert_eq(asked.size(), 1, "A right click off the strip does nothing")
	view._unhandled_input(_mouse(MOUSE_BUTTON_LEFT, Vector2(50, 40)))
	assert_eq(asked.size(), 1, "A left click is not the menu")
	view.free()
	window.free()
