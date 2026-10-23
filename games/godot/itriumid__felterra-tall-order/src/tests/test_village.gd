extends TestCase
## The village as a place: the cats he's rescued live in it, huts go up as more join, the houses
## are solid, a cutscene can walk him to a spot, and walking out on the path to the clearing is the
## way into a run.


func _rescued(count: int) -> Array:
	var cats: Array = []
	for index in count:
		cats.append({"name": Cage.NAMES[index % Cage.NAMES.size()], "coat": Cage.COATS[index % Cage.COATS.size()]})
	return cats


func test_the_cats_she_rescued_live_there() -> void:
	var map := VillageMap.new(_rescued(3))
	check(map.villagers.size() == 3, "%d villagers for 3 rescued" % map.villagers.size())
	check(map.villagers[1].coat == Cage.COATS[1] and map.names[1] == Cage.NAMES[1], "a villager came out in the wrong coat or name")
	for villager in map.villagers:
		check(villager.body.position.x > VillageMap.VILLAGE_FROM, "a villager lives out in the forest")


func test_everything_starts_in_ruins() -> void:
	var map := VillageMap.new()
	var ruins := map.buildings.filter(func(each: Dictionary) -> bool: return each.kind != "board")
	check(ruins.size() == VillageMap.building_names().size(), "%d buildings stand" % ruins.size())
	check(ruins.all(func(each: Dictionary) -> bool: return not each.restored), "something stood restored before anything was")


func test_restored_buildings_stand_restored() -> void:
	var map := VillageMap.new([], ["smithy", "hut_2"])
	var restored := map.buildings.filter(func(each: Dictionary) -> bool: return each.restored and each.kind != "board").map(func(each: Dictionary) -> String: return each.name)
	check(restored == ["smithy", "hut_2"], "restored: %s" % str(restored))


func test_what_is_restored_is_kept() -> void:
	var village := Village.new()
	village.restored.assign(["longhouse", "not_a_building"])
	var path := "user://test_village_restored.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.restored == ["longhouse"], "the village came back with %s restored" % str(loaded.restored))


func test_the_houses_are_solid() -> void:
	var map := VillageMap.new()
	map.cat.body.position = Vector2(VillageMap.LONGHOUSE.get_center().x, VillageMap.LONGHOUSE.end.y + 0.6)
	map.cat.steering = Vector2.UP
	for step in 120:
		map.step(Arena.STEP)
	check(not VillageMap.LONGHOUSE.has_point(map.cat.body.position), "he walked into the longhouse")


func test_in_the_forest_she_keeps_to_the_path() -> void:
	var map := VillageMap.new()
	map.cat.steering = Vector2.UP
	for step in 120:
		map.step(Arena.STEP)
	# Stopped right at the path's edge: meters on the map are only as exact as a float.
	check(map.cat.body.position.y >= VillageMap.PATH_TOP - 0.001, "he wandered off the path into the trees")


func test_a_cutscene_walks_her_there() -> void:
	var map := VillageMap.new()
	map.walk_to(VillageMap.HOME_SPOT)
	for step in 60 * 20:
		map.step(Arena.STEP)
	check(not map.walking() and map.cat.body.position.distance_to(VillageMap.HOME_SPOT) < 0.1, "he stopped at %s" % map.cat.body.position)


func test_with_nothing_to_tell_she_walks_in_at_her_full_pace() -> void:
	var map := VillageMap.new()
	map.stroll_speed = VillageMap.WALK_IN_SPEED
	map.walk_to(VillageMap.HOME_SPOT)
	var steps := 0
	while map.walking() and steps < 60 * 30:
		map.step(Arena.STEP)
		steps += 1
	var seconds := steps * Arena.STEP
	var at_full_pace := VillageMap.TITLE_SPOT.distance_to(VillageMap.HOME_SPOT) / Cat.SPEED
	check(seconds <= at_full_pace + 0.2, "the walk in took %.1f seconds, not %.1f" % [seconds, at_full_pace])


func test_the_path_out_starts_a_run() -> void:
	var map := VillageMap.new()
	map.cat.body.position = VillageMap.RETURN_SPOT
	check(not map.leaving(), "he was leaving from the middle of the village")
	map.cat.steering = Vector2.RIGHT
	for step in 120:
		map.step(Arena.STEP)
	check(map.leaving(), "he walked out along the path and never left")


func test_off_the_path_the_village_edge_is_a_wall() -> void:
	var map := VillageMap.new()
	map.cat.body.position = Vector2(VillageMap.SIZE.x - 1.0, 1.2)
	map.cat.steering = Vector2.RIGHT
	for step in 120:
		map.step(Arena.STEP)
	check(not map.leaving(), "he left the village through the trees")


func test_the_opening_is_remembered_once_told() -> void:
	var village := Village.new()
	village.intro_seen = true
	var path := "user://test_village_intro.cfg"
	village.save(path)
	var loaded := Village.new()
	loaded.load_from(path)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check(loaded.intro_seen, "the opening would be told again")
	loaded.clear()
	check(not loaded.intro_seen, "a reset didn't bring the opening back")


func test_jogiboy_keeps_pace_with_tompel_without_stopping_and_starting() -> void:
	var map := VillageMap.new()
	map.cat.body.position = Vector2(14.0, 5.0)
	map.jogi.body.position = Vector2(13.0, 5.0)
	var stops := 0
	var was_moving := false
	for step in 60 * 5:
		map.cat.steering = Vector2.RIGHT
		map.step(Arena.STEP)
		var moving := map.jogi.body.velocity.length() > 0.1
		if step > 60 and was_moving and not moving:
			stops += 1
		was_moving = moving
	check(stops == 0, "Jogiboy stopped %d times while Tompel walked" % stops)
	check(map.cat.body.position.distance_to(map.jogi.body.position) < 1.5, "Jogiboy fell behind")
	for step in 90:
		map.cat.steering = Vector2.ZERO
		map.step(Arena.STEP)
	check(map.jogi.body.velocity.length() < 0.1, "Jogiboy kept going once Tompel stopped")


func test_left_standing_jogiboy_plays_then_comes_back() -> void:
	var map := VillageMap.new()
	map.cat.body.position = Vector2(20.0, 5.0)
	map.jogi.body.position = Vector2(19.2, 5.3)
	var played: Array[String] = []
	for step in 60 * 40:
		map.step(Arena.STEP)
		if not map.jogi_playing.is_empty() and not map.jogi_playing in played:
			played.append(map.jogi_playing)
	check(played.size() >= 2, "in forty seconds standing, Jogiboy only played at %s" % str(played))
	map.cat.steering = Vector2.RIGHT
	map.step(Arena.STEP)
	check(map.jogi_playing.is_empty(), "Jogiboy kept playing when Tompel set off")
