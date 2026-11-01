class_name StatusVineSnare extends StatusData


func _init(enemy_id: String) -> void:
	source_enemy_id = enemy_id
	display_name = "VINE SNARE"
	display_color = Color(0.20, 0.55, 0.15)
	icon = "◆"


func on_zap(target: StatusTarget, setup: BattleSetup) -> void:
	var penalty := ceili(target.get_hp() / 2.0)
	target.set_hp(maxi(0, target.get_hp() - penalty))
	var state := target.get_state()
	if state.enemies.has(source_enemy_id):
		var snarer := setup.get_enemy(source_enemy_id)
		if snarer != null:
			var es := state.enemies[source_enemy_id] as EnemyState
			es.combatant.hp = mini(es.combatant.hp + penalty, snarer.max_hp)
	target.remove_status(self)


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	target.remove_status(self)
