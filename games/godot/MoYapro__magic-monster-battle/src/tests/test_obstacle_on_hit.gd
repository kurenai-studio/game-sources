extends GutTest


func _make_setup(
		body_spell: SpellData,
		enemies: Array[EnemyData],
		enemy_positions: Array[Vector2i],
		obstacles: Array[ObstacleData],
		obstacle_positions: Array[Vector2i]
) -> BattleSetup:
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = body_spell
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	return BattleSetup.new(enemies, enemy_positions, [mage], [wand], 10, obstacles, obstacle_positions)


func _make_state(setup: BattleSetup) -> BattleState:
	var s := BattleState.new()
	for e: EnemyData in setup.enemies:
		var es := EnemyState.new()
		es.combatant.hp = e.max_hp
		s.enemies[e.id] = es
	for o: ObstacleData in setup.obstacles:
		var os := ObstacleState.new()
		os.combatant.hp = o.max_hp
		s.obstacles[o.id] = os
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 99
	ms.slot_charges["tip"] = 1
	s.mages.append(ms)
	s.mana = 10
	return s


func _strike() -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


func test_hitting_bone_pile_blinds_adjacent_enemy() -> void:
	var bone_pile := BonePile.new()
	var enemy := EnemyData.new("goblin_1", "Goblin", 20, Vector2i(1, 1), Color.GREEN)
	var setup := _make_setup(
		_strike(),
		[enemy], [Vector2i(1, 3)],
		[bone_pile], [Vector2i(2, 3)]
	)
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(_make_state(setup), setup).state
	var blind: Array = (result.enemies["goblin_1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusBlind)
	assert_gt(blind.size(), 0)


func test_hitting_bone_pile_does_not_blind_distant_enemy() -> void:
	var bone_pile := BonePile.new()
	var enemy := EnemyData.new("goblin_1", "Goblin", 20, Vector2i(1, 1), Color.GREEN)
	var setup := _make_setup(
		_strike(),
		[enemy], [Vector2i(0, 0)],
		[bone_pile], [Vector2i(2, 3)]
	)
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(_make_state(setup), setup).state
	var blind: Array = (result.enemies["goblin_1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusBlind)
	assert_eq(blind.size(), 0)


func test_bone_pile_cloud_fires_even_when_destroyed_by_the_hit() -> void:
	var bone_pile := BonePile.new()
	var enemy := EnemyData.new("goblin_1", "Goblin", 20, Vector2i(1, 1), Color.GREEN)
	var setup := _make_setup(
		_strike(),
		[enemy], [Vector2i(1, 3)],
		[bone_pile], [Vector2i(2, 3)]
	)
	var state := _make_state(setup)
	(state.obstacles["bone_pile"] as ObstacleState).combatant.hp = 1
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(state, setup).state
	assert_false(result.obstacles.has("bone_pile"), "bone pile destroyed")
	var blind: Array = (result.enemies["goblin_1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusBlind)
	assert_gt(blind.size(), 0, "cloud still fires on lethal hit")


func test_hitting_bone_pile_reduces_its_hp() -> void:
	var bone_pile := BonePile.new()
	var setup := _make_setup(_strike(), [], [], [bone_pile], [Vector2i(2, 3)])
	var result := ActionZapWand.new(0, Vector2i(2, 3)).apply(_make_state(setup), setup).state
	assert_eq((result.obstacles.get("bone_pile") as ObstacleState).combatant.hp, bone_pile.max_hp - 5)
