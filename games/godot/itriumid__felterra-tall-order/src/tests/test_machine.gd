extends TestCase
## The feller buncher: it turns on its tracks before it drives, its tracks crush the horde while
## they turn, its bite is warned before it lands, its steel shrugs off most of a hit while its
## exposed joint takes double, and broken, it stays where it stopped.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func _cat(arena: Arena, at: Vector2) -> Cat:
	var cat := arena.add_cat(at)
	cat.weapons.clear()
	cat.health = 1000.0
	cat.max_health = 1000.0
	return cat


func test_it_turns_on_the_spot_before_it_drives() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	_cat(arena, Arena.SIZE / 2.0 + Vector2(-10.0, 0.0))
	var start := machine.body.position
	for step in 20:
		arena.step()
	check(machine.body.position.distance_to(start) < 0.05, "it drove off before it had turned to face him")
	for step in 60 * 8:
		arena.step()
	check(absf(angle_difference(machine.heading, PI)) < Machine.DRIVE_WITHIN, "it never turned to face him")
	check(machine.body.position.x < start.x - 1.0, "facing him, it never drove toward him")


func test_its_tracks_crush_the_horde_while_they_turn() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	_cat(arena, Arena.SIZE / 2.0 + Vector2(-10.0, 0.0))
	var rat := arena.add_creature(machine.body.position + Vector2(0.5, 0.6))
	rat.health = 2.0
	arena.step()
	check(arena.kills == 1, "a rat under turning tracks lived")


func test_standing_still_its_steel_just_doesnt_give() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	var cat := _cat(arena, machine.body.position + Vector2(0.2, 0.0))
	machine.state = Machine.State.STUCK
	machine.state_for = 10.0
	arena.step()
	check(not machine.covers(cat.body.position), "he stood inside its steel")
	check(cat.health == 1000.0, "standing still, its tracks hurt him")


func test_the_bite_is_warned_and_lands_where_she_was() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	machine.bite_ready_in = 0.0
	var cat := _cat(arena, machine.root() + Vector2(3.0, 0.0))
	arena.step()
	check(machine.state == Machine.State.AIMING, "in reach, it didn't swing its boom out")
	check(machine.bite_at.distance_to(cat.body.position) < 0.1, "the bite isn't aimed where he is")
	var warned := 0
	while machine.state == Machine.State.AIMING:
		arena.step()
		warned += 1
	check(warned * Arena.STEP >= Machine.AIM_TIME - 0.02, "the warning lasted only %.2f seconds" % (warned * Arena.STEP))
	while machine.state == Machine.State.BITING:
		arena.step()
	check(cat.health <= 1000.0 - Machine.BITE_DAMAGE + 0.01, "he stood in the shadow and the jaws missed him")


func test_leaving_the_shadow_gets_her_clear() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	machine.bite_ready_in = 0.0
	var cat := _cat(arena, machine.root() + Vector2(3.0, 0.0))
	arena.step()
	cat.steering = Vector2.DOWN
	while machine.state in [Machine.State.AIMING, Machine.State.BITING]:
		arena.step()
	check(cat.health == 1000.0, "he walked out of the shadow and was still bitten")


func test_its_jaws_cut_its_own_horde() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	arena.jaws(machine, machine.root() + Vector2(3.0, 0.0))
	var rat := arena.add_creature(machine.root() + Vector2(3.0, 0.1))
	arena.jaws(machine, machine.root() + Vector2(3.0, 0.0))
	check(arena.kills == 1 and not rat.alive(), "its jaws shut on a rat and the rat lived")


func test_steel_shrugs_off_most_of_a_hit_and_the_joint_takes_double() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	arena.strike(machine, 10.0, Vector2.ZERO, 0.0, 0.0, "round")
	check(is_equal_approx(machine.health, Machine.HEALTH - 10.0 * Machine.ARMOR_SHARE), "a hit on its steel took %.1f" % (Machine.HEALTH - machine.health))
	check(not machine.joint.alive(), "the joint was open with the head up")
	machine.state = Machine.State.STUCK
	var before := machine.health
	arena.strike(machine.joint, 10.0, Vector2.ZERO, 0.0, 0.0, "round")
	check(is_equal_approx(before - machine.health, 10.0 * Machine.JOINT_SHARE), "a hit on the open joint took %.1f" % (before - machine.health))
	check(machine.joint in arena._targets(), "the open joint isn't something to aim at")


func test_too_close_for_the_boom_it_backs_off() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	_cat(arena, machine.point(Machine.LENGTH * 0.5 + 0.3, 0.0))
	var start := machine.body.position
	for step in 30:
		arena.step()
	check(machine.body.position.x < start.x - 0.1, "he stood under its boom and it didn't back off")


func test_broken_it_stays_as_a_wreck() -> void:
	var arena := _arena()
	var machine := arena.add_machine(Arena.SIZE / 2.0, 0.0)
	var cat := _cat(arena, Arena.SIZE / 2.0 + Vector2(-8.0, 0.0))
	arena.strike(machine, Machine.HEALTH / Machine.ARMOR_SHARE + 1.0, Vector2.ZERO, 0.0, 0.0, "round", cat)
	check(not machine.standing() and arena.machines_broken == 1, "it took more than its health and kept working")
	var gained := arena.experience + (arena.level - 1) * 100
	check(gained > 0, "breaking it gave no experience")
	var at := machine.body.position
	for step in 60 * 5:
		arena.step()
	check(machine.body.position == at and machine.head_height == 0.0, "the wreck moved, or its boom stayed up")
	cat.body.position = machine.body.position
	arena.step()
	check(not machine.covers(cat.body.position), "he walked through the wreck")


func test_one_comes_once_a_run_is_long_on() -> void:
	var arena := Arena.new()
	arena.time = Arena.MACHINE_FROM - 1.0
	arena._since_machine = Arena.MACHINE_INTERVAL - 1.0
	for step in 30:
		arena.step()
	check(arena.machines.is_empty(), "it came before its time")
	for step in 60 * 2:
		arena.step()
	check(arena.machines.size() == 1, "%d machines came" % arena.machines.size())


func test_mines_go_off_under_its_tracks() -> void:
	var arena := _arena()
	var cat := _cat(arena, Arena.SIZE / 2.0 + Vector2(-8.0, 0.0))
	Upgrades.apply(cat, {"id": "support:mines", "rarity": Upgrades.Rarity.COMMON})
	var mines: Support = cat.supports.set_down
	var machine := arena.add_machine(Arena.SIZE / 2.0 + Vector2(-3.0, 0.0), PI)
	machine.state = Machine.State.STUCK
	machine.state_for = 10.0
	var mine := Body.new()
	mine.position = machine.point(0.5, 0.6)
	mines.mines.append({"body": mine, "armed_in": 0.0})
	arena.step()
	check(machine.health < Machine.HEALTH, "a mine under its tracks didn't go off")
