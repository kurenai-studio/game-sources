extends McpTestSuite
## What the player is shown: decisions (with what each choice needs), the journal, the summary of
## time away, the panel that holds them, the strip's icons, and the window room for a panel.

const DAY: int = SimFixture.TICKS_PER_DAY


func suite_name() -> String:
	return "ui"


func _decision(sim: Simulation, event_id: StringName, subject: VillagerState = null) -> PendingDecision:
	sim.fire_event(sim.content.get_event(event_id), subject)
	return SimFixture.pending_for(sim, event_id)


func _buttons(panel: PanelHost) -> Array[Button]:
	var buttons: Array[Button] = []
	for node: Node in panel.find_children("*", "Button", true, false):
		var button: Button = node as Button
		if button.visible and button.text != "x":
			buttons.append(button)
	return buttons


# ---- DecisionPresenter ----------------------------------------------------------------------

func test_a_decision_shows_its_title_text_and_choices() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: DecisionPresenter = DecisionPresenter.present(
		_decision(sim, &"fire_from_storm", sim.world.villagers[0]), sim
	)
	assert_eq(view.title, "A burning tree")
	assert_true(view.body.begins_with("A storm rolled"))
	assert_eq(view.choices.size(), 2)
	assert_eq(view.choices[0].id, &"carry_fire")
	assert_true(view.choices[0].enabled)
	assert_eq(view.choices[0].note, "", "Nothing to afford, nothing to note")


func test_the_subject_s_name_is_filled_in() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var subject: VillagerState = sim.world.villagers[1]
	var view: DecisionPresenter = DecisionPresenter.present(
		_decision(sim, &"fire_from_sparks", subject), sim
	)
	assert_true(view.body.begins_with(subject.display_name), "Body names %s" % subject.display_name)
	assert_false(view.body.contains("{subject}"))


func test_a_choice_that_costs_something_says_what_it_needs() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 60)
	sim.world.resources[&"wood"] = 10
	var view: DecisionPresenter = DecisionPresenter.present(_decision(sim, &"building_opportunity"), sim)
	var by_id: Dictionary = {}
	for choice: DecisionPresenter.ChoiceView in view.choices:
		by_id[choice.id] = choice
	assert_true(by_id[&"build_drying_rack"].enabled)
	assert_eq(by_id[&"build_drying_rack"].note, "needs 10 wood")
	assert_false(by_id[&"build_knapping_spot"].enabled, "Twelve wood is more than ten")
	assert_eq(by_id[&"build_knapping_spot"].note, "needs 12 wood (have 10)")


func test_choices_not_yet_unlocked_are_not_listed_at_all() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.resources[&"wood"] = 50
	var view: DecisionPresenter = DecisionPresenter.present(_decision(sim, &"building_opportunity"), sim)
	assert_eq(view.choices.size(), 1, "Only the Lookout is unlocked on day 1")
	assert_eq(view.choices[0].id, &"build_lookout")


func test_a_choice_for_something_already_built_is_not_listed() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 60)
	sim.world.resources[&"wood"] = 50
	var lookout: BuildingState = BuildingState.new()
	lookout.def_id = &"lookout"
	sim.world.buildings.append(lookout)
	sim.complete_building(lookout)
	var view: DecisionPresenter = DecisionPresenter.present(_decision(sim, &"building_opportunity"), sim)
	for choice: DecisionPresenter.ChoiceView in view.choices:
		assert_ne(choice.id, &"build_lookout")


func test_an_unknown_event_does_not_crash_the_presenter() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var decision: PendingDecision = PendingDecision.new()
	decision.id = &"d1"
	decision.event_id = &"no_such_event"
	var view: DecisionPresenter = DecisionPresenter.present(decision, sim)
	assert_eq(view.title, "no_such_event")
	assert_eq(view.choices.size(), 0)


# ---- JournalPresenter -----------------------------------------------------------------------

func test_the_journal_reads_newest_first() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_journal("First thing.", &"settlement", &"", &"")
	sim.add_journal("Second thing.", &"settlement", &"", &"")
	var lines: PackedStringArray = JournalPresenter.lines(sim.world)
	assert_eq(lines.size(), 3, "Founding line plus two")
	assert_true(lines[0].ends_with("Second thing."))
	assert_true(lines[2].ends_with("The settlement was founded."))
	assert_true(lines[0].begins_with("Day 1"), "Days count from 1")


