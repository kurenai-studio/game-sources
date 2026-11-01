extends GutTest

const LEECHER_ID := "leecher"
const LEECHER_MAX_HP := 40


func _make_state() -> BattleState:
	var s := BattleState.new()
	var ms := MageState.new()
	ms.combatant.hp = 30
	s.mages.append(ms)
	return s


func _make_setup() -> BattleSetup:
	return BattleSetup.new([], [], [], [], 10)


func _make_setup_with_leecher() -> BattleSetup:
	var leecher := EnemyData.new(LEECHER_ID, "Leecher", LEECHER_MAX_HP, Vector2i(0, 0), Color.RED)
	return BattleSetup.new([leecher], [Vector2i(0, 0)], [], [], 10)


func _add_enemy(state: BattleState, id: String, hp: int) -> void:
	var es := EnemyState.new()
	es.combatant.hp = hp
	state.enemies[id] = es


# --- on_mana_spent ---

func test_leech_heals_source_by_one_per_mana_spent() -> void:
	var state := _make_state()
	_add_enemy(state, LEECHER_ID, 20)
	var leech := StatusLeech.new(LEECHER_ID)
	leech.on_mana_spent(StatusTarget.for_mage(state, 0), _make_setup_with_leecher())
	assert_eq((state.enemies[LEECHER_ID] as EnemyState).combatant.hp, 21)


func test_leech_does_not_heal_beyond_max_hp() -> void:
	var state := _make_state()
	_add_enemy(state, LEECHER_ID, LEECHER_MAX_HP)
	var leech := StatusLeech.new(LEECHER_ID)
	leech.on_mana_spent(StatusTarget.for_mage(state, 0), _make_setup_with_leecher())
	assert_eq((state.enemies[LEECHER_ID] as EnemyState).combatant.hp, LEECHER_MAX_HP)


func test_leech_no_crash_when_source_is_dead() -> void:
	var state := _make_state()
	var leech := StatusLeech.new(LEECHER_ID)
	leech.on_mana_spent(StatusTarget.for_mage(state, 0), _make_setup_with_leecher())
	assert_false(state.enemies.has(LEECHER_ID))


# --- on_turn_end ---

func test_leech_self_removes_on_turn_end() -> void:
	var state := _make_state()
	var leech := StatusLeech.new(LEECHER_ID)
	(state.mages[0] as MageState).combatant.statuses.append(leech)
	leech.on_turn_end(StatusTarget.for_mage(state, 0), _make_setup())
	assert_eq((state.mages[0] as MageState).combatant.statuses.size(), 0)
