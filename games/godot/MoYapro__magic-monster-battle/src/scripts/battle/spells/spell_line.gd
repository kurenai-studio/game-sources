class_name SpellLine

static func create() -> SpellData:
	var s := SpellData.new("Line", "|||", ["tip", "line"], Color(0.30, 0.80, 0.95),
			[Vector2i(0, -1), Vector2i(0, 0), Vector2i(0, 1)], "", 0, 2,
			"Strikes three enemies in a vertical line.")
	s.spell_id = "line"
	s.spell_type = "tip"
	return s
