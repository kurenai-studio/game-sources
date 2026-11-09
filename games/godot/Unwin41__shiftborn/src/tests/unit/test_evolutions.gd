extends TestCase
## Momentum and the four hybrid evolutions. The player is instantiated but
## never added to the tree, like in test_upgrade_effects.

const PLAYER_SCENE := preload("res://scenes/player.tscn")


func _player() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.health = player.max_health
	return player


func test_momentum_stacks_per_level() -> void:
	var player := _player()
	assert_true(UpgradeEffects.apply(player, &"momentum"))
	assert_almost_eq(player.momentum_bonus, UpgradeEffects.MOMENTUM_STEP)
	UpgradeEffects.apply(player, &"momentum")
	assert_almost_eq(player.momentum_bonus, UpgradeEffects.MOMENTUM_STEP * 2.0)
	player.free()


func test_momentum_factor_only_while_the_window_is_open() -> void:
	assert_almost_eq(Player.momentum_factor(0.4, 1.0), 1.4)
	assert_almost_eq(Player.momentum_factor(0.4, 0.0), 1.0)


func test_blood_pact_bonus_only_at_full_health() -> void:
	assert_almost_eq(Player.blood_pact_factor(true, 10.0, 10.0), Player.BLOOD_PACT_FULL_HEALTH_BONUS)
	assert_almost_eq(Player.blood_pact_factor(true, 9.0, 10.0), 1.0)
	assert_almost_eq(Player.blood_pact_factor(false, 10.0, 10.0), 1.0)


func test_each_evolution_is_recorded_on_the_player() -> void:
	for id: StringName in [&"evo_arcane_orbit", &"evo_storm_cleaver", &"evo_blood_pact", &"evo_twin_soul"]:
		var player := _player()
		assert_false(player.has_evolution(id), "%s before apply" % id)
		assert_true(UpgradeEffects.apply(player, id), "%s apply" % id)
		assert_true(player.has_evolution(id), "%s after apply" % id)
		player.free()


func test_arcane_orbit_adds_the_orbit_node() -> void:
	var player := _player()
	UpgradeEffects.apply(player, &"evo_arcane_orbit")
	assert_eq(player.find_children("*", "ArcaneOrbit", false, false).size(), 1)
	player.free()


func test_orbit_offsets_are_evenly_spaced_on_the_ring() -> void:
	var offsets := ArcaneOrbit.orb_offsets(0.0, 3, 30.0)
	assert_eq(offsets.size(), 3)
	for offset in offsets:
		assert_almost_eq(offset.length(), 30.0)
	assert_almost_eq(offsets[0].angle_to(offsets[1]), TAU / 3.0)


func test_storm_targets_are_the_nearest_within_range() -> void:
	var positions: Array[Vector2] = [Vector2(50, 0), Vector2(10, 0), Vector2(500, 0), Vector2(20, 0)]
	var picked := StormCleaver.pick_targets(Vector2.ZERO, positions, 2, 60.0)
	assert_eq(picked, [1, 3] as Array[int])


func test_storm_targets_ignore_everything_out_of_range() -> void:
	var positions: Array[Vector2] = [Vector2(500, 0)]
	assert_eq(StormCleaver.pick_targets(Vector2.ZERO, positions, 2, 60.0).size(), 0)


func test_evolution_cards_say_evolution() -> void:
	var evolution := Upgrade.new()
	evolution.requires_maxed = [&"a", &"b"]
	assert_eq(LevelUpMenu.badge_text(evolution, 0), "EVOLUTION")
	assert_eq(LevelUpMenu.badge_text(Upgrade.new(), 0), "NEW")
