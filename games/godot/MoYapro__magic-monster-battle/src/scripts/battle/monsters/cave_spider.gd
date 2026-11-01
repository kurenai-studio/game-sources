class_name CaveSpider extends EnemyData

func _init() -> void:
	super("cave_spider_1", "Cave Spider", 40, Vector2i(1, 1), Color(0.18, 0.15, 0.22))
	description = "A large venomous spider that webs its prey in place before slowly killing it."
	main_role = MonsterRole.Type.TRAPPER
	difficulty_rating = 18
	traits = [MonsterTraitVenom.new(3)]
	drop_pool = [SpellVenom.create(), SpellShield.create()]
	action_pool = [
		MonsterActionAttack.new("Bite", 6),
		MonsterActionAttack.new("Web Shot", 3, 0, false, true),
		MonsterActionAttack.new("Venom Bite", 8),
	]
