class_name StatusLeech extends StatusData


func _init(enemy_id: String) -> void:
	source_enemy_id = enemy_id
	display_name = "LEECH"
	display_color = Color(0.55, 0.10, 0.30)
	icon = "●"


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	target.remove_status(self)


func on_mana_spent(target: StatusTarget, setup: BattleSetup) -> void:
	var state := target.get_state()
	if not state.enemies.has(source_enemy_id):
		return
	var es := state.enemies[source_enemy_id] as EnemyState
	var leecher := setup.get_enemy(source_enemy_id)
	if leecher != null:
		es.combatant.hp = mini(es.combatant.hp + 1, leecher.max_hp)