func test_the_journal_can_be_limited() -> void:
	var sim: Simulation = SimFixture.new_sim()
	for index: int in 10:
		sim.add_journal("Entry %d" % index, &"settlement", &"", &"")
	var lines: PackedStringArray = JournalPresenter.lines(sim.world, 3)
	assert_eq(lines.size(), 3)
	assert_true(lines[0].ends_with("Entry 9"))


# ---- AwaySummary ----------------------------------------------------------------------------

func _report(seconds: float, texts: Array[String]) -> CatchUpReport:
	var report: CatchUpReport = CatchUpReport.new()
	report.elapsed_seconds = seconds
	for text: String in texts:
		var entry: JournalEntry = JournalEntry.new()
		entry.text = text
		report.journal_entries.append(entry)
	return report


func test_a_short_absence_is_not_summarised() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_true(AwaySummary.present(_report(120.0, ["Something."]), sim.world, 300.0) == null)


func test_an_absence_where_nothing_happened_is_not_summarised() -> void:
	var sim: Simulation = SimFixture.new_sim()
	assert_true(AwaySummary.present(_report(7200.0, []), sim.world, 300.0) == null)


func test_the_summary_lists_what_happened_oldest_first() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var summary: AwaySummary = AwaySummary.present(
		_report(8100.0, ["One.", "Two."]), sim.world, 300.0
	)
	assert_eq(summary.duration_text, "2 h 15 min")
	assert_eq(summary.lines, PackedStringArray(["One.", "Two."]))
	assert_eq(summary.more_count, 0)


func test_a_long_story_is_cut_to_the_latest_and_counted() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var texts: Array[String] = []
	for index: int in 10:
		texts.append("Event %d" % index)
	var summary: AwaySummary = AwaySummary.present(_report(8100.0, texts), sim.world, 300.0)
	assert_eq(summary.lines.size(), AwaySummary.MAX_LINES)
	assert_eq(summary.lines[summary.lines.size() - 1], "Event 9")
	assert_eq(summary.more_count, 10 - AwaySummary.MAX_LINES)


func test_waiting_decisions_are_counted_and_can_be_the_only_news() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_decision(sim, &"fire_from_storm", sim.world.villagers[0])
	var summary: AwaySummary = AwaySummary.present(_report(7200.0, []), sim.world, 300.0)
	assert_true(summary != null)
	assert_eq(summary.decisions_waiting, 1)


func test_skipped_time_is_flagged() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var report: CatchUpReport = _report(99999999.0, ["Something."])
	report.ticks_dropped = 100
	assert_true(AwaySummary.present(report, sim.world, 300.0).time_was_skipped)


func test_durations_read_naturally() -> void:
	assert_eq(AwaySummary.describe_duration(20.0), "a moment")
	assert_eq(AwaySummary.describe_duration(12 * 60.0), "12 min")
	assert_eq(AwaySummary.describe_duration(3600.0), "1 h")
	assert_eq(AwaySummary.describe_duration(8100.0), "2 h 15 min")
	assert_eq(AwaySummary.describe_duration(86400.0), "1 day")
	assert_eq(AwaySummary.describe_duration(86400.0 * 2 + 3 * 3600.0), "2 days 3 h")


# ---- PanelHost ------------------------------------------------------------------------------

func test_the_panel_shows_a_decision_and_reports_the_choice_picked() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var decision: PendingDecision = _decision(sim, &"fire_from_storm", sim.world.villagers[0])
	var panel: PanelHost = PanelHost.new()
	var picked: Array = []
	panel.choice_picked.connect(func(did: StringName, cid: StringName) -> void: picked.append([did, cid]))
	panel.show_decision(sim)
	assert_true(panel.is_open())
	assert_eq(panel.mode(), &"decision")
	var buttons: Array[Button] = _buttons(panel)
	assert_eq(buttons.size(), 2)
	assert_eq(buttons[0].text, "Carry a burning branch back to the cave")
	buttons[0].pressed.emit()
	assert_eq(picked, [[decision.id, &"carry_fire"]])
	panel.free()


func test_a_choice_that_cannot_be_afforded_is_disabled_in_the_panel() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 60)
	sim.world.resources[&"wood"] = 10
	_decision(sim, &"building_opportunity")
	var panel: PanelHost = PanelHost.new()
	panel.show_decision(sim)
	var disabled: int = 0
	for button: Button in _buttons(panel):
		if button.disabled:
			disabled += 1
	assert_eq(disabled, 1, "Only the Knapping Spot is out of reach")
	panel.free()


