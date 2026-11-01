class_name SpellBomb

static func create() -> SpellData:
	var s := SpellData.new("Bomb", "", ["tip", "aoe"], Color(0.25, 0.25, 0.28),
			[Vector2i(-1,-1), Vector2i(-1, 0), Vector2i(-1, 1),
			 Vector2i( 0,-1), Vector2i( 0, 0), Vector2i( 0, 1),
			 Vector2i( 1,-1), Vector2i( 1, 0), Vector2i( 1, 1)], "bomb", 0, 3,
			"Explodes in a 3x3 area, hitting all nearby enemies.")
	s.spell_id = "bomb"
	s.spell_type = "tip"
	return s
