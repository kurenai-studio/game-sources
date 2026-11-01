extends GutTest
## The campaign loader and the bundled starter campaign.


func _level(id: String) -> Dictionary:
	return {
		"schemaVersion": 1,
		"levelId": id,
		"levelVersion": 1,
		"slug": id,
		"title": id,
		"description": "",
		"difficulty": "easy",
		"requires": {"mechanics": []},
		"board": {"width": 3, "height": 3, "walls": []},
		"initialState": {"position": [0, 2], "direction": "north"},
		"availableCommands": ["MOVE_FORWARD", "TURN_LEFT", "TURN_RIGHT"],
		"constraints": {"maxCommands": 6, "maxSteps": 20},
		"goal": {"type": "reach_tile", "position": [0, 0]},
		"hints": [],
	}


func _placement() -> Dictionary:
	return {
		"worlds":
		[
			{
				"id": "w1",
				"title": "One",
				"summary": "",
				"chapters":
				[
					{"id": "c1", "title": "A", "levels": ["a", "b"]},
					{"id": "c2", "title": "B", "levels": ["c"]},
				],
			},
			{
				"id": "w2",
				"title": "Two",
				"summary": "",
				"chapters": [{"id": "c3", "title": "C", "levels": ["d"]}],
			},
		],
	}


func _loader(levels: Dictionary) -> Callable:
	return func(id: String) -> Variant: return levels.get(id)


func _all_four() -> Dictionary:
	var levels := {}
	for id in ["a", "b", "c", "d"]:
		levels[id] = _level(id)
	return levels


func test_order_follows_world_chapter_level() -> void:
	var campaign := Campaign.from_data(_placement(), _loader(_all_four()))
	var ids: Array[String] = []
	for entry in campaign.entries:
		ids.append(entry["id"])
	assert_eq(ids, ["a", "b", "c", "d"] as Array[String])
	assert_eq(campaign.errors.size(), 0)


func test_entries_know_their_place() -> void:
	var campaign := Campaign.from_data(_placement(), _loader(_all_four()))
	var c: Dictionary = campaign.entry_by_id("c")
	assert_eq(c["number"], 3)
	assert_eq(c["world"], 0)
	assert_eq(c["chapter"], 1)
	var d: Dictionary = campaign.entry_by_id("d")
	assert_eq(d["world"], 1)
	assert_eq(campaign.worlds.size(), 2)
	assert_eq(campaign.worlds[0]["chapters"].size(), 2)


func test_next_after_walks_the_flattened_order_and_ends() -> void:
	var campaign := Campaign.from_data(_placement(), _loader(_all_four()))
	assert_eq(campaign.next_after("b")["id"], "c")
	assert_eq(campaign.next_after("c")["id"], "d")
	assert_true(campaign.next_after("d").is_empty())
	assert_true(campaign.next_after("missing").is_empty())


func test_invalid_level_is_skipped_and_reported() -> void:
	var levels := _all_four()
	levels["b"]["board"]["width"] = 99
	var campaign := Campaign.from_data(_placement(), _loader(levels))
	assert_eq(campaign.entries.size(), 3)
	assert_eq(campaign.entry_by_id("b"), {})
	assert_eq(campaign.errors.size(), 1)
	assert_eq(campaign.entry_by_id("c")["number"], 2, "numbers close the gap")


func test_missing_level_file_does_not_crash() -> void:
	var levels := _all_four()
	levels.erase("a")
	var campaign := Campaign.from_data(_placement(), _loader(levels))
	assert_eq(campaign.entries.size(), 3)
	assert_eq(campaign.errors.size(), 1)


func test_level_that_needs_a_mechanic_is_blocked_not_playable() -> void:
	var levels := _all_four()
	levels["d"]["requires"]["mechanics"] = ["wormhole"]
	var campaign := Campaign.from_data(_placement(), _loader(levels))
	assert_eq(campaign.entries.size(), 3, "it cannot be played")
	assert_eq(campaign.worlds.size(), 2, "its world stays, so the player can see why")
	var blocked := campaign.blocked_by_id("d")
	assert_eq(blocked["reason"], "mechanic")
	assert_eq(blocked["title"], levels["d"]["title"])
	assert_eq(campaign.blocked_levels().size(), 1)


func test_level_with_a_newer_schema_is_blocked() -> void:
	var levels := _all_four()
	levels["a"]["schemaVersion"] = 2
	var campaign := Campaign.from_data(_placement(), _loader(levels))
	assert_eq(campaign.entry_by_id("a"), {})
	assert_eq(campaign.blocked_by_id("a")["reason"], "schema")


