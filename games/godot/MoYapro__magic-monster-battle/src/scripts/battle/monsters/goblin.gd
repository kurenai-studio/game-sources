class_name Goblin extends EnemyData

func _init() -> void:
	super("goblin_1", "Goblin", 30, Vector2i(1, 1), Color(0.2, 0.65, 0.2))
	label_color = Color.BLACK
	description = "A scrappy little pest that bites and scratches anything in its way."
	main_role = MonsterRole.Type.BRUISER
	difficulty_rating = 12
	drop_pool = [SpellEmber.create(), SpellVenom.create()]
	action_pool = [
		MonsterActionAttack.new("Scratch", 3),
		MonsterActionAttack.new("Bite", 5),
		MonsterActionTakeCover.new(),
	]
