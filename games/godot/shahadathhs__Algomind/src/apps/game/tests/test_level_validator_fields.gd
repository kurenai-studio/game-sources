extends GutTest
## Field rules of the level validator: patterns, lengths, cells, walls, and programs.


func _pairs(level: Variant) -> Array[String]:
	return ContractSupport.pairs(LevelValidator.validate_level(level)["issues"])


func test_id_pattern_is_strict() -> void:
	for bad: String in ["Abc", "a--b", "-a", "a-", "a_b", "a b", "a\n", "\na", "ä", "a-b-"]:
		var level := ContractSupport.base_level()
		level["levelId"] = bad
		assert_eq(_pairs(level), ["levelId|INVALID_FORMAT"], bad.c_escape())
	for good: String in ["a", "0", "a-b", "a1-b2-c3", "x".repeat(64)]:
		var level := ContractSupport.base_level()
		level["slug"] = good
		assert_eq(_pairs(level), [], good)


func test_id_length_beats_format() -> void:
	var level := ContractSupport.base_level()
	level["levelId"] = ""
	level["slug"] = "a".repeat(65)
	assert_eq(_pairs(level), ["levelId|LENGTH_OUT_OF_RANGE", "slug|LENGTH_OUT_OF_RANGE"])


func test_mechanic_pattern_is_strict() -> void:
	for bad: String in ["1a", "A", "a-b", "a b", "a\n", "_a"]:
		var level := ContractSupport.base_level()
		level["requires"]["mechanics"] = [bad]
		assert_eq(_pairs(level), ["requires.mechanics[0]|INVALID_FORMAT"], bad.c_escape())
	var ok_level := ContractSupport.base_level()
	ok_level["requires"]["mechanics"] = ["a", "a_1", "b"]
	assert_eq(_pairs(ok_level), [])


func test_duplicate_mechanic_and_command_report_the_later_index() -> void:
	var level := ContractSupport.base_level()
	level["requires"]["mechanics"] = ["x", "y", "x"]
	level["availableCommands"] = ["TURN_LEFT", "TURN_LEFT"]
	assert_eq(
		_pairs(level),
		["availableCommands[1]|DUPLICATE_COMMAND", "requires.mechanics[2]|DUPLICATE_MECHANIC"]
	)


func test_command_names_are_case_sensitive() -> void:
	var level := ContractSupport.base_level()
	level["availableCommands"] = ["move_forward"]
	assert_eq(_pairs(level), ["availableCommands[0]|UNKNOWN_COMMAND"])


func test_string_length_counts_code_points() -> void:
	var level := ContractSupport.base_level()
	level["title"] = "\U01F600".repeat(60)
	assert_eq(_pairs(level), [])
	level["title"] = "\U01F600".repeat(61)
	assert_eq(_pairs(level), ["title|LENGTH_OUT_OF_RANGE"])


func test_bad_board_size_suppresses_outside_board() -> void:
	var level := ContractSupport.base_level()
	level["board"]["width"] = 99
	level["goal"]["position"] = [50, 50]
	assert_eq(_pairs(level), ["board.width|OUT_OF_RANGE"])


func test_cells_outside_the_board() -> void:
	var level := ContractSupport.base_level()
	level["board"]["walls"] = [[5, 0], [0, -1]]
	level["goal"]["position"] = [4, 5]
	assert_eq(
		_pairs(level),
		[
			"board.walls[0]|OUTSIDE_BOARD",
			"board.walls[1]|OUTSIDE_BOARD",
			"goal.position|OUTSIDE_BOARD"
		]
	)


func test_duplicate_wall_start_on_wall_goal_on_wall_and_goal_equals_start() -> void:
	var level := ContractSupport.base_level()
	level["board"]["walls"] = [[1, 1], [1, 1.0], [0, 4], [4, 0]]
	level["goal"]["position"] = [4, 0]
	assert_eq(
		_pairs(level),
		[
			"board.walls[1]|DUPLICATE_WALL",
			"goal.position|GOAL_ON_WALL",
			"initialState.position|START_ON_WALL"
		]
	)
	level["board"]["walls"] = []
	level["goal"]["position"] = [0.0, 4.0]
	assert_eq(_pairs(level), ["goal.position|GOAL_EQUALS_START"])


func test_too_many_walls() -> void:
	var level := ContractSupport.base_level()
	var walls: Array = []
	level["board"]["width"] = 12
	level["board"]["height"] = 12
	for i in 101:
		walls.append([i % 12, i / 12 + 1])
	level["board"]["walls"] = walls
	level["goal"]["position"] = [11, 0]
	level["initialState"]["position"] = [0, 0]
	assert_eq(_pairs(level), ["board.walls|LENGTH_OUT_OF_RANGE"])


func test_validator_does_not_modify_its_input() -> void:
	var level := ContractSupport.base_level()
	level["board"]["width"] = 99
	var before := level.duplicate(true)
	LevelValidator.validate_level(level)
	assert_true(ContractSupport.same(level, before))


func test_program_validation() -> void:
	var level := ContractSupport.base_level()
	level["availableCommands"] = ["MOVE_FORWARD"]
	level["constraints"]["maxCommands"] = 2
	var program: Array = [
		{"op": "TURN_LEFT"}, {"op": "JUMP"}, {"op": 3}, {}, {"op": "MOVE_FORWARD", "x": 1}, "s"
	]
	var result := LevelValidator.validate_program(level, program)
	assert_eq(
		ContractSupport.pairs(result["issues"]),
		[
			"program[0].op|COMMAND_NOT_AVAILABLE",
			"program[1].op|UNKNOWN_COMMAND",
			"program[2].op|INVALID_TYPE",
			"program[3].op|REQUIRED",
			"program[4].x|UNKNOWN_FIELD",
			"program[5]|INVALID_TYPE",
			"program|TOO_MANY_COMMANDS",
		]
	)


func test_program_that_is_not_an_array() -> void:
	var level := ContractSupport.base_level()
	for value: Variant in [null, {}, "x", 3]:
		var result := LevelValidator.validate_program(level, value)
		assert_eq(ContractSupport.pairs(result["issues"]), ["program|INVALID_TYPE"])


func test_empty_program_is_valid_and_length_at_the_limit_is_valid() -> void:
	var level := ContractSupport.base_level()
	assert_true(LevelValidator.validate_program(level, [])["ok"])
	level["constraints"]["maxCommands"] = 2
	var two := ContractSupport.program_of(["MOVE_FORWARD", "TURN_LEFT"])
	assert_true(LevelValidator.validate_program(level, two)["ok"])
	two.append({"op": "TURN_RIGHT"})
	assert_false(LevelValidator.validate_program(level, two)["ok"])
