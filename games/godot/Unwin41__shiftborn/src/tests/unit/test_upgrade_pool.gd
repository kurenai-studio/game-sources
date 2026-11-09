extends TestCase


func _make(id: StringName, max_level: int = 3, weight: float = 1.0, tags: PackedStringArray = [], requires: Array[StringName] = []) -> Upgrade:
	var upgrade := Upgrade.new()
	upgrade.id = id
	upgrade.title = String(id)
	upgrade.max_level = max_level
	upgrade.weight = weight
	upgrade.tags = tags
	upgrade.requires = requires
	return upgrade


func _rng(seed_value: int = 1) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_offer_returns_requested_count_when_enough_candidates() -> void:
	var pool := UpgradePool.new([_make(&"a"), _make(&"b"), _make(&"c"), _make(&"d")])
	assert_eq(pool.offer(3, _rng()).size(), 3)


func test_offer_never_returns_duplicates() -> void:
	var pool := UpgradePool.new([_make(&"a"), _make(&"b"), _make(&"c")])
	for seed_value in 50:
		var ids := {}
		for upgrade in pool.offer(3, _rng(seed_value)):
			ids[upgrade.id] = true
		assert_eq(ids.size(), 3, "seed %d" % seed_value)


func test_offer_returns_fewer_when_not_enough_candidates() -> void:
	var pool := UpgradePool.new([_make(&"a"), _make(&"b")])
	assert_eq(pool.offer(3, _rng()).size(), 2)


func test_offer_excludes_maxed_upgrades() -> void:
	var pool := UpgradePool.new([_make(&"a", 1), _make(&"b")])
	pool.apply(&"a")
	var offered := pool.offer(3, _rng())
	assert_eq(offered.size(), 1)
	assert_eq(offered[0].id, &"b")


func test_offer_excludes_zero_weight_upgrades() -> void:
	var pool := UpgradePool.new([_make(&"a", 3, 0.0), _make(&"b")])
	for seed_value in 20:
		for upgrade in pool.offer(2, _rng(seed_value)):
			assert_true(upgrade.id != &"a", "zero weight upgrade was offered")


func test_offer_requires_prerequisites() -> void:
	var pool := UpgradePool.new([_make(&"base"), _make(&"advanced", 3, 1.0, [], [&"base"])])
	assert_eq(pool.offer(5, _rng()).size(), 1, "advanced offered before base")
	pool.apply(&"base")
	assert_eq(pool.offer(5, _rng()).size(), 2, "advanced not offered after base")


func test_offer_filters_by_tag_and_keeps_shared_upgrades() -> void:
	var pool := UpgradePool.new([
		_make(&"sword", 3, 1.0, ["knight"]),
		_make(&"fireball", 3, 1.0, ["mage"]),
		_make(&"boots"),
	])
	var ids := {}
	for upgrade in pool.offer(5, _rng(), ["knight"]):
		ids[upgrade.id] = true
	assert_true(ids.has(&"sword"), "tagged upgrade missing")
	assert_true(ids.has(&"boots"), "shared upgrade missing")
	assert_false(ids.has(&"fireball"), "other form upgrade offered")


func test_offer_favours_higher_weight() -> void:
	var pool := UpgradePool.new([_make(&"common", 3, 9.0), _make(&"rare", 3, 1.0)])
	var rng := _rng(42)
	var common_count := 0
	for i in 1000:
		if pool.offer(1, rng)[0].id == &"common":
			common_count += 1
	assert_true(common_count > 800 and common_count < 980, "common picked %d/1000" % common_count)


func test_apply_increments_level_and_emits_signal() -> void:
	var pool := UpgradePool.new([_make(&"a")])
	var emitted: Array = []
	pool.upgrade_applied.connect(func(upgrade: Upgrade, level: int) -> void: emitted.append([upgrade.id, level]))
	assert_eq(pool.apply(&"a"), 1)
	assert_eq(pool.apply(&"a"), 2)
	assert_eq(pool.level_of(&"a"), 2)
	assert_eq(emitted, [[&"a", 1], [&"a", 2]])


func test_apply_rejects_unknown_and_maxed_upgrades() -> void:
	var pool := UpgradePool.new([_make(&"a", 1)])
	assert_eq(pool.apply(&"missing"), -1)
	assert_eq(pool.apply(&"a"), 1)
	assert_eq(pool.apply(&"a"), -1)
	assert_eq(pool.level_of(&"a"), 1)


func test_reset_clears_levels() -> void:
	var pool := UpgradePool.new([_make(&"a")])
	pool.apply(&"a")
	pool.reset()
	assert_eq(pool.level_of(&"a"), 0)


func test_owned_lists_only_upgrades_with_levels_in_add_order() -> void:
	var pool := UpgradePool.new([_make(&"a"), _make(&"b"), _make(&"c")])
	pool.apply(&"c")
	pool.apply(&"a")
	pool.apply(&"a")
	var owned := pool.owned()
	assert_eq(owned.size(), 2)
	assert_eq(owned[0].id, &"a")
	assert_eq(owned[1].id, &"c")


func test_requires_maxed_blocks_until_every_id_is_at_max() -> void:
	var evolution := _make(&"evo", 1)
	evolution.requires_maxed = [&"a", &"b"]
	var pool := UpgradePool.new([_make(&"a", 2), _make(&"b", 1), evolution])
	assert_false(pool.is_eligible(evolution), "nothing maxed yet")
	pool.apply(&"a")
	pool.apply(&"b")
	assert_false(pool.is_eligible(evolution), "a is not maxed yet")
	pool.apply(&"a")
	assert_true(pool.is_eligible(evolution), "both maxed")
