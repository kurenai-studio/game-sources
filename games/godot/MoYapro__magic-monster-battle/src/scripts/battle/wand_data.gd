class_name WandData

var slots: Array[SpellSlotData]


func _init(p_slots: Array[SpellSlotData]) -> void:
	slots = p_slots


func get_tip_slot() -> SpellSlotData:
	for slot in slots:
		if slot.is_tip:
			return slot
	return null


func get_slot(p_id: String) -> SpellSlotData:
	for slot in slots:
		if slot.id == p_id:
			return slot
	return null
