class_name WorldFactory
extends RefCounted
## Builds a brand-new world from authored content.


static func create_new(
	content: ContentLibrary, config: SimConfig, rng_seed: int, now_unix: float
) -> WorldState:
	var world: WorldState = WorldState.new()
	world.rng_seed = rng_seed
	world.last_seen_unix = now_unix
	world.tick = config.tick_for_hour(config.wake_hour)
	var first_era: EraDef = content.first_era()
	if first_era != null:
		world.era = first_era.id
		world.era_order = first_era.order
		world.era_started_tick = world.tick
	_add_starting_villagers(world, content)
	for key: StringName in content.starting_resources:
		world.resources[key] = content.starting_resources[key]
	var founded: JournalEntry = JournalEntry.new()
	founded.tick = world.tick
	founded.day = config.day_of(world.tick)
	founded.text = "The settlement was founded."
	founded.kind = &"settlement"
	world.journal.append(founded)
	return world


## Draws names, looks and traits from the content pools. Uses its own generator (derived from
## the world seed) so the simulation's rng sequence is not disturbed, and a seed always gives
## the same group.
static func _add_starting_villagers(world: WorldState, content: ContentLibrary) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash("starting_villagers_%d" % world.rng_seed)
	var count: int = mini(
		content.starting_villager_count,
		mini(content.villager_names.size(), content.villager_looks.size()),
	)
	var names: Array[int] = SimRandom.shuffled_indices(rng, content.villager_names.size())
	var looks: Array[int] = SimRandom.shuffled_indices(rng, content.villager_looks.size())
	for index: int in count:
		var villager: VillagerState = VillagerState.new()
		villager.display_name = content.villager_names[names[index]]
		villager.id = StringName(villager.display_name.to_lower())
		villager.look = content.villager_looks[looks[index]]
		var pool: Array[int] = SimRandom.shuffled_indices(rng, content.villager_traits.size())
		for pick: int in mini(content.traits_per_villager, pool.size()):
			villager.traits.append(content.villager_traits[pool[pick]])
		world.villagers.append(villager)
	_guarantee_traits(world, content, rng)


## Makes sure every guaranteed trait is held by somebody, giving it to a different villager each
## time and never taking a trait that is the only copy of another guaranteed one.
static func _guarantee_traits(
	world: WorldState, content: ContentLibrary, rng: RandomNumberGenerator
) -> void:
	var order: Array[int] = SimRandom.shuffled_indices(rng, world.villagers.size())
	for slot: int in content.guaranteed_traits.size():
		var wanted: StringName = content.guaranteed_traits[slot]
		if _holders(world, wanted) > 0 or slot >= order.size():
			continue
		var villager: VillagerState = world.villagers[order[slot]]
		for position: int in villager.traits.size():
			var held: StringName = villager.traits[position]
			var is_sole_copy: bool = content.guaranteed_traits.has(held) \
					and _holders(world, held) <= 1
			if not is_sole_copy:
				villager.traits[position] = wanted
				break


static func _holders(world: WorldState, trait_name: StringName) -> int:
	var holders: int = 0
	for villager: VillagerState in world.villagers:
		if villager.has_trait(trait_name):
			holders += 1
	return holders
