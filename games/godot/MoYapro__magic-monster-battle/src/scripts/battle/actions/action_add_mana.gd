class_name ActionAddMana extends BattleAction

var mage_index: int
var slot_id: String


func _init(p_mage_index: int, p_slot_id: String) -> void:
	mage_index = p_mage_index
	slot_id = p_slot_id


func apply(state: BattleState, setup: BattleSetup) -> ActionResult:
	var result := ActionResult.new()
	var new_state := state.duplicate()
	if new_state.mana <= 0:
		result.state = new_state
		return result
	var slot := setup.wands[mage_index].get_slot(slot_id)
	if slot == null or slot.spell == null:
		result.state = new_state
		return result
	var ms := new_state.mages[mage_index] as MageState
	var current: int = ms.slot_charges.get(slot_id, 0)
	if current >= slot.spell.mana_cost:
		result.state = new_state
		return result
	ms.slot_charges[slot_id] = current + 1
	new_state.mana -= 1
	ms.mana_spent += 1
	var mana_target := StatusTarget.for_mage(new_state, mage_index)
	for status: StatusData in ms.combatant.statuses.duplicate():
		status.on_mana_spent(mana_target, setup)
	result.state = new_state
	return result
