extends "res://tests/test_case.gd"


func _arena() -> Dictionary:
	var world := make_world()
	var monster := Monster.new()
	monster.position = Vector2(-600, 0)
	monster.speed = 200.0
	monster.stop_x = 2000.0
	world.add_child(monster)
	return {"world": world, "monster": monster}


func test_monster_stun_halts_then_resumes() -> void:
	var a := _arena()
	var monster: Monster = a.monster
	monster.start()
	await frames(30)
	monster.stun(1.0)
	var x0 := monster.position.x
	await frames(50)
	check(absf(monster.position.x - x0) < 1.0, "stunned monster must not move, moved %s" % (monster.position.x - x0))
	await frames(30)
	check(not monster.is_stunned() and monster.position.x > x0 + 20.0, "monster resumes after the stun, dx=%s" % (monster.position.x - x0))
	a.world.queue_free()
	await frames(1)


func test_stunned_monster_does_not_kill() -> void:
	var a := _arena()
	var monster: Monster = a.monster
	monster.position.x = -40.0
	var player := spawn_player(a.world, 0.0)
	monster.start()
	monster.stun(2.0)
	await frames(40)
	check(not player.is_dead, "a stunned monster must not kill")
	a.world.queue_free()
	await frames(1)


func test_drop_trap_stuns_only_when_monster_is_under_it() -> void:
	var a := _arena()
	var monster: Monster = a.monster
	var trap := DropTrap.new()
	trap.position = Vector2(0, 0)
	a.world.add_child(trap)
	monster.start()
	await frames(10)
	trap.trigger()  # fired too early: lands after 0.55 s, the monster is still ~100 px short of the zone at x=-130
	check(not trap.armed, "trigger spends the trap")
	await frames(45)
	check(not monster.is_stunned(), "missed: monster not in the zone yet, x=%s" % monster.position.x)
	a.world.queue_free()
	await frames(1)

	a = _arena()
	monster = a.monster
	trap = DropTrap.new()
	a.world.add_child(trap)
	monster.start()
	var frames_to_zone := int((600.0 - 100.0) / 200.0 * 60.0)  # monster reaches x=-100 (inside the zone)
	await frames(frames_to_zone - 33)  # fall takes 0.55 s = 33 frames
	trap.trigger()
	await frames(45)
	check(monster.is_stunned(), "hit: the boulder lands on the monster, x=%s" % monster.position.x)
	check(is_equal_approx(trap.get_child(0).position.y, 0.0), "boulder rests on the ground")
	a.world.queue_free()
	await frames(1)


func test_trap_ignores_release_and_second_trigger() -> void:
	var a := _arena()
	var trap := ShockTrap.new()
	a.world.add_child(trap)
	var fired := [0]
	trap.sprung.connect(func() -> void: fired[0] += 1)
	trap.trigger(false)
	check(trap.armed and fired[0] == 0, "plate release must not spring it")
	trap.trigger(true)
	trap.trigger(true)
	check(fired[0] == 1, "springs once, fired %d" % fired[0])
	a.world.queue_free()
	await frames(1)


func test_shock_trap_holds_monster_while_active_then_lets_go() -> void:
	var a := _arena()
	var monster: Monster = a.monster
	monster.position.x = -50.0
	var trap := ShockTrap.new()
	trap.active_time = 1.0
	trap.stun_time = 0.5
	a.world.add_child(trap)
	monster.start()
	trap.trigger()
	await frames(50)
	check(monster.position.x < -40.0, "held while the arcs run, x=%s" % monster.position.x)
	await frames(80)
	check(monster.position.x > 0.0, "released after the shock ends, x=%s" % monster.position.x)
	a.world.queue_free()
	await frames(1)


func test_checkpoint_rearms_traps() -> void:
	var a := _arena()
	var trap := DropTrap.new()
	a.world.add_child(trap)
	trap.save_checkpoint()
	trap.trigger()
	await frames(50)
	trap.reset_to_checkpoint()
	check(trap.armed and is_equal_approx(trap.get_child(0).position.y, -trap.drop_height), "trap armed again with the boulder back up")
	a.world.queue_free()
	await frames(1)


func test_boulder_crushes_a_player_under_it_but_not_one_beside_it() -> void:
	var a := _arena()
	var trap := DropTrap.new()
	a.world.add_child(trap)
	var under := spawn_player(a.world, 0.0)
	var beside := spawn_player(a.world, 300.0)
	await frames(20)
	trap.trigger()
	await frames(45)
	check(under.is_dead, "standing under the boulder when it lands is fatal")
	check(not beside.is_dead, "standing clear of it is safe")
	a.world.queue_free()
	await frames(1)


