## Bots that play the game: scripted runs of what a player would do (including the wrong things) and
## seeded random button mashing. FlightRecorder reports any physics that cannot be right.
extends "res://tests/test_case.gd"

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"jump", &"interact", &"climb_up"]


func _hold(action: StringName, count: int) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)


func _record(player: PlayerController) -> FlightRecorder:
	var recorder := FlightRecorder.new(player, tree)
	recorder.start()
	return recorder


func test_bot_plain_jump_has_a_believable_arc() -> void:
	var world := make_world()
	var player := spawn_player(world, 0.0)
	await frames(20)
	var rec := _record(player)
	await _hold(&"jump", 3)
	await frames(90)
	rec.stop()
	check(rec.violations.is_empty(), "jump arc violations:\n%s" % rec.report())
	check(rec.max_rise > 110.0 and rec.max_rise < 135.0, "jump should rise ~128 px, rose %s" % rec.max_rise)
	check(player.is_on_floor(), "bot should be back on the floor")
	world.queue_free()
	await frames(1)


func test_bot_jump_with_up_held_grabs_the_ledge() -> void:
	var world := make_ledge_world()
	var player := spawn_player(world, 160.0)
	await frames(20)
	var rec := _record(player)
	Input.action_press(&"climb_up")
	await _hold(&"jump", 3)
	await frames(120)
	release_all_inputs()
	rec.stop()
	check(rec.violations.is_empty(), "ledge violations:\n%s" % rec.report())
	check(player.position.x > 185.0 and player.position.y < -150.0, "bot should end on the platform, at %s" % player.position)
	world.queue_free()
	await frames(1)


