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

func test_poison_deals_one_damage_per_turn() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(3)
	(state.mages[0] as MageState).combatant.statuses.append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.hp, 29)


func test_poison_damage_is_always_one_regardless_of_stacks() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(5)
	(state.mages[0] as MageState).combatant.statuses.append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.hp, 29)


func test_poison_decrements_stacks_each_turn() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(3)
	(state.mages[0] as MageState).combatant.statuses.append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq(poison.stacks, 2)


func test_poison_is_removed_when_stacks_reach_zero() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(1)
	(state.mages[0] as MageState).combatant.statuses.append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)


func test_poison_persists_while_stacks_remain() -> void:
	var state := _make_state()
	var poison := StatusPoison.new(3)
	(state.mages[0] as MageState).combatant.statuses.append(poison)
	poison.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


# --- add_mage_status (same type) ---

func test_adding_poison_when_none_exists_creates_one_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusPoison.new(2))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)


func test_adding_poison_when_poison_exists_merges_stacks() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusPoison.new(2))
	state.add_mage_status(0, StatusPoison.new(3))
	assert_eq(((state.mages[0] as MageState).combatant.statuses[0] as StatusPoison).stacks, 5)


func test_adding_poison_again_does_not_create_second_status() -> void:
	var state := _make_state()
	state.add_mage_status(0, StatusPoison.new(2))
	state.add_mage_status(0, StatusPoison.new(3))
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 1)
