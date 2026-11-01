extends GutTest


func _gen(seed: int) -> WandData:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return WandGenerator.generate(rng)


func test_wand_has_exactly_one_tip() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		var tip_count := 0
		for slot: SpellSlotData in wand.slots:
			if slot.is_tip:
				tip_count += 1
		assert_eq(tip_count, 1, "seed %d" % s)


func test_every_non_tip_slot_has_next_id() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		for slot: SpellSlotData in wand.slots:
			if not slot.is_tip:
				assert_false(slot.next_id.is_empty(), "slot %s seed %d" % [slot.id, s])


func test_every_next_id_points_to_existing_slot() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		for slot: SpellSlotData in wand.slots:
			if not slot.next_id.is_empty():
				assert_not_null(wand.get_slot(slot.next_id),
						"slot %s next_id '%s' seed %d" % [slot.id, slot.next_id, s])


func test_tip_slot_always_has_spell() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		assert_not_null(wand.get_tip_slot().spell, "seed %d" % s)


func test_tip_spell_has_non_empty_hit_pattern() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		var tip := wand.get_tip_slot()
		assert_false(tip.spell.hit_pattern.is_empty(), "seed %d" % s)


func test_body_spells_have_empty_hit_pattern() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		for slot: SpellSlotData in wand.slots:
			if not slot.is_tip and slot.spell != null:
				assert_true(slot.spell.hit_pattern.is_empty(),
						"slot %s seed %d" % [slot.id, s])


func test_wand_has_minimum_two_slots() -> void:
	for s in [1, 2, 3, 42, 100]:
		var wand := _gen(s)
		assert_gte(wand.slots.size(), 2, "seed %d" % s)
