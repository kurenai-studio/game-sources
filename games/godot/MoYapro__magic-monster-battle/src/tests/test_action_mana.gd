extends GutTest


func _make_setup() -> BattleSetup:
	var slot := SpellSlotData.new("s0", 0, 0)
	slot.spell = SpellData.new("Strike", "S", [], Color.WHITE, [], "", 5, 3)  # mana_cost = 3
	var wand := WandData.new([slot])
	var mage := MageData.new("Mage", 30)
	var mages: Array[MageData] = [mage]
	var wands: Array[WandData] = [wand]
	var enemies: Array[EnemyData] = []
	var positions: Array[Vector2i] = []
	return BattleSetup.new(enemies, positions, mages, wands, 10)


func _make_state() -> BattleState:
	var s := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	s.mages.append(ms)
	s.mana = 10
	return s


# --- add mana ---

func test_add_mana_charges_the_slot() -> void:
	var setup := _make_setup()
	var result := ActionAddMana.new(0, "s0").apply(_make_state(), setup).state
	assert_eq((result.mages[0] as MageState).slot_charges.get("s0", 0), 1)


func test_add_mana_reduces_mana_pool_by_one() -> void:
	var setup := _make_setup()
	var result := ActionAddMana.new(0, "s0").apply(_make_state(), setup).state
	assert_eq(result.mana, 9)


func test_add_mana_does_nothing_when_pool_is_empty() -> void:
	var setup := _make_setup()
	var state := _make_state()
	state.mana = 0
	var result := ActionAddMana.new(0, "s0").apply(state, setup).state
	assert_eq((result.mages[0] as MageState).slot_charges.get("s0", 0), 0)


func test_add_mana_cannot_charge_slot_beyond_spell_cost() -> void:
	var setup := _make_setup()
	var state := _make_state()
	(state.mages[0] as MageState).slot_charges["s0"] = 3  # already at mana_cost cap
	var result := ActionAddMana.new(0, "s0").apply(state, setup).state
	assert_eq((result.mages[0] as MageState).slot_charges.get("s0", 0), 3)
	assert_eq(result.mana, 10)  # pool unchanged


# --- remove mana ---

func test_remove_mana_discharges_the_slot() -> void:
	var setup := _make_setup()
	var state := _make_state()
	(state.mages[0] as MageState).slot_charges["s0"] = 2
	var result := ActionRemoveMana.new(0, "s0").apply(state, setup).state
	assert_eq((result.mages[0] as MageState).slot_charges.get("s0", 0), 1)


func test_remove_mana_returns_one_to_pool() -> void:
	var setup := _make_setup()
	var state := _make_state()
	(state.mages[0] as MageState).slot_charges["s0"] = 2
	var result := ActionRemoveMana.new(0, "s0").apply(state, setup).state
	assert_eq(result.mana, 11)


func test_remove_mana_does_nothing_when_slot_is_empty() -> void:
	var setup := _make_setup()
	var result := ActionRemoveMana.new(0, "s0").apply(_make_state(), setup).state
	assert_eq(result.mana, 10)
