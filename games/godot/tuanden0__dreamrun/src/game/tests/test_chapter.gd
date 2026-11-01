## Chapter 1 played by bots on the real scene (levels/chapter1.tscn): every section from its own checkpoint, then the
## whole chapter in one go. A bot may not die and FlightRecorder must stay quiet (physics, teleports, being stuck).
## The solvers do what a player does: run, hop, climb with up held, swing and let go, push a crate, pull a lever.
extends "res://tests/test_case.gd"

const SCENE := "res://levels/chapter1.tscn"
const SimBot := preload("res://tests/test_player_sim.gd")


## Loads the chapter and, when `checkpoint` is given, puts the player on that checkpoint the way a respawn would.
func _chapter(checkpoint: String = "") -> Dictionary:
	SaveGame.erase()  # a section test must not resume where the one before it ended
	var room := (load(SCENE) as PackedScene).instantiate() as Chapter
	room.change_scenes = false
	tree.root.add_child(room)
	var player := room.get_node("Player") as PlayerController
	var heard := {"zones": [], "steps": [0], "saved": []}
	(room.get_node("Audio") as AudioManager).zone_changed.connect(func(zone: StringName) -> void: heard.zones.append(zone))
	(room.get_node("Audio") as AudioManager).footstep.connect(func(_kind: StringName) -> void: heard.steps[0] += 1)
	(room.get_node("Progress") as Progress).saved.connect(func(checkpoint: StringName) -> void: heard.saved.append(checkpoint))
	await frames(5)
	if checkpoint != "":
		var cp := room.get_node(checkpoint) as Checkpoint
		player.position = cp.position + Vector2(0.0, -2.0)
		await frames(20)
	var c := {"room": room, "player": player, "deaths": [0], "done": [false], "carry": [], "heard": heard}
	player.died.connect(func() -> void: c.deaths[0] += 1)
	room.completed.connect(func() -> void: c.done[0] = true)
	var rec := FlightRecorder.new(player, tree)
	rec.start()
	c["rec"] = rec
	return c


## A deliberate jump to another spot (a test, not a bug): the recorder starts afresh there.
func _teleport(c: Dictionary, to: Vector2) -> void:
	c.rec.stop()
	c.carry.append_array(c.rec.violations.filter(func(v: String) -> bool: return not v.contains("teleported")))
	c.player.position = to
	c.player.velocity = Vector2.ZERO
	await frames(30)
	c.rec = FlightRecorder.new(c.player, tree)
	c.rec.start()


func _finish(c: Dictionary) -> void:
	c.rec.stop()
	release_all_inputs()
	var all: Array = c.carry + c.rec.violations
	check(c.deaths[0] == 0, "the bot must not die, died %d times" % c.deaths[0])
	check(all.is_empty(), "violations:\n%s" % "\n".join(all.slice(0, 6)))
	tree.paused = false
	c.room.queue_free()
	await frames(3)


func _reached(c: Dictionary, checkpoint: String) -> void:
	check((c.room.get_node(checkpoint) as Checkpoint).is_active, "should have reached %s, player at %s" % [checkpoint, c.player.position])


func _hold(action: StringName, count: int) -> void:
	Input.action_press(action)
	await frames(count)
	Input.action_release(action)


## Holds right until the player is at `x` (or `max_frames` pass). Keeps the key down on return when `keep` is set.
func _run_to(p: PlayerController, x: float, max_frames: int = 900, keep: bool = false, toward: StringName = &"") -> void:
	var action := toward if toward != &"" else (&"move_right" if x > p.position.x else &"move_left")
	Input.action_press(action)
	for i in max_frames:
		await frames(1)
		if (action == &"move_right" and p.position.x >= x) or (action == &"move_left" and p.position.x <= x):
			break
	if not keep:
		Input.action_release(action)


