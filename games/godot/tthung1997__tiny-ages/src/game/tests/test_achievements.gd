extends McpTestSuite
## The achievements panel: only what is earned, under the title it was earned with, in the order
## it was earned (docs/gameplay.md P12), and the title is kept in the save.

const SAVE_PATH: String = "user://test_achievements_save.tres"


func suite_name() -> String:
	return "achievements"


func teardown() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))


func _titles(panel: PanelHost) -> PackedStringArray:
	var texts: PackedStringArray = PackedStringArray()
	for node: Node in panel.find_children("*", "Label", true, false):
		texts.append((node as Label).text)
	return texts


# ---- the simulation keeps the title ---------------------------------------------------------

func test_an_earned_achievement_keeps_its_title_and_the_journal_line() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.grant_achievement(&"first_harvest", "The First Calves")
	assert_true(sim.world.has_achievement(&"first_harvest"))
	assert_eq(sim.world.achievement_titles[&"first_harvest"], "The First Calves")
	assert_true(SimFixture.journal_index(sim.world, "Achievement: The First Calves") >= 0)


func test_earning_it_again_changes_nothing() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.grant_achievement(&"first_harvest", "The First Harvest")
	var entries: int = sim.world.journal.size()
	sim.grant_achievement(&"first_harvest", "The First Calves")
	assert_eq(sim.world.achievement_titles[&"first_harvest"], "The First Harvest")
	assert_eq(sim.world.journal.size(), entries, "No second journal line")


func test_the_title_survives_a_save() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.grant_achievement(&"fire", "Fire")
	assert_eq(SaveStore.save_world(sim.world, SAVE_PATH), OK)
	var loaded: WorldState = SaveStore.load_world(SAVE_PATH)
	assert_eq(loaded.achievement_titles, sim.world.achievement_titles)


# ---- the presenter --------------------------------------------------------------------------

func test_the_badges_are_what_is_earned_in_the_order_it_was_earned() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.clear()
	sim.world.achievement_titles.clear()
	assert_eq(AchievementPresenter.badges(sim.world, sim.content).size(), 0, "Nothing, not empty slots")
	sim.grant_achievement(&"stone_tools", "Stone Tools")
	sim.grant_achievement(&"fire", "Fire")
	var badges: Array[AchievementPresenter.Badge] = AchievementPresenter.badges(sim.world, sim.content)
	assert_eq(badges.size(), 2)
	assert_eq(badges[0].title, "Stone Tools")
	assert_eq(badges[1].title, "Fire")
	assert_eq(badges[0].icon, AchievementPresenter.ICON_ORDER.find(&"stone_tools"))


func test_the_title_the_group_earned_is_the_one_shown() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.grant_achievement(&"first_harvest", "The First Calves")
	assert_eq(AchievementPresenter.title_for(&"first_harvest", sim.world, sim.content), "The First Calves")


func test_an_older_save_without_titles_falls_back_to_the_content_then_the_key() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.clear()
	sim.world.achievements.append(&"fire")
	sim.world.achievements.append(&"made_up_thing")
	sim.world.achievement_titles.clear()
	var badges: Array[AchievementPresenter.Badge] = AchievementPresenter.badges(sim.world, sim.content)
	assert_eq(badges[0].title, "Fire", "From the content that grants it")
	assert_eq(badges[1].title, "Made Up Thing", "Or the key spelled out")
	assert_eq(badges[1].icon, AchievementPresenter.GENERIC_ICON)


func test_every_achievement_the_game_can_grant_has_an_icon() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	for key: StringName in content._grantable_achievements():
		assert_true(AchievementPresenter.ICON_ORDER.has(key), "%s has an icon" % key)
		assert_false(content.achievement_title(key).is_empty(), "%s has a title" % key)


func test_the_icon_sheet_has_a_cell_for_each_icon_and_the_generic_one() -> void:
	var sheet: Texture2D = load(AchievementPresenter.ICONS_PATH) as Texture2D
	assert_true(sheet != null)
	assert_eq(AchievementPresenter.GENERIC_ICON, AchievementPresenter.ICON_ORDER.size())
	assert_eq(sheet.get_width(), (AchievementPresenter.GENERIC_ICON + 1) * AchievementPresenter.CELL.x)
	assert_eq(sheet.get_height(), AchievementPresenter.CELL.y)


# ---- the panel ------------------------------------------------------------------------------

func test_the_panel_lists_only_what_is_earned_and_goes_back_to_the_menu() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.clear()
	sim.grant_achievement(&"fire", "Fire")
	sim.grant_achievement(&"first_roof", "A Roof of Your Own")
	var panel: PanelHost = PanelHost.new()
	var picked: Array[StringName] = []
	panel.action_picked.connect(func(action: StringName) -> void: picked.append(action))
	panel.show_achievements(sim)
	assert_eq(panel.mode(), &"achievements")
	assert_eq(panel.current_height(), PanelHost.HEIGHT)
	var titles: PackedStringArray = _titles(panel)
	assert_true(titles.has("Fire"))
	assert_true(titles.has("A Roof of Your Own"))
	assert_false(titles.has("Stone Tools"), "Not earned, not shown")
	for button: Button in panel.find_children("*", "Button", true, false):
		if button.text == "Back":
			button.pressed.emit()
	assert_eq(picked, [&"menu"] as Array[StringName])
	panel.free()


func test_the_panel_is_quiet_before_anything_is_earned() -> void:
	var sim: Simulation = SimFixture.new_sim()
	sim.world.achievements.clear()
	var panel: PanelHost = PanelHost.new()
	panel.show_menu()
	var baseline: int = panel.find_children("*", "TextureRect", true, false).size()
	panel.show_achievements(sim)
	assert_true(_titles(panel).has("Nothing here yet."))
	assert_eq(panel.find_children("*", "TextureRect", true, false).size(), baseline, "No empty slots")
	panel.free()
