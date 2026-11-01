class_name WandGenerator

# Generates a random directed graph wand where all edges point toward the tip.
#
# Strategy: build columns left-to-right. Each column's slots each connect to
# one slot in the next column. The final column is always a single tip slot.
# This guarantees the tip is the unique sink and the graph is acyclic.
#
# Column counts and row counts per column are randomised within bounds.

static func generate_starter(rng: RandomNumberGenerator) -> WandData:
	var wand := generate(rng, 2, 2, 1, 2)
	for slot: SpellSlotData in wand.slots:
		if slot.is_tip:
			slot.spell = SpellSingle.create()
	# Guarantee at least one body slot has a spell so the wand always deals damage
	var empty_body := wand.slots.filter(func(s: SpellSlotData) -> bool:
			return not s.is_tip and s.spell == null)
	if empty_body.size() == wand.slots.filter(func(s: SpellSlotData) -> bool:
			return not s.is_tip).size():
		(empty_body[rng.randi_range(0, empty_body.size() - 1)] as SpellSlotData).spell = \
				_pick_body_spell(rng)
	return wand


static func generate(rng: RandomNumberGenerator, min_cols: int = 2, max_cols: int = 3,
		min_rows: int = 1, max_rows: int = 3) -> WandData:
	var slots: Array[SpellSlotData] = []
	var col_count := rng.randi_range(min_cols, max_cols)
	# build body columns (everything left of the tip)
	var prev_ids: Array[String] = []
	for col in col_count:
		var row_count := rng.randi_range(min_rows, max_rows)
		var col_ids: Array[String] = []
		for row in row_count:
			var id := "s%d_%d" % [col, row]
			col_ids.append(id)
			# next_id assigned below once we know the next column's ids
			slots.append(SpellSlotData.new(id, col, row, ""))
		# wire previous column → this column
		_wire_columns(rng, slots, prev_ids, col_ids)
		prev_ids = col_ids

	# add tip as single final column
	var tip_row := _center_row(prev_ids, slots)
	var tip := SpellSlotData.new("tip", col_count, tip_row)
	slots.append(tip)
	_wire_columns(rng, slots, prev_ids, ["tip"])

	for slot in slots:
		if slot.is_tip:
			slot.spell = _pick_tip_spell(rng)
		elif rng.randf() < 0.5:
			slot.spell = _pick_body_spell(rng)

	return WandData.new(slots)


static func _pick_body_spell(rng: RandomNumberGenerator) -> SpellData:
	var spells: Array[SpellData] = [
		SpellEmber.create(), SpellFrost.create(), SpellVenom.create(),
		SpellAmplify.create(), SpellShield.create(),
		SpellFireCatalyst.create(), SpellForcePush.create(),
		SpellBone.create(), SpellLightning.create(),
	]
	return spells[rng.randi_range(0, spells.size() - 1)]


static func _pick_tip_spell(rng: RandomNumberGenerator) -> SpellData:
	var spells: Array[SpellData] = [
		SpellSingle.create(), SpellLine.create(), SpellPierce.create(), SpellBomb.create(),
		SpellBoltN.create(), SpellBoltNE.create(), SpellBoltE.create(), SpellBoltSE.create(),
		SpellBoltS.create(), SpellBoltSW.create(), SpellBoltW.create(), SpellBoltNW.create(),
	]
	return spells[rng.randi_range(0, spells.size() - 1)]


# Assign each slot in prev_ids a next_id drawn from next_ids.
# Slots are sorted by row and mapped proportionally so edges never cross.
# When prev >= next, every next slot is guaranteed at least one incoming edge.
static func _wire_columns(_rng: RandomNumberGenerator, slots: Array[SpellSlotData],
		prev_ids: Array[String], next_ids: Array[String]) -> void:
	if prev_ids.is_empty():
		return
	var prev_sorted := _ids_sorted_by_row(prev_ids, slots)
	var next_sorted := _ids_sorted_by_row(next_ids, slots)
	var n := prev_sorted.size()
	var m := next_sorted.size()
	for i in n:
		_set_next(slots, prev_sorted[i], next_sorted[(i * m) / n])


static func _ids_sorted_by_row(ids: Array[String], slots: Array[SpellSlotData]) -> Array[String]:
	var result := ids.duplicate()
	result.sort_custom(func(a, b): return _row_of(slots, a) < _row_of(slots, b))
	return result


static func _row_of(slots: Array[SpellSlotData], id: String) -> int:
	for slot in slots:
		if slot.id == id:
			return slot.grid_row
	return 0


static func _set_next(slots: Array[SpellSlotData], slot_id: String, next_id: String) -> void:
	for slot in slots:
		if slot.id == slot_id:
			slot.next_id = next_id
			return


# Pick a grid row for the tip that sits near the vertical centre of the last column.
static func _center_row(prev_ids: Array[String], slots: Array[SpellSlotData]) -> int:
	if prev_ids.is_empty():
		return 0
	var total_row := 0
	var count := 0
	for slot in slots:
		if slot.id in prev_ids:
			total_row += slot.grid_row
			count += 1
	return roundi(float(total_row) / float(count))
