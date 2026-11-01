class_name SpellEmber

static func create() -> SpellData:
	var s := SpellData.new("Ember", "Em", ["fire"], Color(1.00, 0.45, 0.10), [], "", 3, 1,
			"Deals damage and applies fire stacks equal to the damage dealt.")
	s.spell_id = "ember"
	s.spell_type = "projectile"
	s.on_hit_effects = [{"type": "fire", "stacks_from_damage": true}]
	return s
