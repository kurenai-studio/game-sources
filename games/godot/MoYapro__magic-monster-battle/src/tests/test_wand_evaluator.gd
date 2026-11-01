extends GutTest


# --- helpers ---

func _projectile(id: String, damage: int, effects: Array[Dictionary] = []) -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", damage, 1)
	s.spell_id = id
	s.spell_type = "projectile"
	s.on_hit_effects = effects
	return s


func _catalyst(id: String, damage: int = 1) -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", damage, 1)
	s.spell_id = id
	s.spell_type = "catalyst"
	return s


func _modifier(effect: Dictionary) -> SpellData:
	var s := SpellData.new("mod", "M", [], Color.WHITE, [], "", 0, 1)
	s.spell_id = "mod"
	s.spell_type = "modifier"
	s.modifier_effect = effect
	return s


# --- basic firing ---

func test_single_projectile_emits_one_projectile_event() -> void:
	var events := WandEvaluator.evaluate([_projectile("p", 5)])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[0] as CastEvent).total_damage, 5)


func test_two_projectiles_emit_two_events() -> void:
	var events := WandEvaluator.evaluate([_projectile("a", 3), _projectile("b", 4)])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[1] as CastEvent).type, CastEvent.Type.PROJECTILE)


func test_solo_catalyst_fires_as_projectile() -> void:
	var events := WandEvaluator.evaluate([_catalyst("cat", 3)])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).type, CastEvent.Type.PROJECTILE)
	assert_eq((events[0] as CastEvent).total_damage, 3)


func test_catalyst_with_reactants_fires_all_individually() -> void:
	# Fusion happens at loot-screen time, not at cast time.
	# A catalyst sitting next to reactants in the wand fires as three separate projectiles.
	var events := WandEvaluator.evaluate([
		_catalyst("force_push", 3), _projectile("frost", 2), _projectile("fire", 2)
	])
	assert_eq(events.size(), 3)
	for ev in events:
		assert_eq((ev as CastEvent).type, CastEvent.Type.PROJECTILE)


# --- modifiers ---

func test_modifier_doubles_damage_of_next_projectile() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}), _projectile("p", 5)
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 10)


func test_modifier_adds_on_hit_effect_to_next_projectile() -> void:
	var extra := {"type": "fire", "stacks": 3}
	var events := WandEvaluator.evaluate([
		_modifier({"type": "add_on_hit", "effect": extra}), _projectile("p", 5)
	])
	assert_eq(events.size(), 1)
	assert_true((events[0] as CastEvent).on_hit_effects.has(extra))


func test_modifier_only_affects_next_spell_not_all() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 3}),
		_projectile("a", 4),
		_projectile("b", 4),
	])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).total_damage, 12)
	assert_eq((events[1] as CastEvent).total_damage, 4)


func test_modifier_applies_to_catalyst_firing_as_projectile() -> void:
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}), _catalyst("cat", 3)
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 6)


# --- multi-cast (consecutive identical spells) ---

func test_two_identical_spells_merge_into_one_event() -> void:
	# 5^2 = 25
	var events := WandEvaluator.evaluate([_projectile("frost", 5), _projectile("frost", 5)])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 25)


func test_three_identical_spells_cube_damage() -> void:
	# 3^3 = 27
	var events := WandEvaluator.evaluate([
		_projectile("frost", 3), _projectile("frost", 3), _projectile("frost", 3)
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 27)


func test_different_spells_do_not_merge() -> void:
	var events := WandEvaluator.evaluate([_projectile("frost", 5), _projectile("fire", 5)])
	assert_eq(events.size(), 2)


func test_modifier_applies_once_to_merged_multi_cast() -> void:
	# 3^3 = 27, then damage_mult x2 → 54
	var events := WandEvaluator.evaluate([
		_modifier({"type": "damage_mult", "factor": 2}),
		_projectile("frost", 3), _projectile("frost", 3), _projectile("frost", 3),
	])
	assert_eq(events.size(), 1)
	assert_eq((events[0] as CastEvent).total_damage, 54)


func test_two_shields_multiply_amount() -> void:
	var shield := SpellShield.create()
	var events := WandEvaluator.evaluate([shield, shield])
	assert_eq(events.size(), 1)
	var amount: int = (events[0] as CastEvent).on_hit_effects[0].get("amount", 0)
	assert_eq(amount, 100)  # 10^2


func test_three_shields_cube_amount() -> void:
	var shield := SpellShield.create()
	var events := WandEvaluator.evaluate([shield, shield, shield])
	assert_eq(events.size(), 1)
	var amount: int = (events[0] as CastEvent).on_hit_effects[0].get("amount", 0)
	assert_eq(amount, 1000)  # 10^3


func test_single_shield_amount_unchanged() -> void:
	var shield := SpellShield.create()
	var events := WandEvaluator.evaluate([shield])
	assert_eq(events.size(), 1)
	var amount: int = (events[0] as CastEvent).on_hit_effects[0].get("amount", 0)
	assert_eq(amount, 10)


func test_modifier_between_identical_spells_breaks_merge() -> void:
	# frost, modifier, frost → two separate events; modifier applies only to second frost
	var events := WandEvaluator.evaluate([
		_projectile("frost", 5),
		_modifier({"type": "damage_mult", "factor": 3}),
		_projectile("frost", 5),
	])
	assert_eq(events.size(), 2)
	assert_eq((events[0] as CastEvent).total_damage, 5)
	assert_eq((events[1] as CastEvent).total_damage, 15)
