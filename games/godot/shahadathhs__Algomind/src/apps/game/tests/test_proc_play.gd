extends GutTest
## The play screen on a level that offers PROC, built headless: the palette, the layout at three
## phone sizes, and a run through a procedure. Nothing is drawn to a window.

const SIZES: Array[Vector2] = [Vector2(390, 844), Vector2(360, 640), Vector2(412, 915)]
const M := "MOVE_FORWARD"
const R := "TURN_RIGHT"


func _state() -> AppState:
	var level := ProcSupport.level()
	level["availableCommands"] = [
		"MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT", "REPEAT", "REPEAT_UNTIL", "IF", "PROC"
	]
	var campaign := Campaign.new()
	campaign.entries.append({"id": "proc-t", "number": 1, "world": 0, "chapter": 0, "level": level})
	# An empty content store of its own: the real one holds the campaign a run of the game downloaded,
	# and AppState prefers that campaign to the one given here.
	var content := ContentStore.new("user://test_proc_play_content")
	return AppState.new(campaign, ProgressStore.new("user://test_proc_play.json"), content)


func _screen(at: Vector2) -> PlayScreen:
	var host := Control.new()
	host.size = at
	add_child_autofree(host)
	var screen: PlayScreen = load("res://scenes/play.tscn").instantiate()
	screen.persist = false
	screen.setup(_state(), {"level_id": "proc-t"})
	host.add_child(screen)
	return screen


func _visible_palette(screen: PlayScreen) -> Array[Control]:
	return PlayLayout._palette_nodes(screen)


func test_the_proc_tile_is_in_the_palette_and_calls_follow_the_definitions() -> void:
	var screen := _screen(SIZES[0])
	await wait_process_frames(2)
	assert_eq(screen._group_buttons.size(), 4, "repeat, until, if, proc")
	var proc_button: TileButton = screen._group_buttons["PROC"]
	assert_eq(proc_button.label, "PROC")
	for button in screen._call_buttons:
		assert_false(button.visible, "no call tile before a definition")
	screen._on_command("PROC")
	assert_eq(proc_button.label, "END PROC")
	assert_true(proc_button.disabled, "an empty definition cannot be ended")
	for button in screen._call_buttons:
		assert_false(button.visible)
	assert_false(screen._step.visible and not screen._step.disabled, "Step is off")
	screen._on_command(M)
	assert_false(proc_button.disabled)
	screen._on_command("PROC")
	assert_eq(proc_button.label, "PROC")
	assert_true(screen._call_buttons[0].visible)
	assert_eq(screen._call_buttons[0].label, "CALL A")
	assert_false(screen._call_buttons[1].visible)


func test_the_palette_fits_and_stays_clear_of_the_tape_at_every_size() -> void:
	for at in SIZES:
		var screen := _screen(at)
		await wait_process_frames(2)
		for step in ["PROC", M, "PROC", "PROC", R, "PROC", "PROC", M, "PROC"]:
			screen._on_command(step)
		for name in ["A", "B", "C"]:
			screen._on_call(name)
		await wait_process_frames(1)
		var nodes := _visible_palette(screen)
		assert_gt(nodes.size(), 7, "%s: many tiles show" % str(at))
		var tape_bottom: float = screen._tape_view.position.y + screen._tape_view.size.y
		for node in nodes:
			var rect := Rect2(node.position, node.size)
			assert_true(Rect2(Vector2.ZERO, at).encloses(rect), "%s %s inside" % [str(at), node])
			assert_gte(node.size.y, 44.0, "%s touch height" % str(at))
			assert_gte(node.size.x, 40.0, "%s touch width %f" % [str(at), node.size.x])
			assert_gte(node.position.y, tape_bottom, "%s below the tape" % str(at))
		for i in nodes.size():
			for j in range(i + 1, nodes.size()):
				var a := Rect2(nodes[i].position, nodes[i].size)
				var b := Rect2(nodes[j].position, nodes[j].size)
				assert_false(a.intersects(b), "%s tiles %d and %d overlap" % [str(at), i, j])
		var run_bottom: float = screen._run.position.y
		var last_bottom := 0.0
		for node in nodes:
			last_bottom = maxf(last_bottom, node.position.y + node.size.y)
		assert_lte(last_bottom, run_bottom, "%s palette above the controls" % str(at))
		assert_gte(screen._board.size.x, 120.0, "%s the board keeps room" % str(at))


func test_a_run_through_a_procedure_highlights_the_definition_and_the_call() -> void:
	var screen := _screen(SIZES[1])
	await wait_process_frames(2)
	for step in ["PROC", M, R, "PROC"]:
		screen._on_command(step)
	screen._on_call("A")
	screen._on_command(M)
	assert_eq(screen._tape.slots(), 5)
	assert_true(screen._start(PlaySession.State.PAUSED))
	await PlayAnimator.play_one_step(screen)
	var view: TapeView = screen._tape_view
	assert_eq(view.current, 1, "the move inside the definition")
	assert_eq(view.call_index, 3, "the CALL tile that is running it")
	await PlayAnimator.play_one_step(screen)
	assert_eq(view.current, 2)
	await PlayAnimator.play_one_step(screen)
	assert_eq(view.current, 4, "back in the main program")
	assert_eq(view.call_index, -1)
	await wait_process_frames(2)
	assert_true(is_instance_valid(view))


func test_a_failure_inside_a_procedure_puts_the_x_on_that_tile() -> void:
	var screen := _screen(SIZES[0])
	await wait_process_frames(2)
	for step in ["PROC", M, M, M, M, M, "PROC"]:
		screen._on_command(step)
	# Start (0,8) facing north on a board nine cells high: the ninth move leaves the board.
	screen._on_call("A")
	screen._on_call("A")
	assert_true(screen._start(PlaySession.State.PAUSED))
	while screen._session.state == PlaySession.State.PAUSED:
		await PlayAnimator.play_one_step(screen)
	assert_eq(screen._session.state, PlaySession.State.FAILED)
	assert_eq(screen._session.failing_node(), [0, 3])
	assert_eq(screen._tape_view.failed_index, 4, "the X is on the fourth tile of the definition")


func test_removing_a_called_definition_turns_run_off_and_says_why() -> void:
	var screen := _screen(SIZES[0])
	await wait_process_frames(2)
	for step in ["PROC", M, "PROC"]:
		screen._on_command(step)
	screen._on_call("A")
	screen._on_tile_tapped(0)
	screen._on_tool("x")
	assert_true(screen._run.disabled)
	assert_true(screen._message.text.begins_with("PROCEDURE A IS NOT DEFINED"))
