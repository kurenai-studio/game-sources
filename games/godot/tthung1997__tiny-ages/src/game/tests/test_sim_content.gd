extends McpTestSuite
## Authored content is consistent, and new worlds start the way the design says.


func suite_name() -> String:
	return "sim_content"


func test_content_validates() -> void:
	var problems: PackedStringArray = SimFixture.load_content().validate()
	assert_eq(problems.size(), 0, "Content problems: %s" % "; ".join(problems))


func test_validation_catches_broken_references() -> void:
	var content: ContentLibrary = SimFixture.load_content().duplicate(true)
	var broken: SimEffect = SimEffect.new()
	broken.kind = SimEffect.Kind.START_BUILD
	broken.key = &"does_not_exist"
	content.events[0].effects.append(broken)
	assert_gt(content.validate().size(), 0)


func test_starting_group_is_drawn_from_the_content_pools() -> void:
	var content: ContentLibrary = SimFixture.load_content()
	var sim: Simulation = SimFixture.new_sim()
	assert_eq(sim.world.villagers.size(), content.starting_villager_count)
	for villager: VillagerState in sim.world.villagers:
		assert_true(content.villager_names.has(villager.display_name))
		assert_true(content.villager_looks.has(villager.look))
		assert_eq(villager.traits.size(), content.traits_per_villager)


func test_new_world_starts_at_dawn_with_a_founding_entry() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var config: SimConfig = sim.config
	assert_eq(config.hour_of(sim.world.tick), config.wake_hour)
	assert_eq(sim.world.journal.size(), 1)
	assert_eq(sim.world.resource_amount(&"wood"), 2)
	assert_eq(sim.world.villagers.size(), 3)