## Walks up to `x` gently and stops there (for grabbing a crate or reaching a lever).
func _walk_to(p: PlayerController, x: float) -> void:
	await _run_to(p, x - 70.0 if x > p.position.x else x + 70.0, 900)
	var action := &"move_right" if x > p.position.x else &"move_left"
	for i in 120:
		if absf(p.position.x - x) < 8.0:
			break
		Input.action_press(&"move_right" if x > p.position.x else &"move_left")
		await frames(2)
		Input.action_release(&"move_right")
		Input.action_release(&"move_left")
		await frames(2)
	await frames(15)


## Jumps without letting go of the direction key.
func _hop(count: int = 3) -> void:
	await _hold(&"jump", count)


func _pushing_until(p: PlayerController, crate: Crate, direction: StringName, done: Callable, max_frames: int = 900) -> void:
	Input.action_press(&"interact")
	Input.action_press(direction)
	var still := 0
	var last := crate.global_position.x
	for i in max_frames:
		await frames(1)
		if done.call():
			break
		still = still + 1 if absf(crate.global_position.x - last) < 0.2 else 0
		last = crate.global_position.x
		if still > 40 and i > 30:
			break
	Input.action_release(direction)
	Input.action_release(&"interact")
	await frames(10)


# ---------------------------------------------------------------- sections

func _intro(c: Dictionary) -> void:
	var p: PlayerController = c.player
	await _run_to(p, 430.0, 600, true)  # the log: hop it
	await _hop()
	await _run_to(p, 700.0, 300)
	await _walk_to(p, 985.0)  # the wall: jump at it with up held, the hands catch the ledge
	Input.action_press(&"climb_up")
	Input.action_press(&"move_right")
	await _hop()
	await frames(100)
	release_all_inputs()
	check(p.position.y < -150.0, "on top of the first wall, at %s" % p.position)
	await _run_to(p, 1300.0, 400)  # off the far side
	await _walk_to(p, 1760.0)  # under the rope: jump, catch the grip at the top of the jump
	await _hop()
	await frames(18)
	await _hold(&"interact", 2)
	await frames(3)
	var rope := c.room.get_node("Rope1") as Rope
	check(rope.attached, "should be hanging on the rope")
	Input.action_press(&"move_right")
	for i in 60:
		await frames(1)
	for i in 300:  # let go on the way up at the far end of the swing
		await frames(1)
		if rope.angle > deg_to_rad(15.0) and rope.omega > 0.0:
			break
	await _hold(&"jump", 2)
	Input.action_release(&"move_right")
	for i in 200:
		await frames(1)
		if p.is_on_floor():
			break
	check(p.position.x > 1940.0 and p.position.y < -150.0, "landed on the platform above, at %s" % p.position)
	await _run_to(p, 2400.0, 600)  # walk off its far end


func _door_one(c: Dictionary) -> void:
	var p: PlayerController = c.player
	var crate := c.room.get_node("Crate1") as Crate
	var plate := c.room.get_node("Plate1") as PressurePlate
	await _walk_to(p, 2508.0)
	await _pushing_until(p, crate, &"move_right", func() -> bool: return plate.is_pressed)
	check(plate.is_pressed, "the crate should be holding the plate, crate x=%s" % crate.global_position.x)
	await frames(60)  # the door slides open
	check((c.room.get_node("Door1") as Door).is_open, "door one is open")
	await _run_to(p, crate.global_position.x - 70.0, 300, true, &"move_right")  # hop the crate that holds it
	await _hop()
	await _run_to(p, 3500.0, 400)


func _lever_platform(c: Dictionary) -> void:
	var p: PlayerController = c.player
	await _run_to(p, 3725.0, 600)
	Input.action_press(&"climb_up")
	Input.action_press(&"move_right")
	await _hop()
	await frames(100)
	release_all_inputs()
	check(p.position.y < -150.0, "up on the lever platform, at %s" % p.position)
	var lever := c.room.get_node("Lever2") as Lever
	await _walk_to(p, lever.position.x - 5.0)
	await _hold(&"interact", 3)
	await frames(60)
	check(lever.is_on and (c.room.get_node("Door2") as Door).is_open, "the lever opens door two")
	await _run_to(p, 4560.0, 600)


