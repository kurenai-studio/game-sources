extends TestCase
## Guard dogs: bigger than the cat and faster, they crouch before they lunge (the warning), leap
## through the air, and take a hit a rat would fly from.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_a_dog_outruns_the_cat() -> void:
	check(float(Creature.KINDS.dog.speed) > Cat.SPEED, "a dog is no faster than the cat")
	var arena := _arena()
	var cat := arena.add_cat(Vector2(5.0, 12.0))
	cat.weapons.clear()
	cat.steering = Vector2.RIGHT
	var dog := arena.add_creature(Vector2(1.0, 12.0), "dog")
	var start_gap := cat.body.position.x - dog.body.position.x
	# Three seconds: the first half second goes on getting up to speed from a standstill.
	for step in 60 * 3:
		cat.steering = Vector2.RIGHT
		arena.step()
	check(cat.body.position.x - dog.body.position.x < start_gap - 0.8, "a running cat kept ahead of the dog")


func test_a_dog_crouches_before_it_lunges() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var dog := arena.add_creature(cat.body.position + Vector2(1.2, 0.0), "dog")
	var crouched := false
	var lunged_after_crouching := false
	for step in 60:
		arena.step()
		crouched = crouched or dog.state == Creature.State.CROUCHING
		if dog.lunging():
			lunged_after_crouching = crouched
			break
	check(crouched, "the dog never crouched")
	check(lunged_after_crouching, "the dog lunged without crouching first")


func test_a_lunge_bites_a_cat_that_stays_put() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	arena.add_creature(cat.body.position + Vector2(1.2, 0.0), "dog")
	for step in 60:
		arena.step()
	check(cat.health < Cat.MOST_HEALTH, "a lunge at a cat standing still missed")


func test_a_dodge_gets_her_out_from_under_a_lunge() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var dog := arena.add_creature(cat.body.position + Vector2(1.2, 0.0), "dog")
	# He waits for the crouch, then rolls out sideways.
	for step in 60:
		arena.step()
		if dog.state == Creature.State.CROUCHING:
			break
	cat.steering = Vector2.DOWN
	cat.dodge()
	for step in 30:
		cat.steering = Vector2.DOWN
		arena.step()
	check(cat.health == Cat.MOST_HEALTH, "he rolled clear of the lunge and was still bitten")


func test_a_round_shoves_a_dog_less_than_a_rat() -> void:
	var arena := _arena()
	var rat := arena.add_creature(Vector2(5.0, 5.0))
	var dog := arena.add_creature(Vector2(5.0, 10.0), "dog")
	rat.health = 100.0
	dog.health = 100.0
	arena.strike(rat, 1.0, Vector2.RIGHT, 1.6, 1.0, "round")
	arena.strike(dog, 1.0, Vector2.RIGHT, 1.6, 1.0, "round")
	check(dog.body.velocity.length() * 2.0 < rat.body.velocity.length(), "a dog was shoved like a rat")


func test_dogs_come_in_packs_once_a_run_is_going() -> void:
	var arena := Arena.new()
	arena.add_cat(Arena.SIZE / 2.0).health = 1.0e9
	var first_dogs := -1.0
	while arena.time < Arena.DOGS_FROM + 2.0:
		arena.step()
		if first_dogs < 0.0 and arena.creatures.any(func(creature: Creature) -> bool: return creature.kind == "dog"):
			first_dogs = arena.time
	var pack := arena.creatures.filter(func(creature: Creature) -> bool: return creature.kind == "dog").size()
	check(first_dogs >= Arena.DOGS_FROM - 0.1, "dogs came at %.1f s, before %.0f" % [first_dogs, Arena.DOGS_FROM])
	check(pack >= 1 and pack <= Arena.DOG_PACK, "%d dogs in the first pack" % pack)