func test_several_decisions_can_be_paged_through() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_decision(sim, &"fire_from_storm", sim.world.villagers[0])
	_decision(sim, &"fire_from_sparks", sim.world.villagers[1])
	var panel: PanelHost = PanelHost.new()
	panel.show_decision(sim, 0)
	var next: Button = null
	for button: Button in _buttons(panel):
		if button.text == "Next >":
			next = button
	assert_true(next != null, "A Next button when more than one is waiting")
	next.pressed.emit()
	var texts: PackedStringArray = PackedStringArray()
	for button: Button in _buttons(panel):
		texts.append(button.text)
	assert_true(texts.has("Blow on the spark, gently"), "The second decision is showing")
	panel.free()


func test_the_panel_closes_when_nothing_is_pending() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	assert_true(panel.is_open())
	panel.show_decision(sim)
	assert_false(panel.is_open(), "No decision to show, so it closes")
	panel.free()


func test_closing_is_announced_once() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var panel: PanelHost = PanelHost.new()
	var closes: Array[int] = [0]
	panel.closed.connect(func() -> void: closes[0] += 1)
	panel.show_journal(sim)
	panel.close_panel()
	panel.close_panel()
	assert_eq(closes[0], 1)
	assert_eq(panel.mode(), &"")
	panel.free()


func test_the_away_panel_offers_to_show_waiting_decisions() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var summary: AwaySummary = AwaySummary.new()
	summary.duration_text = "1 h"
	summary.decisions_waiting = 2
	summary.lines = PackedStringArray(["Something happened."])
	var panel: PanelHost = PanelHost.new()
	var requested: Array[int] = [0]
	panel.decisions_requested.connect(func() -> void: requested[0] += 1)
	panel.show_away(summary)
	assert_eq(panel.mode(), &"away")
	var texts: PackedStringArray = PackedStringArray()
	for button: Button in _buttons(panel):
		texts.append(button.text)
		if button.text == "See it":
			button.pressed.emit()
	assert_true(texts.has("Got it") and texts.has("See it"))
	assert_eq(requested[0], 1)
	panel.free()


func test_the_age_panel_names_the_age_and_stays_until_dismissed() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var era: EraDef = sim.content.get_era(&"settled")
	var panel: PanelHost = PanelHost.new()
	panel.show_age(era)
	assert_eq(panel.mode(), &"age")
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has("A new age: %s" % era.display_name))
	assert_true(texts.has(era.description))
	assert_true(panel.is_open(), "It does not go away by itself")
	var dismissed: Array[Button] = []
	for button: Button in _buttons(panel):
		if button.text == "Got it":
			dismissed.append(button)
	assert_eq(dismissed.size(), 1)
	dismissed[0].pressed.emit()
	assert_false(panel.is_open())
	panel.free()


func test_old_button_actions_do_not_leak_into_new_content() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var summary: AwaySummary = AwaySummary.new()
	summary.decisions_waiting = 1
	summary.lines = PackedStringArray(["x"])
	var panel: PanelHost = PanelHost.new()
	var requested: Array[int] = [0]
	panel.decisions_requested.connect(func() -> void: requested[0] += 1)
	panel.show_away(summary)
	panel.show_away(summary)
	for button: Button in _buttons(panel):
		if button.text == "See it":
			button.pressed.emit()
	assert_eq(requested[0], 1, "Showing it twice must not double the action")
	panel.free()


# ---- StripIcons -----------------------------------------------------------------------------

func test_the_bulb_appears_only_while_a_decision_waits() -> void:
	var icons: StripIcons = StripIcons.new()
	assert_false(icons.has_bulb())
	assert_eq(icons.clickable_regions().size(), 5, "The glyph, the two gauges, the journal and the gear")
	icons.update_pending(1)
	assert_true(icons.has_bulb())
	assert_eq(icons.badge_text(), "", "No number for a single decision")
	assert_eq(icons.clickable_regions().size(), 6)
	icons.update_pending(3)
	assert_eq(icons.badge_text(), "3")
	icons.update_pending(0)
	assert_false(icons.has_bulb())
	icons.free()


