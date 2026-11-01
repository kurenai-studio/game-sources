class_name BoneCaller extends EnemyData

func _init() -> void:
	super("bone_caller_1", "Bone Caller", 60, Vector2i(1, 1), Color(0.75, 0.72, 0.65))
	label_color = Color.BLACK
	description = "A necromancer that raises bone spikes and calls the dead to do its bidding."
	main_role = MonsterRole.Type.SUMMONER
	difficulty_rating = 38
	traits = [MonsterTraitPoisonImmunity.new(), MonsterTraitRevengeRevive.new()]
	drop_pool = [SpellVenom.create(), SpellPierce.create()]
	action_pool = [
		MonsterActionAttack.new("Dark Bolt", 9),
		MonsterActionAttack.new("Bone Spike", 15),
	]
