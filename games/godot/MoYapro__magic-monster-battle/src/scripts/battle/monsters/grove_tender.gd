class_name GroveTender extends EnemyData

func _init() -> void:
	super("grove_tender_1", "Grove Tender", 45, Vector2i(1, 1), Color(0.45, 0.75, 0.35))
	label_color = Color.BLACK
	description = "A forest spirit that keeps its allies alive with restorative nature magic."
	main_role = MonsterRole.Type.HEALER
	difficulty_rating = 28
	traits = [MonsterTraitRegen.new(5), MonsterTraitWetHealing.new(10)]
	drop_pool = [SpellAmplify.create(), SpellShield.create()]
	action_pool = [
		MonsterActionAttack.new("Root Lash", 5),
		MonsterActionHeal.new("Mend", 25),
		MonsterActionVineSnare.new(),
	]
