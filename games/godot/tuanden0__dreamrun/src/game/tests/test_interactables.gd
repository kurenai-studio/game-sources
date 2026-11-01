extends "res://tests/test_case.gd"


func _crate(world: Node2D, x: float) -> Crate:
	var crate := Crate.new()
	crate.position = Vector2(x, -28)
	world.add_child(crate)
	return crate


func test_push_then_pull_crate() -> void:
	var world := make_world()
	var player := spawn_player(world, 0.0)
	var crate := _crate(world, 50.0)  # 7 px gap to the player's right side, inside the grab zone
	await frames(30)
	var seen: Array[StringName] = []
	player.state_changed.connect(func(s: StringName) -> void: seen.append(s))

	var start := crate.position.x
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	await frames(60)
	check(player.grabbed == crate, "interact next to the crate should grab it")
	check(crate.position.x - start > 40.0, "pushing 1 s should move the crate right > 40 px, moved %s" % (crate.position.x - start))
	check(seen.has(&"push"), "should enter push state: %s" % [seen])

	Input.action_release(&"move_right")
	await frames(20)
	var after_push := crate.position.x
	Input.action_press(&"move_left")
	await frames(60)
	check(after_push - crate.position.x > 40.0, "pulling 1 s should move the crate left > 40 px, moved %s" % (after_push - crate.position.x))
	check(seen.has(&"pull"), "should enter pull state: %s" % [seen])

	release_all_inputs()
	await frames(3)
	check(player.grabbed == null, "releasing interact should let go")
	world.queue_free()
	await frames(1)


func test_plate_opens_door_and_closes_again() -> void:
	var world := make_world()
	var plate := PressurePlate.new()
	world.add_child(plate)
	var door := Door.new()
	door.position = Vector2(300, -110)
	door.size = Vector2(44, 220)
	world.add_child(door)
	plate.pressed_changed.connect(door.set_open)
	var crate := Crate.new()
	crate.position = Vector2(0, -80)  # drops onto the plate
	world.add_child(crate)
	await frames(80)
	check(plate.is_pressed and door.is_open, "crate on plate should press it and open the door")
	check(door.position.y < -110.0 - 200.0, "door should have slid up, y=%s" % door.position.y)
	crate.free()
	await frames(80)
	check(not plate.is_pressed and not door.is_open, "removing the crate should release the plate and close the door")
	check(absf(door.position.y - (-110.0)) < 2.0, "door should be back down, y=%s" % door.position.y)
	world.queue_free()
	await frames(1)


func test_lever_toggles_on_interact() -> void:
	var world := make_world()
	var lever := Lever.new()
	world.add_child(lever)
	var player := spawn_player(world, 0.0)
	var states: Array[bool] = []
	lever.toggled.connect(func(on: bool) -> void: states.append(on))
	await frames(10)
	Input.action_press(&"interact")
	await frames(2)
	Input.action_release(&"interact")
	await frames(2)
	Input.action_press(&"interact")
	await frames(2)
	release_all_inputs()
	check(states == [true, false], "two presses should toggle on then off, got %s" % [states])
	check(player.grabbed == null, "lever press must not grab anything")
	world.queue_free()
	await frames(1)


func test_ledge_ignores_climb_up_from_the_ground() -> void:
	var world := make_ledge_world()
	var player := spawn_player(world, 160.0)
	await frames(10)
	Input.action_press(&"climb_up")
	await frames(60)
	release_all_inputs()
	check(player.state != &"climb", "feet 160 px below the top are out of reach, state=%s" % player.state)
	check(player.position.y > -10.0, "player must stay on the ground, at %s" % player.position)
	world.queue_free()
	await frames(1)


func test_ledge_climb_when_hands_reach_the_edge() -> void:
	var world := make_ledge_world()
	var player := spawn_player(world, 160.0)
	player.position.y = -52.0  # low in a jump: hands level with the platform edge (feet 112 px below it)
	player.velocity.y = -300.0
	await frames(2)
	var seen: Array[StringName] = []
	player.state_changed.connect(func(s: StringName) -> void: seen.append(s))
	Input.action_press(&"climb_up")
	await frames(90)
	release_all_inputs()
	check(seen.has(&"climb"), "should enter climb state: %s" % [seen])
	check(player.position.x > 185.0 and player.position.y < -150.0, "should end on the platform, at %s" % player.position)
	world.queue_free()
	await frames(1)


func test_rope_grab_swing_and_release() -> void:
	var world := make_world()
	var rope := Rope.new()
	rope.position = Vector2(0, -400)
	world.add_child(rope)
	var player := spawn_player(world, 0.0)
	player.position = rope.bob_position() + Vector2(0, 78)  # hands at the grip, feet in the air
	await frames(3)
	var seen: Array[StringName] = []
	player.state_changed.connect(func(s: StringName) -> void: seen.append(s))
	Input.action_press(&"interact")
	await frames(2)
	Input.action_release(&"interact")
	await frames(30)
	check(rope.attached and player.state == &"hang", "interact in mid-air near the grip should hang on, state=%s" % player.state)
	var hang_error := player.global_position.distance_to(rope.bob_position() + Vector2(0, 78))
	check(hang_error < 2.0, "player should follow the rope tip, off by %s" % hang_error)
	var swing_velocity := rope.bob_velocity()
	Input.action_press(&"jump")
	await frames(2)
	Input.action_release(&"jump")
	check(not rope.attached, "jump should let go")
	check(player.velocity.y > swing_velocity.y - 60.0, "letting go must not add a jump: vy %s vs swing %s" % [player.velocity.y, swing_velocity.y])
	world.queue_free()
	await frames(1)


