class_name BoardValidator
extends RefCounted
## Validates a board with its start and goal: the level's own, and the extra test boards.
## Mirrors validateBoardAndCells and validateExtraBoards in packages/level-contract/src/validate.ts.
## Issues use LevelValidator's helpers and shape.


static func _under(prefix: String, key: String) -> String:
	return key if prefix == "" else prefix + "." + key


## Checks the board, initialState and goal found in root. prefix is "" for the level itself and
## "extraBoards[i]" for a test board; it starts every issue path.
static func check_board_and_cells(
	issues: Array[Dictionary], root: Dictionary, prefix: String = ""
) -> void:
	var board_path := _under(prefix, "board")
	var initial_path := _under(prefix, "initialState")
	var goal_path := _under(prefix, "goal")
	var board: Variant = LevelValidator._object_field(issues, root, prefix, "board")
	var size: Variant = null
	var walls: Array = []
	if board != null:
		var board_dict: Dictionary = board
		LevelValidator._reject_unknown(issues, board_dict, board_path, ["width", "height", "walls"])
		var width: Variant = LevelValidator._int_field(
			issues,
			board_dict,
			board_path,
			"width",
			ContractLimits.BOARD_SIDE_MIN,
			ContractLimits.BOARD_SIDE_MAX
		)
		var height: Variant = LevelValidator._int_field(
			issues,
			board_dict,
			board_path,
			"height",
			ContractLimits.BOARD_SIDE_MIN,
			ContractLimits.BOARD_SIDE_MAX
		)
		if width != null and height != null:
			size = Vector2i(width, height)
		walls = _check_walls(issues, board_dict, size, board_path)

	var initial: Variant = LevelValidator._object_field(issues, root, prefix, "initialState")
	var start: Variant = null
	if initial != null:
		var initial_dict: Dictionary = initial
		LevelValidator._reject_unknown(
			issues, initial_dict, initial_path, ["position", "direction"]
		)
		var position_path := initial_path + ".position"
		if initial_dict.has("position"):
			start = LevelValidator._check_pair(
				issues, initial_dict["position"], position_path, size
			)
		else:
			LevelValidator._add(
				issues, position_path, "REQUIRED", "%s is required." % position_path
			)
		LevelValidator._enum_field(
			issues, initial_dict, initial_path, "direction", ContractLimits.DIRECTIONS
		)

	var goal: Variant = LevelValidator._object_field(issues, root, prefix, "goal")
	var goal_cell: Variant = null
	var goal_position_path := goal_path + ".position"
	if goal != null:
		var goal_dict: Dictionary = goal
		var goal_type: Variant = goal_dict.get("type")
		var visit_all: bool = typeof(goal_type) == TYPE_STRING and goal_type == "visit_all"
		var goal_keys: Array[String] = ["type", "position"]
		if visit_all:
			goal_keys = ["type"]
		LevelValidator._reject_unknown(issues, goal_dict, goal_path, goal_keys)
		LevelValidator._enum_field(issues, goal_dict, goal_path, "type", ContractLimits.GOAL_TYPES)
		if visit_all:
			# The sweep needs somewhere to go: at least two floor cells, the start and one more.
			if size != null and (size as Vector2i).x * (size as Vector2i).y - walls.size() < 2:
				LevelValidator._add(
					issues,
					goal_path,
					"GOAL_EQUALS_START",
					"The board needs at least two floor cells to sweep."
				)
		elif goal_dict.has("position"):
			goal_cell = LevelValidator._check_pair(
				issues, goal_dict["position"], goal_position_path, size
			)
		else:
			LevelValidator._add(
				issues, goal_position_path, "REQUIRED", "%s is required." % goal_position_path
			)

	if start != null and walls.has(start):
		LevelValidator._add(
			issues,
			initial_path + ".position",
			"START_ON_WALL",
			"The start cell must not be a wall."
		)
	if goal_cell != null and walls.has(goal_cell):
		LevelValidator._add(
			issues, goal_position_path, "GOAL_ON_WALL", "The goal cell must not be a wall."
		)
	if start != null and goal_cell != null and start == goal_cell:
		LevelValidator._add(
			issues,
			goal_position_path,
			"GOAL_EQUALS_START",
			"The goal cell must differ from the start cell."
		)


## Checks extraBoards when present: 1 to 5 objects, each validated like the level's own board.
static func check_extra_boards(issues: Array[Dictionary], root: Dictionary) -> void:
	if not root.has("extraBoards"):
		return
	var raw: Variant = root["extraBoards"]
	if typeof(raw) != TYPE_ARRAY:
		LevelValidator._add(issues, "extraBoards", "INVALID_TYPE", "extraBoards must be an array.")
		return
	var entries: Array = raw
	if (
		entries.size() < ContractLimits.EXTRA_BOARDS_MIN
		or entries.size() > ContractLimits.EXTRA_BOARDS_MAX
	):
		LevelValidator._add(
			issues,
			"extraBoards",
			"LENGTH_OUT_OF_RANGE",
			(
				"extraBoards must have %d to %d boards, or be left out."
				% [ContractLimits.EXTRA_BOARDS_MIN, ContractLimits.EXTRA_BOARDS_MAX]
			)
		)
	for i in entries.size():
		var path := "extraBoards[%d]" % i
		if typeof(entries[i]) != TYPE_DICTIONARY:
			LevelValidator._add(issues, path, "INVALID_TYPE", "%s must be an object." % path)
			continue
		var entry: Dictionary = entries[i]
		LevelValidator._reject_unknown(issues, entry, path, ["board", "initialState", "goal"])
		check_board_and_cells(issues, entry, path)


## Returns the well-formed wall cells (Vector2i). Malformed entries are reported and left out.
static func _check_walls(
	issues: Array[Dictionary], board: Dictionary, size: Variant, board_path: String
) -> Array:
	var walls_path := board_path + ".walls"
	if not board.has("walls"):
		LevelValidator._add(issues, walls_path, "REQUIRED", "%s is required." % walls_path)
		return []
	var raw: Variant = board["walls"]
	if typeof(raw) != TYPE_ARRAY:
		LevelValidator._add(issues, walls_path, "INVALID_TYPE", "%s must be an array." % walls_path)
		return []
	var entries: Array = raw
	if entries.size() > ContractLimits.MAX_WALLS:
		LevelValidator._add(
			issues,
			walls_path,
			"LENGTH_OUT_OF_RANGE",
			"%s must have at most %d entries." % [walls_path, ContractLimits.MAX_WALLS]
		)
	var out: Array = []
	var seen := {}
	for i in entries.size():
		var path := "%s[%d]" % [walls_path, i]
		var pair: Variant = LevelValidator._check_pair(issues, entries[i], path, size)
		if pair == null:
			continue
		if seen.has(pair):
			LevelValidator._add(
				issues, path, "DUPLICATE_WALL", "%s repeats an earlier wall." % path
			)
		else:
			seen[pair] = true
			out.append(pair)
	return out
