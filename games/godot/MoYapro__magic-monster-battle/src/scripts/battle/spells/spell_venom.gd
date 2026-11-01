class_name SpellVenom

static func create() -> SpellData:
	var s := SpellData.new("Venom", "Vn", ["poison"], Color(0.30, 0.85, 0.20), [], "", 2, 1,
			"Deals damage and applies poison stacks equal to the damage dealt.")
	s.spell_id = "venom"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "poison", "stacks_from_damage": true}]
	return s
