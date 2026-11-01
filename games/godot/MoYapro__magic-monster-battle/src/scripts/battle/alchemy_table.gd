class_name AlchemyTable

# Lookup: (catalyst_id, reactant_a_id, reactant_b_id) → AlchemyResult
# Reactant IDs are sorted alphabetically before lookup so order doesn't matter.
# Wildcard keys use "*" in one reactant position — checked after exact match fails.

static var _table: Dictionary = {}
static var _initialized: bool = false


static func lookup(catalyst: SpellData, r1: SpellData, r2: SpellData) -> AlchemyResult:
	if not _initialized:
		_build_table()
	var ids: Array = [r1.spell_id, r2.spell_id]
	ids.sort()
	var exact := "%s|%s|%s" % [catalyst.spell_id, ids[0], ids[1]]
	if _table.has(exact):
		return (_table[exact] as Callable).call()
	# Wildcard: first sorted reactant is known, second is anything
	var wk0 := "%s|%s|*" % [catalyst.spell_id, ids[0]]
	if _table.has(wk0):
		return (_table[wk0] as Callable).call()
	# Wildcard: second sorted reactant is known, first is anything
	var wk1 := "%s|*|%s" % [catalyst.spell_id, ids[1]]
	if _table.has(wk1):
		return (_table[wk1] as Callable).call()
	return null  # no recipe — caller should fire spells individually


static func _build_table() -> void:
	_initialized = true

	# fire_catalyst + fire_catalyst + frost → Steam (blind)
	# fire heats water → clouds of blinding steam
	_add("fire_catalyst", "fire_catalyst", "frost",
			func(): return AlchemyResult.success(_steam()))

	# fire_catalyst + ember + ember → Flame Burst (heavy fire damage)
	# two fire spells intensify under heat
	_add("fire_catalyst", "ember", "ember",
			func(): return AlchemyResult.success(_flame_burst()))

	# fire_catalyst + bone + venom → Curse (deep poison)
	# fire renders bone and poison into a festering curse
	_add("fire_catalyst", "bone", "venom",
			func(): return AlchemyResult.success(_curse()))

	# force_push + frost + frost → Ice Cube (high damage + freeze)
	# smashing two frosts together compresses into solid ice
	_add("force_push", "frost", "frost",
			func(): return AlchemyResult.success(_ice_cube()))

	# force_push + bone + frost → Soap (cleanses poison)
	# smashing bone + water produces a slippery cleansing compound
	_add("force_push", "bone", "frost",
			func(): return AlchemyResult.success(_soap()))

	# fire_catalyst + frost + venom → Fizzle (fire extinguished by water+poison mix)
	_add("fire_catalyst", "frost", "venom",
			func(): return AlchemyResult.fizzle())

	# force_push + lightning + * → Backfire (unstable electrical explosion)
	# wildcard: lightning + any spell under force detonates back at the caster
	var bf := func(): return AlchemyResult.backfire(8, [{"type": "stun", "turns": 1}])
	_table["force_push|lightning|*"] = bf
	_table["force_push|*|lightning"] = bf


static func _add(cat: String, r1: String, r2: String, fn: Callable) -> void:
	var ids: Array = [r1, r2]
	ids.sort()
	_table["%s|%s|%s" % [cat, ids[0], ids[1]]] = fn


# --- Alchemy spell definitions ---

static func _steam() -> SpellData:
	var s := SpellData.new("Steam", "St", ["steam"], Color(0.85, 0.85, 0.85), [], "", 0, 0,
			"A cloud of scalding steam blinds all enemies it envelops.")
	s.spell_id = "steam"
	s.spell_type = "alchemy"
	s.on_hit_effects = [{"type": "blind", "turns": 2}]
	return s


static func _flame_burst() -> SpellData:
	var s := SpellData.new("Flame Burst", "FB", ["fire"], Color(1.00, 0.30, 0.00), [], "", 8, 0,
			"An explosive concentration of fire.")
	s.spell_id = "flame_burst"
	s.spell_type = "alchemy"
	s.on_hit_effects = [{"type": "fire", "stacks": 5}]
	return s


static func _ice_cube() -> SpellData:
	var s := SpellData.new("Ice Cube", "IC", ["frost"], Color(0.60, 0.85, 1.00), [], "", 6, 0,
			"Encases the target in a solid block of ice.")
	s.spell_id = "ice_cube"
	s.spell_type = "alchemy"
	s.on_hit_effects = [{"type": "freeze"}]
	return s


static func _soap() -> SpellData:
	var s := SpellData.new("Soap", "Sp", ["water"], Color(0.95, 0.95, 1.00), [], "", 0, 0,
			"A slippery compound that washes away poison.")
	s.spell_id = "soap"
	s.spell_type = "alchemy"
	s.on_hit_effects = [{"type": "cleanse_poison"}]
	return s


static func _curse() -> SpellData:
	var s := SpellData.new("Curse", "Cu", ["death", "poison"], Color(0.50, 0.20, 0.70), [], "", 2, 0,
			"A festering curse that eats away at the target.")
	s.spell_id = "curse"
	s.spell_type = "alchemy"
	s.on_hit_effects = [{"type": "poison", "stacks": 5}]
	return s
