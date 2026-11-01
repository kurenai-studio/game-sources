extends "res://tests/base_test.gd"
## The board scene, setup and layout: scenes/board/board.tscn holds a
## BoardController, the skin view fills the board's rect, the preferred
## height comes from the skin view, and setup shows the session as it is.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")
const StubBoardController: GDScript = preload("res://tests/board/stub_board_controller.gd")
const BOARD_SCENE: String = "res://scenes/board/board.tscn"
const NO_CELL: Vector2i = Vector2i(-1, -1)

var rig: BF.Rig = null
var _nodes: Array[Node] = []


func after_each() -> void:
	if rig != null:
		rig.free_all()
	for node: Node in _nodes:
		if is_instance_valid(node):
			node.free()
	_nodes.clear()


func test_the_board_scene_root_is_a_board_controller() -> void:
	var scene: PackedScene = load(BOARD_SCENE) as PackedScene
	assert_true(scene != null, "the scene loads")
	var root: Node = scene.instantiate()
	_nodes.append(root)
	assert_true(root is BoardController, "its root is a BoardController")
	assert_eq((root as Control).mouse_filter, Control.MOUSE_FILTER_STOP, "it takes pointer events")
	assert_false((root as BoardController).is_animating(), "at rest")
	assert_eq((root as BoardController).preferred_height(1000.0), 0.0, "no height before setup")


func test_the_view_fills_the_board() -> void:
	rig = BF.rig(F.board_p(), 0)
	assert_eq(rig.view().size, rig.board.size, "filled at setup")
	rig.board.size = Vector2(600.0, 900.0)
	rig.board.notification(Control.NOTIFICATION_RESIZED)
	assert_eq(rig.view().position, Vector2.ZERO, "at the board's corner")
	assert_eq(rig.view().size, Vector2(600.0, 900.0), "and the board's size after a resize")


func test_the_preferred_height_comes_from_the_view() -> void:
	rig = BF.rig(F.board_p(), 0)
	assert_eq(rig.board.preferred_height(500.0), 800.0, "the stub's height for that width")


func test_setup_shows_the_session_as_it_is() -> void:
	var session: GameSession = GameSession.new()
	session.resume(RunState.create(F.board_p(), BigNum.from_int(5000)))
	session.move_shown()
	session.press_booster(BoosterRules.SWAP)
	session.tap_cell(Vector2i(0, 0))
	var board: StubBoardController = StubBoardController.new()
	_nodes.append(board)
	board.setup(session, SkinCatalog.get_skin(SkinCatalog.DEFAULT_ID), null)
	assert_eq(board.stub().boards, [F.board_p()], "the board")
	assert_eq(board.stub().targeting, [BoosterRules.SWAP] as Array[StringName], "Swap is active")
	assert_eq(board.stub().swap_selected, BF.cells([Vector2i(0, 0)]), "(0,0) is selected")


func test_setup_before_any_run_shows_no_board() -> void:
	var board: StubBoardController = StubBoardController.new()
	_nodes.append(board)
	board.setup(GameSession.new(), SkinCatalog.get_skin(SkinCatalog.DEFAULT_ID), null)
	assert_eq(board.stub().boards.size(), 0, "no board to show yet")


func test_a_board_with_no_audio_still_plays() -> void:
	var session: GameSession = GameSession.new()
	var board: StubBoardController = StubBoardController.new()
	_nodes.append(board)
	board.setup(session, SkinCatalog.get_skin(SkinCatalog.DEFAULT_ID), null)
	session.resume(RunState.create(F.board_p(), BigNum.from_int(0)))
	var at: Vector2 = BoardGeometry.cell_center(Vector2i(1, 6), BF.StubBoardView.ORIGIN, BF.StubBoardView.PITCH)
	var to: Vector2 = BoardGeometry.cell_center(Vector2i(2, 6), BF.StubBoardView.ORIGIN, BF.StubBoardView.PITCH)
	board._gui_input(BF.touch(0, at, true))
	board._gui_input(BF.drag(0, to))
	board._gui_input(BF.touch(0, to, false))
	assert_eq(session.state.score.to_int(), 4, "the chain commits without a click service")


func test_a_second_setup_moves_the_board_to_the_new_session() -> void:
	rig = BF.rig(F.board_p(), 0)
	var old_session: GameSession = rig.session
	var new_session: GameSession = GameSession.new()
	rig.board.setup(new_session, rig.skin, rig.audio)
	rig.session = new_session
	new_session.resume(RunState.create(F.board_all(4), BigNum.from_int(0)))
	assert_eq(rig.view().boards.back(), F.board_all(4), "the new session's board shows")
	var shown: int = rig.view().boards.size()
	old_session.start_new_run()
	assert_eq(rig.view().boards.size(), shown, "the old session no longer reaches the board")
	assert_true(old_session.is_waiting_for_view(), "nor does the board answer it")


func test_a_drag_open_at_a_second_setup_is_released() -> void:
	rig = BF.rig(F.board_p(), 0)
	rig.drag_cells([Vector2i(1, 6), Vector2i(2, 6)])
	var old_session: GameSession = rig.session
	rig.board.setup(GameSession.new(), rig.skin, rig.audio)
	assert_false(old_session.is_dragging(), "the old session's drag lock is released")
