extends TestCase


func _count_tagged(upgrades: Array[Upgrade], tag: String) -> int:
	var count := 0
	for upgrade in upgrades:
		if tag in upgrade.tags:
			count += 1
	return count


func test_six_upgrades_per_form_six_shared_and_four_evolutions() -> void:
	var upgrades := UpgradeCatalog.build()
	assert_eq(_count_tagged(upgrades, UpgradeCatalog.KNIGHT_TAG), 6, "knight")
	assert_eq(_count_tagged(upgrades, UpgradeCatalog.MAGE_TAG), 6, "mage")
	var shared := 0
	var evolutions := 0
	for upgrade in upgrades:
		if not upgrade.requires_maxed.is_empty():
			evolutions += 1
		elif upgrade.tags.is_empty():
			shared += 1
	assert_eq(shared, 6, "shared")
	assert_eq(evolutions, 4, "evolutions")


func test_evolutions_need_two_known_upgrades_and_have_one_level() -> void:
	var by_id := {}
	for upgrade in UpgradeCatalog.build():
		by_id[upgrade.id] = upgrade
	for upgrade: Upgrade in by_id.values():
		if upgrade.requires_maxed.is_empty():
			continue
		assert_eq(upgrade.requires_maxed.size(), 2, "%s recipe size" % upgrade.id)
		assert_eq(upgrade.max_level, 1, "%s max level" % upgrade.id)
		assert_true(upgrade.tags.is_empty(), "%s should be offered in both forms" % upgrade.id)
		for required in upgrade.requires_maxed:
			assert_true(by_id.has(required), "%s needs unknown %s" % [upgrade.id, required])
			assert_true((by_id[required] as Upgrade).requires_maxed.is_empty(), "%s chains evolutions" % upgrade.id)


func test_evolution_is_offered_once_its_recipe_is_maxed() -> void:
	var pool := UpgradePool.new(UpgradeCatalog.build())
	var orbit := pool.get_upgrade(&"evo_arcane_orbit")
	assert_false(pool.is_eligible(orbit), "orbit offered too early")
	for required in orbit.requires_maxed:
		while not pool.is_maxed(required):
			pool.apply(required)
	assert_true(pool.is_eligible(orbit, UpgradeCatalog.tags_for_form(Player.Form.MAGE)), "orbit not offered after recipe")


func test_ids_are_unique_and_entries_complete() -> void:
	var ids := {}
	for upgrade in UpgradeCatalog.build():
		assert_false(ids.has(upgrade.id), "duplicate id %s" % upgrade.id)
		ids[upgrade.id] = true
		assert_true(upgrade.title != "", "%s has no title" % upgrade.id)
		assert_true(upgrade.description != "", "%s has no description" % upgrade.id)
		assert_true(upgrade.icon != null, "%s has no icon" % upgrade.id)
		assert_true(upgrade.max_level >= 1, "%s max level" % upgrade.id)


func test_every_upgrade_has_an_effect() -> void:
	for upgrade in UpgradeCatalog.build():
		assert_true(upgrade.id in UpgradeEffects.KNOWN_IDS, "%s has no effect" % upgrade.id)


func test_knight_offers_never_include_mage_upgrades() -> void:
	var pool := UpgradePool.new(UpgradeCatalog.build())
	var rng := RandomNumberGenerator.new()
	var tags := UpgradeCatalog.tags_for_form(Player.Form.KNIGHT)
	for i in 100:
		for upgrade in pool.offer(3, rng, tags):
			assert_false(UpgradeCatalog.MAGE_TAG in upgrade.tags, "mage upgrade %s offered to knight" % upgrade.id)


func test_mage_offers_never_include_knight_upgrades() -> void:
	var pool := UpgradePool.new(UpgradeCatalog.build())
	var rng := RandomNumberGenerator.new()
	var tags := UpgradeCatalog.tags_for_form(Player.Form.MAGE)
	for i in 100:
		for upgrade in pool.offer(3, rng, tags):
			assert_false(UpgradeCatalog.KNIGHT_TAG in upgrade.tags, "knight upgrade %s offered to mage" % upgrade.id)
