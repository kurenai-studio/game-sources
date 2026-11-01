extends GutTest

# Integration test: verifies that LootScreen._try_fuse_wand correctly fuses a
# linear alchemy recipe and stores the result spell in the wand.

var _saved_wands: Array[WandData] = []
var _saved_mages: Array[MageData] = []


func before_each() -> void:
	_saved_wands = GameState.wands.duplicate()
	_saved_mages = GameState.mages.duplicate()
	GameState.wands.clear()
	GameState.mages.clear()


func after_each() -> void:
	GameState.wands = _saved_wands
	GameState.mages = _saved_mages


# --- helpers (mirrored from test_alchemy_fuser for self-containment) ---

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


func _tip() -> SpellData:
	var s := SpellData.new("Single", "Si", ["tip"], Color.WHITE, [], "", 0, 0, "")
	s.spell_id = "single"
	s.spell_type = "tip"
	return s


# Linear chain: s0 → s1 → s2 → tip
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


# Parallel branches: s0, s1, s2 all → tip directly
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


# --- integration tests ---

func test_loot_screen_fuses_linear_recipe_and_places_spell_in_wand() -> void:
	var wand := _linear_wand(
			_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	GameState.wands.append(wand)
	GameState.mages.append(MageData.new("Test Mage", 30))

	var screen: Node = load("res://scenes/loot/loot_screen.tscn").instantiate()
	screen.call("_try_fuse_wand", 0)
	screen.free()

	assert_not_null(wand.get_slot("s0").spell,
			"catalyst slot should have the fused spell after fusion")
	assert_eq(wand.get_slot("s0").spell.spell_id, "flame_burst")


func test_loot_screen_clears_reactant_slots_after_fusion() -> void:
	var wand := _linear_wand(
			_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	GameState.wands.append(wand)
	GameState.mages.append(MageData.new("Test Mage", 30))

	var screen: Node = load("res://scenes/loot/loot_screen.tscn").instantiate()
	screen.call("_try_fuse_wand", 0)
	screen.free()

	assert_null(wand.get_slot("s1").spell, "first reactant slot should be cleared")
	assert_null(wand.get_slot("s2").spell, "second reactant slot should be cleared")


func test_loot_screen_does_not_fuse_parallel_branches() -> void:
	var wand := _parallel_wand(
			_catalyst("fire_catalyst"), _projectile("ember"), _projectile("ember"))
	GameState.wands.append(wand)
	GameState.mages.append(MageData.new("Test Mage", 30))

	var screen: Node = load("res://scenes/loot/loot_screen.tscn").instantiate()
	screen.call("_try_fuse_wand", 0)
	screen.free()

	assert_eq(wand.get_slot("s0").spell.spell_id, "fire_catalyst",
			"parallel slots must not be consumed — catalyst slot unchanged")
	assert_not_null(wand.get_slot("s1").spell, "parallel ember slot should be untouched")
	assert_not_null(wand.get_slot("s2").spell, "parallel ember slot should be untouched")
