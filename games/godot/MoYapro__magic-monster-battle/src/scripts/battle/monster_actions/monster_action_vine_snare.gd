class_name MonsterActionVineSnare extends MonsterActionData


func _init() -> void:
	name = "Vine Snare"
	target_type = TargetType.MAGE


func execute(state: BattleState, _setup: BattleSetup, enemy_id: String, target: int) -> BattleState:
	if target < 0:
		return state
	var new_state := state.duplicate()
	new_state.add_mage_status(target, StatusVineSnare.new(enemy_id))
	return new_state
