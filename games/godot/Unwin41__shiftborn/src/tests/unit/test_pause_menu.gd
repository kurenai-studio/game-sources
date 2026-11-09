extends TestCase
## The menu is never added to the tree here: only visibility and the
## switch between the button list and the settings panel.


func test_can_open_only_during_a_live_unpaused_run() -> void:
	assert_true(PauseMenu.can_open(false, false), "live run should allow pause")
	assert_false(PauseMenu.can_open(true, false), "finished run should not pause")
	assert_false(PauseMenu.can_open(false, true), "level-up pause should block the menu")


func test_open_shows_buttons_not_settings() -> void:
	var menu := PauseMenu.new()
	menu.open()
	assert_true(menu.visible, "menu should show after open")
	assert_false(menu.is_settings_shown(), "settings should start hidden")
	menu.free()


func test_back_from_settings_returns_to_buttons() -> void:
	var menu := PauseMenu.new()
	menu.open()
	menu.show_settings()
	assert_true(menu.is_settings_shown(), "settings should show")
	menu.go_back()
	assert_false(menu.is_settings_shown(), "back should leave settings")
	assert_true(menu.visible, "back from settings keeps the menu open")
	menu.free()


func test_go_back_from_buttons_resumes() -> void:
	var menu := PauseMenu.new()
	var resumed := [false]
	menu.resumed.connect(func() -> void: resumed[0] = true)
	menu.open()
	menu.go_back()
	assert_false(menu.visible, "menu should hide on resume")
	assert_true(resumed[0], "resumed should emit")
	menu.free()
