class_name Scorpion extends EnemyData

func _init() -> void:
	super("scorpion_1", "Scorpion", 50, Vector2i(1, 1), Color(0.70, 0.55, 0.20))
	label_color = Color.BLACK
	description = "A desert predator with a venomous sting that poisons its prey slowly."
	main_role = MonsterRole.Type.DAMAGE
	difficulty_rating = 22
	traits = [MonsterTraitVenom.new(5)]
	drop_pool = [SpellVenom.create(), SpellEmber.create()]
	action_pool = [
		MonsterActionAttack.new("Sting", 8),
		MonsterActionAttack.new("Claw", 5),
		MonsterActionAttack.new("Venom Sting", 7),
		MonsterActionTakeCover.new(),
	]
