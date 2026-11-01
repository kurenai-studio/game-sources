extends GutTest
## The depth board is a drop-in for the flat board, chosen by the Look setting.

const PATH := "user://test_look.json"

var _store: ProgressStore


func before_each() -> void:
	_remove_all()
	_store = ProgressStore.new(PATH)
	_store.load_data()


func after_each() -> void:
	_remove_all()
	DepthPalette.apply(false)


func _remove_all() -> void:
	for suffix in ["", ".tmp", ".bak", ".corrupt"]:
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(PATH + suffix)


func test_the_look_defaults_to_depth_and_only_accepts_known_values() -> void:
	var settings := _store.settings
	assert_eq(settings.look(), Settings.LOOK_DEPTH, "a new player gets the depth look")
	settings.set_look(Settings.LOOK_FLAT)
	assert_eq(settings.look(), Settings.LOOK_FLAT)
	settings.set_look("nonsense")
	assert_eq(settings.look(), Settings.LOOK_FLAT, "an unknown look is ignored")


func test_an_old_save_without_a_look_reads_as_the_default() -> void:
	_store.data["settings"].erase("look")
	assert_eq(_store.settings.look(), Settings.LOOK_DEFAULT)
	_store.data["settings"]["look"] = 5
	assert_eq(_store.settings.look(), Settings.LOOK_DEFAULT, "a damaged value reads as the default")


func test_the_look_is_not_part_of_the_synced_settings() -> void:
	_store.settings.set_look(Settings.LOOK_FLAT)
	assert_false(_store.settings.synced_settings().has("look"))


func test_the_factory_makes_the_board_for_the_look() -> void:
	var depth := BoardViews.make(Settings.LOOK_DEPTH)
	var flat := BoardViews.make(Settings.LOOK_FLAT)
	assert_true(depth is BoardView25D)
	assert_false(flat is BoardView25D)
	assert_true(flat is BoardView)
	assert_eq(depth.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	depth.free()
	flat.free()


func test_the_depth_board_takes_the_same_state_and_draws_every_goal_type() -> void:
	DepthPalette.apply(true)
	var campaign := Campaign.load_bundled()
	for slug in ["first-turn", "small-room", "first-loop", "big-spiral"]:
		var level: Dictionary = campaign.entry_by_id(slug)["level"]
		var board := BoardViews.make(Settings.LOOK_DEPTH)
		board.size = Vector2(350.0, 350.0)
		add_child_autofree(board)
		board.set_level(level)
		var start: Array = level["initialState"]["position"]
		var trail: Array[Vector2i] = [Vector2i(int(start[0]), int(start[1]))]
		var marks := {trail[0]: "north"}
		board.show_state(start, level["initialState"]["direction"], trail, null, marks)
		await get_tree().process_frame
		var view: BoardProjection = (board as BoardView25D).projection()
		assert_gt(view.cell_scale, 0.0, slug)
		assert_eq(view.cols, int(level["board"]["width"]), slug)


func test_the_projection_is_rebuilt_only_when_the_board_or_size_changes() -> void:
	var campaign := Campaign.load_bundled()
	var level: Dictionary = campaign.entry_by_id("first-turn")["level"]
	var board := BoardView25D.new()
	board.size = Vector2(300.0, 300.0)
	add_child_autofree(board)
	board.set_level(level)
	var first := board.projection()
	assert_same(board.projection(), first, "unchanged state reuses the projection")
	board.size = Vector2(320.0, 320.0)
	assert_not_same(board.projection(), first, "a new size makes a new projection")