## Regression: the climb used to float straight up and then slide sideways high in the air.
func test_bot_ledge_climb_hugs_the_wall_then_rolls_over_the_top() -> void:
	var world := make_ledge_world()
	var ledge := world.get_children().filter(func(n: Node) -> bool: return n is Ledge)[0] as Ledge
	var player := spawn_player(world, 160.0)
	player.position.y = -52.0  # low in a jump: hands level with the edge
	player.velocity.y = -300.0
	await frames(2)
	var rec := _record(player)
	var lean_peak := 0.0
	var progress_seen := []
	var sideways_while_high := false
	player.climb_progress.connect(func(t: float) -> void: progress_seen.append(t))
	Input.action_press(&"move_right")  # only needed to catch the edge; the climb itself ignores input
	await frames(3)
	Input.action_release(&"move_right")
	for i in 150:
		await frames(1)
		var visual := player.get_node("Visual") as Node2D
		lean_peak = maxf(lean_peak, absf(visual.rotation))
		if player.state == &"climb" and player.global_position.x > ledge.hug_position().x + 6.0 				and player.global_position.y > ledge.hug_position().y + 4.0:
			sideways_while_high = true
	release_all_inputs()
	await frames(30)
	rec.stop()
	check(rec.violations.is_empty(), "climb violations:
%s" % rec.report())
	check(not progress_seen.is_empty() and progress_seen.back() >= 0.99, "climb progress should run to 1, saw %s samples" % progress_seen.size())
	check(not sideways_while_high, "must not slide over the edge while still below knee height")
	check(lean_peak > 0.25, "chest should lean over the edge mid-climb, peak lean %s rad" % lean_peak)
	check(player.position.x > ledge.top_position().x - 10.0 and absf(player.position.y - ledge.top_position().y) < 8.0, "ends standing on the platform, at %s" % player.position)
	check(absf((player.get_node("Visual") as Node2D).rotation) < 0.15, "upright again afterwards")
	world.queue_free()
	await frames(1)


## The jump should be low: the hands catch the edge on the way up, then the body hangs and pulls up.
func test_bot_low_jump_catches_the_edge_with_the_hands() -> void:
	var world := make_ledge_world()
	var ledge := world.get_children().filter(func(n: Node) -> bool: return n is Ledge)[0] as Ledge
	var player := spawn_player(world, 160.0)
	await frames(20)
	var grab := {}
	player.state_changed.connect(func(s: StringName) -> void:
		if s == &"climb" and not grab.has("feet_y"):
			grab["feet_y"] = player.global_position.y
			grab["vy"] = player.velocity.y)
	Input.action_press(&"move_right")
	await _hold(&"jump", 3)
	await frames(100)
	release_all_inputs()
	check(grab.has("feet_y"), "should have caught the edge")
	if grab.has("feet_y"):
		var below: float = grab.feet_y - ledge.top_position().y
		check(below > 85.0 and below < 140.0, "hands (not feet) meet the edge: feet were %s px below the top" % below)
	check(player.position.x > 185.0 and player.position.y < -150.0, "ends on the platform, at %s" % player.position)
	world.queue_free()
	await frames(1)


## Standing on the platform, even right at the edge, up must not start a climb.
func test_bot_up_key_on_top_of_the_platform_does_nothing() -> void:
	var world := make_ledge_world()
	var player := spawn_player(world, 200.0)
	player.position.y = -170.0
	await frames(30)
	var seen: Array[StringName] = []
	player.state_changed.connect(func(s: StringName) -> void: seen.append(s))
	var standing_y := player.position.y
	for action in [&"climb_up", &"move_right", &"climb_up"]:
		Input.action_press(action)
		await frames(40)
		Input.action_release(action)
	release_all_inputs()
	check(not seen.has(&"climb"), "no climb from standing on top: %s" % [seen])
	check(player.position.y < -150.0, "still standing on the platform, at %s (was %s)" % [player.position, standing_y])
	world.queue_free()
	await frames(1)


func test_bot_rope_pump_release_and_land() -> void:
	var world := make_world()
	var rope := Rope.new()
	rope.position = Vector2(0, -400)
	rope.start_angle_deg = 0.0
	world.add_child(rope)
	var player := spawn_player(world, 0.0)
	await frames(20)
	var rec := _record(player)
	await _hold(&"jump", 3)
	await frames(18)  # near the apex, hands level with the grip
	await _hold(&"interact", 2)
	await frames(5)
	check(rope.attached, "bot should be hanging on the rope, state=%s" % player.state)
	Input.action_press(&"move_right")
	var widest := 0.0
	for i in 300:
		await frames(1)
		widest = maxf(widest, absf(rope.angle))
	Input.action_release(&"move_right")
	check(widest > deg_to_rad(25.0), "pumping should build a swing, widest %s deg" % rad_to_deg(widest))
	await _hold(&"jump", 2)
	for i in 400:
		await frames(1)
		if player.is_on_floor():
			break
	await frames(5)
	rec.stop()
	check(rec.violations.is_empty(), "rope violations:\n%s" % rec.report())
	check(player.is_on_floor(), "bot should have landed after letting go, at %s" % player.position)
	world.queue_free()
	await frames(1)


## Regression: pushing a crate into a wall used to jam it into the floor and let the player sink into it.
func test_bot_pushes_crate_into_a_wall_then_pulls_it_back() -> void:
	var world := make_world()
	var wall := StaticBody2D.new()
	var wall_shape := CollisionShape2D.new()
	wall_shape.shape = RectangleShape2D.new()
	wall_shape.shape.size = Vector2(40, 200)
	wall.position = Vector2(320, -100)
	wall.add_child(wall_shape)
	world.add_child(wall)
	var crate := Crate.new()
	crate.position = Vector2(100, -28)
	world.add_child(crate)
	var player := spawn_player(world, 50.0)
	await frames(30)
	var rest_y := crate.position.y  # the irregular outline decides how high the centre rests
	var rec := _record(player)
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	var tightest_gap := INF
	for i in 300:
		await frames(1)
		# gap between the player's right side (15 px) and the crate's left side (~28 px)
		tightest_gap = minf(tightest_gap, (crate.position.x - 28.0) - (player.position.x + 15.0))
	check(crate.position.x > 250.0 and crate.position.x < 276.0, "crate should stop at the wall (~272), x=%s" % crate.position.x)
	check(absf(crate.position.y - rest_y) < 3.0, "crate must stay on the floor (rest %s), y=%s" % [rest_y, crate.position.y])
	check(tightest_gap > -2.0, "player must never sink into the crate, tightest gap %s" % tightest_gap)
	Input.action_release(&"move_right")
	var at_wall := crate.position.x
	Input.action_press(&"move_left")
	await frames(90)
	check(at_wall - crate.position.x > 40.0, "pulling should bring the crate back, moved %s" % (at_wall - crate.position.x))
	release_all_inputs()
	await frames(5)
	rec.stop()
	check(rec.violations.is_empty(), "violations:\n%s" % rec.report())
	check(absf(crate.position.y - rest_y) < 3.0, "crate must still be on the floor (rest %s), y=%s" % [rest_y, crate.position.y])
	world.queue_free()
	await frames(1)


func test_bot_random_mashing_in_the_test_room_breaks_no_physics() -> void:
	for seed_value in [1, 2, 3]:
		var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
		tree.root.add_child(room)
		var player := room.get_node("Player") as PlayerController
		await frames(10)
		var rec := _record(player)
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for step in 120:
			var action: StringName = ACTIONS[rng.randi() % ACTIONS.size()]
			Input.action_press(action)
			await frames(rng.randi_range(1, 40))
			if rng.randf() < 0.8:
				Input.action_release(action)
		release_all_inputs()
		await frames(5)
		rec.stop()
		check(rec.violations.is_empty(), "seed %d violations (%d):\n%s" % [seed_value, rec.violations.size(), rec.report()])
		room.queue_free()
		await frames(2)


## The real test_room trap set-up: a boulder over the path at x=1900 fired by a plate at 2250 (crate on it),
## electricity at 2450 fired by a lever at 2800. The monster walks right from x=1300.
func _trap_room() -> Dictionary:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	tree.root.add_child(room)
	var player := room.get_node("Player") as PlayerController
	var crate := room.get_node("CrateT") as Crate
	player.position = Vector2(crate.position.x - 50.0, -2)  # right behind the crate, inside the grab zone
	var monster := room.get_node("Monster") as Monster
	monster.position.x = 1300.0
	var stuns := [0]
	monster.stunned.connect(func() -> void: stuns[0] += 1)
	return {"room": room, "player": player, "crate": crate, "monster": monster, "stuns": stuns}


func test_bot_times_the_crate_on_the_plate_to_drop_the_boulder_on_the_monster() -> void:
	var t := _trap_room()
	var player: PlayerController = t.player
	var monster: Monster = t.monster
	await frames(30)
	var rec := _record(player)
	monster.start()
	Input.action_press(&"interact")  # take hold of the crate and wait for the monster to get close
	while monster.position.x < 1650.0:
		await frames(1)
	Input.action_press(&"move_right")
	var plate := t.room.get_node("PlateT") as PressurePlate
	for i in 400:
		await frames(1)
		if plate.is_pressed:
			break
	release_all_inputs()
	check(plate.is_pressed, "pushing the crate should press the plate, crate x=%s" % t.crate.position.x)
	await frames(60)
	check(t.stuns[0] == 1, "the boulder should land on the monster, stuns=%d monster x=%s" % [t.stuns[0], monster.position.x])
	check(not player.is_dead, "the player stays alive")
	var held_at := monster.position.x
	await frames(60)
	check(absf(monster.position.x - held_at) < 1.0, "monster stays stunned, moved %s" % (monster.position.x - held_at))
	# Wrong way: run back at the monster the boulder lies on. The boulder blocks the way and the monster stays pinned.
	Input.action_press(&"move_left")
	await frames(200)
	release_all_inputs()
	check(not player.is_dead, "the pinned monster must not kill, x=%s monster x=%s" % [player.position.x, monster.position.x])
	check(monster.is_stunned(), "still pinned many seconds after the boulder landed")
	check(player.position.x > 1900.0 + 65.0, "the solid boulder stops the player, x=%s" % player.position.x)
	rec.stop()
	check(rec.violations.is_empty(), "violations:\n%s" % rec.report())
	t.room.queue_free()
	await frames(2)


## Wrong way: pressing the plate long before the monster is under the boulder wastes the trap.
func test_bot_presses_the_plate_too_early_and_the_monster_walks_on() -> void:
	var t := _trap_room()
	var monster: Monster = t.monster
	await frames(30)
	monster.start()
	Input.action_press(&"interact")
	Input.action_press(&"move_right")
	var plate := t.room.get_node("PlateT") as PressurePlate
	for i in 400:
		await frames(1)
		if plate.is_pressed:
			break
	release_all_inputs()
	await frames(60)
	var trap := t.room.get_node("DropTrapA") as DropTrap
	check(plate.is_pressed and not trap.armed, "the early press spends the trap")
	check(t.stuns[0] == 0 and monster.position.x < 1700.0, "boulder landed on empty ground: stuns=%d monster x=%s" % [t.stuns[0], monster.position.x])
	await frames(120)
	check(monster.position.x > 1800.0, "monster walks past the spent trap, x=%s" % monster.position.x)
	t.room.queue_free()
	await frames(2)


func test_bot_pulls_the_lever_while_the_monster_crosses_the_electric_field() -> void:
	var t := _trap_room()
	var player: PlayerController = t.player
	var monster: Monster = t.monster
	var lever := t.room.get_node("LeverT") as Lever
	player.position = Vector2(lever.position.x - 20.0, -2)
	monster.position.x = 2200.0
	await frames(30)
	var rec := _record(player)
	monster.start()
	while monster.position.x < 2350.0:
		await frames(1)
	await _hold(&"interact", 3)
	check(lever.is_on, "interact next to the lever should flip it")
	await frames(120)
	check(monster.position.x > 2350.0 and monster.position.x < 2450.0 + 130.0, "monster held inside the field, x=%s" % monster.position.x)
	check(not player.is_dead, "the player stays alive")
	rec.stop()
	check(rec.violations.is_empty(), "violations:\n%s" % rec.report())
	t.room.queue_free()
	await frames(2)


## Regression: the hands used to be held out at shoulder height, above the crate, pushing air.
func _hand_gap(player: PlayerController, crate: Crate) -> Dictionary:
	var face_x := crate.global_position.x - crate.size.x * 0.5
	var top_y := crate.global_position.y - crate.size.y * 0.5
	var worst_x := 0.0
	var outside_y := false
	for i in 2:
		var fore := player.get_node("Visual/Skeleton/Hip/Arm%d/Fore%d" % [i, i]) as Node2D
		var hand := fore.to_global(Vector2(15.0, 0.0))
		worst_x = maxf(worst_x, absf(hand.x - face_x))
		outside_y = outside_y or hand.y < top_y - 2.0 or hand.y > crate.global_position.y + crate.size.y * 0.5
	return {"gap": worst_x, "outside_y": outside_y}


func test_bot_hands_stay_on_the_crate_face_while_pushing_and_pulling() -> void:
	var world := make_world()
	var crate := Crate.new()
	crate.position = Vector2(100, -28)
	world.add_child(crate)
	var player := spawn_player(world, 50.0)
	await frames(30)
	var worst := 0.0
	var worst_by := {}
	var off_crate := 0
	Input.action_press(&"interact")
	for direction in [&"move_right", &"move_left"]:
		Input.action_press(direction)
		for i in 90:
			await frames(1)
			if i < 30:
				continue  # let the pose settle after grabbing or turning
			var g := _hand_gap(player, crate)
			worst = maxf(worst, g.gap)
			worst_by[direction] = maxf(worst_by.get(direction, 0.0), g.gap)
			off_crate += 1 if g.outside_y else 0
		Input.action_release(direction)
		await frames(10)
	release_all_inputs()
	check(worst < 6.0, "hands must rest on the crate face, worst gap %s px %s" % [worst, worst_by])
	check(off_crate == 0, "hands must be level with the crate, %d frames off" % off_crate)
	world.queue_free()
	await frames(1)


## The real boss arena in test_room: boss pen -2500..-1900, a lever alcove beyond each end (east LeverBR fires the
## electric trap, west LeverBL the boulder). The player walks in from the checkpoint at -1480.
func _boss_room() -> Dictionary:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	tree.root.add_child(room)
	var player := room.get_node("Player") as PlayerController
	player.position = Vector2(-1400, -2)
	return {"room": room, "player": player, "boss": room.get_node("Boss"), "east": room.get_node("LeverBR"), "west": room.get_node("LeverBL")}


func _walk_to(player: PlayerController, x: float, max_frames: int) -> void:
	var action := &"move_left" if x < player.position.x else &"move_right"
	Input.action_press(action)
	for i in max_frames:
		await frames(1)
		if (action == &"move_left" and player.position.x <= x) or (action == &"move_right" and player.position.x >= x):
			break
	Input.action_release(action)
	await frames(15)  # stop sliding


func _wait_state(boss: Boss, state: StringName, within: int) -> bool:
	for i in within:
		if boss.state_name() == state:
			return true
		await frames(1)
	return false


func test_bot_beats_the_boss_with_the_two_levers() -> void:
	var b := _boss_room()
	var player: PlayerController = b.player
	var boss: Boss = b.boss
	await frames(30)
	var rec := _record(player)
	await _walk_to(player, -1715.0, 200)  # past the trigger (wakes the boss) into the east alcove
	check(boss.active, "walking in wakes the boss")
	check(await _wait_state(boss, &"recover", 600) and boss.position.x > -1950.0, "boss charges east and crashes at the edge, x=%s" % boss.position.x)
	await _hold(&"interact", 3)  # electric trap
	await frames(10)
	check(boss.hits == 1 and boss.phase() == 2, "the electric trap is the first hit, hits=%d" % boss.hits)
	check(not player.is_dead, "the alcove is out of its reach")
	await _walk_to(player, -2660.0, 400)  # cross the pen while it is held down
	check(not player.is_dead, "crossed the pen while the boss was stunned")
	check(player.position.x < -2600.0, "reached the west alcove, x=%s" % player.position.x)
	check(await _wait_state(boss, &"recover", 600) and boss.position.x < -2450.0, "phase 2 charges west and crashes, x=%s" % boss.position.x)
	await _hold(&"interact", 3)  # boulder
	await frames(60)
	check(boss.state_name() == &"dead", "the boulder brings it down, state=%s hits=%d" % [boss.state_name(), boss.hits])
	check(not player.is_dead, "player survives the whole fight")
	rec.stop()
	check(rec.violations.is_empty(), "violations:\n%s" % rec.report())
	b.room.queue_free()
	await frames(2)


## Wrong way: stepping into the pen gets you killed, and the checkpoint puts the boss back as it was.
func test_bot_dies_in_the_pen_and_the_checkpoint_restores_the_boss() -> void:
	var b := _boss_room()
	var player: PlayerController = b.player
	var boss: Boss = b.boss
	await frames(30)
	await _walk_to(player, -1715.0, 200)
	check(await _wait_state(boss, &"recover", 600), "boss at the edge")
	await _hold(&"interact", 3)
	await frames(10)
	check(boss.hits == 1, "the electric trap lands, hits=%d" % boss.hits)
	await _walk_to(player, -2660.0, 400)  # cross while it is held down: the west alcove has the mid-fight checkpoint
	check((b.room.get_node("CheckpointD") as Checkpoint).is_active, "mid-fight checkpoint reached, x=%s" % player.position.x)
	await _walk_to(player, -2300.0, 300)  # wrong way: back into the pen
	for i in 600:
		await frames(1)
		if player.is_dead:
			break
	check(player.is_dead, "stepping into the pen kills")
	for i in 120:
		await frames(1)
		if not player.is_dead:
			break
	await frames(5)
	check(not player.is_dead and boss.hits == 1 and boss.phase() == 2 and boss.active, "respawned in the alcove with the boss still hit once, hits=%d" % boss.hits)
	check(player.position.x < -2600.0, "respawn at the mid-fight checkpoint, x=%s" % player.position.x)
	b.room.queue_free()
	await frames(2)


## The fire trap of the test room: its lever is out of the monster's reach, so lighting it as the monster walks into the
## flames holds it there while they burn; lighting it long before does nothing to a monster that is not yet in them.
func test_bot_lights_the_fire_as_the_monster_walks_in() -> void:
	var room := (load("res://scenes/test_room.tscn") as PackedScene).instantiate()
	tree.root.add_child(room)
	var player := room.get_node("Player") as PlayerController
	var monster := room.get_node("Monster") as Monster
	var lever := room.get_node("LeverF") as Lever
	var fire := room.get_node("FireTrapA") as FireTrap
	player.position = Vector2(lever.position.x - 15.0, -2.0)
	monster.position.x = 2300.0
	await frames(30)
	var rec := _record(player)
	monster.start()
	while monster.position.x < 2540.0:  # the edge of the flames
		await frames(1)
	await _hold(&"interact", 3)
	check(lever.is_on and fire.is_burning(), "the lever lights the fire")
	var held_at := monster.position.x
	await frames(120)
	check(monster.is_stunned() and monster.position.x - held_at < 20.0, "the monster is held in the flames, moved %s" % (monster.position.x - held_at))
	check(not player.is_dead, "the player is untouched")
	await frames(60 * 7 - 120)  # the fire burns 3.5 s and the stun lingers 3 s after it; then it walks on
	check(not fire.is_burning() and not monster.is_stunned() and monster.position.x > held_at + 15.0, "when the fire dies down the monster walks on, x=%s" % monster.position.x)
	rec.stop()
	check(rec.violations.is_empty(), "violations:\n%s" % rec.report())
	room.queue_free()
	await frames(2)
