extends GutTest

var SaveScript := preload("res://autoload/save_system.gd")
var save: Node


func before_each() -> void:
	save = autofree(SaveScript.new())
	save.data = SaveScript.default_data()


func test_cost_grows() -> void:
	assert_eq(MetaShop.cost(&"vitality", 0), 60)
	assert_gt(MetaShop.cost(&"vitality", 2), MetaShop.cost(&"vitality", 1))


func test_buy_requires_coins() -> void:
	assert_false(MetaShop.buy(save, &"vitality"))
	save.data["coins"] = 1000
	assert_true(MetaShop.buy(save, &"vitality"))
	assert_eq(save.get_meta_level(&"vitality"), 1)
	assert_eq(save.get_coins(), 940)


func test_buy_stops_at_max() -> void:
	save.data["coins"] = 100000
	for i in 10:
		MetaShop.buy(save, &"magnet")
	assert_eq(save.get_meta_level(&"magnet"), MetaShop.UPGRADES[&"magnet"]["max"])
	assert_true(MetaShop.is_maxed(&"magnet", save.get_meta_level(&"magnet")))


func test_unknown_id_rejected() -> void:
	save.data["coins"] = 1000
	assert_false(MetaShop.buy(save, &"nope"))


func test_apply_to_stats() -> void:
	var s := PlayerStats.new()
	MetaShop.apply_to_stats(s, {"vitality": 2, "power": 1, "greed": 2})
	assert_eq(s.get_stat(&"max_hp"), 120.0)
	assert_almost_eq(s.get_stat(&"damage"), 12.0 * 1.06, 0.001)
	assert_almost_eq(s.get_stat(&"coin_gain"), 1.3, 0.001)


func test_achievements_evaluate() -> void:
	var got := Achievements.evaluate({"total_kills": 1, "wave": 5}, [])
	assert_true(got.has(&"first_blood"))
	assert_true(got.has(&"survivor"))
	assert_false(got.has(&"veteran"))


func test_achievements_skip_unlocked() -> void:
	var got := Achievements.evaluate({"total_kills": 1000}, ["first_blood"])
	assert_false(got.has(&"first_blood"))
	assert_true(got.has(&"slayer"))


func test_achievement_progress() -> void:
	assert_almost_eq(Achievements.progress(&"slayer", {"total_kills": 250}), 0.5, 0.001)
	assert_eq(Achievements.progress(&"slayer", {"total_kills": 99999}), 1.0)


func test_every_achievement_has_strings() -> void:
	TranslationServer.set_locale("en")
	for def in Achievements.DEFS:
		var k := Achievements.name_key(def["id"])
		assert_ne(tr(k), k, "missing translation for %s" % k)
		assert_ne(tr(Achievements.desc_key(def["id"])), Achievements.desc_key(def["id"]))
	Settings.apply()


func test_meta_shop_strings_exist() -> void:
	TranslationServer.set_locale("en")
	for id in MetaShop.ids():
		var key: String = MetaShop.UPGRADES[id]["name"]
		assert_ne(tr(key), key)
	Settings.apply()
