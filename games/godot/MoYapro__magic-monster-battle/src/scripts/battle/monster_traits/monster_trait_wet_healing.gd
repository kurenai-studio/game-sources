class_name MonsterTraitWetHealing extends MonsterTraitData

var amount: int


func _init(p_amount: int) -> void:
	super("Wet Heal %d" % p_amount, 2)
	amount = p_amount


func apply_end_of_round(state: BattleState, setup: BattleSetup, enemy_id: String) -> BattleState:
	if not state.enemies.has(enemy_id):
		return state
	var es := state.enemies[enemy_id] as EnemyState
	var wet_status: StatusWet = null
	for s: StatusData in es.combatant.statuses:
		if s is StatusWet:
			wet_status = s
			break
	if wet_status == null or wet_status.stacks <= 0:
		return state
	var wet := wet_status.stacks
	var new_state := state.duplicate()
	var enemy := setup.get_enemy(enemy_id)
	if enemy == null:
		return new_state
	var new_es := new_state.enemies[enemy_id] as EnemyState
	new_es.combatant.hp = mini(new_es.combatant.hp + wet * amount, enemy.max_hp)
	return new_state
