class_name ActionRemoveMana extends BattleAction

var mage_index: int
var slot_id: String


func _init(p_mage_index: int, p_slot_id: String) -> void:
	mage_index = p_mage_index
	slot_id = p_slot_id


func apply(state: BattleState, _setup: BattleSetup) -> ActionResult:
	var result := ActionResult.new()
	var new_state := state.duplicate()
	var ms := new_state.mages[mage_index] as MageState
	var current: int = ms.slot_charges.get(slot_id, 0)
	if current <= 0:
		result.state = new_state
		return result
	ms.slot_charges[slot_id] = current - 1
	new_state.mana += 1
	ms.mana_spent -= 1
	result.state = new_state
	return result
