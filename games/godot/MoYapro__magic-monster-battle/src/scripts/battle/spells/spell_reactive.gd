class_name SpellReactive

static func create() -> SpellData:
	var s := SpellData.new("Reactive", "Re", ["reactive"], Color(0.20, 0.75, 0.55), [], "", 0, 1,
			"The next spell checks the target's existing conditions and responds to them.")
	s.spell_id = "reactive"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "reactive"}
	return s
