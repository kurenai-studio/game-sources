extends GutTest


func _make_setup(body_spell: SpellData, enemy: EnemyData) -> BattleSetup:
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = body_spell
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	var mages: Array[MageData] = [mage]
	var wands: Array[WandData] = [wand]
	var enemies: Array[EnemyData] = [enemy]
	var positions: Array[Vector2i] = [Vector2i(0, 0)]
	return BattleSetup.new(enemies, positions, mages, wands, 10)


func _make_state(setup: BattleSetup) -> BattleState:
	var s := BattleState.new()
	for e: EnemyData in setup.enemies:
		var es := EnemyState.new()
		es.combatant.hp = e.max_hp
		s.enemies[e.id] = es
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 99  # body slot always charged
	ms.slot_charges["tip"] = 1    # tip charged
	s.mages.append(ms)
	s.mana = 10
	return s


func _strike_spell() -> SpellData:
	var s := SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 1)
	s.spell_id = "strike"
	s.spell_type = "projectile"
	return s


# --- damage ---

func test_zap_reduces_enemy_hp_by_spell_damage() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 15)


func test_zap_kills_enemy_when_damage_meets_or_exceeds_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	assert_false(result.enemies.has("e1"))


func test_zap_does_nothing_when_mage_is_frozen() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).combatant.statuses.append(StatusFrozen.new())
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 20)


# --- armor ---

func test_armor_absorbs_damage_before_hp() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).armor = 3
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	# 5 damage, 3 absorbed → 2 reaches hp
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 18)


func test_armor_is_removed_when_fully_depleted() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).armor = 3
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).armor, 0)


# --- block ---

func test_block_prevents_all_damage() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).block = 2
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).combatant.hp, 20)


func test_block_consumes_one_charge_per_hit() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var state := _make_state(setup)
	(state.enemies["e1"] as EnemyState).block = 2
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_eq((result.enemies["e1"] as EnemyState).block, 1)


# --- on-hit effects ---

func test_fire_on_hit_applies_fire_stacks_to_surviving_enemy() -> void:
	var spell := SpellEmber.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	var fires: Array = (result.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusFire)
	assert_gt(fires.size(), 0)


func test_frost_applies_frozen_to_enemy() -> void:
	var spell := SpellFrost.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	var frozen: Array = (result.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusFrozen)
	assert_gt(frozen.size(), 0)


func test_poison_on_hit_applies_poison_stacks_to_enemy() -> void:
	var spell := SpellVenom.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	var poisons: Array = (result.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusPoison)
	assert_gt(poisons.size(), 0)


func test_poison_stacks_accumulate_across_two_zaps() -> void:
	var spell := SpellVenom.create()
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(spell, enemy)
	var result1 := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	# re-charge the slot so second zap fires
	(result1.mages[0] as MageState).slot_charges["s0_0"] = 99
	(result1.mages[0] as MageState).slot_charges["tip"] = 1
	(result1.mages[0] as MageState).mana_spent = 0
	var result2 := ActionZapWand.new(0, Vector2i(0, 0)).apply(result1, setup).state
	var poisons: Array = (result2.enemies["e1"] as EnemyState).combatant.statuses.filter(
			func(s: StatusData) -> bool: return s is StatusPoison)
	assert_eq(poisons.size(), 1, "should have one merged poison entry")
	assert_eq((poisons[0] as StatusPoison).stacks, 4, "poison stacks should accumulate (2+2=4)")


func test_on_hit_effects_not_applied_when_enemy_is_killed() -> void:
	var spell := SpellEmber.create()
	var enemy := EnemyData.new("e1", "Target", 2, Vector2i(1, 1), Color.RED)  # low hp
	var setup := _make_setup(spell, enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup).state
	assert_false(result.enemies.has("e1"))


# --- bounce ---

func test_lightning_bounces_to_second_enemy() -> void:
	var e1 := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var e2 := EnemyData.new("e2", "Other", 20, Vector2i(1, 1), Color.BLUE)
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = SpellLightning.create()
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = SpellSingle.create()
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	var setup := BattleSetup.new(
		[e1, e2], [Vector2i(0, 0), Vector2i(1, 0)],
		[mage], [wand], 10)
	var s := BattleState.new()
	var es1 := EnemyState.new()
	es1.combatant.hp = 20
	s.enemies["e1"] = es1
	var es2 := EnemyState.new()
	es2.combatant.hp = 20
	s.enemies["e2"] = es2
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 99
	ms.slot_charges["tip"] = 1
	s.mages.append(ms)
	s.mana = 10
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(s, setup).state
	assert_eq((result.enemies.get("e1") as EnemyState).combatant.hp, 18, "e1 took lightning damage")
	assert_eq((result.enemies.get("e2") as EnemyState).combatant.hp, 18, "e2 took bounce damage")


# --- cast events ---

func test_cast_events_recorded_on_result() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.RED)
	var setup := _make_setup(_strike_spell(), enemy)
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(_make_state(setup), setup)
	assert_gt(result.cast_events.size(), 0)


# --- bone soul harvest ---

func test_bone_kill_refunds_all_zap_mana() -> void:
	var enemy := EnemyData.new("e1", "Target", 3, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges["s0_0"] = 1
	(state.mages[0] as MageState).slot_charges["tip"] = 1
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_false(result.enemies.has("e1"), "enemy should be dead")
	assert_eq(result.mana, 7, "2 mana spent this zap should be refunded")


func test_bone_no_refund_when_enemy_survives() -> void:
	var enemy := EnemyData.new("e1", "Target", 20, Vector2i(1, 1), Color.WHITE)
	var setup := _make_setup(SpellBone.create(), enemy)
	var state := _make_state(setup)
	(state.mages[0] as MageState).slot_charges["s0_0"] = 1
	(state.mages[0] as MageState).slot_charges["tip"] = 1
	state.mana = 5
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_true(result.enemies.has("e1"), "enemy should survive")
	assert_eq(result.mana, 5, "no refund when kill does not happen")


func test_bone_multi_kill_does_not_double_refund_mana() -> void:
	var e1 := EnemyData.new("e1", "Target1", 3, Vector2i(1, 1), Color.WHITE)
	var e2 := EnemyData.new("e2", "Target2", 3, Vector2i(1, 1), Color.WHITE)
	var body := SpellSlotData.new("s0_0", 0, 0, "tip")
	body.spell = SpellBone.create()
	var tip_spell := SpellData.new("Wide", "W", [], Color.WHITE,
			[Vector2i(0, 0), Vector2i(0, 1)], "", 0, 1)
	tip_spell.spell_type = "tip"
	var tip := SpellSlotData.new("tip", 1, 0)
	tip.spell = tip_spell
	var wand := WandData.new([body, tip])
	var mage := MageData.new("Mage", 30)
	var setup := BattleSetup.new(
			[e1, e2] as Array[EnemyData],
			[Vector2i(0, 0), Vector2i(0, 1)] as Array[Vector2i],
			[mage] as Array[MageData],
			[wand] as Array[WandData], 10)
	var state := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	ms.slot_charges["s0_0"] = 1
	ms.slot_charges["tip"] = 1
	state.mages.append(ms)
	state.mana = 8
	for e: EnemyData in setup.enemies:
		var es := EnemyState.new()
		es.combatant.hp = e.max_hp
		state.enemies[e.id] = es
	var result := ActionZapWand.new(0, Vector2i(0, 0)).apply(state, setup).state
	assert_false(result.enemies.has("e1"), "e1 should be dead")
	assert_false(result.enemies.has("e2"), "e2 should be dead")
	assert_eq(result.mana, 10, "refund happens only once, capped at max_mana")
