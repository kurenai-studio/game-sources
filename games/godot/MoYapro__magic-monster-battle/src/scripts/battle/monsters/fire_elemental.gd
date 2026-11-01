class_name FireElemental extends EnemyData

func _init() -> void:
	super("fire_elemental_1", "Fire Elemental", 55, Vector2i(1, 1), Color(0.95, 0.40, 0.05))
	label_color = Color.BLACK
	description = "A living inferno that scorches everything it touches."
	main_role = MonsterRole.Type.MAGE
	difficulty_rating = 38
	traits = [MonsterTraitFire.new()]
	drop_pool = [SpellEmber.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Fire Blast", 13),
		MonsterActionAttack.new("Ignite", 7),
		MonsterActionAttack.new("Flame Wave", 11),
	]
