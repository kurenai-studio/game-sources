class_name BiomesData

# Layer 1 — starters (always available):
#   Desert, Tundra, Forest, Swamp, Mountain
#
# RPS cycle: Fire(Desert) > Ice(Tundra) > Nature(Forest) > Poison(Swamp) > Earth(Mountain) > Fire
#
# Layer 2 — unlocked by layer 1 boss:
#   Desert     → Pyramids, Coast
#   Tundra     → Glacial Temple, Frozen Shipwreck
#   Forest     → Jungle, Graveyard
#   Swamp      → Ruins, Coast (shared)
#   Mountain   → Cave, Volcano
#
# Layer 3 — unlocked by layer 2 boss (any one suffices):
#   Hell        ← Graveyard | Ruins | Volcano
#   Astral Plane← Glacial Temple | Pyramids | Jungle
#   Underwater  ← Coast | Frozen Shipwreck | Cave
#
# The Source — unlocked after all three layer 3 bosses

static var _all: Array[BiomeData] = []


static func all() -> Array[BiomeData]:
	if _all.is_empty():
		_all = _build()
	return _all


static func by_layer(layer: int) -> Array[BiomeData]:
	return all().filter(func(b: BiomeData) -> bool: return b.layer == layer)


static func unlocked(battle_counts: Dictionary) -> Array[BiomeData]:
	return all().filter(func(b: BiomeData) -> bool:
		if b.layer == 1:
			return true
		var beaten := func(n: String) -> bool: return battle_counts.get(n, 0) >= 10
		if b.name == "The Source":
			return b.unlocked_by.all(beaten)
		return b.unlocked_by.any(beaten)
	)


static func get_by_name(biome_name: String) -> BiomeData:
	for biome: BiomeData in all():
		if biome.name == biome_name:
			return biome
	return null


static func neighbors(biome: BiomeData) -> Array[BiomeData]:
	return all().filter(func(b: BiomeData) -> bool: return b != biome)


static func stray_pool(biome: BiomeData) -> Array[BiomeData]:
	var result: Array[BiomeData] = []
	for b: BiomeData in all():
		if b == biome:
			continue
		if BiomeData.stray_weight(biome, b) > 0.0:
			result.append(b)
	return result


