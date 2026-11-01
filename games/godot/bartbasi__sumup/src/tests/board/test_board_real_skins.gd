extends "res://tests/base_test.gd"
## The real BoardController on every skin's real board view: hit testing on
## the view's own geometry, a chain played in real time to the end, a
## Hammer, and live switches between the skins with the board kept.

const F := preload("res://tests/core/core_fixtures.gd")
const BF := preload("res://tests/board/board_fixtures.gd")
const CommonBoardView: GDScript = preload("res://src/skins/common/common_board_view.gd")
const SIZE: Vector2 = Vector2(1008.0, 1600.0)
const FRAME: float = 1.0 / 60.0
const MAX_FRAMES: int = 600

var _session: GameSession = null
var _audio: AudioService = null
var _board: BoardController = null


func after_each() -> void:
	if is_instance_valid(_board):
		_board.free()
	if is_instance_valid(_audio):
		_audio.free()


func _start(skin_id: StringName, board: PackedInt64Array, score: int) -> void:
	if is_instance_valid(_board):
		_board.free()
	if is_instance_valid(_audio):
		_audio.free()
	_session = GameSession.new()
	_audio = AudioService.new()
	_board = BoardController.new()
	_board.size = SIZE
	_board.setup(_session, SkinCatalog.get_skin(skin_id), _audio)
	_session.resume(RunState.create(board, BigNum.from_int(score)))
	_session.rng.set_seed(3)


func _view() -> CommonBoardView:
	return _board.get_node("SkinBoardView") as CommonBoardView


func _point(cell: Vector2i) -> Vector2:
	var view: SkinBoardView = _view()
	return view.position + BoardGeometry.cell_center(cell, view.grid_origin(), view.cell_pitch())


## Runs frames until the move ends. Returns the seconds it took.
func _settle() -> float:
	var elapsed: float = 0.0
	var frames: int = 0
	while _board.is_animating() and frames < MAX_FRAMES:
		_board._process(FRAME)
		_view().advance_effects(FRAME)
		elapsed += FRAME
		frames += 1
	return elapsed


func _assert_view_shows_the_session(message: String) -> void:
	for index: int in _session.state.cells.size():
		var cell: Vector2i = CoreRules.cell_of(index, 5)
		if _view().value_at(cell) != _session.state.cells[index]:
			fail("%s: the view shows %d on %s, the board holds %d" % [message, _view().value_at(cell), cell, _session.state.cells[index]])
			return


func test_every_skin_plays_a_chain_to_the_end() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		_start(skin_id, F.board_p(), 0)
		assert_true(_view() != null, "%s: a real board view" % skin_id)
		assert_eq(_view().get_script().resource_path, "res://src/skins/%s/%s_board_view.gd" % [skin_id, skin_id], "%s: the skin's own view" % skin_id)
		assert_true(_board.preferred_height(SIZE.x) > 0.0, "%s: a preferred height" % skin_id)
		_board._gui_input(BF.touch(0, _point(Vector2i(1, 6)), true))
		_board._gui_input(BF.drag(0, _point(Vector2i(2, 6))))
		_board._gui_input(BF.drag(0, _point(Vector2i(3, 6))))
		assert_eq(_audio.click_requests, 3, "%s: three tiles joined on the real geometry" % skin_id)
		_board._gui_input(BF.touch(0, _point(Vector2i(3, 6)), false))
		assert_eq(_session.state.score.to_int(), 8, "%s: the chain committed" % skin_id)
		assert_true(_board.is_animating(), "%s: the merge plays in real time" % skin_id)
		var skin: SkinData = SkinCatalog.get_skin(skin_id)
		var took: float = _settle()
		assert_false(_board.is_animating(), "%s: the move ends" % skin_id)
		assert_true(took >= skin.duration(&"merge_travel"), "%s: it took at least the travel (%.2f s)" % [skin_id, took])
		assert_true(took < 3.0, "%s: and settles in under 3 s (%.2f s)" % [skin_id, took])
		assert_false(_session.is_waiting_for_view(), "%s: the session heard it" % skin_id)
		_assert_view_shows_the_session(skin_id)


func test_every_skin_plays_a_hammer_to_the_end() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		_start(skin_id, F.board_p(), 5000)
		_session.press_booster(BoosterRules.HAMMER)
		_board._gui_input(BF.touch(0, _point(Vector2i(2, 4)), true))
		_board._gui_input(BF.touch(0, _point(Vector2i(2, 4)), false))
		assert_eq(_session.state.score.to_int(), 4872, "%s: Hammer applied" % skin_id)
		_settle()
		assert_false(_session.is_waiting_for_view(), "%s: the move was shown" % skin_id)
		_assert_view_shows_the_session(skin_id)


func test_every_skin_takes_a_tap_anywhere_on_the_tile_and_none_in_a_gap() -> void:
	for skin_id: StringName in SkinCatalog.IDS:
		_start(skin_id, F.board_p(), 5000)
		_session.press_booster(BoosterRules.HAMMER)
		var view: SkinBoardView = _view()
		var left: Rect2 = view.cell_rect(Vector2i(1, 4))
		var tile: Rect2 = view.cell_rect(Vector2i(2, 4))
		assert_true(left.end.x < tile.position.x, "%s: tiles have a gap between them" % skin_id)
		var gap: Vector2 = view.position + Vector2((left.end.x + tile.position.x) * 0.5, tile.get_center().y)
		_board._gui_input(BF.touch(0, gap, true))
		_board._gui_input(BF.touch(0, gap, false))
		assert_eq(_session.state.score.to_int(), 5000, "%s: a tap in the gap picks nothing" % skin_id)
		var corner_local: Vector2 = tile.position + tile.size * 0.05
		var miss: Vector2i = BoardGeometry.cell_at(corner_local, view.grid_origin(), view.cell_pitch(), 5, 8, _session.config.join_radius)
		assert_eq(miss, Vector2i(-1, -1), "%s: the corner is outside the join circle" % skin_id)
		var corner: Vector2 = view.position + corner_local
		_board._gui_input(BF.touch(0, corner, true))
		_board._gui_input(BF.touch(0, corner, false))
		assert_eq(_session.state.score.to_int(), 4872, "%s: a tap near the tile's corner applies Hammer" % skin_id)
		_settle()
		_assert_view_shows_the_session(skin_id)


func test_switching_skins_live_keeps_the_board() -> void:
	_start(SkinCatalog.DEFAULT_ID, F.board_p(), 0)
	for skin_id: StringName in [&"slate", &"nova", &"gumdrop"]:
		_board.set_skin(SkinCatalog.get_skin(skin_id))
		assert_eq(_board.get_child_count(), 1, "%s: one view" % skin_id)
		assert_eq(_view().get_script().resource_path, "res://src/skins/%s/%s_board_view.gd" % [skin_id, skin_id], "%s: the new skin's view" % skin_id)
		assert_eq(_view().size, SIZE, "%s: it fills the board" % skin_id)
		_assert_view_shows_the_session(skin_id)
