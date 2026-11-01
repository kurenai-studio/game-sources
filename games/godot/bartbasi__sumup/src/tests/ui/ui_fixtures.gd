extends RefCounted
## Helpers for the ui tests. Each test gets a fresh temp save folder inside
## user:// (never the real save files) and a real App in the scene tree.
##
## Headless tests run before the first frame, so no tween or board animation
## ever finishes. Tests stand in for the board by calling
## session.move_shown(), the call the board makes when a move has been shown.

const SaveFixtures: GDScript = preload("res://tests/save/save_fixtures.gd")
const APP_SCENE: PackedScene = preload("res://scenes/ui/app.tscn")

const NO_CELL: Vector2i = Vector2i(-1, -1)


static func make_temp_dir() -> String:
	return SaveFixtures.make_temp_dir()


static func remove_temp_dir(path: String) -> void:
	SaveFixtures.remove_temp_dir(path)


static func root() -> Window:
	return (Engine.get_main_loop() as SceneTree).root


## A started App saving into folder, with quits recorded in quits instead of
## ending the test run. Headless tests run before the scene tree starts, so
## the App is started by hand rather than by _ready.
static func start_app(folder: String, quits: Array[int]) -> App:
	var app: App = APP_SCENE.instantiate() as App
	app.save_folder = folder
	app.quit_handler = func() -> void: quits.append(1)
	app.start()
	return app


## Taps Play on the splash: the held saved run resumes, or a new run starts.
static func play(app: App) -> void:
	app.splash_screen().play_chosen.emit()


## Frees the App. Its queued saves are flushed first, as on a real exit.
static func stop_app(app: App) -> void:
	if app == null or not is_instance_valid(app):
		return
	settle(app)
	if app.get_parent() != null:
		app.get_parent().remove_child(app)
	app.free()


## Writes a saved run and a profile into folder, as a previous session would.
## best_score takes an int, a digit String or a BigNum; best_tile is an
## exponent (0 for none).
static func save_game(folder: String, state: RunState, best_score: Variant = 0, best_tile: int = 0, settings: Settings = null) -> void:
	var service: SaveService = SaveService.new(folder)
	var best: BigNum = num(best_score)
	if state != null:
		# A real run always knows its starting Best Score (QA6-03); the codec refuses null.
		if state.best_at_start == null:
			state.best_at_start = best
		service.save_run(state)
	var records: Records = Records.new()
	records.best_score = best
	records.best_tile = best_tile
	service.save_profile(settings if settings != null else Settings.new(), records)


static func board_d() -> PackedInt64Array:
	return SaveFixtures.board_d()


static func with_cell(board: PackedInt64Array, cell: Vector2i, exponent: int) -> PackedInt64Array:
	return SaveFixtures.with_cell(board, cell, exponent)


## value as a BigNum (see save_fixtures.gd num).
static func num(value: Variant) -> BigNum:
	return SaveFixtures.num(value)


## A BigNum as its digits, or "null", for assert_eq.
static func text(value: BigNum) -> String:
	return SaveFixtures.text(value)


## A run state that can be saved, scores as ints (see save_fixtures.gd run).
static func run(cells: PackedInt64Array, score: Variant, snapshot_cells: PackedInt64Array = PackedInt64Array(), snapshot_points: Variant = 0, run_highest: int = 0, free_used: int = 0, best_at_start: Variant = -1) -> RunState:
	return SaveFixtures.run(cells, score, snapshot_cells, snapshot_points, run_highest, free_used, best_at_start)


## Board D1024 (GDD 19.0): no valid move, H = 1024 (exponent 10).
static func board_d1024() -> PackedInt64Array:
	return with_cell(board_d(), Vector2i(2, 0), 10)


## Board P (GDD 19.0), H = 32, as exponents.
static func board_p() -> PackedInt64Array:
	var rows: Array[PackedInt64Array] = [
		PackedInt64Array([1, 2, 1, 2, 1]),
		PackedInt64Array([3, 4, 3, 4, 3]),
		PackedInt64Array([1, 2, 1, 2, 1]),
		PackedInt64Array([3, 4, 3, 4, 3]),
		PackedInt64Array([1, 2, 1, 2, 1]),
		PackedInt64Array([3, 2, 3, 4, 3]),
		PackedInt64Array([1, 1, 1, 2, 1]),
		PackedInt64Array([3, 3, 5, 3, 3]),
	]
	var cells: PackedInt64Array = PackedInt64Array()
	for row: PackedInt64Array in rows:
		cells.append_array(row)
	return cells


## A snapshot board with a valid move, for states that need Undo.
static func snapshot_board() -> PackedInt64Array:
	return with_cell(board_d(), Vector2i(1, 7), 3)


## Waits for the App's queued saves, before a test reads the files through
## another SaveService or writes to them itself.
static func settle(app: App) -> void:
	if app != null and is_instance_valid(app) and app.save != null:
		app.save.flush()


## Lets the session finish showing the last move, as the board would: the
## save lands, the board's show gate opens, then the move has been shown.
static func shown(app: App) -> void:
	gate(app)
	app.session.move_shown()


## A host Control size_px big with skin's Theme, for layout checks. Headless
## tests run before the scene tree enters, so nothing is ever inside the tree:
## anchors never size anything and screens skip their own layout. Layout
## checks size every screen by hand (fit), call its layout_in with rects of
## their own, sort its containers (layout) and measure with rect_in. Free the
## host with free_stage.
static func stage(size_px: Vector2i, skin_id: StringName) -> Control:
	var host: Control = Control.new()
	host.theme = UiKit.build_theme(SkinCatalog.get_skin(skin_id))
	root().add_child(host)
	fit(host, Vector2(size_px))
	return host


static func free_stage(host: Control) -> void:
	if host != null and is_instance_valid(host):
		host.get_parent().remove_child(host)
		host.free()


## A phone's safe rect on a screen of size_px: the capture tool's default
## insets, 120 px on top and 66 px at the bottom.
static func safe_rect(size_px: Vector2i) -> Rect2:
	return Rect2(0.0, 120.0, float(size_px.x), float(size_px.y) - 186.0)


## control's rect in the coordinates of ancestor, from positions alone
## (global rects need the scene tree).
static func rect_in(control: Control, ancestor: Node) -> Rect2:
	var at: Vector2 = Vector2.ZERO
	var node: Node = control
	while node != null and node != ancestor:
		if node is Control:
			at += (node as Control).position
		node = node.get_parent()
	return Rect2(at, control.size)


## Places control at the origin, size_px big, without anchors.
static func fit(control: Control, size_px: Vector2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = Vector2.ZERO
	control.size = size_px


## Lays out every container under node now, as the next frame would. Wrapped
## labels need their width before their height, so it runs a few passes.
static func layout(node: Node, passes: int = 4) -> void:
	for pass_index: int in passes:
		if node is Container:
			node.notification(Container.NOTIFICATION_SORT_CHILDREN)
		for child: Node in node.find_children("*", "Container", true, false):
			child.notification(Container.NOTIFICATION_SORT_CHILDREN)


## The save lands and the board runs the gate check it would run deferred
## (headless tests never run the frame's message queue), so a move held at
## the gate starts, with its move_started.
static func gate(app: App) -> void:
	settle(app)
	if app != null and app.game_screen() != null:
		app.game_screen().board()._check_gate()