func test_the_icons_sit_inside_the_viewport() -> void:
	var icons: StripIcons = StripIcons.new()
	icons.update_pending(1)
	var viewport: Rect2i = Rect2i(Vector2i.ZERO, WorldLayout.VIEW_SIZE)
	for region: Rect2i in icons.clickable_regions():
		assert_true(viewport.encloses(region), "%s is inside the viewport" % region)
	icons.free()


func test_the_gear_is_always_there_and_never_overlaps_another_icon() -> void:
	var icons: StripIcons = StripIcons.new()
	icons.update_pending(1)
	var regions: Array[Rect2i] = icons.clickable_regions()
	var gear: Rect2i = Rect2i(Vector2i(StripIcons.GEAR_POSITION), StripIcons.GEAR_REGION.size)
	assert_true(regions.has(gear), "The gear is in the click region")
	for region: Rect2i in regions:
		if region != gear:
			assert_false(gear.intersects(region), "%s does not overlap the gear" % region)
	icons.update_pending(0)
	assert_true(icons.clickable_regions().has(gear), "Present with no decision waiting")
	icons.free()


func test_pressing_the_gear_asks_for_the_menu() -> void:
	var icons: StripIcons = StripIcons.new()
	var asked: Array[int] = []
	icons.menu_pressed.connect(func() -> void: asked.append(1))
	icons._gear.pressed.emit()
	assert_eq(asked.size(), 1)
	icons.free()


# ---- room for a panel in the window ---------------------------------------------------------

func test_a_panel_pushes_the_viewport_down_by_its_height() -> void:
	var window: DesktopWindow = DesktopWindow.new()
	assert_eq(window.art_origin().y, 0)
	window.set_panel_height(PanelHost.HEIGHT)
	assert_eq(window.art_origin().y, PanelHost.HEIGHT)
	window.set_panel_height(-5)
	assert_eq(window.art_origin().y, 0, "Negative means none")
	window.free()


func test_an_open_panel_is_clickable_across_the_viewport_width() -> void:
	var window: DesktopWindow = DesktopWindow.new()
	window.set_skyline(Skyline.new(WorldLayout.WORLD_WIDTH, 80).tops)
	window.set_panel_height(PanelHost.HEIGHT)
	var tops: PackedInt32Array = window._view_tops()
	assert_eq(tops.size(), DesktopWindow.ART_SIZE.x)
	assert_eq(tops[0], -PanelHost.HEIGHT, "The click region reaches up to the panel's top")
	assert_eq(tops[383], -PanelHost.HEIGHT)
	window.set_panel_height(0)
	assert_eq(window._view_tops()[0], 80, "And shrinks back when it closes")
	window.free()


func test_the_window_makes_room_for_the_whole_panel() -> void:
	var window: DesktopWindow = DesktopWindow.new()
	window.set_panel_height(PanelHost.HEIGHT)
	assert_eq(window.panel_height, PanelSkin.PANEL_HEIGHT, "The window and the skin's art agree")
	window.free()


# ---- skins ----------------------------------------------------------------------------------

func test_every_piece_of_every_skin_is_inside_its_atlas() -> void:
	for era: StringName in PanelSkin.skins():
		var skin: PanelSkin = PanelSkin.for_era(era)
		assert_eq(skin.era_id, era)
		var bounds: Rect2 = Rect2(Vector2.ZERO, skin.atlas().get_size())
		var pieces: Array[Rect2] = [skin.panel_region]
		for region: Rect2 in skin.button_regions.values():
			pieces.append(region)
		for region: Rect2 in skin.close_regions.values():
			pieces.append(region)
		for region: Rect2 in skin.icon_regions.values():
			pieces.append(region)
		for region: Rect2 in pieces:
			assert_true(bounds.encloses(region), "%s: %s is outside the atlas" % [era, region])
		assert_eq(skin.panel_region.size, Vector2(PanelHost.WIDTH, PanelHost.HEIGHT))


func test_an_age_without_a_skin_gets_the_cave_one() -> void:
	assert_eq(PanelSkin.for_era(&"cave").era_id, &"cave")
	assert_eq(PanelSkin.for_era(&"no_such_age").era_id, &"cave")


func test_the_settled_age_has_its_own_skin() -> void:
	var settled: PanelSkin = PanelSkin.for_era(&"settled")
	assert_eq(settled.era_id, &"settled")
	assert_true(settled.atlas_path != PanelSkin.cave().atlas_path, "Its own atlas, not the hide")
	assert_true(settled.title_color != PanelSkin.cave().title_color)
	assert_true(settled.icon_for(&"wood") != null and settled.icon_for(&"food") != null)


