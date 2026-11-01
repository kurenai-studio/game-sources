extends GutTest
## The depth look's motion: the lift between cells, the turning wedge, the rising goal pad, and
## keys that sink and spring back. All of it stops when the player chose reduce motion.


func before_each() -> void:
	UiLook.animate = true
	UiLook.depth = true


func after_each() -> void:
	UiLook.animate = true
	UiLook.depth = false


func _board() -> BoardView25D:
	var board := BoardView25D.new()
	board.size = Vector2(350.0, 350.0)
	add_child_autofree(board)
	var level: Dictionary = Campaign.load_bundled().entry_by_id("first-turn")["level"]
	board.set_level(level)
	return board


func test_the_lift_is_zero_on_a_cell_and_highest_halfway() -> void:
	assert_eq(BoardView25D.lift_at(Vector2(3.0, 2.0)), 0.0)
	assert_almost_eq(BoardView25D.lift_at(Vector2(3.5, 2.0)), BoardView25D.LIFT, 0.0001)
	assert_almost_eq(BoardView25D.lift_at(Vector2(2.0, 4.5)), BoardView25D.LIFT, 0.0001)
	assert_almost_eq(
		BoardView25D.lift_at(Vector2(2.25, 1.0)), BoardView25D.lift_at(Vector2(2.75, 1.0)), 0.0001
	)
	assert_gt(BoardView25D.lift_at(Vector2(2.25, 1.0)), 0.0)


func test_a_facing_is_an_angle_on_the_board() -> void:
	assert_almost_eq(BoardView25D.angle_of("east"), 0.0, 0.0001)
	assert_almost_eq(BoardView25D.angle_of("south"), PI / 2.0, 0.0001)
	assert_almost_eq(BoardView25D.angle_of("north"), -PI / 2.0, 0.0001)
	assert_almost_eq(absf(BoardView25D.angle_of("west")), PI, 0.0001)


func test_the_wedge_turns_to_a_new_facing_in_steps_and_then_the_board_goes_idle() -> void:
	var board := _board()
	var start: float = board.get("_wedge_angle")
	board.facing = "east" if board.facing != "east" else "west"
	assert_true(board.is_processing(), "a change starts the frames")
	board._process(0.02)
	var partway: float = board.get("_wedge_angle")
	assert_ne(partway, start, "it has begun to turn")
	assert_ne(partway, BoardView25D.angle_of(board.facing), "but has not arrived")
	for i in 10:
		board._process(0.05)
	assert_almost_eq(float(board.get("_wedge_angle")), BoardView25D.angle_of(board.facing), 0.0001)
	assert_false(board.is_processing(), "nothing runs while it is idle")


func test_reduce_motion_turns_the_wedge_at_once() -> void:
	UiLook.animate = false
	var board := _board()
	board.facing = "south" if board.facing != "south" else "north"
	board._process(0.001)
	assert_almost_eq(float(board.get("_wedge_angle")), BoardView25D.angle_of(board.facing), 0.0001)
	assert_false(board.is_processing())


func test_the_goal_pad_rises_when_the_automaton_stands_on_it_and_sinks_when_it_leaves() -> void:
	var board := _board()
	var goal: Array = board.level["goal"]["position"]
	var rest := board.goal_height()
	assert_eq(rest, BoardProjection.Z_GOAL)
	board.automaton = Vector2(float(goal[0]), float(goal[1]))
	board._process(0.1)
	assert_gt(board.goal_height(), rest, "it is rising")
	assert_lt(board.goal_height(), rest + BoardView25D.GOAL_RISE, "and has not finished")
	for i in 10:
		board._process(0.05)
	assert_almost_eq(board.goal_height(), rest + BoardView25D.GOAL_RISE, 0.0001)
	assert_false(board.is_processing())
	board.automaton = Vector2.ZERO
	for i in 10:
		board._process(0.05)
	assert_almost_eq(board.goal_height(), rest, 0.0001)


func test_reduce_motion_raises_the_pad_at_once() -> void:
	UiLook.animate = false
	var board := _board()
	var goal: Array = board.level["goal"]["position"]
	board.automaton = Vector2(float(goal[0]), float(goal[1]))
	board._process(0.001)
	assert_almost_eq(board.goal_height(), BoardProjection.Z_GOAL + BoardView25D.GOAL_RISE, 0.0001)


func test_an_idle_button_runs_no_frames_and_a_press_eases_in_and_out() -> void:
	var button := TileButton.make(TileButton.Kind.SECONDARY, "MOVE", "move", 20)
	button.size = Vector2(120.0, 56.0)
	add_child_autofree(button)
	assert_false(button.is_processing(), "an idle button never redraws itself")
	button._down = true
	button.set_process(true)
	button._process(TileButton.SINK_SECONDS / 2.0)
	assert_between(float(button.get("_sink")), 0.01, 0.99, "halfway down")
	button._process(TileButton.SINK_SECONDS)
	assert_eq(float(button.get("_sink")), 1.0)
	assert_false(button.is_processing(), "it stops once it has sunk")
	button._down = false
	button.set_process(true)
	button._process(TileButton.SINK_SECONDS * 2.0)
	assert_eq(float(button.get("_sink")), 0.0, "and springs back")


func test_reduce_motion_sinks_a_key_at_once() -> void:
	UiLook.animate = false
	var button := TileButton.make(TileButton.Kind.PRIMARY, "RUN", "play", 20)
	add_child_autofree(button)
	button._down = true
	button.set_process(true)
	button._process(0.001)
	assert_eq(float(button.get("_sink")), 1.0)


func test_a_sunk_key_moves_its_face_down_by_the_lip_and_keeps_its_base() -> void:
	var rect := Rect2(0.0, 0.0, 100.0, 60.0)
	var probe := KeyProbe.new()
	probe.rect = rect
	add_child_autofree(probe)
	await get_tree().process_frame
	var lip := DepthKit.lip_height(rect)
	assert_almost_eq(probe.up.position.y, 0.0, 0.001)
	assert_almost_eq(probe.half.position.y, lip * 0.5, 0.001)
	assert_almost_eq(probe.down.position.y, lip, 0.001)


## Draws a key at three depths inside a real draw callback and remembers the faces.
class KeyProbe:
	extends Control
	var rect := Rect2()
	var up := Rect2()
	var half := Rect2()
	var down := Rect2()

	func _draw() -> void:
		up = DepthKit.key_sunk(self, rect, DepthKit.Kind.TILE, 0.0)
		half = DepthKit.key_sunk(self, rect, DepthKit.Kind.TILE, 0.5)
		down = DepthKit.key_sunk(self, rect, DepthKit.Kind.TILE, 1.0)
