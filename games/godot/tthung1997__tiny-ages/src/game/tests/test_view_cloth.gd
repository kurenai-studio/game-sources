extends McpTestSuite
## Villagers change clothes with the age (docs/ages.md B8): the sheet is chosen by the world,
## swapped live without losing the animation, a newcomer arrives dressed, and the popup portrait
## and the villager list wear the same clothes.


func suite_name() -> String:
	return "view_cloth"


func _sheet_of(actor: VillagerActor) -> String:
	var frame: AtlasTexture = actor._sprite.sprite_frames.get_frame_texture(&"idle", 0) as AtlasTexture
	return frame.atlas.resource_path


func _dress_for(sim: Simulation, outfit: StringName) -> void:
	match outfit:
		VillagerOutfit.FUR:
			sim.world.era_order = 0
		VillagerOutfit.FIELD:
			sim.world.era_order = 1
		VillagerOutfit.WOVEN:
			sim.world.era_order = 1
			sim.world.achievements.append(&"woven_cloth")
		VillagerOutfit.TOWN:
			sim.world.era_order = 2
		VillagerOutfit.BRONZE:
			sim.world.era_order = 2
			sim.world.achievements.append(&"first_casting")
		VillagerOutfit.CHECKED:
			sim.world.era_order = 3
		VillagerOutfit.IRON:
			sim.world.era_order = 3
			sim.world.achievements.append(&"first_bloom")
		VillagerOutfit.LINEN:
			sim.world.era_order = 4
		VillagerOutfit.CIVIC:
			sim.world.era_order = 4
			sim.world.achievements.append(&"the_square")


func test_the_view_starts_in_furs() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	for actor: VillagerActor in view._actors.values():
		assert_eq(_sheet_of(actor), WorldLayout.villager_sheet_path(actor.get_meta(&"look"), &"fur"))
	view.free()


func test_villagers_change_clothes_as_the_world_earns_them() -> void:
	var sim: Simulation = SimFixture.new_sim()
	var view: WorldView = WorldView.new()
	view.setup(sim, DesktopWindow.new())
	var actor: VillagerActor = view._actors[sim.world.villagers[0].id]
	assert_true(_sheet_of(actor).contains("/cave/"), "Furs to begin with")
	for outfit: StringName in VillagerOutfit.ORDER:
		_dress_for(sim, outfit)
		view.on_world_changed()
		for other: VillagerActor in view._actors.values():
			var expected: String = WorldLayout.villager_sheet_path(other.get_meta(&"look"), outfit)
			assert_eq(_sheet_of(other), expected, "Everyone wears the %s outfit" % outfit)
	view.free()


func test_a_villager_who_arrives_later_is_already_dressed() -> void:
	for outfit: StringName in VillagerOutfit.ORDER:
		var sim: Simulation = SimFixture.new_sim()
		_dress_for(sim, outfit)
		var view: WorldView = WorldView.new()
		view.setup(sim, DesktopWindow.new())
		sim.add_villager()
		view.on_world_changed()
		for actor: VillagerActor in view._actors.values():
			var expected: String = WorldLayout.villager_sheet_path(actor.get_meta(&"look"), outfit)
			assert_eq(_sheet_of(actor), expected, "%s" % outfit)
		view.free()


func test_swapping_clothes_keeps_the_animation() -> void:
	var actor: VillagerActor = VillagerActor.new()
	actor.setup(&"t", load(WorldLayout.villager_sheet_path(&"mira", &"fur")) as Texture2D)
	actor._sprite.play(&"chop")
	actor._sprite.frame = 2
	for outfit: StringName in VillagerOutfit.ORDER:
		var path: String = WorldLayout.villager_sheet_path(&"mira", outfit)
		actor.set_sheet(load(path) as Texture2D)
		assert_eq(actor._sprite.animation, &"chop", "%s" % outfit)
		assert_eq(actor._sprite.frame, 2, "%s" % outfit)
		assert_eq(_sheet_of(actor), path)
	actor.free()


func test_the_popup_portrait_wears_the_same_clothes() -> void:
	for outfit: StringName in VillagerOutfit.ORDER:
		var sim: Simulation = SimFixture.new_sim()
		_dress_for(sim, outfit)
		var panel: PanelHost = PanelHost.new()
		panel.show_villager(sim, sim.world.villagers[0].id)
		assert_eq(_portrait_sheets(panel), [
			WorldLayout.villager_sheet_path(sim.world.villagers[0].look, outfit)
		], "%s" % outfit)
		panel.free()


func test_the_villager_list_wears_the_same_clothes() -> void:
	for outfit: StringName in VillagerOutfit.ORDER:
		var sim: Simulation = SimFixture.new_sim()
		_dress_for(sim, outfit)
		var panel: PanelHost = PanelHost.new()
		panel.show_villagers(sim)
		var expected: Array[String] = []
		for villager: VillagerState in sim.world.villagers:
			expected.append(WorldLayout.villager_sheet_path(villager.look, outfit))
		assert_eq(_portrait_sheets(panel), expected, "%s" % outfit)
		panel.free()


func _portrait_sheets(panel: PanelHost) -> Array[String]:
	var sheets: Array[String] = []
	for node: Node in panel.find_children("*", "TextureRect", true, false):
		var picture: TextureRect = node as TextureRect
		if picture.custom_minimum_size == PanelHost.PORTRAIT_SIZE:
			sheets.append((picture.texture as AtlasTexture).atlas.resource_path)
	return sheets