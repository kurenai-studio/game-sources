extends TestCase
## Liberation: each area's plan spawns only what that place has; its goal, done, brings its boss;
## the boss beaten frees the area. And each area's own things and bosses do what they do.


func _area(area_id: String) -> Arena:
	var arena := Arena.new()
	arena.begin_area(area_id)
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1.0e6
	return arena


func _steps(arena: Arena, steps: int) -> void:
	for step in steps:
		arena.step()


func test_endless_is_the_plan_it_always_was() -> void:
	var arena := Arena.new()
	check(arena.plan == Arena.ENDLESS and arena.area.is_empty(), "a plain arena isn't Endless")
	arena.add_cat(Arena.SIZE / 2.0).health = 1.0e9
	_steps(arena, 60 * 5)
	check(not arena.liberated and arena.boss == null, "Endless had a boss or was freed")


func test_every_area_sets_out_its_goal() -> void:
	for area: Dictionary in Areas.LIST:
		var arena := _area(area.id)
		var progress := arena.goal_progress()
		check(progress.y > 0.0 and progress.x == 0.0, "%s starts at %s" % [area.id, progress])


func test_an_area_spawns_only_what_it_has() -> void:
	var arena := _area("edge")
	_steps(arena, 60 * 70)
	check(not arena.creatures.any(func(creature: Creature) -> bool: return creature.kind == "dog"), "dogs came to the village's edge")
	check(arena.giants.is_empty(), "a giant came to the village's edge")


func test_breaking_the_nests_brings_the_rat_baron_and_beating_him_frees_the_edge() -> void:
	var arena := _area("edge")
	for structure in arena.structures:
		arena.strike(structure, 1000.0, Vector2.ZERO, 0.0, 0.0, "round")
	arena.step()
	check(arena.goal_done and arena.boss is Creature and arena.boss.kind == "rat_baron", "the nests broke and no Rat Baron came")
	arena.strike(arena.boss, 1.0e6, Vector2.ZERO, 0.0, 0.0, "round")
	arena.step()
	check(arena.liberated, "the Rat Baron fell and the edge wasn't freed")


func test_freeing_the_caged_is_the_deep_forests_goal() -> void:
	var arena := _area("deep")
	for cage in arena.goal_cages:
		cage.picked = 0.999
		cage.body.position = arena.cats[0].body.position
	arena.step()
	check(arena.goal_done and arena.boss is Giant and arena.boss.kind == "handler", "the cages opened and no handler came")


func test_holding_the_clearing_brings_the_log_loader() -> void:
	var arena := _area("clearing")
	arena.held_for = Areas.named("clearing").goal.seconds - 0.05
	_steps(arena, 10)
	check(arena.goal_done and arena.boss is LogLoader, "the clearing was held and no log loader came")


func test_a_lever_lets_logs_roll_over_the_horde() -> void:
	var arena := _area("slide")
	var cat: Cat = arena.cats[0]
	var lever: Dictionary = arena.levers[0]
	cat.body.position = lever.position
	var rat := arena.add_creature(lever.position + Vector2(0.5, 4.0))
	rat.health = 50.0
	for step in ceili((Arena.LEVER_TIME + Arena.LOG_WAIT) / Arena.STEP) + 120:
		cat.body.position = lever.position
		if rat.alive():
			rat.body.position = lever.position + Vector2(0.5, 4.0)
			rat.body.velocity = Vector2.ZERO
		arena.step()
	check(lever.pulled and not rat.alive(), "the logs didn't roll over the rat below the lever")


func test_a_nest_breeds_and_a_saw_cuts() -> void:
	var arena := _area("edge")
	var before := arena.creatures.size()
	_steps(arena, ceili(Structure.BREED_INTERVAL / Arena.STEP) + 2)
	check(arena.creatures.size() > before, "the nests bred nothing")
	var sawpits := _area("sawpits")
	var cat: Cat = sawpits.cats[0]
	var saw: Structure = sawpits.structures[0]
	cat.body.position = saw.body.position + Vector2(saw.body.radius + 0.2, 0.0)
	var health := cat.health
	_steps(sawpits, 60)
	check(cat.health < health, "he stood at the saw and it didn't cut him")


func test_a_broken_fuel_drum_burns() -> void:
	var arena := _area("airstrip")
	arena.strike(arena.structures[0], 1000.0, Vector2.ZERO, 0.0, 0.0, "round")
	check(not arena.fires.is_empty(), "the fuel drum broke and nothing burned")


