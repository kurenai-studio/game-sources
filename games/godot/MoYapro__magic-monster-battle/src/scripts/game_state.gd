extends Node

# Persistent game state passed between scenes.

var mages: Array[MageData] = []
var wands: Array[WandData] = []        # parallel to mages; null = no wand equipped
var backpack: Array[SpellData] = []
var backpack_wands: Array[WandData] = []
var pending_loot: Array[SpellData] = []
var pending_loot_wands: Array[WandData] = []
var current_biome: BiomeData = null
var is_initial_setup: bool = true
var battle_count: int = 0
var battle_count_by_biome: Dictionary = {}  # biome name -> int


func _ready() -> void:
	if mages.is_empty():
		_init_new_game()


func reset_to_new_game() -> void:
	mages.clear()
	wands.clear()
	backpack.clear()
	backpack_wands.clear()
	pending_loot.clear()
	pending_loot_wands.clear()
	current_biome = null
	is_initial_setup = true
	battle_count = 0
	battle_count_by_biome.clear()
	_init_new_game()


func reroll_spell_loot() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	pending_loot.clear()
	pending_loot_wands.clear()
	pending_loot_wands.append(WandGenerator.generate(rng))
	var all_body := SpellRegistry.all_body_spells()
	for _i in 4:
		pending_loot.append(all_body[rng.randi_range(0, all_body.size() - 1)])
	pending_loot.append(WandGenerator._pick_tip_spell(rng))


func _init_new_game() -> void:
	mages = [
		MageData.new("Lyra", 30),
		MageData.new("Eron", 30),
		MageData.new("Vael", 30),
	]
	wands.clear()
	for _i in mages.size():
		wands.append(null)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for _i in 4:
		pending_loot_wands.append(WandGenerator.generate_starter(rng))
