extends TestCase
## Rescue and salvage: standing by a cage picks its lock, leaving lets the pick slip back, a freed
## cat runs home and is counted; what he breaks throws out salvage, and walking over it takes it.
## What a run brings home goes to the village, and stays there until progress is reset.


func _arena() -> Arena:
	var arena := Arena.new()
	arena.spawning = false
	return arena


func test_standing_by_a_cage_picks_its_lock() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	var cage := arena.add_cage(cat.body.position + Vector2(0.5, 0.0))
	for step in ceili(Cage.PICK_TIME / Arena.STEP) - 10:
		arena.step()
	check(not cage.opened, "the lock gave before its time")
	for step in 20:
		arena.step()
	check(cage.opened and arena.rescued.size() == 1, "he stood by it for %.0f seconds and it stayed shut" % Cage.PICK_TIME)
	check(arena.rescued[0].name in Cage.NAMES and arena.rescued[0].coat in Cage.COATS, "the rescued cat came out as %s" % str(arena.rescued[0]))


func test_leaving_lets_the_pick_slip_back() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	var cage := arena.add_cage(cat.body.position + Vector2(0.5, 0.0))
	for step in 60:
		arena.step()
	var picked := cage.picked
	cat.body.position += Vector2(0.0, 4.0)
	for step in 60:
		arena.step()
	check(cage.picked < picked and not cage.opened, "he walked off and the pick held at %.2f" % cage.picked)


func test_a_freed_cat_runs_home() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	var cage := arena.add_cage(cat.body.position + Vector2(0.5, 0.0))
	cage.picked = 0.999
	arena.step()
	check(cage.opened, "the lock didn't give")
	for step in 60 * 10:
		arena.step()
	check(arena.cages.is_empty(), "the freed cat never made it home")


func test_cages_turn_up_away_from_her() -> void:
	var arena := Arena.new()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.health = 1.0e9
	arena._since_cage = Arena.CAGE_INTERVAL - 0.5
	for step in 60:
		arena.step()
	check(arena.cages.size() == 1, "%d cages turned up" % arena.cages.size())
	check(arena.cages[0].body.position.distance_to(cat.body.position) >= Arena.CAGE_DISTANCE - 0.5, "a cage turned up right by him")


func test_breaking_things_throws_out_salvage_and_walking_over_it_takes_it() -> void:
	var arena := _arena()
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	var giant := arena.add_giant(cat.body.position + Vector2(4.0, 0.0))
	arena.strike(giant, 1000.0, Vector2.RIGHT, 0.0, 0.0, "round", cat)
	check(arena.pickups.size() == Arena.SALVAGE.worker, "a felled worker threw out %d pieces" % arena.pickups.size())
	for step in 120:
		arena.step()
	for piece in arena.pickups.duplicate():
		cat.body.position = piece.body.position
		arena.step()
	check(arena.salvage == Arena.SALVAGE.worker and arena.pickups.is_empty(), "he walked over it all and took %d" % arena.salvage)


func test_what_a_run_brings_home_stays_until_reset() -> void:
	var arena := _arena()
	arena.rescued.append({"name": "Oyen", "coat": "orange"})
	arena.salvage = 7
	var village := Village.new()
	village.bring_home(arena)
	village.bring_home(arena)
	var path := "user://test_village.cfg"
	check(village.save(path), "the village didn't save")
	var loaded := Village.new()
	loaded.load_from(path)
	check(loaded.cats.size() == 2 and loaded.salvage == 14, "the village came back with %d cats and %d salvage" % [loaded.cats.size(), loaded.salvage])
	loaded.clear()
	loaded.save(path)
	var reset := Village.new()
	reset.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(reset.cats.is_empty() and reset.salvage == 0, "after a reset, the village still had %d cats" % reset.cats.size())


## A cage of a temperament, opened beside a cat, the arena stepped this many seconds.
func _freed(temperament: String, seconds: float, with_rat := false) -> Dictionary:
	var arena := Arena.new()
	arena.spawning = false
	var cat := arena.add_cat(Arena.SIZE / 2.0)
	cat.weapons.clear()
	cat.health = 1000.0
	var cage := arena.add_cage(cat.body.position + Vector2(0.4, 0.0))
	cage.temperament = temperament
	cage.picked = 1.0
	var rat: Creature = arena.add_creature(cage.body.position + Vector2(2.5, 0.0)) if with_rat else null
	if rat != null:
		rat.health = 1000.0
	var heard: Array[String] = []
	for step in int(seconds / Arena.STEP):
		if rat != null:
			rat.body.position = cage.body.position + Vector2(2.5, 0.0)
		arena.step()
		var line := cage.saying()
		if not line.is_empty() and not line.by + ":" + line.text in heard:
			heard.append(line.by + ":" + line.text)
	return {"cage": cage, "arena": arena, "heard": heard, "rat": rat}


func test_a_freed_cat_has_its_say_and_runs() -> void:
	for temperament: String in Cage.TEMPERAMENTS:
		var freed := _freed(temperament, Cage.LINGER[temperament] + 0.3)
		var cage: Cage = freed.cage
		check(not (freed.heard as Array).is_empty(), "a %s cat said nothing" % temperament)
		check(cage.ran > 0.0, "a %s cat never ran for home" % temperament)


func test_a_chatty_cat_is_told_to_go() -> void:
	var freed := _freed("chatty", 4.0)
	var heard: Array = freed.heard
	check(heard.size() == 3 and (heard[1] as String).begins_with("tompel:"), "a chatty cat's talk went %s" % str(heard))
	var grateful: Cage = _freed("grateful", Cage.LINGER.grateful + 0.3).cage
	check(Cage.LINGER.chatty > Cage.LINGER.grateful and grateful.ran > 0.0, "a chatty cat didn't stay to talk longer")


func test_a_fighter_throws_a_firecracker_on_its_way_out() -> void:
	var freed := _freed("fighter", 3.0, true)
	var rat: Creature = freed.rat
	check((freed.cage as Cage).thrown and rat.health < 1000.0, "the fighter's firecracker never hit the rat")
