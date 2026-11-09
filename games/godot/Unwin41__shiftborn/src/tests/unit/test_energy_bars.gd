extends TestCase


func test_show_levels_clamps_and_tracks_the_active_form() -> void:
	var bars := EnergyBars.new()
	bars.show_levels(1.5, -0.2, Player.Form.MAGE)
	assert_almost_eq(bars.level_of(Player.Form.KNIGHT), 1.0)
	assert_almost_eq(bars.level_of(Player.Form.MAGE), 0.0)
	assert_eq(bars.active_form(), Player.Form.MAGE)
	bars.free()


func test_panel_fits_the_screen_width() -> void:
	assert_true(EnergyBars.panel_size().x < 640.0, "panel wider than the 640 px viewport")
