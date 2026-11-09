extends TestCase
## The UI shows capitals only. They must not depend on the OS locale:
## on a Turkish system, locale-aware upper-casing turns "i" into "İ".


func test_upper_casing_is_locale_independent() -> void:
	assert_eq("Warrior kills".to_upper(), "WARRIOR KILLS")


func test_level_up_card_labels_are_pre_capitalized() -> void:
	var menu := LevelUpMenu.new()
	var label := menu._make_label("Swiftness", 8, Color.WHITE)
	assert_eq(label.text, "SWIFTNESS")
	assert_false(label.uppercase, "Label.uppercase follows the OS locale")
	label.free()
	menu.free()
