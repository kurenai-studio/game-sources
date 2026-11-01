class_name MonsterActionData

enum TargetType { MAGE, SELF, MONSTER, ALL_MAGES }

var name: String
var target_type: TargetType


func check_preconditions(_state: BattleState, _setup: BattleSetup, _enemy_id: String) -> bool:
	return true


func execute(_state: BattleState, _setup: BattleSetup,
		_enemy_id: String, _target: int) -> BattleState:
	return _state.duplicate()
