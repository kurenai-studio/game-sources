extends GutTest


func _make_state() -> BattleState:
	var s := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	s.mages.append(ms)
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


# --- on_turn_end ---

func test_fire_damages_mage_by_stack_count() -> void:
	var state := _make_state()
	var fire := StatusFire.new(6)
	(state.mages[0] as MageState).combatant.statuses.append(fire)
	fire.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.hp, 24)


func test_fire_halves_stacks_after_turn_end() -> void:
	var state := _make_state()
	var fire := StatusFire.new(6)
	(state.mages[0] as MageState).combatant.statuses.append(fire)
	fire.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(fire.stacks, 3)


func test_fire_is_removed_when_stacks_reach_zero() -> void:
	var state := _make_state()
	var fire := StatusFire.new(1)
	(state.mages[0] as MageState).combatant.statuses.append(fire)
	fire.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)


func test_fire_persists_while_stacks_remain() -> void:
	var state := _make_state()
	var fire := StatusFire.new(4)
	(state.mages[0] as MageState).combatant.statuses.append(fire)
	fire.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


# --- add_mage_status (same type) ---

func test_adding_fire_when_none_exists_creates_one_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(3))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


func test_adding_fire_when_fire_exists_merges_stacks() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(3))
	state.add_mage_status(0, StatusFire.new(4))
	assert_eq(((state.mages[0] as MageState).combatant.statuses[0] as StatusFire).stacks, 7)


func test_adding_fire_again_does_not_create_second_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(3))
	state.add_mage_status(0, StatusFire.new(4))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


# --- interaction with wet ---

func test_existing_fire_is_reduced_by_incoming_wet() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(5))
	state.add_mage_status(0, StatusWet.new(2))
	assert_eq(((state.mages[0] as MageState).combatant.statuses[0] as StatusFire).stacks, 3)


func test_existing_fire_is_removed_when_fully_doused_by_wet() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(3))
	state.add_mage_status(0, StatusWet.new(5))
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFire))


func test_wet_remainder_is_added_when_it_outlasts_fire() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(2))
	state.add_mage_status(0, StatusWet.new(5))
	var wet: Array = (state.mages[0] as MageState).combatant.statuses.filter(func(s: StatusData) -> bool: return s is StatusWet)
	assert_eq((wet[0] as StatusWet).stacks, 3)


func test_incoming_fire_fully_absorbed_by_wet_is_not_added() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(5))
	state.add_mage_status(0, StatusFire.new(3))
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusFire))
