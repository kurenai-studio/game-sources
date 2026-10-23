extends TestCase
## Weapons: a blade cuts what it sweeps through, paws limit what a cat can hold, and aim modes
## choose what he goes for.


func _arena_with(weapon_names: Array) -> Array:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.wear({"weapons": weapon_names})
	return [arena, cat]


func test_a_knife_cuts_a_rat_in_reach() -> void:
	var setup := _arena_with(["knife"])
	var arena: Arena = setup[0]
	var cat: Cat = setup[1]
	var rat := arena.add_creature(cat.body.position + Vector2(0.35, 0.05))
	rat.health = 2.0
	for step in 30:
		arena.step()
	check(arena.kills == 1, "a rat in reach of the knife lived")


func test_a_knife_does_not_reach_far() -> void:
	var setup := _arena_with(["knife"])
	var arena: Arena = setup[0]
	var cat: Cat = setup[1]
	var rat := arena.add_creature(cat.body.position + Vector2(1.5, 0.0))
	# Hold the rat where it is: only reach is being tested.
	for step in 30:
		rat.body.position = cat.body.position + Vector2(1.5, 0.0)
		rat.body.velocity = Vector2.ZERO
		arena.step()
	check(arena.kills == 0 and rat.health == 2.0, "the knife reached a meter and a half")


func test_a_swing_cuts_everything_in_its_arc_once() -> void:
	var setup := _arena_with(["knife"])
	var arena: Arena = setup[0]
	var cat: Cat = setup[1]
	var rats: Array[Creature] = []
	for angle in [-0.4, 0.0, 0.4]:
		var rat := arena.add_creature(cat.body.position + Vector2.from_angle(angle) * 0.3)
		rat.health = 100.0
		rats.append(rat)
	var behind := arena.add_creature(cat.body.position + Vector2(-0.3, 0.0))
	behind.health = 100.0
	var knife := cat.weapons[0]
	arena.step()
	while knife.swinging():
		arena.step()
	for rat in rats:
		check(is_equal_approx(rat.health, 100.0 - knife.damage), "a rat in the arc took %.0f, not one cut" % (100.0 - rat.health))
	check(behind.health == 100.0, "the swing cut a rat behind him")


func test_two_paws_hold_two_one_handed_weapons_or_one_two_handed() -> void:
	var cat := Cat.new()
	cat.wear({"weapons": ["knife", "handgun", "submachine_gun"]})
	check(cat.weapons.size() == 2, "he holds %d weapons in his mouth and tail" % cat.weapons.size())
	var two_handed := Weapon.handgun()
	two_handed.hands = 2
	var paws := 0
	for weapon in cat.weapons:
		paws += weapon.hands
	check(paws <= Cat.HOLDS, "his weapons take %d holds" % paws)


func test_aim_modes_choose_their_targets() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var center := Arena.SIZE / 2.0
	var near := arena.add_creature(center + Vector2(1.0, 0.0))
	var tough := arena.add_creature(center + Vector2(3.0, 0.0))
	tough.health = 10.0
	for index in 6:
		arena.add_creature(center + Vector2(-4.0, 0.0) + Vector2.from_angle(index) * 0.2)
	arena.step()
	check(arena.target_for(center, 6.0, "nearest") == near, "nearest didn't pick the nearest")
	check(arena.target_for(center, 6.0, "toughest") == tough, "toughest didn't pick the one with most health")
	var crowded := arena.target_for(center, 6.0, "crowd")
	check(crowded != null and crowded.body.position.x < center.x - 3.0, "crowd didn't pick the cluster")


func test_hits_are_reported_for_the_view() -> void:
	var setup := _arena_with(["handgun"])
	var arena: Arena = setup[0]
	var cat: Cat = setup[1]
	arena.add_creature(cat.body.position + Vector2(3.0, 0.0))
	for step in 30:
		arena.step()
	check(not arena.events.is_empty(), "a hit wasn't reported")
	check(arena.events.any(func(event: Dictionary) -> bool: return event.killed), "a kill wasn't reported")