func test_the_bronze_age_has_its_own_skin() -> void:
	var bronze: PanelSkin = PanelSkin.for_era(&"bronze")
	assert_eq(bronze.era_id, &"bronze")
	assert_true(bronze.atlas_path != PanelSkin.clay().atlas_path, "Its own atlas, not the clay")
	assert_true(bronze.title_color != PanelSkin.clay().title_color)
	assert_true(bronze.icon_for(&"wood") != null and bronze.icon_for(&"food") != null)


func test_every_age_in_the_content_has_its_own_skin() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	assert_true(not content.eras.is_empty(), "The content has ages")
	for era: EraDef in content.eras:
		assert_eq(PanelSkin.for_era(era.id).era_id, era.id, "%s has its own skin" % era.id)


func test_the_panel_changes_skin_when_the_age_turns() -> void:
	var panel: PanelHost = PanelHost.new()
	assert_eq(panel.skin().era_id, &"cave")
	panel.set_skin(PanelSkin.for_era(&"settled"))
	assert_eq(panel.skin().era_id, &"settled")
	panel.free()


func test_the_skin_has_icons_for_the_resources_that_exist() -> void:
	var skin: PanelSkin = PanelSkin.cave()
	assert_true(skin.icon_for(&"wood") != null)
	assert_true(skin.icon_for(&"food") != null)
	assert_true(skin.icon_for(&"flint") == null, "No icon means the panel writes the name")


func test_the_skin_loads_its_pixel_font() -> void:
	var skin: PanelSkin = PanelSkin.cave()
	assert_true(skin.font() is FontFile, "The pixel font loaded, not the fallback")
	assert_true(skin.title_font() != skin.font(), "Titles use the bold weight")


func test_costs_are_drawn_as_icons_and_the_shortfall_is_shown() -> void:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 60)
	sim.world.resources[&"wood"] = 10
	_decision(sim, &"building_opportunity")
	var panel: PanelHost = PanelHost.new()
	panel.show_decision(sim)
	var icons: int = 0
	for node: Node in panel.find_children("*", "TextureRect", true, false):
		if (node as TextureRect).custom_minimum_size == PanelHost.NEED_ICON_SIZE:
			icons += 1
	assert_eq(icons, 3, "A log per costed choice, got %d" % icons)
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has("12 (have 10)"), "The Knapping Spot is two wood short")
	assert_true(texts.has("8"), "The affordable ones just show the cost")
	panel.free()


func test_a_cost_with_no_icon_falls_back_to_its_name() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var event: EventDef = sim.content.get_event(&"building_opportunity")
	var cost: SimCondition = SimCondition.new()
	cost.kind = SimCondition.Kind.RESOURCE_AT_LEAST
	cost.key = &"flint"
	cost.amount = 3
	event.choices[0].requires.append(cost)
	SimFixture.jump_to_day(sim, 60)
	sim.world.resources[&"wood"] = 50
	_decision(sim, &"building_opportunity")
	var panel: PanelHost = PanelHost.new()
	panel.show_decision(sim)
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has("3 (have 0) flint"), "The name stands in for the missing icon")
	panel.free()


func test_the_journal_panel_shows_the_day_apart_from_the_text() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_journal("Something happened.", &"settlement", &"", &"")
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has("Day 1") and texts.has("Something happened."))
	panel.free()


func test_the_journal_entries_carry_day_numbers() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_journal("Later.", &"settlement", &"", &"")
	var entries: Array[Dictionary] = JournalPresenter.entries(sim.world)
	assert_eq(entries[0]["text"], "Later.")
	assert_eq(entries[0]["day"], 1)


func test_a_long_journal_is_shown_a_page_at_a_time() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var extra: int = PanelHost.JOURNAL_PAGE_SIZE * 2 + 5
	for index: int in extra:
		sim.add_journal("Entry %d" % index, &"settlement", &"", &"")
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	assert_eq(panel._content.get_child_count(), PanelHost.JOURNAL_PAGE_SIZE, "One page of rows")
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	assert_true(texts.has("Entry %d" % (extra - 1)), "The newest entry is on the first page")
	assert_true(panel._primary.visible and panel._primary.text.begins_with("Older"))
	assert_false(panel._secondary.visible, "Nothing is newer than the first page")
	panel._primary.pressed.emit()
	assert_eq(panel._content.get_child_count(), PanelHost.JOURNAL_PAGE_SIZE)
	assert_true(panel._secondary.visible, "A later page can go back")
	panel._primary.pressed.emit()
	assert_eq(panel._content.get_child_count(), 6, "The last page holds the 5 left and the founding line")
	assert_false(panel._primary.visible, "Nothing is older than the last page")
	panel._secondary.pressed.emit()
	assert_eq(panel._content.get_child_count(), PanelHost.JOURNAL_PAGE_SIZE)
	panel.free()