func test_level_file_naming_another_id_is_skipped() -> void:
	var levels := _all_four()
	levels["a"]["slug"] = "other"
	var campaign := Campaign.from_data(_placement(), _loader(levels))
	assert_eq(campaign.entry_by_id("a"), {})
	assert_eq(campaign.errors.size(), 1)


func test_level_placed_twice_loads_once() -> void:
	var placement := _placement()
	placement["worlds"][1]["chapters"][0]["levels"] = ["a"]
	var campaign := Campaign.from_data(placement, _loader(_all_four()))
	assert_eq(campaign.entries.size(), 3)
	assert_eq(campaign.errors.size(), 1)


func test_malformed_placement_gives_an_empty_campaign() -> void:
	for bad: Variant in [
		null, 5, {}, {"worlds": "x"}, {"worlds": [5]}, {"worlds": [{"chapters": 1}]}
	]:
		var campaign := Campaign.from_data(bad, _loader({}))
		assert_eq(campaign.entries.size(), 0)
		assert_gt(campaign.errors.size(), 0)


func test_bundled_campaign_loads_cleanly() -> void:
	var campaign := Campaign.load_bundled()
	assert_eq(campaign.errors, [] as Array[String])
	assert_eq(campaign.entries.size(), 113, "the bundled campaign is the published starter set")
	assert_eq(campaign.worlds.size(), 20)
	var chapters := 0
	for world in campaign.worlds:
		chapters += world["chapters"].size()
	assert_eq(chapters, 48)


func test_every_bundled_level_is_solvable_within_its_limit() -> void:
	var campaign := Campaign.load_bundled()
	for entry in campaign.entries:
		var level: Dictionary = entry["level"]
		if str(level["goal"]["type"]) != "reach_tile":
			# A sweep has no target to search for; the server checks its reference solution.
			continue
		var shortest := _shortest_program(level)
		assert_gt(shortest, 0, "%s is solvable" % entry["id"])
		var limit := int(level["constraints"]["maxCommands"])
		if level.has("extraBoards") or level.has("startProgram"):
			# One program solves every board, so the plain program for the first board says nothing
			# about the limit; the server checks the reference solution on all of them. A debug
			# level's limit fits its broken program and the fix, not the need for a loop.
			continue
		if LevelMechanics.recursion(level):
			# A procedure that calls itself repeats without a loop, so this plain search measures
			# a program no shorter than the limit; the server checks the reference solution.
			continue
		if level.has("ice") or level.has("teleports"):
			# Ice slides and a teleporter jumps, so walking cell by cell can be longer than the
			# limit; the server's solver moves through the same rules as the simulator and checks
			# the par.
			continue
		if (
			level["availableCommands"].has("REPEAT")
			or level["availableCommands"].has("REPEAT_UNTIL")
		):
			# This search has no loops, so it measures the plain program. The server's solver checks
			# the loop par (apps/api/test/starter-campaign.test.ts); here a loop level must be one
			# where the plain program does not fit the limit, so that a loop is needed.
			assert_true(
				shortest > limit,
				"%s needs a loop: plain %d, limit %d" % [entry["id"], shortest, limit]
			)
			continue
		assert_true(
			shortest <= limit, "%s limit %d is at least the shortest program" % [entry["id"], limit]
		)


## Breadth-first search over (cell, direction); returns the fewest commands, or 0 if unsolvable.
func _shortest_program(level: Dictionary) -> int:
	var board: Dictionary = level["board"]
	var walls := {}
	for wall: Array in board["walls"]:
		walls[Vector2i(int(wall[0]), int(wall[1]))] = true
	var start: Array = level["initialState"]["position"]
	var goal_cell: Array = level["goal"]["position"]
	var goal := Vector2i(int(goal_cell[0]), int(goal_cell[1]))
	var first := [Vector2i(int(start[0]), int(start[1])), level["initialState"]["direction"]]
	var seen := {first: true}
	var frontier: Array = [first]
	var depth := 0
	while not frontier.is_empty() and depth < 150:
		depth += 1
		var next: Array = []
		for node: Array in frontier:
			var cell: Vector2i = node[0]
			var facing: String = node[1]
			var options: Array = []
			for side in ["left", "right"]:
				options.append([cell, LevelSimulator.turn(facing, side)])
			var ahead := LevelSimulator.cell_ahead([cell.x, cell.y], facing)
			var target := Vector2i(int(ahead[0]), int(ahead[1]))
			var inside := (
				target.x >= 0
				and target.y >= 0
				and target.x < int(board["width"])
				and target.y < int(board["height"])
			)
			if inside and not walls.has(target):
				if target == goal:
					return depth
				options.append([target, facing])
			for option: Array in options:
				if not seen.has(option):
					seen[option] = true
					next.append(option)
		frontier = next
	return 0
