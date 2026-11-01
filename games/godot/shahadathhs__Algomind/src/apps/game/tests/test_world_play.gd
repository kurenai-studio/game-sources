extends GutTest
## The play screen on the later mechanics, built headless: the palette at three phone sizes with
## every tile, the counter readout, breadcrumbs, and the sweep goal. Nothing is drawn to a window.

const SIZES: Array[Vector2] = [Vector2(390, 844), Vector2(360, 640), Vector2(412, 915)]
const M := "MOVE_FORWARD"
const R := "TURN_RIGHT"


func _screen(at: Vector2, level: Dictionary) -> PlayScreen:
	var host := Control.new()
	host.size = at
	add_child_autofree(host)
	return WorldSupport.screen(host, level, "world_play")


func _check_palette(screen: PlayScreen, at: Vector2, label: String) -> int:
	var nodes := PlayLayout._palette_nodes(screen)
	var tape_bottom: float = screen._tape_view.position.y + screen._tape_view.size.y
	for node in nodes:
		var rect := Rect2(node.position, node.size)
		assert_true(Rect2(Vector2.ZERO, at).encloses(rect), "%s %s inside" % [label, node])
		assert_gte(node.size.y, 44.0, "%s touch height" % label)
		assert_gte(node.size.x, 36.0, "%s width %f" % [label, node.size.x])
		assert_gte(node.position.y, tape_bottom, "%s below the tape" % label)
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			var a := Rect2(nodes[i].position, nodes[i].size)
			var b := Rect2(nodes[j].position, nodes[j].size)
			assert_false(a.intersects(b), "%s tiles %d and %d overlap" % [label, i, j])
	var last_bottom := 0.0
	for node in nodes:
		last_bottom = maxf(last_bottom, node.position.y + node.size.y)
	assert_lte(last_bottom, screen._run.position.y, "%s palette above the controls" % label)
	assert_gte(screen._board.size.x, 120.0, "%s the board keeps room" % label)
	return nodes.size()


func test_the_palette_holds_every_tile_at_every_size() -> void:
	for at in SIZES:
		var screen := _screen(at, WorldSupport.level(WorldSupport.ALL, ["nested_loops"]))
		await wait_process_frames(2)
		# Three procedures, then a loop is left open: nine commands, End Loop and three calls.
		for step in ["PROC", M, "PROC", "PROC", R, "PROC", "PROC", M, "PROC", "REPEAT"]:
			screen._on_command(step)
		for name in ["A", "B", "C"]:
			screen._on_call(name)
		await wait_process_frames(1)
		var shown := _check_palette(screen, at, "loop open %s" % str(at))
		assert_eq(shown, 13, "nine commands, End Loop and three calls")
		assert_true(screen._extra_buttons["END_LOOP"].visible)
		assert_false(screen._extra_buttons["END_LOOP"].disabled)
		var repeat_button: TileButton = screen._group_buttons["REPEAT"]
		assert_eq(repeat_button.label, "REPEAT", "the tile still starts a loop")
		assert_false(repeat_button.disabled, "an inner loop can start")
		screen._on_command("REPEAT")
		assert_true(repeat_button.disabled, "two levels at most")


func test_an_open_if_shows_else_and_else_if() -> void:
	for at in SIZES:
		var screen := _screen(at, WorldSupport.level(WorldSupport.ALL, ["nested_loops"]))
		await wait_process_frames(2)
		screen._on_command("IF")
		screen._on_command(M)
		await wait_process_frames(1)
		var else_if: TileButton = screen._extra_buttons["ELSE_IF"]
		assert_true(else_if.visible)
		assert_true(else_if.disabled, "the then branch is still open")
		screen._on_command("ELSE")
		assert_false(else_if.disabled)
		screen._on_command("ELSE_IF")
		assert_eq(screen._tape.cells().size(), 3)
		assert_eq(screen._tape.selected, 2, "the sensor of the new IF is selected")
		await wait_process_frames(1)
		_check_palette(screen, at, "else if %s" % str(at))
		assert_false(screen._extra_buttons["END_LOOP"].visible, "no loop is open")


func test_a_level_without_nested_loops_keeps_the_old_loop_tiles() -> void:
	var screen := _screen(SIZES[0], WorldSupport.level())
	await wait_process_frames(2)
	screen._on_command("REPEAT")
	var repeat_button: TileButton = screen._group_buttons["REPEAT"]
	assert_eq(repeat_button.label, "END LOOP", "the tile that opened the loop ends it")
	assert_false(screen._extra_buttons.has("END_LOOP"))


