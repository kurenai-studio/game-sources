class_name SpellPierce

static func create() -> SpellData:
	var s := SpellData.new("Pierce", "→→", ["tip", "pierce"], Color(0.95, 0.55, 0.20),
			[Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)], "", 0, 2,
			"Pierces through three enemies in a row.")
	s.spell_id = "pierce"
	s.spell_type = "tip"
	return s
