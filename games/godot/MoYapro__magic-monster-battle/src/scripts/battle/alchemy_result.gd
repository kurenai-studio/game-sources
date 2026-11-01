class_name AlchemyResult

enum Outcome { SUCCESS, FIZZLE, BACKFIRE }

var outcome: int  # Outcome enum value
var spell: SpellData  # non-null for SUCCESS
var backfire_damage: int  # for BACKFIRE
var backfire_effects: Array[Dictionary]  # for BACKFIRE


static func success(p_spell: SpellData) -> AlchemyResult:
	var r := AlchemyResult.new()
	r.outcome = Outcome.SUCCESS
	r.spell = p_spell
	return r


static func fizzle() -> AlchemyResult:
	var r := AlchemyResult.new()
	r.outcome = Outcome.FIZZLE
	return r


static func backfire(p_damage: int, p_effects: Array[Dictionary] = []) -> AlchemyResult:
	var r := AlchemyResult.new()
	r.outcome = Outcome.BACKFIRE
	r.backfire_damage = p_damage
	r.backfire_effects = p_effects
	return r
