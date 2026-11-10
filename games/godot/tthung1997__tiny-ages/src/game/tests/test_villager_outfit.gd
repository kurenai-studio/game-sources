extends McpTestSuite
## What the villagers wear (docs/ages.md B8): the outfit follows the world, every outfit has art for
## every look, and a look or outfit without art falls back instead of failing.


func suite_name() -> String:
	return "villager_outfit"


func _world(era_order: int, earned: Array[StringName] = []) -> WorldState:
	var world: WorldState = WorldState.new()
	world.era_order = era_order
	for key: StringName in earned:
		world.achievements.append(key)
	return world


func test_each_world_wears_what_it_has_earned() -> void:
	var cases: Array = [
		[0, [], VillagerOutfit.FUR],
		[1, [], VillagerOutfit.FIELD],
		[1, [&"woven_cloth"], VillagerOutfit.WOVEN],
		[2, [], VillagerOutfit.TOWN],
		[2, [&"woven_cloth"], VillagerOutfit.TOWN],
		[2, [&"first_casting"], VillagerOutfit.BRONZE],
		[2, [&"woven_cloth", &"first_casting"], VillagerOutfit.BRONZE],
		[3, [], VillagerOutfit.CHECKED],
		[3, [&"first_casting"], VillagerOutfit.CHECKED],
		[3, [&"first_bloom"], VillagerOutfit.IRON],
		[4, [], VillagerOutfit.LINEN],
		[4, [&"first_bloom"], VillagerOutfit.LINEN],
		[4, [&"paved_streets"], VillagerOutfit.LINEN],
		[4, [&"the_square"], VillagerOutfit.CIVIC],
	]
	for item: Array in cases:
		var earned: Array[StringName] = []
		earned.assign(item[1])
		var world: WorldState = _world(item[0], earned)
		assert_eq(VillagerOutfit.for_world(world), item[2], "age %d with %s" % [item[0], earned])


func test_an_achievement_means_nothing_before_its_age() -> void:
	assert_eq(VillagerOutfit.for_world(_world(0, [&"woven_cloth"])), VillagerOutfit.FUR)
	assert_eq(VillagerOutfit.for_world(_world(1, [&"first_casting"])), VillagerOutfit.FIELD)
	assert_eq(
		VillagerOutfit.for_world(_world(1, [&"woven_cloth", &"first_casting"])),
		VillagerOutfit.WOVEN
	)
	assert_eq(VillagerOutfit.for_world(_world(3, [&"the_square"])), VillagerOutfit.CHECKED)


func test_a_new_world_wears_furs() -> void:
	assert_eq(VillagerOutfit.for_world(WorldState.new()), VillagerOutfit.FUR)


func test_the_outfits_get_finer_as_the_world_does() -> void:
	var seen: Array[StringName] = []
	var steps: Array = [
		[0, []], [1, []], [1, [&"woven_cloth"]], [2, []], [2, [&"first_casting"]],
		[3, []], [3, [&"first_bloom"]], [4, []], [4, [&"the_square"]],
	]
	for step: Array in steps:
		var earned: Array[StringName] = []
		earned.assign(step[1])
		seen.append(VillagerOutfit.for_world(_world(step[0], earned)))
	assert_eq(seen, VillagerOutfit.ORDER)


func test_every_outfit_has_art_for_every_look() -> void:
	for outfit: StringName in VillagerOutfit.ORDER:
		for look: StringName in SimFixture.load_content().villager_looks:
			var path: String = VillagerOutfit.sheet_path(outfit, look)
			assert_false(path.is_empty(), "%s has no sheet for %s" % [outfit, look])
			var sheet: Texture2D = load(path) as Texture2D
			assert_true(sheet != null, path)
			if sheet != null:
				assert_eq(sheet.get_size(), Vector2(308, 30), "%s keeps the 11-cell layout" % path)


func test_sheet_paths_sit_in_each_outfits_own_folder() -> void:
	assert_true(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.FUR).contains("/cave/"))
	assert_true(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.FIELD).contains("/field/"))
	var woven: String = WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.WOVEN)
	assert_true(woven.contains("/settled/villagers/mira.png"))
	assert_true(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.TOWN).contains("/town/"))
	var bronze: String = WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.BRONZE)
	assert_true(bronze.contains("/fittings/"))
	assert_true(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.CHECKED).contains("/iron/"))
	var iron: String = WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.IRON)
	assert_true(iron.contains("/iron/villagers/fittings/"))
	assert_true(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.LINEN).contains("/classical/villagers/linen/"))
	assert_true(WorldLayout.villager_sheet_path(&"mira", VillagerOutfit.CIVIC).contains("/classical/villagers/civic/"))


func test_the_outfits_are_drawn_differently() -> void:
	var seen: Dictionary = {}
	for outfit: StringName in VillagerOutfit.ORDER:
		var sheet: Texture2D = load(WorldLayout.villager_sheet_path(&"mira", outfit)) as Texture2D
		var image: Image = sheet.get_image()
		seen[image.get_data().hex_encode()] = outfit
	assert_eq(seen.size(), VillagerOutfit.ORDER.size(), "Nine outfits, nine different sheets")


func test_an_unknown_look_wears_miras_clothes_in_the_same_outfit() -> void:
	for outfit: StringName in VillagerOutfit.ORDER:
		assert_eq(
			WorldLayout.villager_sheet_path(&"nobody", outfit),
			WorldLayout.villager_sheet_path(&"mira", outfit),
			"%s" % outfit
		)


func test_an_unknown_outfit_falls_back_to_furs() -> void:
	assert_eq(
		WorldLayout.villager_sheet_path(&"theo", &"nonsense"),
		WorldLayout.villager_sheet_path(&"theo", VillagerOutfit.FUR)
	)


