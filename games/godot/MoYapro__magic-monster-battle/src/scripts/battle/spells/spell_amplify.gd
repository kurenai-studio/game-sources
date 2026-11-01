class_name SpellAmplify

static func create() -> SpellData:
	var s := SpellData.new("Amplify", "Amp", ["amplify"], Color(0.80, 0.30, 1.00), [], "", 0, 2,
			"Doubles the damage of the next spell.")
	s.spell_id = "amplify"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "damage_mult", "factor": 2}
	return s
