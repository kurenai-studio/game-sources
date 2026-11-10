extends McpTestSuite
## Panel heights: a villager's thought gets a short panel, the rest a full one; the art is cut
## to fit without changing how it looks, and the window follows (docs/ages.md V7).


func suite_name() -> String:
	return "panel_height"


func _sim() -> Simulation:
	var sim: Simulation = SimFixture.new_sim()
	SimFixture.jump_to_day(sim, 60)
	return sim


func test_a_villager_has_a_shorter_panel_than_the_rest() -> void:
	var short: int = PanelHost.height_for(&"villager")
	assert_true(short < PanelHost.HEIGHT, "The thought is short")
	assert_true(short >= 96, "But still holds a portrait, a few lines and a button")
	for kind: StringName in [&"decision", &"journal", &"away", &""]:
		assert_eq(PanelHost.height_for(kind), PanelHost.HEIGHT, "%s fills a full panel" % kind)


func test_the_panel_takes_the_height_of_what_it_shows() -> void:
	var sim: Simulation = _sim()
	var panel: PanelHost = PanelHost.new()
	assert_eq(panel.current_height(), 0, "Closed, it needs no room")
	panel.show_villager(sim, sim.world.villagers[0].id)
	var short: int = PanelHost.height_for(&"villager")
	assert_eq(panel.current_height(), short)
	assert_eq(panel.size.y, float(short))
	assert_eq(panel._card.size.y, float(short))
	assert_eq(panel._clip.position.y, 0.0, "Its bottom edge is the window's panel edge")
	assert_eq(panel._clip.size.y, float(short), "Fully unrolled")
	panel.show_journal(sim)
	assert_eq(panel.current_height(), PanelHost.HEIGHT)
	assert_eq(panel.size.y, float(PanelHost.HEIGHT))
	assert_eq(panel._clip.size.y, float(PanelHost.HEIGHT))
	panel.close_panel()
	assert_eq(panel.current_height(), 0)
	panel.free()


func test_the_window_is_told_when_an_open_panel_changes_height() -> void:
	var sim: Simulation = _sim()
	var panel: PanelHost = PanelHost.new()
	var changes: Array[int] = []
	panel.height_changed.connect(func() -> void: changes.append(panel.current_height()))
	panel.show_villager(sim, sim.world.villagers[0].id)
	assert_eq(changes.size(), 0, "Opening is the caller's business, not a change")
	panel.show_villager(sim, sim.world.villagers[1].id)
	assert_eq(changes.size(), 0, "Next within the thoughts is the same height")
	panel.show_journal(sim)
	assert_eq(changes, [PanelHost.HEIGHT] as Array[int])
	panel.show_villager(sim, sim.world.villagers[0].id)
	assert_eq(changes.size(), 2)
	assert_eq(changes[1], PanelHost.height_for(&"villager"))
	panel.free()


func test_a_short_panel_keeps_the_top_and_the_bottom_rail_of_the_art() -> void:
	for era: StringName in PanelSkin.skins():
		var skin: PanelSkin = PanelSkin.for_era(era)
		var source: Image = skin.atlas().get_image()
		var height: int = PanelHost.height_for(&"villager")
		var texture: Texture2D = skin.panel_texture(height)
		assert_eq(texture.get_size(), Vector2(PanelHost.WIDTH, height), "%s" % era)
		var cut: Image = texture.get_image()
		for column: int in [10, 100, 200, 300, 370]:
			assert_eq(cut.get_pixel(column, 0), source.get_pixel(column, 0), "%s: the top rail" % era)
			assert_eq(cut.get_pixel(column, 20), source.get_pixel(column, 20), "%s: the title area" % era)
			assert_eq(
				cut.get_pixel(column, height - 1),
				source.get_pixel(column, PanelSkin.PANEL_HEIGHT - 1), "%s: the bottom rail" % era
			)
			assert_eq(
				cut.get_pixel(column, height - PanelSkin.PANEL_FOOT),
				source.get_pixel(column, PanelSkin.PANEL_HEIGHT - PanelSkin.PANEL_FOOT),
				"%s: where the rail starts" % era
			)


func test_a_full_height_panel_is_the_whole_piece_and_short_ones_are_cached() -> void:
	var skin: PanelSkin = PanelSkin.cave()
	var full: Texture2D = skin.panel_texture(PanelSkin.PANEL_HEIGHT)
	assert_eq(full.get_size(), Vector2(PanelHost.WIDTH, PanelSkin.PANEL_HEIGHT))
	assert_true(skin.panel_texture(112) == skin.panel_texture(112), "Built once per height")


func test_the_card_is_drawn_with_art_of_its_own_height() -> void:
	var sim: Simulation = _sim()
	var panel: PanelHost = PanelHost.new()
	panel.show_villager(sim, sim.world.villagers[0].id)
	var box: StyleBoxTexture = panel._card.get_theme_stylebox("panel") as StyleBoxTexture
	assert_eq(box.texture.get_height(), PanelHost.height_for(&"villager"))
	panel.show_decision(SimFixture.new_sim(), 0)
	panel.set_skin(PanelSkin.for_era(&"settled"))
	var after: StyleBoxTexture = panel._card.get_theme_stylebox("panel") as StyleBoxTexture
	assert_eq(after.texture.get_height(), panel._height, "A new skin keeps the current height")
	panel.free()
