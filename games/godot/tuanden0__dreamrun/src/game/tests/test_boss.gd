extends "res://tests/test_case.gd"


## Arena -300..300 around x=0, boss starts at -300. The player stands wherever the test puts them.
func _arena(player_x: float) -> Dictionary:
	var world := make_world()
	var boss := Boss.new()
	boss.position = Vector2(-300, 0)
	world.add_child(boss)
	var player := spawn_player(world, player_x)
	var states: Array[StringName] = []
	boss.state_changed.connect(func(s: StringName) -> void: states.append(s))
	return {"world": world, "boss": boss, "player": player, "states": states}


func _wait_for(boss: Boss, state: StringName, max_frames: int) -> bool:
	for i in max_frames:
		if boss.state_name() == state:
			return true
		await frames(1)
	return boss.state_name() == state


func test_cycle_patrol_windup_charge_recover_stays_in_the_arena() -> void:
	var a := _arena(480.0)  # beyond the right edge, out of reach
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	var widest := -INF
	var narrowest := INF
	for i in 600:
		await frames(1)
		widest = maxf(widest, boss.position.x)
		narrowest = minf(narrowest, boss.position.x)
	var seen: Array[StringName] = a.states
	check(seen.slice(0, 4) == [&"patrol", &"windup", &"charge", &"recover"], "cycle order, got %s" % [seen])
	check(widest <= 300.0 + 0.1 and narrowest >= -300.0 - 0.1, "stays inside the arena: %s..%s" % [narrowest, widest])
	check(boss.position.x > 250.0, "charged at the player's side, x=%s" % boss.position.x)
	check(not a.player.is_dead, "the player beyond the edge is safe")
	a.world.queue_free()
	await frames(1)


func test_player_in_the_arena_is_killed_by_the_charge() -> void:
	var a := _arena(100.0)
	await frames(20)
	a.boss.start()
	for i in 400:
		await frames(1)
		if a.player.is_dead:
			break
	check(a.player.is_dead, "standing in the arena gets you killed")
	a.world.queue_free()
	await frames(1)


func test_first_hit_starts_phase_two_and_it_charges_faster() -> void:
	var a := _arena(480.0)
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	check(boss.phase() == 1, "starts in phase 1")
	await _wait_for(boss, &"charge", 300)
	var x0 := boss.position.x
	await frames(10)
	var phase_one_speed := (boss.position.x - x0) / (10.0 / 60.0)
	boss.stun(2.0)  # what a trap does
	check(boss.hits == 1 and boss.phase() == 2, "a stun is a hit: hits=%d" % boss.hits)
	check(boss.is_stunned() and boss.state_name() == &"patrol", "stunned, then starts over")
	await frames(130)
	check(not boss.is_stunned(), "stun wears off")
	await _wait_for(boss, &"charge", 400)
	x0 = boss.position.x
	await frames(10)
	var phase_two_speed := absf(boss.position.x - x0) / (10.0 / 60.0)
	check(phase_two_speed > phase_one_speed * 1.25, "phase 2 charge faster: %s vs %s" % [phase_two_speed, phase_one_speed])
	a.world.queue_free()
	await frames(1)


func test_phase_two_charges_back_across_the_arena() -> void:
	var a := _arena(480.0)
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	boss.stun(0.1)
	await frames(10)
	var charges := 0
	var last: StringName = &""
	for i in 900:
		await frames(1)
		if boss.state_name() == &"charge" and last != &"charge":
			charges += 1
		last = boss.state_name()
		if charges == 2:
			break
	check(charges == 2, "phase 2 chains a second charge, saw %d" % charges)
	check(boss.direction == -1, "second charge goes back the other way")
	a.world.queue_free()
	await frames(1)


func test_second_hit_defeats_it_and_it_stops_killing() -> void:
	var a := _arena(480.0)
	var boss: Boss = a.boss
	var won := [false]
	boss.defeated.connect(func() -> void: won[0] = true)
	await frames(20)
	boss.start()
	boss.stun(0.1)
	await frames(30)
	boss.stun(0.1)
	check(won[0] and boss.state_name() == &"dead" and not boss.active, "second hit defeats it")
	a.player.position = Vector2(boss.position.x + 40.0, -2)
	await frames(90)
	check(not a.player.is_dead, "the defeated boss is harmless")
	check(boss.scale.y < 0.8, "it collapses, scale.y=%s" % boss.scale.y)
	a.world.queue_free()
	await frames(1)


func test_a_long_trap_stun_is_capped() -> void:
	var a := _arena(480.0)
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	boss.stun(30.0)
	await frames(60 * 7)
	check(not boss.is_stunned(), "a 30 s pin is shaken off after max_stun")
	a.world.queue_free()
	await frames(1)