func test_the_rat_baron_calls_rats_in() -> void:
	var arena := _area("edge")
	arena.structures.clear()
	var baron := arena.add_creature(Arena.SIZE / 2.0 + Vector2(6.0, 0.0), "rat_baron")
	baron.call_in = 0.0
	arena.step()
	check(arena.creatures.size() > 1, "the Rat Baron called, and nothing came")


func test_the_handler_keeps_off_and_whistles_his_dogs_in() -> void:
	var arena := _area("deep")
	arena.spawning = false
	var handler := arena.add_giant(arena.cats[0].body.position + Vector2(2.0, 0.0), "handler")
	handler.whistle_in = 0.0
	_steps(arena, 60 * 2)
	check(handler.body.position.distance_to(arena.cats[0].body.position) > 3.0, "the handler came in close")
	check(arena.creatures.any(func(creature: Creature) -> bool: return creature.kind == "dog"), "he whistled, and no dogs came")


func test_the_log_loader_throws_where_she_was() -> void:
	var arena := _area("clearing")
	arena.spawning = false
	var loader: LogLoader = arena.add_machine(arena.cats[0].body.position + Vector2(6.0, 0.0), PI, "log_loader")
	loader.bite_ready_in = 0.0
	var cat: Cat = arena.cats[0]
	var health := cat.health
	_steps(arena, 60 * 4)
	check(loader.bites >= 1 and cat.health < health, "the loader never landed a log on him")


func test_the_logging_truck_charges_then_stalls_with_its_tank_open() -> void:
	var arena := _area("slide")
	arena.spawning = false
	var truck: LoggingTruck = arena.add_machine(arena.cats[0].body.position + Vector2(-8.0, 0.0), 0.0, "logging_truck")
	truck.bite_ready_in = 0.0
	var charged := false
	var stalled_open := false
	for step in 60 * 5:
		arena.step()
		charged = charged or truck.state == Machine.State.BITING
		stalled_open = stalled_open or (truck.state == Machine.State.STUCK and truck.exposed())
	check(charged and stalled_open, "the truck didn't charge, or didn't stall with its tank open")


func test_the_bulldozers_weak_point_is_behind_it() -> void:
	var arena := _area("offices")
	var dozer: Bulldozer = arena.add_machine(Arena.SIZE / 2.0 + Vector2(5.0, 0.0), 0.0, "bulldozer")
	arena.step()
	var behind := dozer.point(-dozer.length * 0.5 - 0.15, 0.0)
	check(dozer.exposed() and dozer.joint.body.position.distance_to(behind) < 0.01, "the engine isn't open at the back")
	check(dozer.in_front(dozer.point(dozer.length * 0.5 + 0.3, 0.0)) and not dozer.in_front(behind), "the blade's reach is the wrong way round")


func test_the_helicopter_is_out_of_reach_until_it_lands() -> void:
	var arena := _area("airstrip")
	arena.spawning = false
	var cat: Cat = arena.cats[0]
	var heli: Helicopter = arena.add_machine(cat.body.position + Vector2(0.3, 0.0), 0.0, "helicopter")
	check(heli.flying and not heli.covers(cat.body.position), "a flying helicopter stood on the ground")
	var knife := Weapon.knife()
	check(not heli in arena.cut(cat.body.position, 0.0, 1.0, knife, -PI, PI), "a blade reached the helicopter in the air")
	heli.runs = Helicopter.RUNS_BEFORE_LANDING
	heli.bite_ready_in = 0.0
	var landed := false
	for step in 60 * 10:
		arena.step()
		landed = landed or (heli.landed and heli.exposed())
	check(landed, "it never set down with its tail rotor open")


func test_a_goal_done_before_stays_done_and_the_boss_comes_after_a_while() -> void:
	var arena := Arena.new()
	arena.spawning = false
	arena.add_cat(Arena.SIZE / 2.0)
	arena.begin_area("deep", true)
	check(arena.goal_done and arena.goal_cages.is_empty(), "the cages were set again, with their goal done before")
	for step in int((Arena.BOSS_BUILD_UP - 1.0) / Arena.STEP):
		arena.step()
	check(arena.boss == null, "the boss came before he'd had time to grow")
	for step in int(2.0 / Arena.STEP):
		arena.step()
	check(arena.boss != null, "the boss never came")


func test_the_village_keeps_a_goal_done_until_the_area_is_free() -> void:
	var village := Village.new()
	village.goals_done.append("deep")
	var path := "user://test_goals_done.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.goals_done == ["deep"], "the goal done came back as %s" % str(loaded.goals_done))
	loaded.liberate("deep")
	check(loaded.goals_done.is_empty(), "a freed area still counted its goal as done")
