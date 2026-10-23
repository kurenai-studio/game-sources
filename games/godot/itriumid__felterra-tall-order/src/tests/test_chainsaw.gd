extends TestCase
## The chainsaw worker: he revs (the warning) before he sweeps, the sweep cuts what's in its arc
## at a cat's height and not behind him, a dodge gets him through, and it cuts his own horde too.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func _close_in(arena: Arena, cat: Cat, giant: Giant) -> void:
	for step in 120:
		arena.step()
		if giant.state == Giant.State.REVVING:
			return


func test_he_revs_for_the_full_warning_before_he_sweeps() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(1.0, 0.0), "chainsaw")
	giant.stomp_ready_in = 0.0
	_close_in(arena, cat, giant)
	check(giant.state == Giant.State.REVVING, "he never revved")
	var revving := 0
	while giant.state == Giant.State.REVVING:
		arena.step()
		revving += 1
	check(revving * Arena.STEP >= Giant.REV_TIME - 0.02, "he revved for only %.2f s" % (revving * Arena.STEP))
	check(giant.state == Giant.State.SWEEPING, "the rev led to %d, not a sweep" % giant.state)


func test_the_sweep_cuts_a_cat_in_its_arc() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 100.0
	cat.max_health = 100.0
	var giant := arena.add_giant(cat.body.position + Vector2(1.0, 0.0), "chainsaw")
	giant.stomp_ready_in = 0.0
	for step in 120:
		arena.step()
	check(cat.health <= 100.0 - Giant.SAW_DAMAGE + 0.01, "standing in front of the saw, he took %.1f" % (100.0 - cat.health))


func test_the_sweep_doesnt_reach_behind_him() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(1.0, 0.0), "chainsaw")
	giant.state = Giant.State.SWEEPING
	giant.saw_for = Giant.SWEEP_TIME
	# Facing away from him, the arc is all on his far side.
	giant.sweep_center = 0.0
	giant.saw_angle = -Giant.SAW_ARC * 0.5
	for step in ceili(Giant.SWEEP_TIME / Arena.STEP) + 1:
		arena.step()
	check(cat.health == Cat.MOST_HEALTH, "the saw cut him behind him")


func test_a_dodge_gets_her_through_the_sweep() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(1.0, 0.0), "chainsaw")
	giant.stomp_ready_in = 0.0
	_close_in(arena, cat, giant)
	while giant.state == Giant.State.REVVING:
		arena.step()
	cat.steering = Vector2.LEFT
	cat.dodge()
	while giant.state == Giant.State.SWEEPING:
		arena.step()
	check(cat.health == Cat.MOST_HEALTH, "he rolled through the sweep and was still cut")


func test_the_saw_cuts_his_own_rats() -> void:
	var arena := _arena()
	var giant := arena.add_giant(Arena.SIZE / 2.0, "chainsaw")
	var rat := arena.add_creature(giant.body.position + Vector2(1.0, 0.0))
	rat.health = 50.0
	giant.state = Giant.State.SWEEPING
	giant.saw_for = Giant.SWEEP_TIME
	giant.sweep_center = 0.0
	giant.saw_angle = -Giant.SAW_ARC * 0.5
	for step in ceili(Giant.SWEEP_TIME / Arena.STEP) + 1:
		rat.body.position = giant.body.position + Vector2(1.0, 0.0)
		arena.step()
	check(not rat in arena.creatures, "a rat in the saw's arc lived")


func test_a_chainsaw_worker_is_tougher_and_worth_more() -> void:
	var worker := Giant.new()
	var chainsaw := Giant.new("chainsaw")
	check(chainsaw.most_health > worker.most_health, "the chainsaw worker isn't tougher")
	check(chainsaw.worth > worker.worth, "the chainsaw worker isn't worth more")


func test_chainsaws_only_come_once_a_run_is_well_on() -> void:
	var arena := Arena.new()
	arena.add_cat(Arena.SIZE / 2.0).health = 1.0e9
	var first_chainsaw := -1.0
	while arena.time < Arena.CHAINSAW_FROM + Arena.GIANT_INTERVAL * Arena.CHAINSAW_EVERY + 1.0:
		arena.step()
		# Keep the clearing from filling up: only the giants matter here.
		arena.creatures.clear()
		if first_chainsaw < 0.0 and arena.giants.any(func(giant: Giant) -> bool: return giant.has_chainsaw()):
			first_chainsaw = arena.time
	check(first_chainsaw >= Arena.CHAINSAW_FROM, "a chainsaw came at %.0f s" % first_chainsaw)
	check(first_chainsaw > 0.0, "no chainsaw came by %.0f s" % arena.time)