func test_landed_boulder_is_solid_and_the_checkpoint_lifts_it() -> void:
	var a := _arena()
	var trap := DropTrap.new()
	trap.position = Vector2(300, 0)
	a.world.add_child(trap)
	var player := spawn_player(a.world, 0.0)
	await frames(20)
	trap.save_checkpoint()
	trap.trigger()
	await frames(45)
	Input.action_press(&"move_right")
	await frames(120)
	release_all_inputs()
	check(player.position.x < 300.0 - 40.0, "a landed boulder blocks the way, player x=%s" % player.position.x)
	trap.reset_to_checkpoint()
	player.position = Vector2(0, -2)
	Input.action_press(&"move_right")
	await frames(120)
	release_all_inputs()
	check(player.position.x > 300.0, "with the boulder lifted again the way is open, player x=%s" % player.position.x)
	a.world.queue_free()
	await frames(1)


func test_trap_rearms_after_its_delay_but_not_after_a_checkpoint_reset() -> void:
	var a := _arena()
	var trap := ShockTrap.new()
	trap.rearm_after = 0.5
	trap.active_time = 0.2
	a.world.add_child(trap)
	trap.trigger()
	check(not trap.armed, "spent")
	await frames(45)
	check(trap.armed, "armed again after rearm_after")
	trap.trigger()
	trap.save_checkpoint()
	trap.reset_to_checkpoint()  # saved as spent: the pending timer must not rearm it
	await frames(45)
	check(not trap.armed, "a reset to a spent checkpoint cancels the pending rearm")
	a.world.queue_free()
	await frames(1)


func test_boulder_winches_back_up_when_it_rearms() -> void:
	var a := _arena()
	var trap := DropTrap.new()
	trap.rearm_after = 2.0
	a.world.add_child(trap)
	trap.trigger()
	await frames(45)
	var rock := trap.get_child(0) as Node2D
	check(is_equal_approx(rock.position.y, 0.0), "landed")
	await frames(75 + 100)  # the delay runs from the trigger, then the winch takes 1.5 s
	check(trap.armed and rock.position.y < -trap.drop_height + 5.0, "lifted back, y=%s" % rock.position.y)
	a.world.queue_free()
	await frames(1)


# ---------------------------------------------------------------- fire

func test_fire_holds_the_monster_while_it_burns_then_lets_go() -> void:
	var a := _arena()
	var monster: Monster = a.monster
	monster.position.x = -50.0
	var trap := FireTrap.new()
	trap.active_time = 1.0
	trap.stun_time = 0.5
	a.world.add_child(trap)
	monster.start()
	trap.trigger()
	check(trap.is_burning(), "burning at once")
	await frames(50)
	check(monster.position.x < -40.0, "held while the flames burn, x=%s" % monster.position.x)
	await frames(80)
	check(not trap.is_burning() and monster.position.x > 0.0, "freed when it burns out, x=%s" % monster.position.x)
	a.world.queue_free()
	await frames(1)


func test_fire_does_not_hurt_the_player_and_springs_once() -> void:
	var a := _arena()
	var trap := FireTrap.new()
	a.world.add_child(trap)
	var player := spawn_player(a.world, 0.0)
	var fired := [0]
	trap.sprung.connect(func() -> void: fired[0] += 1)
	await frames(10)
	trap.trigger(false)
	check(fired[0] == 0 and not trap.is_burning(), "an off lever does not light it")
	trap.trigger()
	trap.trigger()
	await frames(60)
	check(fired[0] == 1, "springs once, fired %d" % fired[0])
	check(not player.is_dead, "the player standing in the flames is fine")
	a.world.queue_free()
	await frames(1)


func test_fire_rearms_and_a_checkpoint_puts_it_out() -> void:
	var a := _arena()
	var trap := FireTrap.new()
	trap.active_time = 0.3
	trap.rearm_after = 1.0
	a.world.add_child(trap)
	trap.trigger()
	await frames(90)
	check(trap.armed and not trap.is_burning(), "burnt out and ready again")
	trap.save_checkpoint()
	trap.trigger()
	check(trap.is_burning(), "lit again")
	trap.reset_to_checkpoint()
	check(not trap.is_burning(), "a checkpoint reset puts it out")
	a.world.queue_free()
	await frames(1)