func _crate_step(c: Dictionary) -> void:
	var p: PlayerController = c.player
	var crate := c.room.get_node("Crate2") as Crate
	await _walk_to(p, 4708.0)
	await _pushing_until(p, crate, &"move_right", func() -> bool: return false, 700)  # until it meets the wall
	check(crate.global_position.x > 4950.0, "the crate is against the wall, x=%s" % crate.global_position.x)
	Input.action_press(&"move_right")  # step up onto the crate
	await frames(5)
	await _hop()
	await frames(50)
	Input.action_release(&"move_right")
	check(absf(p.position.y - (crate.global_position.y - 28.0)) < 6.0, "standing on the crate, at %s (crate %s)" % [p.position, crate.global_position])
	Input.action_press(&"climb_up")  # from the crate the ledge is within reach
	Input.action_press(&"move_right")
	await _hop()
	await frames(110)
	release_all_inputs()
	check(p.position.y < -250.0, "up on the tall wall, at %s" % p.position)
	await _run_to(p, 5500.0, 500)


func _chase(c: Dictionary) -> void:
	var p: PlayerController = c.player
	var monster := c.room.get_node("Monster") as Monster
	Input.action_press(&"move_right")
	var hopped := {}
	for i in 2400:
		await frames(1)
		if p.is_dead:
			break
		var x := p.position.x
		for log_x in [5905.0, 6400.0]:  # hop the two logs
			if x >= log_x and not hopped.has(log_x) and p.is_on_floor():
				hopped[log_x] = true
				Input.action_press(&"jump")
				await frames(3)
				Input.action_release(&"jump")
		if x >= 6785.0 and not hopped.has("wall"):  # the last wall needs the ledge
			hopped["wall"] = true
			Input.action_press(&"climb_up")
			Input.action_press(&"jump")
			await frames(3)
			Input.action_release(&"jump")
			await frames(100)
			Input.action_release(&"climb_up")
		if x >= 7520.0:
			break
	Input.action_release(&"move_right")
	check(monster.position.x > 5100.0, "the monster woke and followed, x=%s" % monster.position.x)


func _boss(c: Dictionary) -> void:
	var p: PlayerController = c.player
	var boss := c.room.get_node("Boss") as Boss
	await _walk_to(p, 7730.0 + 15.0)  # the west alcove, beside its lever
	await _wait_for_boss(boss, &"recover", func() -> bool: return boss.position.x < 7950.0)
	await _hold(&"interact", 3)  # the electric trap
	await frames(10)
	check(boss.hits == 1, "the electric trap is the first hit, hits=%d" % boss.hits)
	await _run_to(p, 8665.0, 700)  # across the pen while it is held
	await frames(20)
	check((c.room.get_node("CheckpointMidFight") as Checkpoint).is_active, "the mid-fight checkpoint is lit")
	await _wait_for_boss(boss, &"recover", func() -> bool: return boss.position.x > 8450.0)
	await _hold(&"interact", 3)  # the boulder
	await frames(60)
	check(boss.state_name() == &"dead", "the boulder brings it down, state=%s hits=%d" % [boss.state_name(), boss.hits])
	await _run_to(p, 9060.0, 500)  # out of the pen to the checkpoint before the final boss


