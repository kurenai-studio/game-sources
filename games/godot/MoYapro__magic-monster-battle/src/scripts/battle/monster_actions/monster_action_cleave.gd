class_name MonsterActionCleave extends MonsterActionData

var damage: int


func _init(p_name: String, p_damage: int) -> void:
	name = p_name
	target_type = TargetType.ALL_MAGES
	damage = p_damage


func execute(state: BattleState, _setup: BattleSetup,
		enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	var es := new_state.enemies.get(enemy_id) as EnemyState
	var mult: float = es.attack_mult if es != null else 1.0
	var actual_damage := int(damage * mult)
	for ms: MageState in new_state.mages:
		var remaining := ms.combatant.absorb_shield(actual_damage)
		ms.combatant.hp = max(0, ms.combatant.hp - remaining)
	return new_state
