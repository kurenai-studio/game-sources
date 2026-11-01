# Action ideas:
# - Toxic Brew: apply poison stacks to a mage (fits "brews potions" + SpellVenom drop)
# - Jinx: next spell the mage casts backfires onto themselves (needs on_spell_cast hook)
# - Curse of Fragility: mage takes double damage for one round
# - Counterspell: webs all of a mage's wand slots for the round
# - Mana Sap: remove N mana from the shared pool directly
class_name Witch extends EnemyData

func _init() -> void:
	super("witch_1", "Witch", 45, Vector2i(1, 1), Color(0.55, 0.1, 0.7))
	description = "A dark spellcaster who hexes enemies and brews potions to sustain herself."
	main_role = MonsterRole.Type.MAGE
	off_role = MonsterRole.Type.HEALER
	difficulty_rating = 30
	drop_pool = [SpellVenom.create(), SpellAmplify.create()]
	action_pool = [
		MonsterActionAttack.new("Curse", 4),
		MonsterActionAttack.new("Hex", 9),
		MonsterActionHeal.new("Brew", 18),
		MonsterActionLeech.new(),
	]
