extends GutTest


func test_slot_with_no_next_id_is_tip() -> void:
	var slot := SpellSlotData.new("tip", 2, 1)
	assert_true(slot.is_tip)


func test_slot_with_next_id_is_not_tip() -> void:
	var slot := SpellSlotData.new("s0_0", 0, 0, "tip")
	assert_false(slot.is_tip)


func test_empty_string_next_id_marks_as_tip() -> void:
	var slot := SpellSlotData.new("s0_0", 0, 0, "")
	assert_true(slot.is_tip)


func test_grid_position_stored_correctly() -> void:
	var slot := SpellSlotData.new("s1_2", 1, 2, "tip")
	assert_eq(slot.grid_col, 1)
	assert_eq(slot.grid_row, 2)


func test_spell_is_null_by_default() -> void:
	var slot := SpellSlotData.new("s0_0", 0, 0)
	assert_null(slot.spell)