func test_rope_pumping_builds_amplitude_and_momentum_transfers() -> void:
	var world := make_world()
	var rope := Rope.new()
	rope.position = Vector2(0, -400)
	rope.start_angle_deg = 0.0
	world.add_child(rope)
	rope.attach(Vector2(200, 0))
	check(rope.omega > 0.5, "grabbing with sideways speed should start a swing, omega=%s" % rope.omega)
	rope.release()
	var damped := 0.0
	for i in 240:
		await frames(1)
		damped = maxf(damped, absf(rope.angle))
	rope.attach(Vector2.ZERO)
	var pumped := 0.0
	for i in 240:
		rope.pump(1.0)
		await frames(1)
		pumped = maxf(pumped, absf(rope.angle))
	check(pumped > deg_to_rad(40.0), "pumping should build a real swing, max %s deg" % rad_to_deg(pumped))
	check(absf(rope.angle) < deg_to_rad(70.0), "the swing tops out instead of looping over the anchor")
	world.queue_free()
	await frames(1)


func test_hard_landing_crouches_then_recovers() -> void:
	var world := make_world()
	var player := spawn_player(world, 0.0)
	await frames(30)
	var hip := player.get_node("Visual/Skeleton/Hip") as Node2D
	var rest := hip.position.y
	player.position.y = -200.0  # fall ~ 200 px onto the floor
	for i in 120:
		await frames(1)
		if player.state == &"land":
			break
	await frames(2)
	check(hip.position.y > rest + 5.0, "hips should drop after a hard landing: rest %s now %s" % [rest, hip.position.y])
	await frames(60)
	check(absf(hip.position.y - rest) < 3.0, "hips should recover: rest %s now %s" % [rest, hip.position.y])
	world.queue_free()
	await frames(1)


# ---------------------------------------------------------------- the door never closes on anyone

func _door_world() -> Dictionary:
	var world := make_world()
	var door := Door.new()
	door.position = Vector2(300, -110)
	door.size = Vector2(44, 220)
	world.add_child(door)
	return {"world": world, "door": door}


func _open_door(w: Dictionary) -> void:
	w.door.set_open(true)
	await frames(80)


func test_door_waits_for_a_crate_in_the_gateway_then_closes() -> void:
	var w := _door_world()
	var door: Door = w.door
	await frames(10)
	await _open_door(w)
	var crate := _crate(w.world, 300.0)  # under the raised door, where it would shut
	await frames(40)
	door.set_open(false)
	await frames(90)
	check(not door.is_open and door.is_held_up() and door.position.y < -300.0, "told to close but held up by the crate, y=%s" % door.position.y)
	check(absf(crate.global_position.x - 300.0) < 8.0 and crate.global_position.y > -40.0, "the crate was not pushed around, at %s" % crate.global_position)
	crate.global_position = Vector2(700, -28)
	await frames(60)
	check(not door.is_held_up() and absf(door.position.y - (-110.0)) < 2.0, "the way is clear: it shut, y=%s" % door.position.y)
	w.world.queue_free()
	await frames(1)


func test_door_waits_for_the_player_standing_under_it() -> void:
	var w := _door_world()
	var door: Door = w.door
	await frames(10)
	await _open_door(w)
	var player := spawn_player(w.world, 300.0)
	await frames(40)
	door.set_open(false)
	await frames(60)
	check(door.is_held_up() and door.position.y < -300.0, "does not drop on the player")
	check(not player.is_dead and absf(player.position.x - 300.0) < 4.0, "and the player was not shoved, x=%s" % player.position.x)
	Input.action_press(&"move_left")
	await frames(60)
	Input.action_release(&"move_left")
	await frames(60)
	check(not door.is_held_up() and absf(door.position.y - (-110.0)) < 2.0, "shut once the player stepped out, y=%s" % door.position.y)
	w.world.queue_free()
	await frames(1)


## Wrong way: told to close, then to open again, while still held up: it must not shut when the way clears.
func test_reopening_while_held_up_cancels_the_close() -> void:
	var w := _door_world()
	var door: Door = w.door
	await frames(10)
	await _open_door(w)
	var crate := _crate(w.world, 300.0)
	await frames(40)
	door.set_open(false)
	await frames(30)
	door.set_open(true)
	crate.global_position = Vector2(700, -28)
	await frames(90)
	check(door.is_open and not door.is_held_up() and door.position.y < -300.0, "it stays open, y=%s" % door.position.y)
	w.world.queue_free()
	await frames(1)


func test_a_checkpoint_reset_forgets_a_pending_close() -> void:
	var w := _door_world()
	var door: Door = w.door
	await frames(10)
	door.save_checkpoint()  # saved shut
	await _open_door(w)
	_crate(w.world, 300.0)
	await frames(40)
	door.set_open(false)
	await frames(10)
	check(door.is_held_up(), "setup: held up")
	door.reset_to_checkpoint()
	check(not door.is_held_up() and not door.is_open and absf(door.position.y - (-110.0)) < 2.0, "a reset puts it back shut and idle")
	w.world.queue_free()
	await frames(1)
