class_name FallenPaladin extends EnemyData

func _init() -> void:
	super("fallen_paladin_1", "Fallen Paladin", 400, Vector2i(1, 1), Color(0.65, 0.60, 0.55))
	label_color = Color.BLACK
	description = "A once-holy knight corrupted by darkness, shielding itself with divine guard."
	main_role = MonsterRole.Type.PALADIN
	off_role = MonsterRole.Type.TANK
	difficulty_rating = 55
	traits = [MonsterTraitArmor.new(15), MonsterTraitBlock.new(3)]
	drop_pool = [SpellShield.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Smite", 16),
		MonsterActionAttack.new("Holy Charge", 20),
	]
