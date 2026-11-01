extends "res://tests/test_case.gd"


func _room() -> Node2D:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	tree.root.add_child(room)
	var menu := room.get_node("PauseMenu") as PauseMenu
	menu.quits_the_game = false
	return room


func _action_event(action: StringName, pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


## A key press the way the engine delivers it, so the menu's own input handling is what is tested.
func _tap(action: StringName) -> void:
	_action_event(action, true)
	await frames(2)
	_action_event(action, false)
	await frames(2)


func _cleanup(room: Node2D) -> void:
	tree.paused = false
	release_all_inputs()
	room.queue_free()
	await frames(2)


func test_pause_stops_the_world_and_resume_carries_on() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	var monster := room.get_node("Monster") as Monster
	var player := room.get_node("Player") as PlayerController
	monster.start()
	await frames(20)
	await _tap(&"pause")
	check(tree.paused and menu.is_open(), "pause key opens the menu and pauses the tree")
	var monster_x := monster.position.x
	var player_pos := player.position
	Input.action_press(&"move_right")
	await frames(40)
	check(is_equal_approx(monster.position.x, monster_x), "the monster is frozen, moved %s" % (monster.position.x - monster_x))
	check(player.position.is_equal_approx(player_pos), "the player is frozen even with a key held")
	Input.action_release(&"move_right")
	await _tap(&"pause")
	check(not tree.paused and not menu.is_open(), "pause key again closes it")
	await frames(30)
	check(monster.position.x > monster_x + 20.0, "the monster walks on after resuming")
	await _cleanup(room)


func test_the_menu_shows_only_icons_no_text() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	await _tap(&"pause")
	var texts := 0
	var icons := 0
	var stack: Array[Node] = [menu]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is Label or node is RichTextLabel or node is Button or node is LineEdit:
			texts += 1
		if node is PauseMenu.PauseIcon:
			icons += 1
	check(texts == 0, "no text controls in the pause menu, found %d" % texts)
	check(icons == 3, "three icons: resume, checkpoint, quit; found %d" % icons)
	await _cleanup(room)


func test_arrows_choose_and_stop_at_the_ends() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	await _tap(&"pause")
	check(menu.selected == PauseMenu.Choice.RESUME, "opens on resume")
	for i in 5:
		await _tap(&"ui_left")
	check(menu.selected == PauseMenu.Choice.RESUME, "left of the first icon stays on it")
	await _tap(&"ui_right")
	check(menu.selected == PauseMenu.Choice.CHECKPOINT, "right moves to the checkpoint icon")
	for i in 5:
		await _tap(&"ui_right")
	check(menu.selected == PauseMenu.Choice.QUIT, "right of the last icon stays on it")
	await _tap(&"pause")
	await _tap(&"pause")
	check(menu.selected == PauseMenu.Choice.RESUME, "reopening starts on resume again")
	await _cleanup(room)


func test_accepting_resume_unpauses() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	var resumed := [0]
	menu.resumed.connect(func() -> void: resumed[0] += 1)
	await _tap(&"pause")
	await _tap(&"ui_accept")
	check(not tree.paused and not menu.is_open() and resumed[0] == 1, "accept on resume closes the menu, resumed=%d" % resumed[0])
	await _cleanup(room)


func test_checkpoint_icon_sends_the_player_back_within_a_second() -> void:
	var room := _room()
	var player := room.get_node("Player") as PlayerController
	var start := player.position
	await frames(10)
	Input.action_press(&"move_right")
	await frames(60)
	Input.action_release(&"move_right")
	check(player.position.x > start.x + 50.0, "walked away from the start")
	await _tap(&"pause")
	await _tap(&"ui_right")
	await _tap(&"ui_accept")
	check(not tree.paused, "the game runs again so the respawn can play")
	var frames_taken := 0
	for i in 120:
		await frames(1)
		frames_taken += 1
		if not player.is_dead and player.position.distance_to(start) < 8.0:
			break
	check(player.position.distance_to(start) < 8.0 and not player.is_dead, "back at the checkpoint, at %s" % player.position)
	check(frames_taken <= 60, "back within a second, took %d frames" % frames_taken)
	await _cleanup(room)


func test_quit_icon_asks_to_quit_but_this_test_keeps_running() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	var asked := [0]
	menu.quit_requested.connect(func() -> void: asked[0] += 1)
	await _tap(&"pause")
	await _tap(&"ui_right")
	await _tap(&"ui_right")
	await _tap(&"ui_accept")
	check(asked[0] == 1, "choosing quit asks once, asked=%d" % asked[0])
	await _cleanup(room)


## Wrong way: pausing while dying would freeze the black fade and the player could never come back.
func test_pause_is_ignored_while_dead() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	var player := room.get_node("Player") as PlayerController
	await frames(10)
	player.die()
	await frames(2)
	await _tap(&"pause")
	check(not tree.paused and not menu.is_open(), "no pause while the death plays")
	var came_back := false
	for i in 120:
		await frames(1)
		if not player.is_dead:
			came_back = true
			break
	check(came_back, "the player still respawns")
	await _cleanup(room)


## Wrong way: arrow keys and accept while the menu is closed must not touch the game.
func test_menu_keys_do_nothing_while_closed() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	var player := room.get_node("Player") as PlayerController
	await frames(10)
	var x := player.position.x
	await _tap(&"ui_right")
	await _tap(&"ui_accept")
	check(not tree.paused and not menu.is_open() and menu.selected == PauseMenu.Choice.RESUME, "closed menu ignores its keys")
	check(absf(player.position.x - x) < 1.0 and not player.is_dead, "and the game is untouched")
	await _cleanup(room)


## Wrong way: a person who hammers pause mid-jump and mid-walk. The game must end up running and the physics must
## stay believable across the pauses.
func test_bot_hammers_pause_while_playing() -> void:
	var room := _room()
	var menu := room.get_node("PauseMenu") as PauseMenu
	var player := room.get_node("Player") as PlayerController
	await frames(10)
	var rec := FlightRecorder.new(player, tree)
	rec.start()
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var keys: Array[StringName] = [&"move_left", &"move_right", &"jump", &"pause", &"pause", &"ui_right", &"ui_accept", &"ui_left"]
	for step in 120:
		var action: StringName = keys[rng.randi() % keys.size()]
		_action_event(action, true)
		if action == &"move_left" or action == &"move_right" or action == &"jump":
			Input.action_press(action)
		await frames(rng.randi_range(1, 25))
		Input.action_release(action)
		_action_event(action, false)
	if tree.paused:
		await _tap(&"pause")
	await frames(10)
	rec.stop()
	check(not tree.paused and not menu.is_open(), "ends up running after the mash")
	check(rec.violations.is_empty(), "violations across pauses:\n%s" % rec.report())
	await _cleanup(room)
