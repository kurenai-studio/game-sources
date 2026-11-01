class_name Skeleton extends EnemyData

func _init() -> void:
	super("skeleton_1", "Skeleton", 30, Vector2i(1, 1), Color(0.8, 0.8, 0.7))
	label_color = Color.BLACK
	description = "An undead warrior animated by dark magic, relentless and tireless."
	main_role = MonsterRole.Type.DAMAGE
	difficulty_rating = 10
	traits = [MonsterTraitPoisonImmunity.new()]
	drop_pool = [SpellFrost.create(), SpellShield.create()]
	action_pool = [
		MonsterActionAttack.new("Strike", 4),
		MonsterActionAttack.new("Rattle", 2),
	]
