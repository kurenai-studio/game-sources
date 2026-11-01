class_name LevelValidator
extends RefCounted
## Validates a downloaded public level (parsed JSON) and programs against a level.
## Mirrors packages/level-contract/src/validate.ts; the rules are specified in
## packages/level-contract/README.md and pinned by its fixtures.
##
## Every function takes any Variant and never fails on garbage input. A result is
## { "ok": bool, "issues": [ { "path": String, "code": String, "message": String } ] }.
##
## Numbers: JSON parsing yields floats for every number. A value counts as an integer when it
## is a finite whole number within +-(2^53 - 1) (3.0 is an integer, 3.5 is not). Anything
## larger is not an integer, which also keeps the float arithmetic exact.

enum Pattern { NONE, ID, MECHANIC }

const _PUBLIC_KEYS: Array[String] = [
	"schemaVersion",
	"levelId",
	"levelVersion",
	"slug",
	"title",
	"description",
	"difficulty",
	"requires",
	"board",
	"initialState",
	"availableCommands",
	"constraints",
	"goal",
	"extraBoards",
	"startProgram",
	"patrols",
	"locks",
	"deliveries",
	"switches",
	"teleports",
	"ice",
	"belts",
	"hints",
]


## Validates a public level: no referenceSolution allowed.
static func validate_level(input: Variant) -> Dictionary:
	return _validate_level_with(input, false)


## Validates an authoring level: the public definition plus a required referenceSolution.
static func validate_authoring_level(input: Variant) -> Dictionary:
	return _validate_level_with(input, true)


## Validates a program against a level: well-formed nodes, known ops that the level offers,
## and a length within maxCommands. An empty program is valid.
static func validate_program(level: Variant, program: Variant) -> Dictionary:
	var issues: Array[Dictionary] = []
	ProgramValidator.check_program(issues, program, "program", ProgramValidator.limits_of(level))
	return _result(issues)


static func _result(issues: Array[Dictionary]) -> Dictionary:
	return {"ok": issues.is_empty(), "issues": issues}


static func _add(issues: Array[Dictionary], path: String, code: String, message: String) -> void:
	issues.append({"path": path, "code": code, "message": message})


static func _join(base: String, key: String) -> String:
	return key if base == "" else base + "." + key


