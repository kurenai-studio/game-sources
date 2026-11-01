class_name SpellCorrupted

static func create() -> SpellData:
	var s := SpellData.new("Corrupted", "Co", ["corrupted"], Color(0.55, 0.10, 0.75), [], "", 0, 1,
			"Converts the on-hit status effects of the next spell into immediate damage.")
	s.spell_id = "corrupted"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "corrupted"}
	return s
