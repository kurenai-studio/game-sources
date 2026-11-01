class_name PatrolValidator
extends RefCounted
## Validates the optional patrols of a level.
## Mirrors validatePatrols in packages/level-contract/src/validate.ts. Issues use LevelValidator's
## helpers and shape.


static func check_patrols(issues: Array[Dictionary], root: Dictionary) -> void:
	if not root.has("patrols"):
		return
	var raw: Variant = root["patrols"]
	if typeof(raw) != TYPE_ARRAY:
		LevelValidator._add(issues, "patrols", "INVALID_TYPE", "patrols must be an array.")
		return
	var entries: Array = raw
	if entries.size() < ContractLimits.PATROLS_MIN or entries.size() > ContractLimits.PATROLS_MAX:
		LevelValidator._add(
			issues,
			"patrols",
			"LENGTH_OUT_OF_RANGE",
			(
				"patrols must have %d to %d entries, or be left out."
				% [ContractLimits.PATROLS_MIN, ContractLimits.PATROLS_MAX]
			)
		)
	if root.has("extraBoards"):
		LevelValidator._add(
			issues,
			"patrols",
			"PATROLS_WITH_BOARDS",
			"A level with test boards cannot have patrols."
		)
	var facts := board_facts(root)
	for i in entries.size():
		_check_patrol(issues, entries[i], "patrols[%d]" % i, facts)


static func _check_patrol(
	issues: Array[Dictionary], entry: Variant, path: String, facts: Dictionary
) -> void:
	if typeof(entry) != TYPE_DICTIONARY:
		LevelValidator._add(issues, path, "INVALID_TYPE", "%s must be an object." % path)
		return
	var patrol: Dictionary = entry
	LevelValidator._reject_unknown(issues, patrol, path, ["pattern", "cells"])
	LevelValidator._enum_field(issues, patrol, path, "pattern", ContractLimits.PATROL_PATTERNS)
	var cells_path := path + ".cells"
	if not patrol.has("cells"):
		LevelValidator._add(issues, cells_path, "REQUIRED", "%s is required." % cells_path)
		return
	if typeof(patrol["cells"]) != TYPE_ARRAY:
		LevelValidator._add(issues, cells_path, "INVALID_TYPE", "%s must be an array." % cells_path)
		return
	var cells: Array = patrol["cells"]
	var is_loop: bool = patrol.get("pattern") == "loop"
	var low: int = (
		ContractLimits.PATROL_LOOP_CELLS_MIN if is_loop else ContractLimits.PATROL_CELLS_MIN
	)
	var high: int = ContractLimits.PATROL_CELLS_MAX
	if cells.size() < low or cells.size() > high:
		LevelValidator._add(
			issues,
			cells_path,
			"LENGTH_OUT_OF_RANGE",
			"%s must have %d to %d cells." % [cells_path, low, high]
		)
	var pairs: Array = []
	var seen: Array[Vector2i] = []
	for j in cells.size():
		var cell_path := "%s[%d]" % [cells_path, j]
		var pair: Variant = LevelValidator._check_pair(issues, cells[j], cell_path, facts["size"])
		pairs.append(pair)
		if pair == null:
			continue
		var at: Vector2i = pair
		if (facts["walls"] as Array).has(at):
			LevelValidator._add(
				issues, cell_path, "PATROL_ON_WALL", "%s must not be a wall." % cell_path
			)
		if seen.has(at):
			LevelValidator._add(
				issues, cell_path, "PATROL_CELLS_REPEAT", "%s repeats an earlier cell." % cell_path
			)
		else:
			seen.append(at)
		if j > 0 and pairs[j - 1] != null and not _adjacent(pairs[j - 1], at):
			LevelValidator._add(
				issues,
				cell_path,
				"PATROL_NOT_CONNECTED",
				"%s must be next to the cell before it." % cell_path
			)
	var first: Variant = pairs[0] if not pairs.is_empty() else null
	if first != null and facts["start"] != null and first == facts["start"]:
		LevelValidator._add(
			issues,
			cells_path + "[0]",
			"PATROL_ON_START",
			"A patrol must not start on the automaton's cell."
		)
	var last: Variant = pairs[pairs.size() - 1] if not pairs.is_empty() else null
	if (
		is_loop
		and first != null
		and last != null
		and pairs.size() > 1
		and not _adjacent(last, first)
	):
		LevelValidator._add(
			issues,
			cells_path,
			"PATROL_NOT_CONNECTED",
			"A ring must close: the last cell is next to the first."
		)


static func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1


## The well-formed parts of the board and start, read without reporting (the board check does that).
static func board_facts(root: Dictionary) -> Dictionary:
	var size: Variant = null
	var walls: Array = []
	var start: Variant = null
	if typeof(root.get("board")) == TYPE_DICTIONARY:
		var board: Dictionary = root["board"]
		var side_min := ContractLimits.BOARD_SIDE_MIN
		var side_max := ContractLimits.BOARD_SIDE_MAX
		var width: Variant = board.get("width")
		var height: Variant = board.get("height")
		if (
			LevelValidator._is_int(width)
			and LevelValidator._is_int(height)
			and int(width) >= side_min
			and int(width) <= side_max
			and int(height) >= side_min
			and int(height) <= side_max
		):
			size = Vector2i(int(width), int(height))
		if typeof(board.get("walls")) == TYPE_ARRAY:
			for wall: Variant in board["walls"]:
				var pair: Variant = _pair(wall)
				if pair != null:
					walls.append(pair)
	if typeof(root.get("initialState")) == TYPE_DICTIONARY:
		start = _pair((root["initialState"] as Dictionary).get("position"))
	var goal: Variant = null
	if typeof(root.get("goal")) == TYPE_DICTIONARY:
		goal = _pair((root["goal"] as Dictionary).get("position"))
	return {"size": size, "walls": walls, "start": start, "goal": goal}


static func _pair(v: Variant) -> Variant:
	if (
		typeof(v) == TYPE_ARRAY
		and v.size() == 2
		and LevelValidator._is_int(v[0])
		and LevelValidator._is_int(v[1])
	):
		return Vector2i(int(v[0]), int(v[1]))
	return null
