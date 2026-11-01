extends GutTest
## The play screen on a level with test boards, built headless: the tab row at three phone sizes,
## solving board by board, the marks, and the failure text. Nothing is drawn to a window.

const SIZES: Array[Vector2] = [Vector2(390, 844), Vector2(360, 640), Vector2(412, 915)]


func _state(level: Dictionary) -> AppState:
	var campaign := Campaign.new()
	campaign.entries.append({"id": "mb", "number": 2, "world": 0, "chapter": 0, "level": level})
	# Stores of their own: never the real user:// data of a run of the game.
	var content := ContentStore.new("user://test_multi_board_content")
	return AppState.new(campaign, ProgressStore.new("user://test_multi_board.json"), content)


func _screen(at: Vector2, extra_count: int = 2) -> PlayScreen:
	var host := Control.new()
	host.size = at
	add_child_autofree(host)
	return _mount(host, MultiSupport.level(extra_count))


func _mount(host: Control, level: Dictionary) -> PlayScreen:
	var screen: PlayScreen = load("res://scenes/play.tscn").instantiate()
	screen.persist = false
	screen.setup(_state(level), {"level_id": "mb"})
	host.add_child(screen)
	return screen


func _fill(screen: PlayScreen, program: Array) -> void:
	for node: Dictionary in program:
		screen._on_command(node["op"])
		if node["op"] == "REPEAT":
			screen._tape.adjust_count(int(node["count"]) - ContractLimits.REPEAT_COUNT_MIN)
		for inner: Dictionary in node.get("body", []):
			screen._on_command(inner["op"])
		if node.has("body"):
			screen._on_command(node["op"])


func _run_to_end(screen: PlayScreen) -> void:
	assert_true(screen._start(PlaySession.State.PAUSED))
	while screen._session.state == PlaySession.State.PAUSED:
		await PlayAnimator.play_one_step(screen)


func _marks(screen: PlayScreen) -> Array[bool]:
	var out: Array[bool] = []
	for i in screen._boards.count():
		out.append(screen._boards.is_solved(i))
	return out


func test_a_single_board_level_has_no_tabs() -> void:
	var host := Control.new()
	host.size = SIZES[0]
	add_child_autofree(host)
	var level := MultiSupport.level()
	level.erase("extraBoards")
	var screen := _mount(host, level)
	await wait_process_frames(2)
	assert_null(screen._tab_row)


func test_the_tab_row_fits_at_every_size_with_up_to_six_boards() -> void:
	for at in SIZES:
		for extra in [1, 2, 5]:
			var screen := _screen(at, extra)
			await wait_process_frames(2)
			var row: BoardTabs = screen._tab_row
			assert_not_null(row)
			assert_true(Rect2(Vector2.ZERO, at).encloses(Rect2(row.position, row.size)))
			var tabs: Array[Rect2] = []
			for child in row.get_children():
				if child is TileButton:
					tabs.append(Rect2(child.position, child.size))
					assert_gte(child.size.x, 36.0, "%s %d tab width" % [str(at), extra])
					assert_true(Rect2(Vector2.ZERO, row.size).encloses(tabs[-1]), "tab inside")
			assert_eq(tabs.size(), extra + 1)
			for i in range(1, tabs.size()):
				assert_gt(tabs[i].position.x, tabs[i - 1].end.x - 0.01, "tabs do not overlap")
			assert_gte(screen._board.size.x, 120.0, "%s %d the board keeps room" % [str(at), extra])
			assert_lte(row.position.y + row.size.y, screen._board.position.y + 0.5, "above board")


func test_labels_shrink_to_numbers_only_when_they_do_not_fit() -> void:
	var few := _screen(SIZES[1], 1)
	await wait_process_frames(2)
	assert_eq((few._tab_row.get_child(1) as TileButton).label, "BOARD 1")
	var many := _screen(SIZES[1], 5)
	await wait_process_frames(2)
	assert_eq((many._tab_row.get_child(1) as TileButton).label, "1")
	assert_true(many._tab_row._caption.visible, "the word BOARD stands in front of the row")


func test_solving_each_board_marks_it_and_selects_the_next_one() -> void:
	var screen := _screen(SIZES[0])
	await wait_process_frames(2)
	_fill(screen, MultiSupport.general())
	assert_eq(screen._boards.selected, 0)
	await _run_to_end(screen)
	assert_eq(_marks(screen), [true, false, false])
	assert_eq(screen._boards.selected, 1, "the next unsolved board is shown")
	assert_eq(screen._session.state, PlaySession.State.READY)
	assert_eq(screen._board.level["board"]["width"], 8)
	assert_eq(screen._message.text, "BOARD 1 SOLVED")
	var first_tab: TileButton = screen._tab_row.get_child(1)
	assert_eq(first_tab.icon, "check", "a solved board carries a check and its word")
	assert_eq(first_tab.label, "BOARD 1")
	await _run_to_end(screen)
	assert_eq(screen._boards.selected, 2)
	assert_ne(screen._session.state, PlaySession.State.SUCCEEDED, "not solved yet")
	await _run_to_end(screen)
	assert_eq(screen._session.state, PlaySession.State.SUCCEEDED, "every board solved")
	assert_true(screen._boards.all_solved())
	assert_eq(PlayView.run_steps(screen), 13, "steps are the sum over all boards")


func test_editing_the_program_clears_the_marks() -> void:
	var screen := _screen(SIZES[0])
	await wait_process_frames(2)
	_fill(screen, MultiSupport.general())
	await _run_to_end(screen)
	assert_eq(_marks(screen), [true, false, false])
	screen._on_command("TURN_LEFT")
	assert_eq(_marks(screen), [false, false, false])
	assert_eq(screen._message.text.begins_with("BOARD 1 SOLVED"), false)


func test_a_failure_names_its_board_and_the_level_is_not_solved() -> void:
	var screen := _screen(SIZES[1])
	await wait_process_frames(2)
	_fill(screen, MultiSupport.overfit())
	await _run_to_end(screen)
	assert_eq(screen._boards.selected, 1)
	await _run_to_end(screen)
	assert_eq(screen._session.state, PlaySession.State.FAILED)
	assert_true(
		PlayView.message_text(screen).begins_with("BOARD 2: "), PlayView.message_text(screen)
	)
	assert_false(screen._boards.all_solved())


func test_a_tab_shows_that_board_ready_to_run() -> void:
	var screen := _screen(SIZES[2])
	await wait_process_frames(2)
	PlayBoards.choose(screen, 2)
	assert_eq(screen._boards.selected, 2)
	assert_eq(screen._board.level["board"]["width"], 3)
	assert_eq(screen._session.state, PlaySession.State.READY)
