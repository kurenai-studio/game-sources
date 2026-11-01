extends GutTest
## The interface in the depth look: the shared tile helper, the palette overrides, and the keys.


func before_each() -> void:
	UiLook.depth = false


func after_each() -> void:
	UiLook.depth = false
	Palette.apply(false)
	DepthPalette.apply(false)


func test_the_flat_look_is_the_default() -> void:
	assert_false(UiLook.depth)


func test_the_depth_palette_overrides_the_shared_names_only() -> void:
	DepthPalette.apply(false)
	Palette.apply(false)
	var flat_ink := Palette.INK
	var flat_faint := Palette.FAINT
	Palette.apply(false, true)
	assert_eq(Palette.INK, DepthPalette.INK, "ink takes the depth value")
	assert_eq(Palette.GROUND, DepthPalette.GROUND_TOP, "the ground is the top of the gradient")
	assert_eq(Palette.MUTE, DepthPalette.MUTE)
	assert_ne(Palette.INK, flat_ink)
	assert_eq(Palette.FAINT, flat_faint, "a flat-only name is unchanged")
	Palette.apply(false)
	assert_eq(Palette.INK, flat_ink, "turning depth off restores the flat values")


func test_the_palette_overrides_follow_the_theme() -> void:
	DepthPalette.apply(true)
	Palette.apply(true, true)
	assert_eq(Palette.GROUND, DepthPalette.GROUND_TOP, "the dark depth ground")
	assert_eq(Palette.WALL, DepthPalette.WALL, "the dark depth wall")
	DepthPalette.apply(false)
	Palette.apply(false, true)
	assert_eq(Palette.WALL, DepthPalette.WALL, "the light depth wall")


## Draws one tile inside a real draw callback and remembers the content rect it returned.
class TileProbe:
	extends Control
	var tone := TileDraw.Tone.PLAIN
	var rect := Rect2(0, 0, 80, 60)
	var face := Rect2()

	func _draw() -> void:
		face = TileDraw.tile(self, rect, tone)


func test_a_flat_tile_keeps_its_rect_and_a_depth_tile_gives_up_its_lip() -> void:
	for tone in [TileDraw.Tone.PLAIN, TileDraw.Tone.SOLID, TileDraw.Tone.ACTIVE]:
		for depth in [false, true]:
			UiLook.depth = depth
			var probe := TileProbe.new()
			probe.tone = tone
			probe.size = Vector2(100, 80)
			add_child_autofree(probe)
			await get_tree().process_frame
			assert_ne(probe.face, Rect2(), "the tile was drawn")
			if depth:
				assert_eq(probe.face.size.x, probe.rect.size.x)
				assert_almost_eq(
					probe.face.size.y, probe.rect.size.y - DepthKit.lip_height(probe.rect), 0.001
				)
			else:
				assert_eq(probe.face, probe.rect, "flat content fills the tile")


func test_a_depth_button_draws_every_kind_enabled_pressed_and_disabled() -> void:
	UiLook.depth = true
	DepthPalette.apply(false)
	for kind in [
		TileButton.Kind.PRIMARY,
		TileButton.Kind.SECONDARY,
		TileButton.Kind.TERTIARY,
		TileButton.Kind.SOLID,
		TileButton.Kind.LOCKED
	]:
		var button := TileButton.make(kind, "MOVE", "move", 20)
		button.size = Vector2(120, 56)
		add_child_autofree(button)
		await get_tree().process_frame
		button.set_disabled(true)
		await get_tree().process_frame
		assert_eq(button.self_modulate.a, 1.0, "a depth key is never see-through")


func test_the_wordmark_stat_tile_and_result_badge_draw_in_depth() -> void:
	UiLook.depth = true
	var wordmark := Wordmark.new()
	wordmark.size = Vector2(300, 60)
	var stat := StatTile.new()
	stat.size = Vector2(110, 72)
	stat.value = "7 / 7"
	stat.caption = "COMMANDS"
	var badge := ResultBadge.new()
	badge.size = Vector2(44, 44)
	for node in [wordmark, stat, badge]:
		add_child_autofree(node)
	await get_tree().process_frame
	assert_not_null(wordmark)


func test_a_new_player_gets_the_depth_look_and_can_choose_flat() -> void:
	var path := "user://test_depth_screens.json"
	var state := AppState.new(
		Campaign.load_bundled(),
		ProgressStore.new(path),
		ContentStore.new("user://test_depth_screens_content")
	)
	state.progress.load_data()
	state.apply_theme()
	assert_true(UiLook.depth, "nothing chosen: the default look")
	assert_eq(Palette.GROUND, DepthPalette.GROUND_TOP)
	state.progress.settings.set_look(Settings.LOOK_FLAT)
	state.apply_theme()
	assert_false(UiLook.depth)
	assert_ne(Palette.GROUND, DepthPalette.GROUND_TOP, "flat has its own ground")
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)


func _screen_in(look: String, scene: String) -> ScreenBase:
	var path := "user://test_depth_screens_%s.json" % look
	var state := AppState.new(
		Campaign.load_bundled(),
		ProgressStore.new(path),
		ContentStore.new("user://test_depth_screens_content")
	)
	state.progress.load_data()
	state.progress.settings.set_look(look)
	state.apply_theme()
	var screen: ScreenBase = load("res://scenes/%s.tscn" % scene).instantiate()
	screen.setup(state, {})
	# A screen fills its parent, so the parent carries the phone size.
	var holder := Control.new()
	holder.size = Vector2(390, 844)
	add_child_autofree(holder)
	holder.add_child(screen)
	return screen


func test_the_world_list_is_plates_with_a_picture_of_each_worlds_first_level() -> void:
	var screen := _screen_in(Settings.LOOK_DEPTH, "worlds")
	await get_tree().process_frame
	await get_tree().process_frame
	var list: VBoxContainer = screen.get("_list")
	assert_eq(list.get_child_count(), Campaign.load_bundled().worlds.size())
	for row in list.get_children():
		assert_eq(row.custom_minimum_size.y, 100.0, "a plate")
		var picture: Variant = row.get("_picture")
		assert_not_null(picture, "every world shows its first level")
		assert_true(picture is BoardView25D)
		assert_gt((picture as Control).size.x, 0.0)
	_remove("user://test_depth_screens_depth.json")


func test_the_flat_world_list_keeps_its_plain_rows() -> void:
	var screen := _screen_in(Settings.LOOK_FLAT, "worlds")
	await get_tree().process_frame
	var list: VBoxContainer = screen.get("_list")
	for row in list.get_children():
		assert_eq(row.custom_minimum_size.y, 72.0)
		assert_null(row.get("_picture"))
	_remove("user://test_depth_screens_flat.json")


func test_the_menu_shows_the_next_level_as_a_depth_board() -> void:
	var screen := _screen_in(Settings.LOOK_DEPTH, "home")
	await get_tree().process_frame
	await get_tree().process_frame
	var board: BoardView = screen.get("_board")
	assert_true(board is BoardView25D)
	assert_gt(board.size.x, 300.0, "the board takes the width of the screen")
	assert_false(board.level.is_empty())
	_remove("user://test_depth_screens_depth.json")


func _remove(path: String) -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(path + suffix):
			DirAccess.remove_absolute(path + suffix)
