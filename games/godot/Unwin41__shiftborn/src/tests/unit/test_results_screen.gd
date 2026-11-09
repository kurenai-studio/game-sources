extends TestCase
## The screen is never added to the tree here, so no focus or timers.


func _upgrades(count: int) -> Array[Upgrade]:
	var upgrades: Array[Upgrade] = []
	for i in count:
		var upgrade := Upgrade.new()
		upgrade.id = StringName("test_%d" % i)
		upgrade.title = "Test %d" % i
		upgrades.append(upgrade)
	return upgrades


func test_title_text_for_win_and_loss() -> void:
	assert_eq(ResultsScreen.title_text(true), "YOU WIN")
	assert_eq(ResultsScreen.title_text(false), "YOU DIED")


func test_stats_text_shows_time_kills_and_level() -> void:
	assert_eq(ResultsScreen.stats_text(125.4, 321, 17), "TIME 02:05   KILLS 321   LEVEL 17")


func test_open_shows_title_and_one_slot_per_upgrade() -> void:
	var screen := ResultsScreen.new()
	var levels: Array[int] = [1, 3]
	screen.open(false, 60.0, 10, 4, _upgrades(2), levels)
	assert_true(screen.visible, "screen should show after open")
	assert_eq(screen.title(), "YOU DIED")
	assert_eq(screen.upgrade_slot_count(), 2)
	screen.free()


func test_reopen_replaces_old_upgrade_slots() -> void:
	var screen := ResultsScreen.new()
	var three: Array[int] = [1, 1, 1]
	var one: Array[int] = [2]
	screen.open(true, 1.0, 1, 1, _upgrades(3), three)
	screen.open(true, 1.0, 1, 1, _upgrades(1), one)
	assert_eq(screen.upgrade_slot_count(), 1)
	assert_eq(screen.title(), "YOU WIN")
	screen.free()


func test_hidden_until_opened() -> void:
	var screen := ResultsScreen.new()
	assert_false(screen.visible, "screen should start hidden")
	screen.free()
