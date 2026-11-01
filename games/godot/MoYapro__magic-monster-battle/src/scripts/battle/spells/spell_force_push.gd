class_name SpellForcePush

static func create() -> SpellData:
	var s := SpellData.new("Force Push", "FP", ["force"], Color(0.90, 0.80, 0.20), [], "", 2, 1,
			"Smashes reagents together, or pushes enemies with blunt force.")
	s.spell_id = "force_push"
	s.spell_type = "catalyst"
	s.on_hit_effects = [{"type": "push", "distance_per_cast": 1}]
	return s
