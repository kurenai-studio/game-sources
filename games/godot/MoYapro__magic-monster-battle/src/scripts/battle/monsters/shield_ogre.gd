class_name ShieldOgre extends EnemyData

func _init() -> void:
	super("ogre_1", "Shield Ogre", 350, Vector2i(1, 2), Color(0.65, 0.25, 0.15))
	description = "A hulking ogre hiding behind thick armor, soaking up punishment for its allies."
	main_role = MonsterRole.Type.TANK
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 52
	traits = [MonsterTraitArmor.new(30)]
	drop_pool = [SpellShield.create(), SpellEmber.create()]
	action_pool = [
		MonsterActionAttack.new("Punch", 14),
		MonsterActionAttack.new("Ogre Slam", 18),
	]
