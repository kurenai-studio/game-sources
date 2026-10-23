extends TestCase
## Support: one drone and one thing he sets down, each on his back until it's needed, each
## working on its own.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


## A cat carrying one support and nothing in his paws, so only it does anything.
func _cat(arena: Arena, support_name: String) -> Cat:
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1000.0
	cat.max_health = 1000.0
	Upgrades.apply(cat, {"id": "support:" + support_name, "rarity": Upgrades.Rarity.COMMON})
	return cat


## Holds a creature still, so only what the support does is being tested.
func _hold(creature: Creature, at: Vector2) -> void:
	creature.body.position = at
	creature.body.velocity = Vector2.ZERO


func test_one_of_each_slot() -> void:
	var cat := _cat(_arena(), "meriam_bambu")
	var offered := Upgrades.available(cat)
	check(not "support:mines" in offered, "mines were offered with a cannon already set-down")
	check("support:gun_drone" in offered, "the drone slot wasn't offered beside the cannon")
	check("support_level:meriam_bambu" in offered, "the cannon wasn't offered a level")


func test_the_drone_stays_docked_with_nothing_to_shoot() -> void:
	var arena := _arena()
	var cat := _cat(arena, "gun_drone")
	var drone: Support = cat.supports.drone
	for step in 60:
		arena.step()
	check(not drone.deployed and drone.body.position.distance_to(cat.body.position) < 0.01, "the drone left his pack with nothing to shoot")


func test_the_drone_lifts_off_and_fires_down() -> void:
	var arena := _arena()
	var cat := _cat(arena, "gun_drone")
	var drone: Support = cat.supports.drone
	var rat := arena.add_creature(cat.body.position + Vector2(4.0, 0.0))
	rat.health = 1000.0
	var highest := 0.0
	for step in 180:
		_hold(rat, cat.body.position + Vector2(4.0, 0.0))
		arena.step()
		highest = maxf(highest, drone.body.height)
	check(drone.deployed and highest > 0.9, "the drone stayed low (%.2f m)" % highest)
	check(rat.health < 1000.0, "the drone never hit the rat")


func test_the_drone_docks_once_its_quiet() -> void:
	var arena := _arena()
	var cat := _cat(arena, "gun_drone")
	var drone: Support = cat.supports.drone
	var rat := arena.add_creature(cat.body.position + Vector2(4.0, 0.0))
	for step in 60:
		arena.step()
	arena.creatures.clear()
	for step in 60 * 4:
		arena.step()
	check(not drone.deployed, "the drone never came back to his pack")


func test_the_cannon_is_set_down_and_stays_put() -> void:
	var arena := _arena()
	var cat := _cat(arena, "meriam_bambu")
	var cannon: Support = cat.supports.set_down
	var rat := arena.add_creature(cat.body.position + Vector2(5.0, 0.0))
	rat.health = 1000.0
	arena.step()
	check(cannon.deployed, "something in reach, and the cannon stayed on his back")
	var set_at := cannon.body.position
	cat.steering = Vector2.UP
	for step in 60:
		_hold(rat, set_at + Vector2(5.0, 0.0))
		arena.step()
	check(cannon.body.position == set_at, "the cannon moved with him")
	check(arena.shots.any(func(shot: Shot) -> bool: return shot.falls) or rat.health < 1000.0, "the cannon never lobbed a stone")


func test_a_stone_bursts_through_a_cluster() -> void:
	var arena := _arena()
	var cat := _cat(arena, "meriam_bambu")
	var spot := cat.body.position + Vector2(5.0, 0.0)
	var rats: Array[Creature] = []
	for index in 5:
		rats.append(arena.add_creature(spot + Vector2.from_angle(index * TAU / 5.0) * 0.25))
	for step in 120:
		for index in rats.size():
			if rats[index].alive():
				_hold(rats[index], spot + Vector2.from_angle(index * TAU / 5.0) * 0.25)
		arena.step()
	check(arena.kills >= 3, "a burst among five rats felled only %d" % arena.kills)


func test_a_tube_cracks_and_she_cuts_a_new_one() -> void:
	var arena := _arena()
	var cat := _cat(arena, "meriam_bambu")
	var cannon: Support = cat.supports.set_down
	var rat := arena.add_creature(cat.body.position + Vector2(5.0, 0.0))
	rat.health = 1.0e6
	var steps := 0
	while cannon.cracks == 0 and steps < 60 * 30:
		_hold(rat, cat.body.position + Vector2(5.0, 0.0))
		arena.step()
		steps += 1
	check(cannon.cracks == 1, "the tube never cracked")
	check(not cannon.deployed and cannon.rebuilt_in > 0.0, "a cracked tube kept firing")
	for step in ceili(Support.REBUILD_TIME / Arena.STEP) + 2:
		_hold(rat, cat.body.position + Vector2(5.0, 0.0))
		arena.step()
	check(cannon.deployed and cannon.shots_left > 0, "no new tube after %.0f seconds" % Support.REBUILD_TIME)