## The final boss: three hits. Shock from the west alcove, then the boulder from the east alcove, then (it is now
## fast and recovers in a blink) the fire from the second lever of the east alcove, which burns long enough to catch it.
func _final_boss(c: Dictionary) -> void:
	var p: PlayerController = c.player
	var boss := c.room.get_node("FinalBoss") as Boss
	await _walk_to(p, 9285.0)
	await _wait_for_boss(boss, &"recover", func() -> bool: return boss.position.x < 9560.0)
	await _hold(&"interact", 3)
	await frames(10)
	check(boss.hits == 1 and boss.phase() == 2, "the electric trap is hit one, phase %d" % boss.phase())
	await _walk_to(p, 10630.0)  # across the big pen while it is held, and stop at the lever
	await frames(20)
	check((c.room.get_node("CheckpointFinalMid") as Checkpoint).is_active, "the mid-fight checkpoint is lit")
	await _wait_for_boss(boss, &"recover", func() -> bool: return boss.position.x > 10340.0)
	await _hold(&"interact", 3)
	await frames(50)  # the boulder takes about half a second to fall
	check(boss.hits == 2 and boss.phase() == 3, "the boulder is hit two, phase %d" % boss.phase())
	# phase 3 is too quick to catch with the boulder: light the fire in the second lever's alcove as soon as the boss
	# shakes off the stun, and let it run into the flames
	var fire := c.room.get_node("FinalFireTrap") as FireTrap
	var fire_lever := c.room.get_node("LeverFinalFire") as Lever
	await _walk_to(p, 10710.0)
	for attempt in 4:
		for i in 900:
			if not boss.is_stunned() and fire.armed:
				break
			await frames(1)
		await _hold(&"interact", 3)
		await frames(150)
		if boss.state_name() == &"dead":
			break
		if fire_lever.is_on:
			await _hold(&"interact", 3)  # off, so that the next pull lights it again
	check(boss.state_name() == &"dead", "the third hit brings it down, state=%s hits=%d" % [boss.state_name(), boss.hits])
	await _run_to(p, 11050.0, 500)


func _wait_for_boss(boss: Boss, state: StringName, where: Callable) -> void:
	for i in 900:
		if boss.state_name() == state and where.call():
			return
		await frames(1)


# ---------------------------------------------------------------- tests

func test_intro_log_wall_and_rope() -> void:
	var c := await _chapter("CheckpointStart")
	await _intro(c)
	_reached(c, "CheckpointRope")
	await _finish(c)


func test_puzzle_one_crate_on_the_plate_opens_the_door() -> void:
	var c := await _chapter("CheckpointRope")
	await _door_one(c)
	_reached(c, "CheckpointDoor1")
	await _finish(c)


func test_puzzle_two_lever_on_the_platform() -> void:
	var c := await _chapter("CheckpointDoor1")
	await _lever_platform(c)
	_reached(c, "CheckpointLever")
	await _finish(c)


func test_puzzle_three_crate_is_the_step_to_the_ledge() -> void:
	var c := await _chapter("CheckpointLever")
	await _crate_step(c)
	_reached(c, "CheckpointWall")
	await _finish(c)


func test_chase_from_the_wall_to_the_pen() -> void:
	var c := await _chapter("CheckpointWall")
	await _chase(c)
	_reached(c, "CheckpointPen")
	await _finish(c)


func test_mini_boss_fight_with_the_two_traps() -> void:
	var c := await _chapter("CheckpointPen")
	await _boss(c)
	_reached(c, "CheckpointFinal")
	await _finish(c)


func test_final_boss_fight_with_three_hits_and_the_exit() -> void:
	var c := await _chapter("CheckpointFinal")
	await _final_boss(c)
	check(c.done[0], "walking out through the exit completes the chapter")
	await _finish(c)


func test_the_whole_chapter_in_one_run() -> void:
	var c := await _chapter()
	await _intro(c)
	await _door_one(c)
	await _lever_platform(c)
	await _crate_step(c)
	await _chase(c)
	await _boss(c)
	await _final_boss(c)
	check(c.done[0], "the chapter is completed")
	# what the player heard and what was kept, on the way
	check(c.heard.zones == [&"ZoneIntro", &"ZonePuzzles", &"ZoneChase", &"ZonePen", &"ZoneFinal"], "the ambience changed zone in order: %s" % [c.heard.zones])
	check(c.heard.steps[0] > 60, "footsteps all the way (a step per ~150 px of the 9000), heard %d" % c.heard.steps[0])
	check(c.heard.saved == [&"CheckpointStart", &"CheckpointRope", &"CheckpointDoor1", &"CheckpointLever", &"CheckpointWall", &"CheckpointPen", &"CheckpointMidFight", &"CheckpointFinal", &"CheckpointFinalMid"], "every checkpoint was saved in order: %s" % [c.heard.saved])
	var kept := SaveGame.read()
	check(kept.get("completed") == true and kept.get("checkpoint") == "CheckpointFinalMid", "the finished chapter is in the save: %s" % [kept])
	await _finish(c)


