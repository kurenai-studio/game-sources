extends TestCase
## The player is instantiated but never added to the tree: effects only
## change stats, so no nodes need to be ready.

const PLAYER_SCENE := preload("res://scenes/player.tscn")


func _player() -> Player:
	var player := PLAYER_SCENE.instantiate() as Player
	player.health = player.max_health
	return player


func test_unknown_id_is_rejected() -> void:
	var player := _player()
	assert_false(UpgradeEffects.apply(player, &"missing"))
	player.free()


func test_damage_upgrades_scale_by_a_percentage() -> void:
	var player := _player()
	var knight_before := player.knight_damage
	var mage_before := player.mage_damage
	assert_true(UpgradeEffects.apply(player, &"knight_damage"))
	assert_true(UpgradeEffects.apply(player, &"mage_damage"))
	assert_almost_eq(player.knight_damage, knight_before * UpgradeEffects.DAMAGE_FACTOR)
	assert_almost_eq(player.mage_damage, mage_before * UpgradeEffects.DAMAGE_FACTOR)
	player.free()


func test_precision_raises_crit_chance() -> void:
	var player := _player()
	var before := player.crit_chance
	assert_true(UpgradeEffects.apply(player, &"precision"))
	assert_almost_eq(player.crit_chance, before + UpgradeEffects.PRECISION_STEP)
	player.free()


func test_haste_upgrades_shorten_attack_intervals() -> void:
	var player := _player()
	var knight_before := player.knight_interval
	var mage_before := player.mage_interval
	UpgradeEffects.apply(player, &"knight_haste")
	UpgradeEffects.apply(player, &"mage_haste")
	assert_true(player.knight_interval < knight_before, "knight interval")
	assert_true(player.mage_interval < mage_before, "mage interval")
	player.free()


func test_behaviour_upgrades_raise_counts() -> void:
	var player := _player()
	UpgradeEffects.apply(player, &"knight_twin_blade")
	UpgradeEffects.apply(player, &"mage_multishot")
	UpgradeEffects.apply(player, &"mage_chain")
	UpgradeEffects.apply(player, &"mage_pierce")
	assert_eq(player.blade_count, 2, "blades")
	assert_eq(player.bolt_count, 2, "bolts")
	assert_eq(player.bolt_chain, 1, "chain")
	assert_eq(player.bolt_pierce, 1, "pierce")
	player.free()


func test_vitality_raises_max_health_and_heals_the_same_amount() -> void:
	var player := _player()
	player.health = 4.0
	var max_before := player.max_health
	UpgradeEffects.apply(player, &"vitality")
	var gained := max_before * (UpgradeEffects.VITALITY_FACTOR - 1.0)
	assert_almost_eq(player.max_health, max_before + gained)
	assert_almost_eq(player.health, 4.0 + gained)
	player.free()


func test_shift_burst_enables_burst_damage() -> void:
	var player := _player()
	assert_almost_eq(player.shift_burst_damage, 0.0)
	UpgradeEffects.apply(player, &"shift_burst")
	assert_almost_eq(player.shift_burst_damage, UpgradeEffects.SHIFT_BURST_DAMAGE_STEP)
	player.free()


func test_every_known_id_applies() -> void:
	for id in UpgradeEffects.KNOWN_IDS:
		var player := _player()
		assert_true(UpgradeEffects.apply(player, id), "%s not applied" % id)
		player.free()


func test_sword_hit_on_dead_enemy_gives_no_lifesteal() -> void:
	var player := _player()
	var enemy := preload("res://scenes/enemy.tscn").instantiate() as Enemy
	enemy.health = 0.0
	player.lifesteal = 1.0
	player.health = player.max_health - 2.0
	player._sword_hit(enemy, Vector2.RIGHT)
	assert_almost_eq(player.health, player.max_health - 2.0)
	enemy.free()
	player.free()
