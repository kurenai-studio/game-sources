class_name SpellDistillation

static func create() -> SpellData:
	var s := SpellData.new("Distillation", "Di", ["distillation"], Color(0.20, 0.55, 0.90), [], "", 0, 1,
			"Converts the damage of the next spell into additional stacks or effects.")
	s.spell_id = "distillation"
	s.spell_type = "modifier"
	s.modifier_effect = {"type": "distillation"}
	return s
