class_name ContractSupport
extends RefCounted
## Helpers shared by the level-contract tests.

## Where `make game-fixtures` copies packages/level-contract/fixtures.
const FIXTURE_ROOT := "res://tests/contract_fixtures"


## Parsed JSON of a file; null when it cannot be read or parsed.
static func load_json(path: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null
	return JSON.parse_string(file.get_as_text())


## Sorted file names (with .json) of one fixture directory, for example "levels/valid".
static func fixture_names(directory: String) -> Array[String]:
	var names: Array[String] = []
	for file_name in DirAccess.get_files_at("%s/%s" % [FIXTURE_ROOT, directory]):
		if file_name.ends_with(".json"):
			names.append(file_name)
	names.sort()
	return names


static func load_fixture(directory: String, file_name: String) -> Variant:
	return load_json("%s/%s/%s" % [FIXTURE_ROOT, directory, file_name])


## Deep equality where any two numbers are equal when numerically equal: JSON parsing yields
## floats, while the simulator yields ints, and 3 must equal 3.0 (but not 3.5).
static func same(a: Variant, b: Variant) -> bool:
	var a_number := typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT
	var b_number := typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT
	if a_number and b_number:
		return float(a) == float(b)
	if typeof(a) != typeof(b):
		return false
	if typeof(a) == TYPE_ARRAY:
		var a_array: Array = a
		var b_array: Array = b
		if a_array.size() != b_array.size():
			return false
		for i in a_array.size():
			if not same(a_array[i], b_array[i]):
				return false
		return true
	if typeof(a) == TYPE_DICTIONARY:
		var a_dict: Dictionary = a
		var b_dict: Dictionary = b
		if a_dict.size() != b_dict.size():
			return false
		for key: Variant in a_dict.keys():
			if not b_dict.has(key) or not same(a_dict[key], b_dict[key]):
				return false
		return true
	return a == b


## A valid public level as the JSON parser would give it (all numbers are floats).
static func base_level() -> Dictionary:
	return JSON.parse_string(
		(
			'{"schemaVersion":1,"levelId":"level-intro-001","levelVersion":1,'
			+ '"slug":"first-steps","title":"First Steps","description":"Reach the goal.",'
			+ '"difficulty":"easy","requires":{"mechanics":[]},'
			+ '"board":{"width":5,"height":5,"walls":[[1,1],[1,2],[3,3]]},'
			+ '"initialState":{"position":[0,4],"direction":"north"},'
			+ '"availableCommands":["MOVE_FORWARD","TURN_LEFT","TURN_RIGHT"],'
			+ '"constraints":{"maxCommands":12,"maxSteps":30},'
			+ '"goal":{"type":"reach_tile","position":[4,0]},"hints":[]}'
		)
	)


## A program from op names.
static func program_of(ops: Array) -> Array:
	var out: Array = []
	for op: Variant in ops:
		out.append({"op": op})
	return out


## Issues as a sorted Array of "path|code" strings, so sets compare with ==. A repeated pair
## stays repeated, which the contract forbids.
static func pairs(issues: Array) -> Array[String]:
	var out: Array[String] = []
	for issue: Dictionary in issues:
		out.append("%s|%s" % [issue["path"], issue["code"]])
	out.sort()
	return out
