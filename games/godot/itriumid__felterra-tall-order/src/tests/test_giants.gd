extends TestCase
## Giants: humans at real scale. They walk at a cat and stomp, can be dodged, barely move when
## shot, and fall like the tall bodies they are, crushing what they land on.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_a_giant_walks_at_the_cat() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(6.0, 0.0))
	for step in 60 * 2:
		arena.step()
	check(giant.body.position.distance_to(cat.body.position) < 4.5, "the giant didn't close in two seconds")


func test_a_stomp_hurts_the_cat_under_it_and_crushes_rats() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 100.0
	cat.max_health = 100.0
	var giant := arena.add_giant(cat.body.position + Vector2(0.7, 0.0))
	giant.stomp_ready_in = 0.0
	var rat := arena.add_creature(cat.body.position + Vector2(0.05, 0.1))
	rat.body.velocity = Vector2.ZERO
	for step in ceili(Giant.WIND_TIME * 60.0) + 2:
		# Hold him still under the boot.
		cat.steering = Vector2.ZERO
		arena.step()
	check(cat.health < 100.0, "the boot came down on him and he took nothing")
	check(not rat in arena.creatures, "a rat under the boot lived")


func test_a_dodge_gets_her_out_from_under_the_boot() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(0.7, 0.0))
	giant.stomp_ready_in = 0.0
	arena.step()
	check(giant.state == Giant.State.WINDING, "the giant didn't wind up")
	# He sees the shadow and rolls away from it.
	cat.steering = Vector2.LEFT
	cat.dodge()
	for step in ceili(Giant.WIND_TIME * 60.0) + 2:
		arena.step()
	check(cat.health == Cat.MOST_HEALTH, "he rolled clear and still took %.1f" % (Cat.MOST_HEALTH - cat.health))


func test_a_round_barely_moves_a_giant() -> void:
	var arena := _arena()
	var rat := arena.add_creature(Vector2(10.0, 10.0))
	rat.health = 100.0
	var giant := arena.add_giant(Vector2(20.0, 10.0))
	giant.state = Giant.State.WINDING
	giant.wind_for = 10.0
	arena.strike(rat, 1.0, Vector2.RIGHT, 1.6, 0.0, "round")
	arena.strike(giant, 1.0, Vector2.RIGHT, 1.6, 0.0, "round")
	check(giant.body.velocity.length() * 10.0 < rat.body.velocity.length(), "a giant moved like a rat: %s against %s" % [giant.body.velocity, rat.body.velocity])


func test_a_felled_giant_topples_like_a_tall_body() -> void:
	var arena := _arena()
	var giant := arena.add_giant(Arena.SIZE / 2.0)
	arena.strike(giant, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round")
	check(giant.state == Giant.State.FALLING, "he didn't start to fall")
	var steps := 0
	while giant.state == Giant.State.FALLING and steps < 600:
		arena.step()
		steps += 1
	# A 1.75 m rod nudged five hundredths of a radian off upright takes about 1.3 s to land.
	var seconds := steps / 60.0
	check(seconds > 0.9 and seconds < 1.8, "he fell in %.2f s" % seconds)
	check(giant.state == Giant.State.FALLEN, "he never landed")


func test_a_falling_giant_crushes_what_he_lands_on() -> void:
	var arena := _arena()
	var giant := arena.add_giant(Vector2(10.0, 10.0))
	var under := arena.add_creature(Vector2(11.2, 10.0))
	var clear := arena.add_creature(Vector2(11.2, 12.0))
	under.health = 50.0
	clear.health = 50.0
	arena.strike(giant, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round")
	for step in 120:
		under.body.position = Vector2(11.2, 10.0)
		clear.body.position = Vector2(11.2, 12.0)
		arena.step()
	check(not under in arena.creatures, "a rat under the falling giant lived")
	check(clear in arena.creatures, "a rat two meters clear was crushed")


func test_felling_a_giant_is_worth_more_than_a_rat() -> void:
	var arena := _arena()
	arena.add_cat(Arena.SIZE / 2.0)
	var giant := arena.add_giant(Arena.SIZE / 2.0 + Vector2(3.0, 0.0))
	var before := arena.experience + arena.level * 100
	arena.strike(giant, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round")
	check(arena.experience + arena.level * 100 - before >= Giant.WORTH, "felling a giant gave too little experience")


func test_a_knife_reaches_a_giant_at_his_shins() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.wear({"weapons": ["knife"]})
	var giant := arena.add_giant(cat.body.position + Vector2(0.55, 0.0))
	giant.stomp_ready_in = 100.0
	for step in 40:
		arena.step()
	check(giant.health < Giant.MOST_HEALTH, "the knife never cut the giant beside him")