# ---------------------------------------------------------------- the wrong way

## Pushing the crate past the plate into the door jams it against the door; pulling it back puts it on the plate.
func test_bot_overpushes_crate_one_then_pulls_it_back_onto_the_plate() -> void:
	var c := await _chapter("CheckpointRope")
	var p: PlayerController = c.player
	var crate := c.room.get_node("Crate1") as Crate
	var plate := c.room.get_node("Plate1") as PressurePlate
	await _walk_to(p, 2508.0)
	await _pushing_until(p, crate, &"move_right", func() -> bool: return false, 900)  # never lets go: right up to the door
	check(crate.global_position.x > 3100.0, "the crate went past the plate, x=%s" % crate.global_position.x)
	check(not plate.is_pressed, "so the door is shut again")
	await _pushing_until(p, crate, &"move_left", func() -> bool: return plate.is_pressed, 600)
	check(plate.is_pressed, "pulling it back lands it on the plate, crate x=%s" % crate.global_position.x)
	await _finish(c)


## The puzzles cannot be skipped: the bot throws itself at each obstacle with every move it has.
func test_bot_cannot_skip_the_door_the_rope_or_the_tall_wall() -> void:
	var c := await _chapter("CheckpointRope")
	var p: PlayerController = c.player
	# door one: hop and climb at it for six seconds
	await _run_to(p, 3100.0, 700)
	Input.action_press(&"move_right")
	Input.action_press(&"climb_up")
	for i in 360:
		if i % 30 == 0:
			Input.action_press(&"jump")
		if i % 30 == 5:
			Input.action_release(&"jump")
		await frames(1)
	release_all_inputs()
	check(p.position.x < 3200.0 - 22.0, "door one holds, player x=%s" % p.position.x)
	# the rope platform: jump and climb under it, no rope
	await _teleport(c, Vector2(1700.0, -2.0))
	var top := 0.0
	Input.action_press(&"climb_up")
	Input.action_press(&"move_right")
	for i in 240:
		if i % 40 == 0:
			Input.action_press(&"jump")
		if i % 40 == 6:
			Input.action_release(&"jump")
		await frames(1)
		if p.position.x < 2300.0:  # the crate further on is a step of its own
			top = minf(top, p.position.y)
		if p.position.x > 2250.0:
			Input.action_release(&"move_right")
	release_all_inputs()
	check(top > -140.0 and p.position.y > -150.0, "no way up to the rope platform without the rope, highest %s" % top)
	# the tall wall: jumping at it from the ground (the crate is far away)
	await _teleport(c, Vector2(5030.0, -2.0))
	Input.action_press(&"climb_up")
	Input.action_press(&"move_right")
	for i in 240:
		if i % 40 == 0:
			Input.action_press(&"jump")
		if i % 40 == 6:
			Input.action_release(&"jump")
		await frames(1)
	release_all_inputs()
	check(p.position.y > -150.0, "the tall wall cannot be climbed from the ground, player y=%s" % p.position.y)
	c.deaths[0] = 0
	await _finish(c)


