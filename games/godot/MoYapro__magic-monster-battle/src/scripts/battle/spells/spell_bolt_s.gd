class_name SpellBoltS

static func create() -> SpellData:
	var s := SpellData.new("Bolt ↓", "↓", ["tip", "bolt"], Color(0.95, 0.85, 0.20),
			[Vector2i(0, 0), Vector2i(0, 1)], "", 0, 1, "Strikes the target and the enemy below it.")
	s.spell_id = "bolt_s"
	s.spell_type = "tip"
	return s
