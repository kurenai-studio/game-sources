class_name MonsterActionHeal extends MonsterActionData

var amount: int


func _init(p_name: String, p_amount: int) -> void:
	name = p_name
	target_type = TargetType.MONSTER
	amount = p_amount


func execute(state: BattleState, setup: BattleSetup,
		enemy_id: String, _target: int) -> BattleState:
	var new_state := state.duplicate()
	if not new_state.enemies.has(enemy_id):
		return new_state
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	var es := new_state.enemies[enemy_id] as EnemyState
	es.combatant.hp = mini(enemy.max_hp, es.combatant.hp + amount)
	return new_state
