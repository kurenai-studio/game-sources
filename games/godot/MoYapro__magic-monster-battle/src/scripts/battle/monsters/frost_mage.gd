class_name FrostMage extends EnemyData

func _init() -> void:
	super("frost_mage_1", "Frost Mage", 45, Vector2i(1, 1), Color(0.55, 0.80, 0.95))
	label_color = Color.BLACK
	description = "A robed sorcerer wielding blizzards and frost bolts to freeze and shatter foes."
	main_role = MonsterRole.Type.MAGE
	difficulty_rating = 33
	drop_pool = [SpellFrost.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Ice Bolt", 11, 2),
		MonsterActionAttack.new("Blizzard", 8, 3),
		MonsterActionAttack.new("Frost Nova", 15, 0, true),
	]
