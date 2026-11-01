extends GutTest


func _make_setup(enemy: EnemyData) -> BattleSetup:
	var enemies: Array[EnemyData] = [enemy]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	var mage := MageData.new("Mage", 30)
	var mages: Array[MageData] = [mage]
	return BattleSetup.new(enemies, positions, mages, [], 10)


func _make_state_with_damage(enemy_id: String, max_hp: int, current_hp: int, armor: int) -> BattleState:
	var s := BattleState.new()
	var es := EnemyState.new()
	es.combatant.hp = current_hp
	es.armor = armor
	s.enemies[enemy_id] = es
	var ms := MageState.new()
	ms.combatant.hp = 30
	s.mages.append(ms)
	s.mana = 10
	return s


func test_armor_reset_does_not_restore_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 100, Vector2i(1, 1), Color.RED)
	enemy.traits = [MonsterTraitArmor.new(20)]
	var setup := _make_setup(enemy)
	var state := _make_state_with_damage("e1", 100, 60, 20)

	var armor_trait := MonsterTraitArmor.new(20)
	var result := armor_trait.apply_end_of_round(state, setup, "e1")

	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 60, "HP should remain at 60")
	assert_eq((result.enemies["e1"] as EnemyState).armor, 20, "Armor should be reset to 20")


func test_end_turn_armor_reset_does_not_restore_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 100, Vector2i(1, 1), Color.RED)
	enemy.traits = [MonsterTraitArmor.new(20)]
	var setup := _make_setup(enemy)

	var initial_state := setup.make_initial_state()
	var history := BattleHistory.new(initial_state, setup)

	# Manually deal 40 damage to the enemy (bypassing armor for simplicity)
	var state_after_damage := history.current_state()
	(state_after_damage.enemies["e1"] as EnemyState).combatant.hp = 60
	(state_after_damage.enemies["e1"] as EnemyState).armor = 0
	history = BattleHistory.new(state_after_damage, setup)

	# End the turn
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var result := history.push(ActionEndTurn.new(rng.seed)).state

	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 60, "HP should remain at 60 after end turn")
	assert_eq((result.enemies["e1"] as EnemyState).armor, 20, "Armor should be reset to 20")
