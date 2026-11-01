class_name SpellLightning

static func create() -> SpellData:
	var s := SpellData.new("Lightning", "Lt", ["lightning"], Color(0.95, 0.95, 0.20), [], "", 2, 1,
			"Strikes the target and chains to one additional enemy.")
	s.spell_id = "lightning"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "bounce", "per_cast": 1}]
	return s
