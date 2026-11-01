extends "res://tests/test_case.gd"


func _chase_world(monster_x: float, speed: float) -> Dictionary:
	var world := make_world()
	var monster := Monster.new()
	monster.position = Vector2(monster_x, 0)
	monster.speed = speed
	monster.stop_x = 2000.0
	world.add_child(monster)
	var player := spawn_player(world, 0.0)
	var manager := CheckpointManager.new()
	manager.player_path = ^"../Player"
	world.add_child(manager)
	return {"world": world, "monster": monster, "player": player, "manager": manager}


func _frame_stamps(player: PlayerController, manager: CheckpointManager) -> Dictionary:
	var stamps := {}
	player.died.connect(func() -> void: stamps["died"] = Engine.get_physics_frames())
	manager.respawned.connect(func() -> void: stamps["respawned"] = Engine.get_physics_frames())
	return stamps


func test_monster_kills_and_player_respawns_in_under_a_second() -> void:
	var w := _chase_world(-500.0, 220.0)
	var monster: Monster = w.monster
	var player: PlayerController = w.player
	await frames(20)
	var stamps := _frame_stamps(player, w.manager)
	monster.start()
	for i in 900:
		await frames(1)
		if stamps.has("respawned"):
			break
	check(stamps.has("died") and stamps.has("respawned"), "should die and respawn, stamps=%s" % [stamps])
	if stamps.has("died") and stamps.has("respawned"):
		var frames_taken: int = stamps.respawned - stamps.died
		check(frames_taken <= 60, "respawn must take under 1 s, took %d frames" % frames_taken)
	check(not player.is_dead and player.position.distance_to(Vector2(0, -2)) < 6.0, "back at the start, at %s" % player.position)
	check(not monster.active and is_equal_approx(monster.position.x, -500.0), "monster resets to its saved state, x=%s active=%s" % [monster.position.x, monster.active])
	w.world.queue_free()
	await frames(1)


func test_player_who_keeps_running_is_never_caught() -> void:
	var w := _chase_world(-400.0, 150.0)
	var player: PlayerController = w.player
	await frames(20)
	w.monster.start()
	Input.action_press(&"move_right")
	await frames(300)
	release_all_inputs()
	check(not player.is_dead, "running at full speed outpaces the monster")
	check(player.position.x > 800.0, "player should have run far, x=%s" % player.position.x)
	w.world.queue_free()
	await frames(1)


func test_checkpoint_restores_world_and_restarts_chase_behind_it() -> void:
	var w := _chase_world(-500.0, 160.0)
	var world: Node2D = w.world
	var monster: Monster = w.monster
	var player: PlayerController = w.player
	var checkpoint := Checkpoint.new()
	checkpoint.position = Vector2(400, 0)
	world.add_child(checkpoint)
	var crate := Crate.new()
	crate.position = Vector2(-200, -28)
	world.add_child(crate)
	var door := Door.new()
	door.position = Vector2(700, -110)
	door.size = Vector2(44, 220)
	world.add_child(door)
	await frames(30)
	monster.start()
	Input.action_press(&"move_right")
	for i in 200:
		await frames(1)
		if checkpoint.is_active:
			break
	release_all_inputs()
	check(checkpoint.is_active, "running into the checkpoint should activate it")
	await frames(5)
	var crate_at_checkpoint := crate.global_position
	var monster_at_checkpoint := monster.position.x
	# the world changes after the checkpoint...
	crate.global_position = Vector2(900, -28)
	door.set_open(true)
	await frames(2)
	# ...and dying brings it all back.
	var stamps := _frame_stamps(player, w.manager)
	player.die()
	for i in 200:
		await frames(1)
		if stamps.has("respawned"):
			break
	await frames(3)
	check(stamps.has("respawned"), "should have respawned")
	check(crate.global_position.distance_to(crate_at_checkpoint) < 3.0, "crate back at its checkpoint spot %s, is %s" % [crate_at_checkpoint, crate.global_position])
	check(not door.is_open, "door that was opened after the checkpoint is closed again")
	check(player.position.distance_to(checkpoint.spawn_position()) < 6.0, "respawn at the checkpoint, at %s" % player.position)
	check(monster.active and monster.position.x < monster_at_checkpoint - 300.0, "chase resumes 350 px behind: monster x=%s was %s" % [monster.position.x, monster_at_checkpoint])
	world.queue_free()
	await frames(1)


func test_dying_topples_the_character() -> void:
	var world := make_world()
	var player := spawn_player(world, 0.0)
	await frames(20)
	player.die()
	await frames(40)
	var visual := player.get_node("Visual") as Node2D
	check(absf(visual.rotation) > 1.0, "dead body should topple past 57 deg, rotation %s" % visual.rotation)
	check(player.state == &"die", "state should stay die until respawn")
	player.respawn(Vector2(0, -2))
	await frames(60)
	check(absf(visual.rotation) < 0.3, "respawned body stands up again, rotation %s" % visual.rotation)
	world.queue_free()
	await frames(1)
