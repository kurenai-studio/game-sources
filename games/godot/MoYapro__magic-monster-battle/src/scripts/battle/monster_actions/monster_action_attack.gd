class_name MonsterActionAttack extends MonsterActionData

var damage: int
var wet_stacks: int
var applies_frozen: bool
var applies_web: bool


func _init(p_name: String, p_damage: int, p_wet_stacks: int = 0,
		p_frozen: bool = false, p_web: bool = false) -> void:
	name = p_name
	target_type = TargetType.MAGE
	damage = p_damage
	wet_stacks = p_wet_stacks
	applies_frozen = p_frozen
	applies_web = p_web


func execute(state: BattleState, setup: BattleSetup,
		enemy_id: String, target: int) -> BattleState:
	var new_state := state.duplicate()
	if target >= 0 and target < new_state.mages.size():
		var ms := new_state.mages[target] as MageState
		var es := new_state.enemies.get(enemy_id) as EnemyState
		var mult: float = es.attack_mult if es != null else 1.0
		var actual_damage := int(damage * mult)
		var remaining := ms.combatant.absorb_shield(actual_damage)
		ms.combatant.hp = max(0, ms.combatant.hp - remaining)
		var enemy := setup.get_enemy(enemy_id)
		if enemy != null:
			for t: MonsterTraitData in enemy.traits:
				new_state = t.apply_on_hit(new_state, setup, enemy_id, target, actual_damage) as BattleState
		if wet_stacks > 0:
			new_state.add_mage_status(target, StatusWet.new(wet_stacks))
		if applies_frozen:
			new_state.add_mage_status(target, StatusFrozen.new())
	return new_state
