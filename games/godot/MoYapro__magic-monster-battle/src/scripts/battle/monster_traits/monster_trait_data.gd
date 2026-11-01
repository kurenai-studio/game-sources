class_name MonsterTraitData

# Difficulty tiers: 1 = minor, 2 = moderate, 3 = hard
var label: String  # shown in the enemy cell
var tier: int = 1


func _init(p_label: String, p_tier: int = 1) -> void:
	label = p_label
	tier = p_tier


func apply_end_of_round(state: BattleState, _setup: BattleSetup, _enemy_id: String) -> BattleState:
	return state


func apply_on_hit(state: BattleState, _setup: BattleSetup, _enemy_id: String, _target_mage: int, _damage: int) -> BattleState:
	return state


func apply_on_monster_dies(_state: BattleState, _setup: BattleSetup, _trait_owner_id: String, _dead_enemy_id: String) -> void:
	pass