static func _build() -> Array[BiomeData]:
	# --- Layer 1 ---
	var desert   := BiomeData.new("Desert",   "The heat breaks minds before bodies.",  Color(0.85, 0.60, 0.15), Vector2i(1, 0), 1, [])
	var tundra   := BiomeData.new("Tundra",   "Cold enough to numb courage.",          Color(0.45, 0.65, 0.85), Vector2i(9, 0), 1, [])
	var forest   := BiomeData.new("Forest",   "Ancient trees hide ancient dangers.",   Color(0.15, 0.55, 0.20), Vector2i(4, 1), 1, [])
	var swamp    := BiomeData.new("Swamp",    "Nothing enters here and leaves clean.", Color(0.25, 0.50, 0.30), Vector2i(3, 3), 1, [])
	var mountain := BiomeData.new("Mountain", "The summit demands a toll.",            Color(0.55, 0.55, 0.60), Vector2i(7, 1), 1, [])

	# --- Layer 2 ---
	var pyramids         := BiomeData.new("Pyramids",          "The dead do not sleep here.",               Color(0.80, 0.70, 0.30), Vector2i(1, 2), 2, ["Desert"])
	var coast            := BiomeData.new("Coast",             "The sea takes what it wants.",              Color(0.20, 0.55, 0.75), Vector2i(3, 1), 2, ["Desert", "Swamp"])
	var glacial_temple   := BiomeData.new("Glacial Temple",    "Faith, frozen solid.",                      Color(0.60, 0.80, 0.95), Vector2i(9, 2), 2, ["Tundra"])
	var frozen_shipwreck := BiomeData.new("Frozen Shipwreck",  "No one remembers what they were carrying.", Color(0.40, 0.55, 0.75), Vector2i(8, 1), 2, ["Tundra"])
	var jungle           := BiomeData.new("Jungle",            "Life here does not ask permission.",        Color(0.10, 0.45, 0.15), Vector2i(4, 3), 2, ["Forest"])
	var graveyard        := BiomeData.new("Graveyard",         "The names on the stones are warnings.",     Color(0.35, 0.35, 0.40), Vector2i(3, 4), 2, ["Forest", "Swamp"])
	var ruins            := BiomeData.new("Ruins",             "Something still walks these halls.",        Color(0.55, 0.45, 0.35), Vector2i(7, 6), 2, ["Swamp"])
	var cave             := BiomeData.new("Cave",              "Darkness is the least of your fears.",      Color(0.30, 0.25, 0.40), Vector2i(5, 5), 2, ["Mountain"])
	var volcano          := BiomeData.new("Volcano",           "The earth itself is your enemy.",           Color(0.85, 0.25, 0.10), Vector2i(1, 1), 2, ["Mountain"])

	# --- Layer 3 ---
	var hell       := BiomeData.new("Hell",         "Everything here was once alive.",          Color(0.70, 0.10, 0.05), Vector2i(2, 8), 3, ["Graveyard", "Ruins", "Volcano"])
	var astral     := BiomeData.new("Astral Plane", "Even light casts a shadow here.",          Color(0.85, 0.85, 1.00), Vector2i(6, 8), 3, ["Glacial Temple", "Pyramids", "Jungle"])
	var underwater := BiomeData.new("Underwater",   "Pressure is the least of your problems.", Color(0.05, 0.25, 0.60), Vector2i(5, 7), 3, ["Coast", "Frozen Shipwreck", "Cave"])

	# --- The Source ---
	var the_source := BiomeData.new("The Source", "All things come from here. All things end here.", Color(0.50, 0.00, 0.50), Vector2i(5, 10), 4, ["Hell", "Astral Plane", "Underwater"])

	# --- Monster pools ---
	desert.monster_pool          = [Goblin, Scorpion, ShieldOgre]
	tundra.monster_pool          = [Skeleton, FrostMage, Troll]
	forest.monster_pool          = [Goblin, Treant, ShadowPanther]
	swamp.monster_pool           = [BogShambler, Witch, Troll]
	mountain.monster_pool        = [ShieldOgre, StoneGiant, WarDrummer]

	pyramids.monster_pool        = [Skeleton, Scorpion, CursedKnight, BoneCaller]
	coast.monster_pool           = [Goblin, Witch, ShadowPanther, WraithBlade]
	glacial_temple.monster_pool  = [FrostMage, Skeleton, WraithBlade, Troll]
	frozen_shipwreck.monster_pool = [Skeleton, FrostMage, Troll, BogShambler]
	jungle.monster_pool          = [Treant, GroveTender, ShadowPanther, BogShambler]
	graveyard.monster_pool       = [Skeleton, WraithBlade, Banshee, CursedKnight, BoneCaller]
	ruins.monster_pool           = [CursedKnight, BoneCaller, Banshee, FallenPaladin, WarDrummer]
	cave.monster_pool            = [CaveSpider, Troll, ShieldOgre, WraithBlade, StoneGiant]
	volcano.monster_pool         = [FireElemental, StoneGiant, WarDrummer, ShieldOgre, Troll]

	hell.monster_pool            = [CursedKnight, FallenPaladin, FireElemental, BoneCaller, Banshee]
	astral.monster_pool          = [FallenPaladin, FrostMage, GroveTender, Treant, Banshee]
	underwater.monster_pool      = [BogShambler, CaveSpider, Witch, ShadowPanther, StoneGiant]

	the_source.monster_pool      = [Goblin, Skeleton, Scorpion, Troll, ShieldOgre, FireElemental,
									WarDrummer, Treant, WraithBlade, ShadowPanther, GroveTender,
									StoneGiant, FrostMage, Banshee, Witch, BogShambler, CaveSpider,
									CursedKnight, BoneCaller, FallenPaladin]

	# --- Obstacle pools ---
	desert.obstacle_pool         = [Stone, Boulder, Barrel, Cactus, SandDune, Obelisk, FossilizedBone]
	tundra.obstacle_pool         = [Stone, Boulder, Log, IceWall, FrozenLog, GlacierChunk]
	forest.obstacle_pool         = [ObstacleTree, Log, Stone, Thornbush, AncientStump, MushroomCircle, BramblePatch]
	swamp.obstacle_pool          = [Log, ObstacleTree, Barrel, Mudpit, RottedStump, BogPillar, SporeVent]
	mountain.obstacle_pool       = [Boulder, Stone, Monolith, IceBlock, Stalagmite, SnowDrift]

	pyramids.obstacle_pool       = [Stone, Boulder, Obelisk, Sarcophagus, Monolith, Altar, FossilizedBone, AncientPillar]
	coast.obstacle_pool          = [Log, Barrel, Stone, Boulder, RottedStump, Mudpit, TidePool]
	glacial_temple.obstacle_pool = [IceBlock, IceWall, GlacierChunk, Stone, Monolith, Altar]
	frozen_shipwreck.obstacle_pool = [FrozenLog, IceBlock, Barrel, Log, BonePile, GlacierChunk]
	jungle.obstacle_pool         = [ObstacleTree, Log, Thornbush, AncientStump, MushroomCircle, Mudpit, BramblePatch, WebCocoon, SporeVent]
	graveyard.obstacle_pool      = [Stone, Monolith, BonePile, Sarcophagus, BrokenPillar, Altar, Pyre, CrumblingWall]
	ruins.obstacle_pool          = [Monolith, Stone, Barrel, BrokenPillar, Altar, Sarcophagus, AncientPillar, CrumblingWall]
	cave.obstacle_pool           = [Stone, Boulder, Monolith, StalactitePillar, CrystalFormation, BonePile, WebCocoon]
	volcano.obstacle_pool        = [Stone, Boulder, LavaRock, ObsidianSpike, AshPile, Barrel, Pyre]

	hell.obstacle_pool           = [LavaRock, ObsidianSpike, AshPile, BonePile, Altar, Sarcophagus, Pyre]
	astral.obstacle_pool         = [Stone, Monolith, CrystalFormation, IceBlock, Altar, Obelisk, AncientPillar]
	underwater.obstacle_pool     = [Stone, Boulder, CrystalFormation, StalactitePillar, BonePile, Mudpit, TidePool]

	the_source.obstacle_pool     = [Stone, Boulder, Monolith, CrystalFormation, Altar, Sarcophagus,
									LavaRock, IceBlock, BonePile, ObstacleTree]

	return [desert, tundra, forest, swamp, mountain,
			pyramids, coast, glacial_temple, frozen_shipwreck, jungle, graveyard, ruins, cave, volcano,
			hell, astral, underwater,
			the_source]