## Standing still when the monster wakes gets you caught, and you are back at the checkpoint in under a second with
## the monster pulled back behind it.
func test_bot_stands_still_in_the_chase_and_is_sent_back_to_the_checkpoint() -> void:
	var c := await _chapter("CheckpointWall")
	var p: PlayerController = c.player
	var monster := c.room.get_node("Monster") as Monster
	var stamps := {}
	p.died.connect(func() -> void: stamps["died"] = Engine.get_physics_frames())
	p.respawned.connect(func() -> void: stamps["respawned"] = Engine.get_physics_frames())
	await _run_to(p, 5600.0, 300)  # past the trigger, then stop and wait
	for i in 900:
		await frames(1)
		if stamps.has("respawned"):
			break
	check(stamps.has("died") and stamps.has("respawned"), "caught and respawned, stamps=%s" % [stamps])
	if stamps.has("respawned"):
		check(stamps.respawned - stamps.died <= 60, "back in under a second, took %d frames" % (stamps.respawned - stamps.died))
	await frames(10)
	check(absf(p.position.x - (c.room.get_node("CheckpointWall") as Checkpoint).position.x) < 40.0, "respawned at the checkpoint, at %s" % p.position)
	check(not monster.active and monster.position.x == 5100.0, "the chase is not running yet: it starts when the player crosses the trigger again, active=%s" % monster.active)
	await _run_to(p, 5620.0, 300)
	check(monster.active, "the monster wakes again at the trigger")
	c.deaths[0] = 0  # the one death is the point
	await _finish(c)


# ---------------------------------------------------------------- performance budget

## At most 4 shadow-casting lights may be near the screen at any point of the chapter (lantern included).
func test_never_more_than_four_shadow_lights_on_screen() -> void:
	var room := (load(SCENE) as PackedScene).instantiate()
	tree.root.add_child(room)
	await frames(3)
	var lights: Array[PointLight2D] = []
	var stack: Array[Node] = [room]
	while not stack.is_empty():
		var node: Node = stack.pop_back()
		stack.append_array(node.get_children())
		if node is PointLight2D and (node as PointLight2D).shadow_enabled:
			lights.append(node)
	var worst := 0
	var worst_x := 0.0
	var half_view := 1920.0 / 1.5 * 0.5  # camera zoom 1.5 at 1080p
	for cam_x in range(0, 11300, 50):
		var count := 0
		for light in lights:
			var size := light.texture.get_size() if light.texture != null else Vector2(512, 512)
			var reach := maxf(size.x, size.y) * light.texture_scale * 0.5
			var at := light.global_position.x if light.get_parent() != room.get_node("Player") else float(cam_x)  # the lantern travels with the player
			if absf(at - cam_x) < reach + half_view:
				count += 1
		if count > worst:
			worst = count
			worst_x = cam_x
	check(lights.size() >= 9, "the chapter has its shadow lights, found %d" % lights.size())
	check(worst <= 4, "at most 4 shadow lights near the screen, %d at x=%d" % [worst, worst_x])
	room.queue_free()
	await frames(2)


# ---------------------------------------------------------------- playing it like a person

## The human-like bot of test_player_sim (goal, late reactions, hops, tries things, walks away, pauses) let loose on the
## chapter from several checkpoints. It does not know the puzzles; it must not break physics or get stuck on open ground.
func test_sim_bot_plays_each_stretch_of_the_chapter_like_a_person() -> void:
	var stretches := [["CheckpointStart", 1900.0], ["CheckpointRope", 3300.0], ["CheckpointDoor1", 4400.0], ["CheckpointLever", 5300.0], ["CheckpointWall", 7400.0], ["CheckpointPen", 7650.0], ["CheckpointFinal", 9300.0]]
	for stretch in stretches:
		for seed_value in [1, 2, 3]:
			var c := await _chapter(stretch[0])
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var sim := SimBot.Sim.new(c.player, c.room, rng, tree)
			var arrived: bool = await sim.play(stretch[1], 60 * 45)
			c.rec.stop()
			release_all_inputs()
			print("chapter sim %s seed %d: arrived=%s x=%d..%d deaths=%d interacts=%d pushes=%d violations=%d" % [stretch[0], seed_value, arrived, sim.min_x, sim.max_x, sim.deaths, sim.interacts, sim.crate_pushes, c.rec.violations.size()])
			check(c.rec.violations.is_empty(), "%s seed %d violations (%d):
%s" % [stretch[0], seed_value, c.rec.violations.size(), c.rec.report(6)])
			tree.paused = false
			c.room.queue_free()
			await frames(3)
