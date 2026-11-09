extends TestCase


func test_wrong_form_deals_no_damage() -> void:
	assert_almost_eq(Enemy.damage_after_resist(4.0, Player.Form.MAGE, Player.Form.MAGE), 0.0)


func test_immune_enemy_keeps_its_health_but_still_reports_the_hit() -> void:
	var skull := preload("res://scenes/enemy_skull.tscn").instantiate() as Enemy
	skull.health = skull.max_health
	var reports := []
	skull.damaged.connect(func(_enemy: Enemy, amount: float, resisted: bool, _crit: bool) -> void: reports.append([amount, resisted]))
	skull.take_damage(3.0, Player.Form.MAGE)
	assert_almost_eq(skull.health, skull.max_health)
	assert_eq(reports, [[0.0, true]])
	skull.free()


func test_immune_hits_show_an_immune_popup() -> void:
	var numbers := DamageNumbers.new()
	numbers.spawn(Vector2.ZERO, 0.0, true)
	assert_eq(numbers.count(), 1, "an immune hit should still show something")
	numbers.free()


func test_right_form_deals_full_damage() -> void:
	assert_almost_eq(Enemy.damage_after_resist(4.0, Player.Form.MAGE, Player.Form.KNIGHT), 4.0)


func test_neutral_source_and_neutral_enemy_ignore_resistance() -> void:
	assert_almost_eq(Enemy.damage_after_resist(4.0, Player.Form.MAGE, Enemy.NO_FORM), 4.0)
	assert_almost_eq(Enemy.damage_after_resist(4.0, Enemy.NO_FORM, Player.Form.MAGE), 4.0)


func test_resistant_scenes_resist_the_expected_form() -> void:
	var skull := preload("res://scenes/enemy_skull.tscn").instantiate() as Enemy
	var spirit := preload("res://scenes/enemy_spirit.tscn").instantiate() as Enemy
	var spider := preload("res://scenes/enemy.tscn").instantiate() as Enemy
	assert_eq(skull.resisted_form, Player.Form.MAGE, "skull should shrug off bolts")
	assert_eq(spirit.resisted_form, Player.Form.KNIGHT, "spirit should shrug off the axe")
	assert_eq(spider.resisted_form, Enemy.NO_FORM, "spider should be neutral")
	skull.free()
	spirit.free()
	spider.free()
