class_name MageState

var combatant := CombatantState.new()
var mana_spent: int = 0
var slot_charges: Dictionary = {}  # slot_id -> int
var webbed_slots: Dictionary = {}  # slot_id -> true


func duplicate() -> MageState:
	var s := MageState.new()
	s.combatant = combatant.duplicate()
	s.mana_spent = mana_spent
	s.slot_charges = slot_charges.duplicate()
	s.webbed_slots = webbed_slots.duplicate()
	return s
