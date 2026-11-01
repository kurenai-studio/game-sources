extends GutTest


# --- helpers ---

func _spell(id: String, type: String = "projectile") -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", 0, 0, "")
	s.spell_id = id
	s.spell_type = type
	return s


func _catalyst(id: String) -> SpellData:
	return _spell(id, "catalyst")


func _lookup(cat_id: String, r1_id: String, r2_id: String) -> AlchemyResult:
	return AlchemyTable.lookup(_catalyst(cat_id), _spell(r1_id), _spell(r2_id))


# --- exact matches ---

func test_fire_catalyst_plus_fire_catalyst_plus_frost_yields_steam() -> void:
	var result := _lookup("fire_catalyst", "fire_catalyst", "frost")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "steam")


func test_fire_catalyst_plus_ember_plus_ember_yields_flame_burst() -> void:
	var result := _lookup("fire_catalyst", "ember", "ember")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "flame_burst")


func test_fire_catalyst_plus_bone_plus_venom_yields_curse() -> void:
	var result := _lookup("fire_catalyst", "bone", "venom")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "curse")


func test_force_push_plus_frost_plus_frost_yields_ice_cube() -> void:
	var result := _lookup("force_push", "frost", "frost")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "ice_cube")


func test_force_push_plus_bone_plus_frost_yields_soap() -> void:
	var result := _lookup("force_push", "bone", "frost")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "soap")


# --- reactant order does not matter ---

func test_reactant_order_is_ignored_bone_frost() -> void:
	var a := _lookup("force_push", "bone", "frost")
	var b := _lookup("force_push", "frost", "bone")
	assert_not_null(a)
	assert_not_null(b)
	assert_eq(a.spell.spell_id, b.spell.spell_id)


func test_reactant_order_is_ignored_bone_venom() -> void:
	var a := _lookup("fire_catalyst", "bone", "venom")
	var b := _lookup("fire_catalyst", "venom", "bone")
	assert_not_null(a)
	assert_not_null(b)
	assert_eq(a.spell.spell_id, b.spell.spell_id)


# --- fizzle ---

func test_fire_catalyst_plus_frost_plus_venom_fizzles() -> void:
	var result := _lookup("fire_catalyst", "frost", "venom")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.FIZZLE)


# --- backfire (wildcard) ---

func test_force_push_plus_lightning_plus_anything_backfires() -> void:
	var result := _lookup("force_push", "lightning", "frost")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.BACKFIRE)
	assert_gt(result.backfire_damage, 0)


func test_force_push_plus_anything_plus_lightning_also_backfires() -> void:
	var result := _lookup("force_push", "ember", "lightning")
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.BACKFIRE)


# --- no recipe ---

func test_unknown_combination_returns_null() -> void:
	var result := _lookup("fire_catalyst", "frost", "frost")
	assert_null(result, "no recipe for fire_catalyst + frost + frost should return null")


func test_wrong_catalyst_returns_null() -> void:
	var result := _lookup("ember", "bone", "venom")
	assert_null(result, "ember is not a valid catalyst — should return null")


# --- result spell properties ---

func test_steam_has_blind_effect() -> void:
	var result := _lookup("fire_catalyst", "fire_catalyst", "frost")
	assert_eq(result.spell.spell_type, "alchemy")
	var has_blind := result.spell.on_hit_effects.any(
			func(e: Dictionary) -> bool: return e.get("type") == "blind")
	assert_true(has_blind, "steam should apply blind")


func test_flame_burst_has_fire_effect() -> void:
	var result := _lookup("fire_catalyst", "ember", "ember")
	assert_eq(result.spell.spell_type, "alchemy")
	var has_fire := result.spell.on_hit_effects.any(
			func(e: Dictionary) -> bool: return e.get("type") == "fire")
	assert_true(has_fire, "flame_burst should apply fire stacks")
