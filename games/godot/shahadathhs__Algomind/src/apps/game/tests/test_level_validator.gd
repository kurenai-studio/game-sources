extends GutTest
## Edge cases of the level and program validators beyond the shared fixtures.


func _pairs(level: Variant) -> Array[String]:
	return ContractSupport.pairs(LevelValidator.validate_level(level)["issues"])


func test_base_level_is_valid() -> void:
	var result := LevelValidator.validate_level(ContractSupport.base_level())
	assert_true(result["ok"])
	assert_eq(result["issues"], [])


func test_whole_floats_count_as_integers() -> void:
	var level := ContractSupport.base_level()
	level["board"]["width"] = 5.0
	level["constraints"]["maxSteps"] = 30.0
	assert_eq(_pairs(level), [])


func test_fractional_numbers_are_invalid_type_not_out_of_range() -> void:
	var level := ContractSupport.base_level()
	level["board"]["width"] = 5.5
	level["goal"]["position"] = [4.0, 0.5]
	assert_eq(_pairs(level), ["board.width|INVALID_TYPE", "goal.position|INVALID_TYPE"])


func test_huge_and_special_numbers_never_crash() -> void:
	for value: Variant in [1e300, -1e300, 9007199254740993.0, INF, -INF, NAN, 9223372036854775807]:
		var level := ContractSupport.base_level()
		level["levelVersion"] = value
		level["constraints"]["maxSteps"] = value
		level["initialState"]["position"] = [value, 0]
		level["schemaVersion"] = value
		assert_false(LevelValidator.validate_level(level)["ok"], str(value))


func test_negative_numbers_are_out_of_range() -> void:
	var level := ContractSupport.base_level()
	level["board"]["height"] = -3
	level["constraints"]["maxCommands"] = -1
	assert_eq(_pairs(level), ["board.height|OUT_OF_RANGE", "constraints.maxCommands|OUT_OF_RANGE"])


func test_booleans_and_numeric_strings_are_not_integers() -> void:
	var level := ContractSupport.base_level()
	level["board"]["width"] = true
	level["board"]["height"] = "5"
	assert_eq(_pairs(level), ["board.height|INVALID_TYPE", "board.width|INVALID_TYPE"])


func test_unsupported_schema_version_is_the_only_issue() -> void:
	var level := ContractSupport.base_level()
	level["schemaVersion"] = 2.0
	level["title"] = 7
	assert_eq(_pairs(level), ["schemaVersion|UNSUPPORTED_SCHEMA_VERSION"])


func test_garbage_input_never_crashes() -> void:
	var garbage: Array = [
		null,
		true,
		0,
		1.5,
		"text",
		[],
		[[[[]]]],
		{},
		{"board": 5, "goal": [], "initialState": null, "hints": {}, "requires": []},
		{"schemaVersion": 1, "board": {"walls": [[], [[]], null, "x", {"a": 1}, [1]]}},
		{"schemaVersion": 1, "availableCommands": [null, 1, [], {}], "hints": [null, [], 5]},
		{"schemaVersion": 1, "requires": {"mechanics": [1, null, "", "A", "ok", "ok"]}},
	]
	for value: Variant in garbage:
		var result := LevelValidator.validate_level(value)
		assert_false(result["ok"], str(value))
		var authoring := LevelValidator.validate_authoring_level(value)
		assert_false(authoring["ok"], str(value))
		var program := LevelValidator.validate_program(value, value)
		assert_true(program.has("issues"))


func test_root_that_is_not_an_object_has_one_issue() -> void:
	for value: Variant in [null, [], "x", 3]:
		assert_eq(_pairs(value), ["|INVALID_TYPE"])


func test_null_is_not_missing() -> void:
	var level := ContractSupport.base_level()
	level["title"] = null
	level.erase("slug")
	assert_eq(_pairs(level), ["slug|REQUIRED", "title|INVALID_TYPE"])


func test_reference_solution_is_unknown_in_a_public_level() -> void:
	var level := ContractSupport.base_level()
	level["referenceSolution"] = ContractSupport.program_of(["MOVE_FORWARD"])
	assert_eq(_pairs(level), ["referenceSolution|UNKNOWN_FIELD"])


func test_authoring_requires_a_valid_reference_solution() -> void:
	var level := ContractSupport.base_level()
	var missing := LevelValidator.validate_authoring_level(level)
	assert_eq(ContractSupport.pairs(missing["issues"]), ["referenceSolution|REQUIRED"])
	level["referenceSolution"] = [{"op": "JUMP"}, {"op": "MOVE_FORWARD", "x": 1}, 4]
	var bad := LevelValidator.validate_authoring_level(level)
	assert_eq(
		ContractSupport.pairs(bad["issues"]),
		[
			"referenceSolution[0].op|UNKNOWN_COMMAND",
			"referenceSolution[1].x|UNKNOWN_FIELD",
			"referenceSolution[2]|INVALID_TYPE",
		]
	)
