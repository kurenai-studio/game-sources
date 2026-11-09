extends TestCase
## The menu is never added to the tree here: open() and choose() must work
## without focus handling or frame waits.


func _upgrades(count: int) -> Array[Upgrade]:
	var upgrades: Array[Upgrade] = []
	for i in count:
		var upgrade := Upgrade.new()
		upgrade.id = StringName("test_%d" % i)
		upgrade.title = "Test %d" % i
		upgrade.description = "Does thing %d" % i
		upgrades.append(upgrade)
	return upgrades


func test_open_builds_one_card_per_upgrade() -> void:
	var menu := LevelUpMenu.new()
	var levels: Array[int] = [0, 1, 2]
	menu.open(_upgrades(3), levels)
	assert_eq(menu.card_count(), 3)
	assert_true(menu.visible, "menu should be visible after open")
	menu.free()


func test_reopen_replaces_old_cards() -> void:
	var menu := LevelUpMenu.new()
	var three: Array[int] = [0, 0, 0]
	var two: Array[int] = [0, 0]
	menu.open(_upgrades(3), three)
	menu.choose(0)
	menu.open(_upgrades(2), two)
	assert_eq(menu.card_count(), 2)
	menu.free()


func test_choose_emits_the_picked_upgrade_and_hides() -> void:
	var menu := LevelUpMenu.new()
	var upgrades := _upgrades(3)
	var levels: Array[int] = [0, 0, 0]
	var picked: Array[Upgrade] = []
	menu.chosen.connect(func(upgrade: Upgrade) -> void: picked.append(upgrade))
	menu.open(upgrades, levels)
	menu.choose(1)
	assert_eq(picked.size(), 1)
	assert_eq(picked[0].id, upgrades[1].id)
	assert_false(menu.visible, "menu should hide after a choice")
	menu.free()


func test_choose_ignores_bad_index_and_hidden_menu() -> void:
	var menu := LevelUpMenu.new()
	var picked: Array[Upgrade] = []
	menu.chosen.connect(func(upgrade: Upgrade) -> void: picked.append(upgrade))
	menu.choose(0)
	var levels: Array[int] = [0, 0]
	menu.open(_upgrades(2), levels)
	menu.choose(5)
	menu.choose(-1)
	assert_eq(picked.size(), 0)
	menu.choose(0)
	menu.choose(0)
	assert_eq(picked.size(), 1, "second choose after hiding must be ignored")
	menu.free()


func test_level_text_marks_new_and_next_level() -> void:
	assert_eq(LevelUpMenu.level_text(0), "NEW")
	assert_eq(LevelUpMenu.level_text(2), "Lv 2 > 3")
