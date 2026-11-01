class_name Troll extends EnemyData

func _init() -> void:
	super("troll_1", "Troll", 200, Vector2i(1, 2), Color(0.3, 0.5, 0.2))
	description = "A massive brute that heals rapidly, making it very hard to put down."
	main_role = MonsterRole.Type.SUSTAINER
	off_role = MonsterRole.Type.BRUISER
	difficulty_rating = 45
	traits = [MonsterTraitRegen.new(15)]
	drop_pool = [SpellVenom.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Smash", 11),
		MonsterActionHeal.new("Regenerate", 30),
		MonsterActionAttack.new("Throw", 7),
		MonsterActionCleave.new("Cleave", 8),
	]
