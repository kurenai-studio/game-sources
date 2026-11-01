class_name SpellBone

static func create() -> SpellData:
	var s := SpellData.new("Bone", "Bn", ["death"], Color(0.85, 0.85, 0.75), [], "", 4, 1,
			"Deals necrotic damage. Killing blow refunds all mana spent this zap.")
	s.spell_id = "bone"
	s.spell_type = "projectile"
	s.on_kill_effects = [{type = "refund_zap_mana"}]
	return s
