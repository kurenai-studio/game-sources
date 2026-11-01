class_name ShadowPanther extends EnemyData

func _init() -> void:
	super("shadow_panther_1", "Shadow Panther", 50, Vector2i(1, 1), Color(0.15, 0.12, 0.20))
	description = "A sleek predator that stalks its prey from the shadows before pouncing."
	main_role = MonsterRole.Type.STALKER
	difficulty_rating = 22
	traits = [MonsterTraitVenom.new(2)]
	drop_pool = [SpellVenom.create(), SpellLine.create()]
	action_pool = [
		MonsterActionAttack.new("Stalk", 4),
		MonsterActionAttack.new("Pounce", 12),
		MonsterActionTakeCover.new(),
	]
