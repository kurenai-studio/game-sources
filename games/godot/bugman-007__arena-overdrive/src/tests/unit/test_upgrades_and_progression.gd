extends GutTest

var system: UpgradeSystem
var rng: RandomNumberGenerator


func before_each() -> void:
	system = UpgradeSystem.new(DataRegistry.upgrades())
	rng = RandomNumberGenerator.new()
	rng.seed = 99


func test_pool_loaded_from_tres() -> void:
	assert_gte(system.pool.size(), 12)


func test_roll_three_distinct() -> void:
	for i in 50:
		var picks := system.roll_choices(rng, 3)
		assert_eq(picks.size(), 3)
		assert_ne(picks[0].id, picks[1].id)
		assert_ne(picks[1].id, picks[2].id)
		assert_ne(picks[0].id, picks[2].id)


func test_roll_is_deterministic_for_seed() -> void:
	var a := RandomNumberGenerator.new()
	a.seed = 5
	var b := RandomNumberGenerator.new()
	b.seed = 5
	var ids_a := system.roll_choices(a, 3).map(func(u: UpgradeData) -> StringName: return u.id)
	var ids_b := system.roll_choices(b, 3).map(func(u: UpgradeData) -> StringName: return u.id)
	assert_eq(ids_a, ids_b)


func test_maxed_upgrades_are_excluded() -> void:
	var u: UpgradeData = system.pool[0]
	for i in u.max_stacks:
		system.take(u)
	assert_false(system.available().has(u))
	for i in 30:
		assert_false(system.roll_choices(rng, 3).has(u))


func test_returns_fewer_when_pool_small() -> void:
	var small: Array[UpgradeData] = [system.pool[0], system.pool[1]]
	var s := UpgradeSystem.new(small)
	assert_eq(s.roll_choices(rng, 3).size(), 2)


func test_rarity_weighting() -> void:
	var counts := {0: 0, 1: 0, 2: 0}
	for i in 600:
		for u in system.roll_choices(rng, 1):
			counts[u.rarity] += 1
	assert_gt(counts[UpgradeData.Rarity.COMMON], counts[UpgradeData.Rarity.EPIC])


func test_take_counts_stacks() -> void:
	var u: UpgradeData = system.pool[0]
	assert_eq(system.take(u), 1)
	assert_eq(system.take(u), 2)
	assert_eq(system.stack_count(u.id), 2)


func test_xp_curve_increases() -> void:
	assert_eq(Progression.xp_to_next(1), 8)
	assert_lt(Progression.xp_to_next(2), Progression.xp_to_next(5))


func test_level_up_carries_overflow() -> void:
	var p := Progression.new()
	watch_signals(p)
	assert_eq(p.add_xp(10), 1)
	assert_eq(p.level, 2)
	assert_eq(p.xp, 2)
	assert_signal_emitted_with_parameters(p, "leveled_up", [2])


func test_multi_level_gain() -> void:
	var p := Progression.new()
	assert_eq(p.add_xp(Progression.xp_to_next(1) + Progression.xp_to_next(2) + Progression.xp_to_next(3)), 3)
	assert_eq(p.level, 4)


func test_ignores_non_positive_xp() -> void:
	var p := Progression.new()
	assert_eq(p.add_xp(0), 0)
	assert_eq(p.add_xp(-5), 0)
	assert_eq(p.xp, 0)


func test_progress_ratio() -> void:
	var p := Progression.new()
	p.add_xp(4)
	assert_almost_eq(p.progress_ratio(), 0.5, 0.001)
