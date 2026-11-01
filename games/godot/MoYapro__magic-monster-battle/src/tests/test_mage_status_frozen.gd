extends GutTest


func _make_state() -> BattleState:
	var s := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	s.mages.append(ms)
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


# --- blocks_action ---

func test_frozen_blocks_action() -> void:
	assert_true(StatusFrozen.new().blocks_action())


# --- on_add_status (fire interaction) ---

func test_frozen_absorbs_all_incoming_fire() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFrozen.new())
	state.add_mage_status(0, StatusFire.new(5))
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFire))


func test_frozen_is_removed_when_fire_is_applied() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFrozen.new())
	state.add_mage_status(0, StatusFire.new(5))
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFrozen))


func test_frozen_absorbs_fire_regardless_of_stack_count() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFrozen.new())
	state.add_mage_status(0, StatusFire.new(99))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)


# --- persistence ---

func test_frozen_persists_while_stacks_remain() -> void:
	var state := _make_state()
	var frozen := StatusFrozen.new(2)
	(state.mages[0] as MageState).combatant.statuses.append(frozen)
	frozen.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_true((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFrozen))


func test_frozen_removed_when_stacks_reach_zero() -> void:
	var state := _make_state()
	var frozen := StatusFrozen.new(1)
	(state.mages[0] as MageState).combatant.statuses.append(frozen)
	frozen.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFrozen))


func test_frozen_stacks_accumulate() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFrozen.new(1))
	state.add_mage_status(0, StatusFrozen.new(1))
	var frozen: Array = (state.mages[0] as MageState).combatant.statuses.filter(func(s: StatusData) -> bool: return s is StatusFrozen)
	assert_eq(frozen.size(), 1)
	assert_eq((frozen[0] as StatusFrozen).stacks, 2)


func test_frozen_unaffected_by_wet() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFrozen.new())
	state.add_mage_status(0, StatusWet.new(3))
	assert_true((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFrozen))
