class_name SpellSingle

static func create() -> SpellData:
	var s := SpellData.new("Single", "·", ["tip", "single"], Color(0.90, 0.90, 0.90),
			[Vector2i(0, 0)], "", 0, 1, "Strikes a single target with focused force.")
	s.spell_id = "single"
	s.spell_type = "tip"
	return s