func test_mines_are_dropped_while_enemies_are_near_and_go_off_underfoot() -> void:
	var arena := _arena()
	var cat := _cat(arena, "mines")
	var mines: Support = cat.supports.set_down
	for step in 30:
		arena.step()
	check(mines.mines.is_empty(), "a mine was dropped with nothing near")
	var rat := arena.add_creature(cat.body.position + Vector2(3.0, 0.0))
	rat.health = 1000.0
	_hold(rat, cat.body.position + Vector2(3.0, 0.0))
	arena.step()
	check(mines.mines.size() == 1, "an enemy close, and no mine dropped")
	var mine_at: Vector2 = mines.mines[0].body.position
	cat.body.position += Vector2(0.0, 2.0)
	for step in 40:
		_hold(rat, mine_at + Vector2(1.0, 0.0))
		arena.step()
	check(mines.mines.size() >= 1 and rat.health == 1000.0, "the mine went off with nothing on it")
	for step in 5:
		_hold(rat, mine_at)
		arena.step()
	check(rat.health < 1000.0, "a rat stood on an armed mine and it didn't go off")


func test_no_more_than_four_mines_down() -> void:
	var arena := _arena()
	var cat := _cat(arena, "mines")
	var mines: Support = cat.supports.set_down
	var rat := arena.add_creature(cat.body.position + Vector2(4.0, 0.0))
	cat.steering = Vector2.DOWN
	for step in 60 * 30:
		_hold(rat, Vector2(cat.body.position.x + 4.0, cat.body.position.y))
		arena.step()
	check(mines.mines.size() == Support.MOST_MINES, "%d mines down" % mines.mines.size())


func test_a_giants_boot_sets_a_mine_off() -> void:
	var arena := _arena()
	var cat := _cat(arena, "mines")
	var mines: Support = cat.supports.set_down
	var giant := arena.add_giant(cat.body.position + Vector2(3.0, 0.0))
	giant.stomp_ready_in = 100.0
	arena.step()
	check(mines.mines.size() == 1, "a giant close, and no mine dropped")
	# He walks off, and he follows him over where it lies.
	cat.steering = Vector2.LEFT
	for step in 60 * 6:
		arena.step()
		if giant.health < giant.most_health:
			break
	check(giant.health < giant.most_health, "he walked over his mines and none went off")


func test_levels_make_support_hit_harder() -> void:
	var arena := _arena()
	var cat := _cat(arena, "mines")
	var before: float = (cat.supports.set_down as Support).hit_for(cat)
	Upgrades.apply(cat, {"id": "support_level:mines", "rarity": Upgrades.Rarity.COMMON})
	check((cat.supports.set_down as Support).hit_for(cat) > before, "a level didn't make the mines hit harder")


func test_the_alarm_drum_is_beaten_when_the_horde_crowds_her_and_throws_it_back() -> void:
	var arena := _arena()
	var cat := _cat(arena, "alarm_drum")
	var drum: Support = cat.supports.set_down
	var rats: Array[Creature] = []
	for index in Support.DRUM_CROWD:
		rats.append(arena.add_creature(cat.body.position + Vector2.from_angle(index * TAU / Support.DRUM_CROWD) * 1.0))
	var steps := 0
	while drum.beats == 0 and steps < 120:
		for index in rats.size():
			_hold(rats[index], cat.body.position + Vector2.from_angle(index * TAU / Support.DRUM_CROWD) * 1.0)
		arena.step()
		steps += 1
	check(drum.deployed and drum.beats > 0, "the drum was never beaten with the horde round him")
	arena.step()
	check(rats.all(func(rat: Creature) -> bool: return rat.body.velocity.dot(rat.body.position - drum.body.position) > 0.0 or not rat.alive()), "a beat didn't throw the horde back")
	for step in 60 * 6:
		arena.step()
	check(drum.cracks == 1 and drum.beats == Support.DRUM_BEATS and not drum.deployed, "the drum took %d beats and split %d times" % [drum.beats, drum.cracks])


func test_the_bee_swarm_stings_and_slows_then_comes_home() -> void:
	var arena := _arena()
	var cat := _cat(arena, "bee_swarm")
	var swarm: Support = cat.supports.drone
	var rat := arena.add_creature(cat.body.position + Vector2(3.0, 0.0))
	rat.health = 1000.0
	for step in 120:
		_hold(rat, cat.body.position + Vector2(3.0, 0.0))
		arena.step()
	check(swarm.deployed and rat.health < 1000.0, "the swarm never stung the rat")
	check(rat.afflictions.has("slow"), "a sting didn't slow the rat")
	arena.creatures.erase(rat)
	for step in 120:
		arena.step()
	check(not swarm.deployed, "the swarm never came home")


func test_the_snare_holds_the_first_foot_in_it() -> void:
	var arena := _arena()
	var cat := _cat(arena, "snare")
	var snare: Support = cat.supports.set_down
	var lure := arena.add_creature(cat.body.position + Vector2(4.0, 0.0))
	for step in 5:
		_hold(lure, cat.body.position + Vector2(4.0, 0.0))
		arena.step()
	check(snare.deployed and snare.snare_at.is_finite(), "the snare wasn't set down with something near")
	var giant := arena.add_giant(snare.snare_at + Vector2(0.6, 0.0))
	giant.body.position = snare.snare_at
	arena.creatures.erase(lure)
	cat.body.position += Vector2(0.0, 6.0)
	arena.step()
	check(snare.catches == 1 and giant.snared_for > 0.0, "a giant's boot in the snare wasn't caught")
	var held_at := giant.body.position
	for step in 30:
		arena.step()
	check(giant.body.position.distance_to(held_at) < 0.05, "a snared giant walked off")
	check(not snare.deployed and snare.rebuilt_in > 0.0, "a sprung snare stayed set")
