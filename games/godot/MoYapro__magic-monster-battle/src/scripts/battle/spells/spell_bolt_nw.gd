class_name SpellBoltNW

static func create() -> SpellData:
	var s := SpellData.new("Bolt ↖", "↖", ["tip", "bolt"], Color(0.95, 0.85, 0.20),
			[Vector2i(0, 0), Vector2i(-1, -1)], "", 0, 1, "Strikes the target and the enemy to its upper-left.")
	s.spell_id = "bolt_nw"
	s.spell_type = "tip"
	return s
