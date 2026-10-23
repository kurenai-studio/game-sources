extends TestCase
## The dodge: a quick roll that bites can't land on, then a cooldown.


func test_a_dodge_rolls_further_than_a_walk() -> void:
	var walker := Arena.new()
	walker.spawning = false
	var walking := walker.add_cat(Vector2(10.0, 12.0))
	walking.steering = Vector2.RIGHT
	var roller := Arena.new()
	roller.spawning = false
	var rolling := roller.add_cat(Vector2(10.0, 12.0))
	rolling.steering = Vector2.RIGHT
	check(rolling.dodge(), "the dodge wasn't ready")
	for step in 15:
		walker.step()
		roller.step()
	check(rolling.body.position.x - 10.0 > (walking.body.position.x - 10.0) * 1.5, "the roll was no faster than walking")


func test_bites_do_not_land_during_a_dodge() -> void:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Vector2(10.0, 12.0))
	cat.dodge()
	check(not cat.hurt(1.0, Vector2.ZERO), "a bite landed mid-roll")
	check(cat.health == Cat.MOST_HEALTH, "health dropped mid-roll")
	for step in 30:
		arena.step()
	check(cat.hurt(1.0, Vector2.ZERO), "still safe half a second later")


func test_the_dodge_has_a_cooldown() -> void:
	var cat := Cat.new()
	check(cat.dodge(), "the first dodge wasn't ready")
	check(not cat.dodge(), "dodged again at once")
