class_name MonsterTraitFire extends MonsterTraitData


func _init() -> void:
	super("Fire", 2)


func apply_on_hit(state: BattleState, _setup: BattleSetup, _enemy_id: String, target_mage: int, damage: int) -> BattleState:
	if target_mage < 0 or target_mage >= state.mages.size():
		return state
	var fire_to_apply := maxi(0, damage - 1)
	if fire_to_apply == 0:
		return state
	var new_state := state.duplicate()
	new_state.add_mage_status(target_mage, StatusFire.new(fire_to_apply))
	return new_state
