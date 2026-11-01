class_name MonsterTraitRegen extends MonsterTraitData

var amount: int


func _init(p_amount: int) -> void:
	super("Regen %d" % p_amount, 2)
	amount = p_amount


func apply_end_of_round(state: BattleState, setup: BattleSetup, enemy_id: String) -> BattleState:
	var new_state := state.duplicate()
	if not new_state.enemies.has(enemy_id):
		return new_state
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	var es := new_state.enemies[enemy_id] as EnemyState
	es.combatant.hp = mini(es.combatant.hp + amount, enemy.max_hp)
	return new_state
