class_name BogShambler extends EnemyData

func _init() -> void:
	super("bog_shambler_1", "Bog Shambler", 75, Vector2i(1, 1), Color(0.22, 0.35, 0.18))
	description = "A rotting swamp creature that entangles and slows enemies in thick mud."
	main_role = MonsterRole.Type.CROWD_CONTROLLER
	difficulty_rating = 26
	traits = [MonsterTraitWetHealing.new(15)]
	drop_pool = [SpellVenom.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Mudslap", 6),
		MonsterActionAttack.new("Entangle", 5, 2),
		MonsterActionAttack.new("Bog Slam", 9),
		MonsterActionLeech.new(),
	]
