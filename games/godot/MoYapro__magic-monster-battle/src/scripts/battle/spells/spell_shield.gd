class_name SpellShield

static func create() -> SpellData:
	var s := SpellData.new("Shield", "Sh", ["shield"], Color(0.65, 0.75, 0.90), [], "", 0, 2,
			"Grants the target 10 shield points that absorb damage before HP.")
	s.spell_id = "shield"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "shield", "amount": 10}]
	return s
