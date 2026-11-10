extends McpTestSuite
## Every new world starts with its own three villagers, drawn from the content pools by seed.


const SEED_COUNT: int = 200


func suite_name() -> String:
	return "sim_traits"


func _group(rng_seed: int) -> Array[VillagerState]:
	return SimFixture.new_sim(rng_seed).world.villagers


func test_a_seed_always_gives_the_same_group() -> void:
	for rng_seed: int in [1, 2, 99, 12345]:
		assert_eq(_describe(_group(rng_seed)), _describe(_group(rng_seed)))


func test_different_seeds_give_different_groups() -> void:
	var seen: Dictionary = {}
	for rng_seed: int in SEED_COUNT:
		seen[_describe(_group(rng_seed))] = true
	assert_gt(seen.size(), SEED_COUNT / 2, "Groups should vary a lot between seeds")


func test_villagers_are_distinct_within_a_group() -> void:
	for rng_seed: int in SEED_COUNT:
		var names: Dictionary = {}
		var looks: Dictionary = {}
		for villager: VillagerState in _group(rng_seed):
			names[villager.id] = true
			looks[villager.look] = true
			assert_eq(villager.traits.size(), 2, "seed %d: two traits" % rng_seed)
			assert_ne(villager.traits[0], villager.traits[1], "seed %d: distinct traits" % rng_seed)
		assert_eq(names.size(), 3, "seed %d: names are unique" % rng_seed)
		assert_eq(looks.size(), 3, "seed %d: looks are unique" % rng_seed)


func test_someone_is_always_curious_so_the_first_chain_can_start() -> void:
	for rng_seed: int in SEED_COUNT:
		var curious: int = 0
		for villager: VillagerState in _group(rng_seed):
			if villager.has_trait(VillagerState.TRAIT_CURIOUS):
				curious += 1
		assert_gt(curious, 0, "seed %d has nobody curious" % rng_seed)


func test_traits_vary_across_the_pool() -> void:
	var counts: Dictionary = {}
	for rng_seed: int in SEED_COUNT:
		for villager: VillagerState in _group(rng_seed):
			for trait_name: StringName in villager.traits:
				counts[trait_name] = counts.get(trait_name, 0) + 1
	for trait_name: StringName in SimFixture.load_content().villager_traits:
		assert_gt(counts.get(trait_name, 0), 0, "%s never appears" % trait_name)


func test_guaranteeing_a_trait_never_breaks_another_guarantee() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	content.guaranteed_traits.assign([
		VillagerState.TRAIT_CURIOUS, VillagerState.TRAIT_SOCIAL, VillagerState.TRAIT_INDUSTRIOUS,
	])
	var config: SimConfig = SimFixture.load_config()
	for rng_seed: int in SEED_COUNT:
		var world: WorldState = WorldFactory.create_new(content, config, rng_seed, 0.0)
		for wanted: StringName in content.guaranteed_traits:
			var held: bool = false
			for villager: VillagerState in world.villagers:
				held = held or villager.has_trait(wanted)
			assert_true(held, "seed %d lost guaranteed trait %s" % [rng_seed, wanted])


func test_drawing_the_group_does_not_change_the_simulation_rng() -> void:
	var first: Simulation = SimFixture.new_sim(5)
	var second: Simulation = SimFixture.new_sim(5)
	assert_eq(first.rng.randi(), second.rng.randi())


func test_content_validation_flags_a_pool_that_is_too_small() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	content.villager_names.assign(["Only"])
	assert_gt(content.validate().size(), 0)


func _describe(group: Array[VillagerState]) -> String:
	var parts: PackedStringArray = PackedStringArray()
	for villager: VillagerState in group:
		parts.append("%s/%s/%s" % [villager.id, villager.look, ",".join(villager.traits)])
	return " ".join(parts)
