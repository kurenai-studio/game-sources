class_name AlchemyFuser

# Scans a wand for the first consecutive triple of non-tip slots (A → B → C
# via next_id) that contains at least one catalyst spell and two reactant spells
# forming a valid alchemy recipe.
#
# If found: clears all three slot spells, places the result spell back in the
# catalyst slot (SUCCESS only), and returns the AlchemyResult.
# Returns null when no valid recipe exists — caller should fire spells normally.
#
# Parallel branches (multiple slots all pointing to the same next slot) are
# intentionally ignored: alchemy requires a strict left-to-right chain.


static func try_fuse(wand: WandData) -> AlchemyResult:
	for slot_a: SpellSlotData in wand.slots:
		if slot_a.is_tip or slot_a.spell == null:
			continue
		var slot_b := wand.get_slot(slot_a.next_id)
		if slot_b == null or slot_b.is_tip or slot_b.spell == null:
			continue
		var slot_c := wand.get_slot(slot_b.next_id)
		if slot_c == null or slot_c.is_tip or slot_c.spell == null:
			continue
		var result := _try_fuse_triple(slot_a, slot_b, slot_c)
		if result != null:
			return result
	return null


static func _try_fuse_triple(
		slot_a: SpellSlotData, slot_b: SpellSlotData, slot_c: SpellSlotData) -> AlchemyResult:
	var catalyst_slot: SpellSlotData = null
	var reactant_slots: Array[SpellSlotData] = []
	for slot: SpellSlotData in [slot_a, slot_b, slot_c]:
		if slot.spell.spell_type == "catalyst" and catalyst_slot == null:
			catalyst_slot = slot
		else:
			reactant_slots.append(slot)
	if catalyst_slot == null or reactant_slots.size() != 2:
		return null
	var result := AlchemyTable.lookup(
			catalyst_slot.spell, reactant_slots[0].spell, reactant_slots[1].spell)
	if result == null:
		return null
	slot_a.spell = null
	slot_b.spell = null
	slot_c.spell = null
	if result.outcome == AlchemyResult.Outcome.SUCCESS:
		catalyst_slot.spell = result.spell
	return result
