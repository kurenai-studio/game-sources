extends GutTest
## The worlds list: a locked world can be opened to look at its chapters and levels, but not played.


func _screen() -> ScreenBase:
	var content := ContentStore.new("user://test_worlds_locked_content")
	var state := AppState.new(
		Campaign.load_bundled(), ProgressStore.new("user://test_worlds_locked.json"), content
	)
	var host := Control.new()
	host.size = Vector2(390, 844)
	add_child_autofree(host)
	var screen: ScreenBase = load("res://scenes/worlds.tscn").instantiate()
	screen.setup(state, {})
	host.add_child(screen)
	return screen


func _tap(row: Control) -> void:
	var at := row.size / 2.0
	for pressed in [true, false]:
		var click := InputEventMouseButton.new()
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = pressed
		click.position = at
		row.call("_gui_input", click)


func test_a_locked_world_opens_its_preview_when_tapped() -> void:
	var screen := _screen()
	await wait_process_frames(2)
	var rows: Array = (screen.get("_list") as Control).get_children()
	assert_gt(rows.size(), 2, "several worlds")
	var locked: Control = rows[1]
	assert_eq(locked.get("state"), "locked", "a fresh player has only the first world open")
	assert_string_contains(str(locked.get("subtitle")), "LOCKED")
	watch_signals(screen)
	_tap(locked)
	assert_signal_emitted_with_parameters(screen, "navigate", ["world", {"world": 1}])
