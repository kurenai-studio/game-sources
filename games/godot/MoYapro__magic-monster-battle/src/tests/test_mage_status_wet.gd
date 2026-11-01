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

func test_wet_decays_by_one_per_turn() -> void:
	var state := _make_state()
	var wet := StatusWet.new(3)
	(state.mages[0] as MageState).combatant.statuses.append(wet)
	wet.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(wet.stacks, 2)


func test_wet_is_removed_when_depleted() -> void:
	var state := _make_state()
	var wet := StatusWet.new(1)
	(state.mages[0] as MageState).combatant.statuses.append(wet)
	wet.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)


func test_wet_deals_no_damage() -> void:
	var state := _make_state()
	var wet := StatusWet.new(3)
	(state.mages[0] as MageState).combatant.statuses.append(wet)
	wet.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.hp, 30)


# --- add_mage_status (same type) ---

func test_adding_wet_when_none_exists_creates_one_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(3))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


func test_adding_wet_when_wet_exists_merges_stacks() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(3))
	state.add_mage_status(0, StatusWet.new(2))
	assert_eq(((state.mages[0] as MageState).combatant.statuses[0] as StatusWet).stacks, 5)


func test_adding_wet_again_does_not_create_second_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(3))
	state.add_mage_status(0, StatusWet.new(2))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


# --- interaction with fire ---

func test_existing_wet_is_reduced_by_incoming_fire() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(5))
	state.add_mage_status(0, StatusFire.new(3))
	assert_eq(((state.mages[0] as MageState).combatant.statuses[0] as StatusWet).stacks, 2)


func test_existing_wet_is_removed_when_fire_fully_absorbs_it() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(3))
	state.add_mage_status(0, StatusFire.new(5))
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusWet))


func test_fire_remainder_is_added_when_it_outlasts_wet() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusWet.new(2))
	state.add_mage_status(0, StatusFire.new(5))
	var fire: Array = (state.mages[0] as MageState).combatant.statuses.filter(func(s: StatusData) -> bool: return s is StatusFire)
	assert_eq((fire[0] as StatusFire).stacks, 3)


func test_incoming_wet_fully_absorbed_by_fire_is_not_added() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusFire.new(5))
	state.add_mage_status(0, StatusWet.new(3))
	assert_false((state.mages[0] as MageState).combatant.statuses.any(func(s: StatusData) -> bool: return s is StatusWet))