func test_checkpoint_restores_hits_and_position_and_a_dead_boss_stays_dead() -> void:
	var a := _arena(480.0)
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	boss.stun(0.1)
	await frames(20)
	boss.save_checkpoint()
	var saved_x := boss.position.x
	await frames(120)
	boss.stun(0.1)  # second hit after the checkpoint: dead
	check(boss.state_name() == &"dead", "dead after the second hit")
	boss.reset_to_checkpoint()
	check(boss.hits == 1 and boss.phase() == 2 and boss.active, "back in phase 2 with one hit, hits=%d" % boss.hits)
	check(is_equal_approx(boss.position.x, saved_x) and is_equal_approx(boss.scale.y, 1.0), "back where it was, standing")
	boss.stun(0.1)
	boss.save_checkpoint()  # saved after the kill
	boss.reset_to_checkpoint()
	check(boss.state_name() == &"dead" and not boss.active and boss.visible, "a kill saved by a checkpoint stays")
	a.world.queue_free()
	await frames(1)


# ---------------------------------------------------------------- the final boss: three hits, three phases

## Watches one attack (patrol, then the charges, then back to patrol): how many charges it chained and the frames it
## spent recovering in total.
func _watch_phase(boss: Boss, max_frames: int) -> Dictionary:
	var result := {"charges": 0, "recover": 0}
	for i in max_frames:
		await frames(1)
		var state := boss.state_name()
		if state == &"recover":
			result.recover += 1
		if state == &"charge" and _last_state != &"charge":
			result.charges += 1
		if state == &"patrol" and result.charges > 0:
			break
		_last_state = state
	return result


var _last_state: StringName = &""


func _final_boss_arena() -> Dictionary:
	var a := _arena(2000.0)  # nobody in reach: it just keeps attacking the far end
	(a.boss as Boss).hits_to_win = 3
	return a


func _hit(boss: Boss) -> void:
	boss.stun(0.1)


func test_the_final_boss_speeds_up_chains_more_charges_and_recovers_faster_each_phase() -> void:
	var a := _final_boss_arena()
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	var by_phase: Array[Dictionary] = []
	for phase_number in 3:
		_last_state = &""
		var seen := await _watch_phase(boss, 1200)
		by_phase.append(seen)
		check(boss.phase() == phase_number + 1, "phase %d at the time, boss says %d" % [phase_number + 1, boss.phase()])
		if phase_number < 2:
			_hit(boss)
			await frames(int(boss.max_stun * 60.0) + 30)  # shakes off the stun, starts over
	check(by_phase[0].charges == 1 and by_phase[1].charges == 2 and by_phase[2].charges == 3, "charges per attack 1, 2, 3: %s" % [by_phase.map(func(d: Dictionary) -> int: return d.charges)])
	check(by_phase[1].recover > 0 and by_phase[2].recover > 0, "it recovered after charging in every phase: %s" % [by_phase])
	# recovery per crash: 1.2 s, 1.2/1.4 s, 1.2*0.5/1.8 s
	var per_crash_1: float = by_phase[0].recover / 1.0
	var per_crash_2: float = by_phase[1].recover / 2.0
	var per_crash_3: float = by_phase[2].recover / 3.0
	check(per_crash_2 < per_crash_1 * 0.8 and per_crash_3 < per_crash_2 * 0.5, "each phase recovers faster: %.0f, %.0f, %.0f frames per crash" % [per_crash_1, per_crash_2, per_crash_3])
	a.world.queue_free()
	await frames(1)


func test_the_third_hit_brings_the_final_boss_down_and_not_the_second() -> void:
	var a := _final_boss_arena()
	var boss: Boss = a.boss
	var won := [0]
	boss.defeated.connect(func() -> void: won[0] += 1)
	await frames(20)
	boss.start()
	_hit(boss)
	await frames(int(boss.max_stun * 60.0) + 20)
	_hit(boss)
	check(won[0] == 0 and boss.active and boss.phase() == 3, "two hits are not enough, phase %d" % boss.phase())
	await frames(int(boss.max_stun * 60.0) + 20)
	_hit(boss)
	check(won[0] == 1 and boss.state_name() == &"dead" and not boss.active, "the third hit defeats it, once")
	await frames(60)
	check(won[0] == 1, "and it stays defeated")
	a.world.queue_free()
	await frames(1)


func test_a_checkpoint_in_phase_three_restores_phase_three() -> void:
	var a := _final_boss_arena()
	var boss: Boss = a.boss
	await frames(20)
	boss.start()
	_hit(boss)
	await frames(int(boss.max_stun * 60.0) + 20)
	_hit(boss)
	await frames(30)
	boss.save_checkpoint()
	await frames(int(boss.max_stun * 60.0) + 120)
	_hit(boss)  # beaten after the checkpoint
	check(boss.state_name() == &"dead", "beaten")
	boss.reset_to_checkpoint()
	check(boss.hits == 2 and boss.phase() == 3 and boss.active and not boss.is_stunned(), "back in phase 3 with two hits, hits=%d" % boss.hits)
	a.world.queue_free()
	await frames(1)
