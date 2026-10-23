extends TestCase
## The horde: it comes for the cat, can't stand in itself, and the cat's gun cuts it down.


func _quiet_arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_a_cat_starts_with_one_weapon_and_nothing_else() -> void:
	var cat := Cat.new()
	check(cat.weapons.size() == 1 and cat.weapons[0].name == "handgun", "he starts with %s" % cat.weapons.map(func(w: Weapon) -> String: return w.name))
	check(cat.gear.values().all(func(item: String) -> bool: return item == ""), "he starts wearing %s" % cat.gear)


func test_rats_run_at_the_cat() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var rat := arena.add_creature(cat.body.position + Vector2(5.0, 0.0))
	for step in 60:
		arena.step()
	check(rat.body.position.distance_to(cat.body.position) < 3.5, "the rat didn't close in a second")


func test_a_crowd_does_not_stand_in_itself() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1000.0
	for index in 60:
		arena.add_creature(cat.body.position + Vector2.from_angle(index * 0.7) * (3.0 + index * 0.05))
	for step in 60 * 4:
		arena.step()
	var overlapping := 0
	for creature in arena.creatures:
		for other in arena.creatures:
			if other != creature and creature.body.position.distance_to(other.body.position) < 0.08:
				overlapping += 1
	# Squeezed around the cat, some overlap is the push still settling; most must stand apart.
	check(overlapping < arena.creatures.size() / 4, "%d overlapping pairs in a crowd of 60" % (overlapping / 2))


func test_the_gun_fires_on_its_own_and_kills() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	arena.add_creature(cat.body.position + Vector2(4.0, 1.0))
	for step in 60:
		arena.step()
	check(arena.kills == 1, "the rat lived, %d kills" % arena.kills)
	check(arena.fallen.size() == 1, "the rat left no body")


func test_a_fast_round_cannot_pass_through_a_rat_between_steps() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Vector2(2.0, 12.0))
	var rat := arena.add_creature(Vector2(5.0, 12.0))
	rat.health = 1.0
	cat.weapons[0].spread = 0.0
	# 600 m/s crosses ten meters a step, much more than a rat is wide.
	cat.weapons[0].muzzle_speed = 600.0
	for step in 10:
		arena.step()
	check(arena.kills == 1, "the round passed through")


func test_a_hit_throws_the_rat_back_and_up() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Vector2(2.0, 12.0))
	cat.weapons[0].spread = 0.0
	var rat := arena.add_creature(Vector2(5.0, 12.0))
	rat.health = 100.0
	var thrown := false
	var furthest := rat.body.position.x
	for step in 30:
		arena.step()
		thrown = thrown or rat.body.height > 0.0
		furthest = maxf(furthest, rat.body.position.x)
	check(thrown, "a hit never lifted the rat")
	check(furthest > 5.0, "the rat was never pushed away from the gun")


func test_the_oldest_fallen_crumble_away_rather_than_vanish() -> void:
	var arena := _quiet_arena()
	var first := Body.new()
	arena.fallen.append(first)
	for index in Arena.MOST_FALLEN + 9:
		arena.fallen.append(Body.new())
	arena.step()
	check(arena.fallen.size() == Arena.MOST_FALLEN, "%d fallen kept" % arena.fallen.size())
	check(arena.fading.size() == 10, "%d crumbling" % arena.fading.size())
	check(arena.fading[0].body == first, "the oldest wasn't the first to go")
	for step in ceili(Arena.FADE_TIME / Arena.STEP) + 1:
		arena.step()
	check(arena.fading.is_empty(), "%d still crumbling after the fade" % arena.fading.size())


func test_bodies_lying_still_are_not_simulated() -> void:
	var body := Body.new()
	check(body.resting(), "a body lying still isn't resting")
	body.push(Vector2(1.0, 0.0), 0.0)
	check(not body.resting(), "a sliding body counts as resting")


func test_a_swarm_of_bites_never_throws_the_cat_into_the_air() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e9
	for index in 40:
		arena.add_creature(cat.body.position + Vector2.from_angle(index * TAU / 40.0) * 0.2)
	var highest := 0.0
	for step in 60 * 5:
		arena.step()
		highest = maxf(highest, cat.body.height)
	# One bite's hop is 0.8²/(2g), about 3 centimeters; forty at once must not add up.
	check(highest < 0.1, "forty bites threw the cat %.2f m up" % highest)


func test_rats_cannot_bite_a_cat_above_them() -> void:
	var arena := _quiet_arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.body.height = 0.5
	var rat := arena.add_creature(cat.body.position)
	arena.step()
	check(cat.health == Cat.MOST_HEALTH, "a rat bit a cat half a meter above it")
	check(rat.bite_ready_in == 0.0, "the rat spent a bite it couldn't land")
