class_name Banshee extends EnemyData

func _init() -> void:
	super("banshee_1", "Banshee", 40, Vector2i(1, 1), Color(0.75, 0.85, 0.95))
	label_color = Color.BLACK
	description = "A wailing spirit whose soul-draining screams weaken and terrify the living."
	main_role = MonsterRole.Type.DEBUFFER
	difficulty_rating = 28

	traits = [MonsterTraitFire.new(), MonsterTraitPoisonImmunity.new()]
	drop_pool = [SpellEmber.create(), SpellFrost.create()]
	action_pool = [
		MonsterActionAttack.new("Wail", 9),
		MonsterActionAttack.new("Soul Drain", 12),
		MonsterActionLeech.new(),
	]