func test_a_short_journal_has_no_paging() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.add_journal("Something happened.", &"settlement", &"", &"")
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	assert_false(panel._primary.visible)
	assert_false(panel._secondary.visible)
	panel.free()


func test_journal_entries_can_skip_the_newest() -> void:
	var sim: Simulation = SimFixture.new_sim()
	for index: int in 5:
		sim.add_journal("Entry %d" % index, &"settlement", &"", &"")
	var entries: Array[Dictionary] = JournalPresenter.entries(sim.world, 2, 1)
	assert_eq(entries.size(), 2)
	assert_eq(entries[0]["text"], "Entry 3", "The newest is skipped")
	assert_eq(entries[1]["text"], "Entry 2")
	assert_eq(JournalPresenter.entries(sim.world, 0, 100).size(), 0, "Skipping past the end is empty")


func test_a_long_game_does_not_widen_the_journal_past_the_panel() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.tick = 1377 * sim.config.ticks_per_day
	sim.add_journal("The grain went up the granary ladder in baskets.", &"settlement", &"", &"")
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	var font: Font = panel.skin().font()
	var text_width: float = font.get_string_size(
		"Day 1378", HORIZONTAL_ALIGNMENT_LEFT, -1.0, PanelSkin.FONT_SIZE
	).x
	assert_true(text_width > PanelHost.DAY_WIDTH, "A four digit day needs more than the column")
	var found: bool = false
	for node: Node in panel.find_children("*", "Label", true, false):
		var label: Label = node as Label
		if label.text == "Day 1378":
			found = true
			assert_true(label.custom_minimum_size.x >= text_width, "The day column fits its text")
	assert_true(found, "The journal shows day 1378")
	var card: Vector2 = panel._card.get_combined_minimum_size()
	assert_true(card.x <= float(PanelHost.WIDTH), "Day 1378 fits the card, it asks for %d" % card.x)
	panel.free()


func test_a_panel_starts_at_the_width_of_its_frame_after_a_wider_one() -> void:
	var sim: Simulation = SimFixture.new_sim()
	_decision(sim, &"building_opportunity")
	var panel: PanelHost = PanelHost.new()
	panel._card.custom_minimum_size = Vector2(PanelHost.WIDTH + 11, PanelHost.HEIGHT)
	panel._card.size = Vector2(PanelHost.WIDTH + 11, PanelHost.HEIGHT)
	panel._card.custom_minimum_size = Vector2(PanelHost.WIDTH, PanelHost.HEIGHT)
	assert_eq(panel._card.size.x, float(PanelHost.WIDTH + 11), "The card kept the wider size")
	panel.show_decision(sim)
	assert_eq(panel._card.size.x, float(PanelHost.WIDTH), "A new panel is as wide as the frame")
	panel.free()


func test_the_panel_rolls_out_from_its_bottom_edge() -> void:
	var panel: PanelHost = PanelHost.new()
	panel._set_reveal(60)
	assert_eq(panel._clip.position.y, float(PanelHost.HEIGHT - 60), "The window onto it starts lower")
	assert_eq(panel._clip.size.y, 60.0)
	assert_eq(panel._card.position.y, float(60 - PanelHost.HEIGHT), "While the card stays put")
	panel._set_reveal(PanelHost.HEIGHT)
	assert_eq(panel._clip.position.y, 0.0)
	assert_eq(panel._card.position.y, 0.0)
	panel.free()


func test_a_panel_is_fully_revealed_when_not_animated() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	assert_eq(panel._reveal, PanelHost.HEIGHT)
	panel.close_panel()
	assert_false(panel.visible)
	panel.free()


func test_a_new_skin_can_be_applied_while_showing() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var panel: PanelHost = PanelHost.new()
	panel.show_journal(sim)
	panel.set_skin(PanelSkin.cave())
	assert_true(panel.skin() != null)
	assert_true(panel.is_open())
	panel.free()
