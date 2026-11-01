class_name SpellFrost

static func create() -> SpellData:
	var s := SpellData.new("Frost", "Fr", ["water", "frost"], Color(0.25, 0.65, 1.00), [], "", 2, 3,
			"Freezes the target solid, blocking its next action.")
	s.spell_id = "frost"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "freeze"}]
	return s