func test_the_counter_shows_beside_the_program_caption_during_a_run() -> void:
	var screen := _screen(SIZES[0], WorldSupport.level())
	await wait_process_frames(2)
	for step in ["INC", "INC", M]:
		screen._on_command(step)
	assert_eq(screen._program_caption.text, "PROGRAM")
	assert_true(screen._start(PlaySession.State.PAUSED))
	assert_eq(screen._program_caption.text, "PROGRAM   N 1")
	await PlayAnimator.play_one_step(screen)
	await PlayAnimator.play_one_step(screen)
	assert_eq(screen._program_caption.text, "PROGRAM   N 3")


func test_breadcrumbs_are_drawn_from_the_trace_so_far() -> void:
	var screen := _screen(SIZES[0], WorldSupport.level())
	await wait_process_frames(2)
	for step in ["MARK", M, "MARK", M]:
		screen._on_command(step)
	assert_true(screen._start(PlaySession.State.PAUSED))
	assert_true(screen._board.crumbs.is_empty())
	await PlayAnimator.play_one_step(screen)
	assert_eq(screen._board.crumbs, {Vector2i(0, 0): "west"}, "behind the automaton, facing east")
	await PlayAnimator.play_one_step(screen)
	await PlayAnimator.play_one_step(screen)
	assert_eq(screen._board.crumbs.size(), 2)
	assert_eq(screen._board.crumbs[Vector2i(1, 0)], "west")


func test_a_sweep_level_has_no_target_and_counts_cells() -> void:
	var screen := _screen(SIZES[0], WorldSupport.sweep_level())
	await wait_process_frames(2)
	assert_true(screen._counter.text.ends_with("1 / 18 CELLS"), screen._counter.text)
	assert_eq(screen._message.text, "VISIT EVERY CELL")
	screen._board.size = Vector2(300, 300)
	screen._board.queue_redraw()
	await wait_process_frames(1)
	assert_false(screen._board.level["goal"].has("position"))


func test_a_sweep_that_runs_out_says_how_many_cells_are_left() -> void:
	var screen := _screen(SIZES[1], WorldSupport.sweep_level())
	await wait_process_frames(2)
	for step in ["REPEAT", M, "END_LOOP"]:
		screen._on_command(step)
	assert_true(screen._start(PlaySession.State.PAUSED))
	while screen._session.state == PlaySession.State.PAUSED:
		await PlayAnimator.play_one_step(screen)
	assert_eq(screen._session.state, PlaySession.State.FAILED)
	assert_eq(
		screen._message.text, "THE PROGRAM ENDED BEFORE EVERY CELL WAS VISITED. CELLS LEFT: 15"
	)


func test_a_sweep_is_solved_by_the_lawnmower() -> void:
	var screen := _screen(SIZES[0], WorldSupport.sweep_level())
	await wait_process_frames(2)
	var program := WorldSupport.lawnmower()
	assert_eq(ProgramSlots.count(program), 12)
	var result := LevelSimulator.simulate(screen._level, program)
	assert_eq(result["status"], "SUCCEEDED")
	assert_eq(LoopMessages.cells_left(screen._level, result), 0)


func test_the_mechanics_a_level_needs_come_from_its_content() -> void:
	assert_eq(LevelMechanics.derived(WorldSupport.level(["MOVE_FORWARD"])), [] as Array[String])
	var all := LevelMechanics.derived(WorldSupport.sweep_level())
	assert_eq(all, ["counter", "markers", "visit_all"] as Array[String])
	var level := WorldSupport.level(["MOVE_FORWARD", "INC"])
	level["extraBoards"] = [
		{
			"board": level["board"],
			"initialState": level["initialState"],
			"goal": {"type": "visit_all"}
		}
	]
	assert_eq(
		LevelMechanics.derived(level), ["multi_board", "counter", "visit_all"] as Array[String]
	)
	for name in ["counter", "nested_loops", "markers", "visit_all"]:
		assert_true(Campaign.SUPPORTED_MECHANICS.has(name), name)


func test_loop_messages_name_the_counter_loop() -> void:
	var level := WorldSupport.level()
	level["constraints"]["maxSteps"] = 12
	var program := [
		{"op": "INC"}, {"op": "REPEAT", "count": "N", "body": [{"op": "TURN_LEFT"}, {"op": "INC"}]}
	]
	var result := LevelSimulator.simulate(level, program)
	assert_eq(result["reason"], "PROGRAM_ENDED")
	level["constraints"]["maxSteps"] = 3
	result = LevelSimulator.simulate(level, program)
	assert_eq(result["reason"], "STEP_LIMIT")
	assert_eq(
		LoopMessages.for_result(level, program, result),
		"The loop that counts with N ran for too many steps, so it was stopped."
	)