static func _is_int(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return absi(v) <= ContractLimits.MAX_SAFE_INTEGER
	if typeof(v) == TYPE_FLOAT:
		return is_finite(v) and absf(v) <= float(ContractLimits.MAX_SAFE_INTEGER) and v == floorf(v)
	return false


static func _is_command_name(v: Variant) -> bool:
	return typeof(v) == TYPE_STRING and ContractLimits.COMMAND_NAMES.has(v)


## Reports every key of obj that is not in allowed.
static func _reject_unknown(
	issues: Array[Dictionary], obj: Dictionary, base: String, allowed: Array[String]
) -> void:
	for key: Variant in obj.keys():
		var name := str(key)
		if typeof(key) != TYPE_STRING or not allowed.has(name):
			var path := _join(base, name)
			_add(issues, path, "UNKNOWN_FIELD", "%s is not a known field." % path)


## Reads a required object field. Returns null (after reporting) when absent or not an object.
static func _object_field(
	issues: Array[Dictionary], obj: Dictionary, base: String, key: String
) -> Variant:
	var path := _join(base, key)
	if not obj.has(key):
		_add(issues, path, "REQUIRED", "%s is required." % path)
		return null
	if typeof(obj[key]) != TYPE_DICTIONARY:
		_add(issues, path, "INVALID_TYPE", "%s must be an object." % path)
		return null
	return obj[key]


## Reads a required integer in [low, high]. Returns null after reporting a problem.
static func _int_field(
	issues: Array[Dictionary], obj: Dictionary, base: String, key: String, low: int, high: int
) -> Variant:
	var path := _join(base, key)
	if not obj.has(key):
		_add(issues, path, "REQUIRED", "%s is required." % path)
		return null
	var v: Variant = obj[key]
	if not _is_int(v):
		_add(issues, path, "INVALID_TYPE", "%s must be an integer." % path)
		return null
	var n := int(v)
	if n < low or n > high:
		_add(issues, path, "OUT_OF_RANGE", "%s must be between %d and %d." % [path, low, high])
		return null
	return n


static func _string_field(
	issues: Array[Dictionary],
	obj: Dictionary,
	base: String,
	key: String,
	low: int,
	high: int,
	pattern: Pattern = Pattern.NONE
) -> Variant:
	var path := _join(base, key)
	if not obj.has(key):
		_add(issues, path, "REQUIRED", "%s is required." % path)
		return null
	return _check_string(issues, obj[key], path, low, high, pattern)


## Type, then length (in code points), then pattern. Returns the string, or null on a problem.
static func _check_string(
	issues: Array[Dictionary],
	v: Variant,
	path: String,
	low: int,
	high: int,
	pattern: Pattern = Pattern.NONE
) -> Variant:
	if typeof(v) != TYPE_STRING:
		_add(issues, path, "INVALID_TYPE", "%s must be a string." % path)
		return null
	var s: String = v
	# Godot strings are UTF-32, so length() counts code points.
	var length := s.length()
	if length < low or length > high:
		_add(
			issues,
			path,
			"LENGTH_OUT_OF_RANGE",
			"%s must be %d to %d characters long." % [path, low, high]
		)
		return null
	if not _matches(s, pattern):
		_add(issues, path, "INVALID_FORMAT", "%s has an invalid format." % path)
		return null
	return s


## Hand-written matchers: PCRE's $ also matches before a trailing newline, the contract's does not.
static func _matches(s: String, pattern: Pattern) -> bool:
	if pattern == Pattern.ID:
		# ^[a-z0-9]+(-[a-z0-9]+)*$
		var previous_hyphen := true
		for i in s.length():
			var c := s.unicode_at(i)
			if c == 45:
				if previous_hyphen:
					return false
				previous_hyphen = true
			elif _is_lower(c) or _is_digit(c):
				previous_hyphen = false
			else:
				return false
		return not previous_hyphen
	if pattern == Pattern.MECHANIC:
		# ^[a-z][a-z0-9_]*$
		if s.is_empty() or not _is_lower(s.unicode_at(0)):
			return false
		for i in range(1, s.length()):
			var c := s.unicode_at(i)
			if not (_is_lower(c) or _is_digit(c) or c == 95):
				return false
	return true


static func _is_lower(c: int) -> bool:
	return c >= 97 and c <= 122


static func _is_digit(c: int) -> bool:
	return c >= 48 and c <= 57


static func _enum_field(
	issues: Array[Dictionary], obj: Dictionary, base: String, key: String, allowed: Array[String]
) -> void:
	var path := _join(base, key)
	if not obj.has(key):
		_add(issues, path, "REQUIRED", "%s is required." % path)
		return
	var v: Variant = obj[key]
	if typeof(v) != TYPE_STRING:
		_add(issues, path, "INVALID_TYPE", "%s must be a string." % path)
	elif not allowed.has(v):
		_add(issues, path, "INVALID_VALUE", "%s must be one of: %s." % [path, ", ".join(allowed)])


## Checks that v is a pair [x, y] of integers. Reports INVALID_TYPE otherwise and returns null.
## When the board size is known and the cell lies outside it, reports OUTSIDE_BOARD but still
## returns the pair so the wall, start, and goal comparisons can run. size is a Vector2i or null.
static func _check_pair(
	issues: Array[Dictionary], v: Variant, path: String, size: Variant
) -> Variant:
	if typeof(v) != TYPE_ARRAY or v.size() != 2 or not _is_int(v[0]) or not _is_int(v[1]):
		_add(issues, path, "INVALID_TYPE", "%s must be a pair [x, y] of integers." % path)
		return null
	var cell := Vector2i(int(v[0]), int(v[1]))
	if size != null:
		var board: Vector2i = size
		if cell.x < 0 or cell.y < 0 or cell.x >= board.x or cell.y >= board.y:
			_add(
				issues,
				path,
				"OUTSIDE_BOARD",
				"%s must be inside the %d by %d board." % [path, board.x, board.y]
			)
	return cell


static func _validate_level_with(input: Variant, authoring: bool) -> Dictionary:
	var issues: Array[Dictionary] = []
	_run(issues, input, authoring)
	return _result(issues)


static func _run(issues: Array[Dictionary], input: Variant, authoring: bool) -> void:
	if typeof(input) != TYPE_DICTIONARY:
		_add(issues, "", "INVALID_TYPE", "The level must be an object.")
		return
	var root: Dictionary = input

	# An unsupported schema version is rejected on its own: nothing else can be trusted.
	if root.has("schemaVersion") and _is_int(root["schemaVersion"]):
		var version := int(root["schemaVersion"])
		if version != ContractLimits.SCHEMA_VERSION:
			_add(
				issues,
				"schemaVersion",
				"UNSUPPORTED_SCHEMA_VERSION",
				(
					"schemaVersion %d is not supported; expected %d."
					% [version, ContractLimits.SCHEMA_VERSION]
				)
			)
			return
	elif root.has("schemaVersion"):
		_add(issues, "schemaVersion", "INVALID_TYPE", "schemaVersion must be an integer.")
	else:
		_add(issues, "schemaVersion", "REQUIRED", "schemaVersion is required.")

	var allowed := _PUBLIC_KEYS.duplicate()
	if authoring:
		allowed.append("referenceSolution")
	_reject_unknown(issues, root, "", allowed)

	_string_field(
		issues, root, "", "levelId", ContractLimits.ID_MIN, ContractLimits.ID_MAX, Pattern.ID
	)
	_int_field(
		issues,
		root,
		"",
		"levelVersion",
		ContractLimits.LEVEL_VERSION_MIN,
		ContractLimits.LEVEL_VERSION_MAX
	)
	_string_field(
		issues, root, "", "slug", ContractLimits.ID_MIN, ContractLimits.ID_MAX, Pattern.ID
	)
	_string_field(issues, root, "", "title", ContractLimits.TITLE_MIN, ContractLimits.TITLE_MAX)
	_string_field(
		issues,
		root,
		"",
		"description",
		ContractLimits.DESCRIPTION_MIN,
		ContractLimits.DESCRIPTION_MAX
	)
	_enum_field(issues, root, "", "difficulty", ContractLimits.DIFFICULTIES)
	_validate_requires(issues, root)
	BoardValidator.check_board_and_cells(issues, root)
	BoardValidator.check_extra_boards(issues, root)
	PatrolValidator.check_patrols(issues, root)
	PairValidator.check_all(issues, root)
	TileValidator.check_all(issues, root)
	_validate_commands(issues, root)
	_validate_constraints(issues, root)
	_validate_hints(issues, root)
	if root.has("startProgram"):
		ProgramValidator.check_program(
			issues, root["startProgram"], "startProgram", ProgramValidator.limits_of(root)
		)

	if authoring:
		if not root.has("referenceSolution"):
			_add(issues, "referenceSolution", "REQUIRED", "referenceSolution is required.")
		else:
			ProgramValidator.check_program(
				issues,
				root["referenceSolution"],
				"referenceSolution",
				ProgramValidator.limits_of(root)
			)


static func _validate_commands(issues: Array[Dictionary], root: Dictionary) -> void:
	if not root.has("availableCommands"):
		_add(issues, "availableCommands", "REQUIRED", "availableCommands is required.")
		return
	var raw: Variant = root["availableCommands"]
	if typeof(raw) != TYPE_ARRAY:
		_add(issues, "availableCommands", "INVALID_TYPE", "availableCommands must be an array.")
		return
	var items: Array = raw
	if items.is_empty():
		_add(
			issues,
			"availableCommands",
			"LENGTH_OUT_OF_RANGE",
			"availableCommands must not be empty."
		)
	var seen := {}
	for i in items.size():
		var path := "availableCommands[%d]" % i
		var item: Variant = items[i]
		if typeof(item) != TYPE_STRING:
			_add(issues, path, "INVALID_TYPE", "%s must be a string." % path)
		elif not _is_command_name(item):
			_add(issues, path, "UNKNOWN_COMMAND", "%s is not a known command." % path)
		elif seen.has(item):
			_add(issues, path, "DUPLICATE_COMMAND", "%s repeats an earlier command." % path)
		else:
			seen[item] = true


static func _validate_requires(issues: Array[Dictionary], root: Dictionary) -> void:
	var requires: Variant = _object_field(issues, root, "", "requires")
	if requires == null:
		return
	var requires_dict: Dictionary = requires
	_reject_unknown(issues, requires_dict, "requires", ["mechanics"])
	if not requires_dict.has("mechanics"):
		_add(issues, "requires.mechanics", "REQUIRED", "requires.mechanics is required.")
		return
	var raw: Variant = requires_dict["mechanics"]
	if typeof(raw) != TYPE_ARRAY:
		_add(issues, "requires.mechanics", "INVALID_TYPE", "requires.mechanics must be an array.")
		return
	var items: Array = raw
	if items.size() > ContractLimits.MECHANICS_MAX_COUNT:
		_add(
			issues,
			"requires.mechanics",
			"LENGTH_OUT_OF_RANGE",
			"requires.mechanics must have at most %d entries." % ContractLimits.MECHANICS_MAX_COUNT
		)
	var seen := {}
	for i in items.size():
		var path := "requires.mechanics[%d]" % i
		var name: Variant = _check_string(
			issues,
			items[i],
			path,
			ContractLimits.MECHANIC_MIN,
			ContractLimits.MECHANIC_MAX,
			Pattern.MECHANIC
		)
		if name == null:
			continue
		if seen.has(name):
			_add(issues, path, "DUPLICATE_MECHANIC", "%s repeats an earlier mechanic." % path)
		else:
			seen[name] = true


static func _validate_constraints(issues: Array[Dictionary], root: Dictionary) -> void:
	var constraints: Variant = _object_field(issues, root, "", "constraints")
	if constraints == null:
		return
	var dict: Dictionary = constraints
	_reject_unknown(issues, dict, "constraints", ["maxCommands", "maxSteps"])
	_int_field(
		issues,
		dict,
		"constraints",
		"maxCommands",
		ContractLimits.MAX_COMMANDS_MIN,
		ContractLimits.MAX_COMMANDS_MAX
	)
	_int_field(
		issues,
		dict,
		"constraints",
		"maxSteps",
		ContractLimits.MAX_STEPS_MIN,
		ContractLimits.MAX_STEPS_MAX
	)


static func _validate_hints(issues: Array[Dictionary], root: Dictionary) -> void:
	if not root.has("hints"):
		_add(issues, "hints", "REQUIRED", "hints is required.")
		return
	var raw: Variant = root["hints"]
	if typeof(raw) != TYPE_ARRAY:
		_add(issues, "hints", "INVALID_TYPE", "hints must be an array.")
		return
	var items: Array = raw
	if items.size() > ContractLimits.HINTS_MAX_COUNT:
		_add(
			issues,
			"hints",
			"LENGTH_OUT_OF_RANGE",
			"hints must have at most %d entries." % ContractLimits.HINTS_MAX_COUNT
		)
	for i in items.size():
		_check_string(
			issues, items[i], "hints[%d]" % i, ContractLimits.HINT_MIN, ContractLimits.HINT_MAX
		)
