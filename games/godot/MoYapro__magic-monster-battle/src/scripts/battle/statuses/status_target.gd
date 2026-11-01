class_name StatusTarget extends RefCounted

var _combatant: CombatantState
var _state: BattleState
var _enemy_id: String = ""
var _mage_index: int = -1


static func for_enemy(state: BattleState, enemy_id: String) -> StatusTarget:
	var t := StatusTarget.new()
	t._state = state
	t._enemy_id = enemy_id
	t._mage_index = -1
	t._combatant = (state.enemies[enemy_id] as EnemyState).combatant
	return t


static func for_mage(state: BattleState, mage_index: int) -> StatusTarget:
	var t := StatusTarget.new()
	t._state = state
	t._mage_index = mage_index
	t._enemy_id = ""
	t._combatant = (state.mages[mage_index] as MageState).combatant
	return t


func is_enemy() -> bool:
	return not _enemy_id.is_empty()


func get_hp() -> int:
	return _combatant.hp


func set_hp(val: int) -> void:
	_combatant.hp = val


func get_statuses() -> Array:
	return _combatant.statuses


func add_status(s: StatusData) -> void:
	if is_enemy():
		_state.add_enemy_status(_enemy_id, s)
	else:
		_state.add_mage_status(_mage_index, s)


func remove_status(s: StatusData) -> void:
	get_statuses().erase(s)


func kill(setup: BattleSetup = null) -> void:
	if is_enemy():
		_state.kill_enemy(_enemy_id, setup)


func is_alive() -> bool:
	return _combatant.is_alive()


func get_state() -> BattleState:
	return _state
