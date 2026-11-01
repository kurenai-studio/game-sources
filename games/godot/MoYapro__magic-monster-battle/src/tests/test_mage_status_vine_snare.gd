extends GutTest

const SNARER_ID := "snarer"
const SNARER_MAX_HP := 50


func _make_state() -> BattleState:
	var s := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	s.mages.append(ms)
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


func _make_setup_with_snarer() -> BattleSetup:
	var snarer := EnemyData.new(SNARER_ID, "Snarer", SNARER_MAX_HP, Vector2i(0, 0), Color.GREEN)
	return BattleSetup.new([snarer], [Vector2i(0, 0)], [], [], 10)


func _add_enemy(state: BattleState, id: String, hp: int) -> void:
	var es := EnemyState.new()
	es.combatant.hp = hp
	state.enemies[id] = es


func _state_with_live_snarer() -> BattleState:
	var state := _make_state()
	_add_enemy(state, SNARER_ID, 20)
	return state


# --- on_zap ---

func test_vine_snare_applies_half_hp_penalty_on_zap() -> void:
	var state := _state_with_live_snarer()
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_zap(StatusTarget.for_mage(state, 0), _make_setup_with_snarer())
	assert_eq((state.mages[0] as MageState).combatant.hp, 15)


func test_vine_snare_heals_snarer_by_penalty_amount() -> void:
	var state := _state_with_live_snarer()
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_zap(StatusTarget.for_mage(state, 0), _make_setup_with_snarer())
	assert_eq((state.enemies[SNARER_ID] as EnemyState).combatant.hp, 35)


func test_vine_snare_heal_does_not_exceed_snarer_max_hp() -> void:
	var state := _make_state()
	_add_enemy(state, SNARER_ID, 45)
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_zap(StatusTarget.for_mage(state, 0), _make_setup_with_snarer())
	assert_eq((state.enemies[SNARER_ID] as EnemyState).combatant.hp, SNARER_MAX_HP)


func test_vine_snare_self_removes_after_zap() -> void:
	var state := _state_with_live_snarer()
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_zap(StatusTarget.for_mage(state, 0), _make_setup_with_snarer())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)


func test_vine_snare_still_applies_penalty_when_snarer_is_dead() -> void:
	var state := _make_state()
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_zap(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.hp, 15)


func test_vine_snare_no_heal_when_snarer_is_dead() -> void:
	var state := _make_state()
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_zap(StatusTarget.for_mage(state, 0), _make_setup())
	assert_false(state.enemies.has(SNARER_ID))


# --- on_turn_end ---

func test_vine_snare_self_removes_on_turn_end_without_zapping() -> void:
	var state := _make_state()
	var snare := StatusVineSnare.new(SNARER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(snare)
	snare.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)
