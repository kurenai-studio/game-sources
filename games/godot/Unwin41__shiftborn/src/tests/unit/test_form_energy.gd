extends TestCase


func test_starts_full_at_full_damage() -> void:
	var energy := FormEnergy.new()
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 1.0)
	assert_almost_eq(energy.damage_multiplier(Player.Form.MAGE), 1.0)


func test_active_form_drains_and_idle_form_recovers() -> void:
	var energy := FormEnergy.new()
	energy.tick(Player.Form.KNIGHT, FormEnergy.DRAIN_TIME * 0.5)
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 0.5)
	assert_almost_eq(energy.level(Player.Form.MAGE), 1.0)
	energy.tick(Player.Form.MAGE, FormEnergy.RECOVER_TIME * 0.25)
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 0.75)


func test_levels_stay_between_zero_and_one() -> void:
	var energy := FormEnergy.new()
	energy.tick(Player.Form.MAGE, 1000.0)
	assert_almost_eq(energy.level(Player.Form.MAGE), 0.0)
	assert_almost_eq(energy.level(Player.Form.KNIGHT), 1.0)


func test_empty_form_deals_minimum_damage() -> void:
	var energy := FormEnergy.new()
	energy.tick(Player.Form.KNIGHT, 1000.0)
	assert_almost_eq(energy.damage_multiplier(Player.Form.KNIGHT), FormEnergy.MIN_DAMAGE)
