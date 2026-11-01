extends GutTest

# Tests that AlchemyFuser.try_fuse only triggers on consecutive slot chains (A→B→C),
# not on parallel branches where slots independently point to the same next slot.


# --- wand builders ---

# Linear chain: s0 → s1 → s2 → tip
# Spells assigned left-to-right to s0, s1, s2 respectively.
func _linear_wand(sp0: SpellData, sp1: SpellData, sp2: SpellData) -> WandData:
	var s0 := SpellSlotData.new("s0", 0, 0, "s1")
	var s1 := SpellSlotData.new("s1", 1, 0, "s2")
	var s2 := SpellSlotData.new("s2", 2, 0, "tip")
	var tip := SpellSlotData.new("tip", 3, 0, "")
	s0.spell = sp0
	s1.spell = sp1
	s2.spell = sp2
	tip.spell = _tip()
	return WandData.new([s0, s1, s2, tip])


# Parallel branches: s0, s1, s2 all point directly to tip (no consecutive triple).
func _parallel_wand(sp0: SpellData, sp1: SpellData, sp2: SpellData) -> WandData:
	var s0 := SpellSlotData.new("s0", 0, 0, "tip")
	var s1 := SpellSlotData.new("s1", 0, 1, "tip")
	var s2 := SpellSlotData.new("s2", 0, 2, "tip")
	var tip := SpellSlotData.new("tip", 1, 1, "")
	s0.spell = sp0
	s1.spell = sp1
	s2.spell = sp2
	tip.spell = _tip()
	return WandData.new([s0, s1, s2, tip])


# Fan-in: s0 and s1 both point to s2, s2 points to tip.
# s0→s2→tip is a 2-slot chain (no third), s1→s2→tip same — no valid triple.
func _fanin_wand(sp0: SpellData, sp1: SpellData, sp2: SpellData) -> WandData:
	var s0 := SpellSlotData.new("s0", 0, 0, "s2")
	var s1 := SpellSlotData.new("s1", 0, 1, "s2")
	var s2 := SpellSlotData.new("s2", 1, 0, "tip")
	var tip := SpellSlotData.new("tip", 2, 0, "")
	s0.spell = sp0
	s1.spell = sp1
	s2.spell = sp2
	tip.spell = _tip()
	return WandData.new([s0, s1, s2, tip])


func _tip() -> SpellData:
	var s := SpellData.new("Single", "Si", ["tip"], Color.WHITE, [], "", 0, 0, "")
	s.spell_id = "single"
	s.spell_type = "tip"
	return s


func _projectile(id: String) -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", 0, 0, "")
	s.spell_id = id
	s.spell_type = "projectile"
	return s


func _catalyst(id: String) -> SpellData:
	var s := SpellData.new(id, id, [], Color.WHITE, [], "", 0, 0, "")
	s.spell_id = id
	s.spell_type = "catalyst"
	return s


# --- linear chain — should fuse ---

func test_linear_chain_with_valid_recipe_fuses() -> void:
	var wand := _linear_wand(_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_not_null(result, "linear chain with valid recipe should fuse")
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "flame_burst")


func test_linear_chain_catalyst_slot_receives_result_spell() -> void:
	var wand := _linear_wand(_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	AlchemyFuser.try_fuse(wand)
	assert_eq(wand.get_slot("s0").spell.spell_id, "flame_burst",
			"catalyst slot (s0) should hold the fused spell")


func test_linear_chain_reactant_slots_are_cleared() -> void:
	var wand := _linear_wand(_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	AlchemyFuser.try_fuse(wand)
	assert_null(wand.get_slot("s1").spell, "reactant slot s1 should be cleared")
	assert_null(wand.get_slot("s2").spell, "reactant slot s2 should be cleared")


func test_linear_chain_catalyst_in_middle_position_fuses() -> void:
	var wand := _linear_wand(_projectile("ember"), _catalyst("fire_catalyst"), _projectile("ember"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "flame_burst")
	assert_eq(wand.get_slot("s1").spell.spell_id, "flame_burst",
			"middle catalyst slot should receive the result")


func test_linear_chain_catalyst_at_end_position_fuses() -> void:
	var wand := _linear_wand(_projectile("ember"), _projectile("ember"), _catalyst("fire_catalyst"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.SUCCESS)
	assert_eq(result.spell.spell_id, "flame_burst")


func test_linear_chain_fizzle_clears_all_three_slots() -> void:
	# fire_catalyst + frost + venom → fizzle
	var wand := _linear_wand(_catalyst("fire_catalyst"), _projectile("frost"), _projectile("venom"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.FIZZLE)
	assert_null(wand.get_slot("s0").spell)
	assert_null(wand.get_slot("s1").spell)
	assert_null(wand.get_slot("s2").spell)


func test_linear_chain_backfire_clears_all_three_slots() -> void:
	# force_push + lightning + frost → backfire (wildcard)
	var wand := _linear_wand(_catalyst("force_push"), _projectile("lightning"), _projectile("frost"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_not_null(result)
	assert_eq(result.outcome, AlchemyResult.Outcome.BACKFIRE)
	assert_null(wand.get_slot("s0").spell)
	assert_null(wand.get_slot("s1").spell)
	assert_null(wand.get_slot("s2").spell)


func test_linear_chain_no_recipe_returns_null_and_leaves_slots_intact() -> void:
	# fire_catalyst + frost + frost — no recipe
	var wand := _linear_wand(_catalyst("fire_catalyst"), _projectile("frost"), _projectile("frost"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_null(result, "unknown recipe should return null")
	assert_not_null(wand.get_slot("s0").spell, "slots should be untouched on null result")
	assert_not_null(wand.get_slot("s1").spell)
	assert_not_null(wand.get_slot("s2").spell)


# --- parallel branches — must NOT fuse ---

func test_parallel_branches_do_not_fuse() -> void:
	# All three slots point directly to tip; no consecutive chain exists.
	var wand := _parallel_wand(
			_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_null(result, "parallel slots (all → tip) must not trigger alchemy")


func test_parallel_branches_leave_slots_untouched() -> void:
	var wand := _parallel_wand(
			_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	AlchemyFuser.try_fuse(wand)
	assert_not_null(wand.get_slot("s0").spell)
	assert_not_null(wand.get_slot("s1").spell)
	assert_not_null(wand.get_slot("s2").spell)


func test_fanin_topology_does_not_fuse() -> void:
	# s0→s2, s1→s2, s2→tip: no slot-triple forms a full A→B→C chain
	var wand := _fanin_wand(
			_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_null(result, "fan-in topology (s0→s2, s1→s2) must not trigger alchemy")


# --- empty / incomplete wand ---

func test_wand_with_only_two_body_slots_does_not_fuse() -> void:
	var s0 := SpellSlotData.new("s0", 0, 0, "tip")
	var tip := SpellSlotData.new("tip", 1, 0, "")
	s0.spell = _catalyst("fire_catalyst")
	tip.spell = _tip()
	var wand := WandData.new([s0, tip])
	var result := AlchemyFuser.try_fuse(wand)
	assert_null(result)


func test_wand_with_empty_slot_in_chain_does_not_fuse() -> void:
	# s0 → s1 (empty) → s2 → tip: gap in chain, no fusion
	var wand := _linear_wand(_catalyst("fire_catalyst"), null, _projectile("ember"))
	var result := AlchemyFuser.try_fuse(wand)
	assert_null(result)
