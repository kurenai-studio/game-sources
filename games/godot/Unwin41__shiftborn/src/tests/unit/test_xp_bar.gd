extends TestCase
## XpBar is never added to the tree; tick() is driven by hand.


func test_fill_eases_toward_target() -> void:
	var bar := XpBar.new()
	bar.set_progress(1, 0.5)
	bar.tick(0.05)
	assert_true(bar.shown_fill() > 0.0 and bar.shown_fill() < 0.5, "fill should move partway")
	for i in 100:
		bar.tick(0.05)
	assert_almost_eq(bar.shown_fill(), 0.5, 0.01)
	bar.free()


func test_level_up_restarts_fill_and_flashes() -> void:
	var bar := XpBar.new()
	bar.set_progress(1, 0.9)
	for i in 100:
		bar.tick(0.05)
	bar.set_progress(2, 0.1)
	assert_almost_eq(bar.shown_fill(), 0.0)
	assert_true(bar.is_flashing(), "level-up should flash")
	assert_eq(bar.label_text(), "Lv 2")
	for i in 100:
		bar.tick(0.05)
	assert_false(bar.is_flashing(), "flash should end")
	bar.free()


func test_progress_is_clamped() -> void:
	var bar := XpBar.new()
	bar.set_progress(1, 3.0)
	for i in 200:
		bar.tick(0.05)
	assert_almost_eq(bar.shown_fill(), 1.0, 0.01)
	bar.free()
